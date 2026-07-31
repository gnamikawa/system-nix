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
  # job is to run the screen and then follow it out.
  #
  # systemd-cat is not decoration: greetd gives its session the seat's VT for
  # stdio, and the screen is drawing on that VT, so anything it prints lands
  # under the compositor where no one can read it. A login screen that dies
  # has to say why somewhere survivable, and journald is the only such place
  # before a user session exists.
  session = pkgs.writeShellScript "greeter-session" ''
    ${config.systemd.package}/bin/systemd-cat --identifier=greeter ${lib.getExe greeterPackage}
    ${hyprland}/bin/hyprctl dispatch exit
  '';

  # A compositor with one client, no wallpaper, and nothing to configure.
  # Note for anything added here: `#` opens a comment in a Hyprland config
  # even inside an exec argument, so a hex colour has to be written `##`.
  greeterConf = pkgs.writeText "greeter-hyprland.conf" ''
    monitor = , preferred, auto, 1

    animations {
      enabled = false
    }

    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
      force_default_wallpaper = 0
    }

    exec-once = ${session}
  '';
in
{
  services.greetd = {
    enable = true;
    # The user is greetd's own default, `greeter`; greeter-state.nix pins its
    # uid and owns its home.
    settings.default_session.command = "${hyprland}/bin/Hyprland --config ${greeterConf}";
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
