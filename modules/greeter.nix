# greeter.nix — how the login screen is launched.
#
# dotfiles-nix ships the screen itself as a bin (its packages.greeter, an AGS
# surface built rather than run from live source). Everything about how that
# bin reaches the seat — the compositor under it, the user it runs as, what
# that user is allowed to do — is decided here, because the greeter user's
# state is this repository's problem (greeter-state.nix, docs/adr/0005).
#
# Replaces sysc-greet, which was a whole third-party greeter carrying its own
# module, its own preference store, and a session picker for the one session
# this machine has.

{
  config,
  lib,
  pkgs,
  greeterPackage,
  ...
}:

let
  # The same Hyprland the user session runs, so the greeter cannot be left
  # behind on an older compositor by a partial update.
  hyprland = config.programs.hyprland.package;

  # The screen exits the moment a session starts, and greetd hands the seat
  # over only once this whole process tree is gone — so the compositor's only
  # job is to run the screen and then follow it out. A compositor crash makes
  # GJS fail instead; leave Hyprland running in that case so the seat wrapper
  # below can put the screen back on the watchdog's replacement compositor.
  #
  # systemd-cat is not decoration: greetd gives its session the seat's VT for
  # stdio, and the screen is drawing on that VT, so anything it prints lands
  # under the compositor where no one can read it. A login screen that dies
  # has to say why somewhere survivable, and journald is the only such place
  # before a user session exists.
  #
  # The identifier is a hint, not a promise. Making stderr a journal stream is
  # what matters — GJS notices that and writes its entries to the journal
  # directly, tagged from its own program name, so the screen's lines arrive
  # under `gjs` rather than `greeter`. Grep the journal for the message, never
  # for this tag.
  session = pkgs.writeShellScript "greeter-session" ''
    socket="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
    socket_id=$(${pkgs.coreutils}/bin/stat --format=%d:%i "$socket")

    if ${config.systemd.package}/bin/systemd-cat --identifier=greeter ${lib.getExe greeterPackage}; then
      current_socket_id=$(${pkgs.coreutils}/bin/stat --format=%d:%i "$socket" 2>/dev/null || true)
      if test "$current_socket_id" = "$socket_id"; then
        ${hyprland}/bin/hyprctl --instance 0 dispatch exit
        exit 0
      fi
    fi

    exit 1
  '';

  # The greeter's warm surface has to land on the primary display, but this
  # Hyprland instance has no monitors.conf: without a per-host pin,
  # auto-placement puts whichever connector Hyprland enumerates first at (0,0)
  # and the screen appears on the wrong seat. The greeter code identifies
  # primary as "monitor at (0,0)" (common/monitors.ts's findPrimaryMonitor,
  # shared with the session lock), so making that contract hold here is what
  # puts the screen where it should be.
  primaryRule = lib.optionalString (config.hardware.primaryMonitor != null)
    "monitor = ${config.hardware.primaryMonitor}, preferred, 0x0, 1\n";

  # A compositor with one client, no wallpaper, and nothing to configure.
  # Note for anything added here: `#` opens a comment in a Hyprland config
  # even inside an exec argument, so a hex colour has to be written `##`.
  greeterConf = pkgs.writeText "greeter-hyprland.conf" ''
    monitor = , preferred, auto, 1
    ${primaryRule}
    animations {
      enabled = false
    }

    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
      force_default_wallpaper = 0
    }
  '';

  # An initialized Hyprland that crashes is deliberately restarted by
  # start-hyprland in safe mode. Safe mode ignores the greeter config, so an
  # exec-once there could never restore the screen. Keep the watchdog as the
  # compositor owner, but launch the screen whenever one of its children
  # exposes a Wayland socket. A successful screen exit is a login and shuts
  # the compositor down; a failed exit means the socket disappeared, so the
  # loop waits for the safe-mode replacement and launches a fresh screen.
  greeterCompositor = pkgs.writeShellScript "greeter-compositor" ''
    ${hyprland}/bin/start-hyprland -- --config ${greeterConf} &
    watchdog_pid=$!

    cleanup() {
      kill "$watchdog_pid" 2>/dev/null || true
      wait "$watchdog_pid" 2>/dev/null || true
    }
    trap cleanup EXIT
    trap 'exit 0' INT TERM

    while kill -0 "$watchdog_pid" 2>/dev/null; do
      for socket in "$XDG_RUNTIME_DIR"/wayland-*; do
        test -S "$socket" || continue
        export WAYLAND_DISPLAY
        WAYLAND_DISPLAY=$(${pkgs.coreutils}/bin/basename "$socket")

        if ${session}; then
          wait "$watchdog_pid"
          exit $?
        fi
      done

      ${pkgs.coreutils}/bin/sleep 0.2
    done

    wait "$watchdog_pid"
  '';
in
{
  services.greetd = {
    enable = true;
    # The user is greetd's own default, `greeter`; greeter-state.nix pins its
    # uid and owns its home.
    #
    # start-hyprland, not Hyprland: 0.55 expects to be started through its
    # watchdog and says so on the screen when it isn't, which put an error
    # banner on the login screen. The watchdog is also the behaviour we want
    # here — it exits when Hyprland exits cleanly (the greeter's normal end)
    # and restarts it when it doesn't, so a compositor crash puts the login
    # screen back rather than leaving a black VT with greetd waiting on a
    # process tree that will never do anything. The seat wrapper above starts
    # the screen on both its configured child and its safe-mode replacement.
    #
    # greetd attaches this whole tree's stdout and stderr to the seat VT. The
    # VT is the greeter's visible surface, so start-hyprland's warning and
    # Hyprland's banner/debug output must leave through journald instead.
    # systemd-cat changes only those inherited streams: start-hyprland remains
    # the watchdog supervising Hyprland, with its exit behavior intact.
    settings.default_session.command =
      "${config.systemd.package}/bin/systemd-cat --identifier=greeter-compositor ${greeterCompositor}";
  };

  # The screen reads the session's command out of
  # /run/current-system/sw/share/wayland-sessions/hyprland-uwsm.desktop rather
  # than baking a uwsm store path, so it stays correct across uwsm updates
  # without a rebuild of its own. That directory is linked into the system
  # path by the uwsm module, which desktop.nix turns on via
  # programs.hyprland.withUWSM — nothing extra is needed here, but the
  # dependency is real: drop uwsm and the greeter has no session to start.

  # The two power verbs on the screen. logind would put an interactive
  # authentication prompt in front of both, and at the login screen there is
  # nobody logged in to answer it. Hibernate is included where sysc-greet's
  # equivalent rule covered only power-off and reboot: this screen offers
  # hibernate, and this machine hibernates by design (hibernation.nix).
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "greeter" &&
          (action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.hibernate")) {
        return polkit.Result.YES;
      }
    });
  '';
}
