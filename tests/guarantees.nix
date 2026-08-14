# The guarantee flow for one host, as one sequential VM run:
# boot (greeter rendered) → login (through the greeter) → terminal (the
# user's own keybinding) → ambient toolkit → default development
# environment (present at any cwd; a project layers over it; a project
# removes it) → plain-sudo inheritance → system and user systemd health.
# Definitions in CONTEXT.md; carve-out policy in docs/adr/0001.
host:
{
  hostModules,
  pkgs,
  dotfiles,
  nixpkgsSrc,
  ...
}:
let
  # Fixture project environment for the layering guarantee. A real project
  # says `use flake dotfiles#<env>`, resolved through the registry to the
  # dotfiles checkout — which, like the network, does not exist in the VM.
  # This store-local flake exercises the same mechanism (direnv allow →
  # `use flake …#default` → devshell) with the same package list, imported
  # from the same devshells/default.nix; only the flake reference differs.
  projectShell = pkgs.mkShell (
    { name = "dotfiles-default"; } // (import (dotfiles + "/devshells/default.nix") pkgs)
  );
  fixtureFlake = pkgs.runCommand "project-env-fixture" { } ''
    mkdir $out
    cp ${dotfiles + "/devshells/default.nix"} $out/default-env.nix
    cat > $out/flake.nix <<EOF
    {
      inputs.nixpkgs.url = "path:${nixpkgsSrc}";
      outputs =
        { nixpkgs, ... }:
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        {
          devShells.x86_64-linux.default = pkgs.mkShell (
            { name = "dotfiles-default"; } // (import ./default-env.nix pkgs)
          );
        };
    }
    EOF
    cat > $out/flake.lock <<EOF
    {
      "nodes": {
        "nixpkgs": {
          "locked": {
            "type": "path",
            "path": "${nixpkgsSrc}",
            "narHash": "${nixpkgsSrc.narHash}",
            "lastModified": ${toString nixpkgsSrc.lastModified}
          },
          "original": { "type": "path", "path": "${nixpkgsSrc}" }
        },
        "root": { "inputs": { "nixpkgs": "nixpkgs" } }
      },
      "root": "root",
      "version": 7
    }
    EOF
  '';

  # The default development environment is claimed by interactive shell
  # init, so every check below runs through a real interactive shell
  # (bash -i) — the same path a terminal shell takes — and the checks
  # compare against the DEFAULT_DEV_ENV prefix that init exports.
  setupProjects = pkgs.writeShellScript "setup-projects" ''
    set -eu
    mkdir -p /home/genzo/proj-layer /home/genzo/proj-drop
    echo "use flake ${fixtureFlake}#default" > /home/genzo/proj-layer/.envrc
    echo "drop_default_env" > /home/genzo/proj-drop/.envrc
    cd /home/genzo/proj-layer && direnv allow
    cd /home/genzo/proj-drop && direnv allow
  '';
  checkGlobal = pkgs.writeShellScript "check-global" ''
    set -eu
    cd /tmp
    [ "$(command -v python3)" = "$DEFAULT_DEV_ENV/bin/python3" ]
    [ "$(command -v make)" = "$DEFAULT_DEV_ENV/bin/make" ]
  '';
  checkLayer = pkgs.writeShellScript "check-layer" ''
    set -eu
    cd /home/genzo/proj-layer
    base="$(command -v python3)"
    [ "$base" = "$DEFAULT_DEV_ENV/bin/python3" ]
    layered="$(direnv exec . sh -c 'command -v python3')"
    [ "$layered" != "$base" ]
  '';
  checkDrop = pkgs.writeShellScript "check-drop" ''
    set -eu
    cd /home/genzo/proj-drop
    [ "$(command -v python3)" = "$DEFAULT_DEV_ENV/bin/python3" ]
    if direnv exec . sh -c 'command -v python3'; then
      echo "python3 still resolves after drop_default_env" >&2
      exit 1
    fi
    if direnv exec . sh -c 'command -v make'; then
      echo "make still resolves after drop_default_env" >&2
      exit 1
    fi
    direnv exec . sh -c 'command -v rg'
  '';
  checkSudo = pkgs.writeShellScript "check-sudo" ''
    set -eu
    echo "$1" | sudo -S python3 --version
  '';
in
{
  name = "guarantees-${host}";
  # Deliberately paid per host: CONTEXT.md defines booted as the greeter being
  # rendered and awaiting input, and requires every guarantee on every host.
  enableOCR = true;

  # The host config sets nixpkgs.config itself (e.g. allowUnfree for steam),
  # which the framework's default read-only pkgs would reject.
  node.pkgsReadOnly = false;

  nodes.machine = {
    imports = hostModules.${host} ++ [ ./carve-out.nix ];

    # carve-out.nix substitutes the flake source for the dotfiles checkout
    # the asset symlinks point into.
    _module.args.dotfiles = dotfiles;

    # VM sizing and a KMS-capable virtual GPU (Hyprland cannot start on
    # the default -vga std).
    virtualisation = {
      memorySize = 4096;
      cores = 2;
      qemu.options = [ "-vga none -device virtio-gpu-pci" ];

      # The layering guarantee evaluates the fixture inside the offline
      # VM: it needs the fixture, the nixpkgs source it locks, and the
      # already-built shell so nothing has to be rebuilt.
      additionalPaths = [
        fixtureFlake
        nixpkgsSrc
        projectShell
      ];
    };
  };

  # The credential is read back from the node's own config so the carve-out
  # in carve-out.nix stays its single source.
  testScript =
    { nodes, ... }:
    ''
      machine.start()

      with subtest("boot: greeter is rendered and awaiting input"):
          machine.wait_for_unit("graphical.target")
          machine.succeed("fc-list | grep -q ': Geist:'")
          machine.succeed("fc-list | grep -q ': Geist Mono:'")

      with subtest("boot: compositor diagnostics bypass the visible VT for journald"):
          machine.wait_until_succeeds("pgrep -u greeter -f /bin/start-hyprland")
          machine.wait_until_succeeds("pgrep -u greeter -f /bin/Hyprland")
          machine.succeed(
              """for pid in $(pgrep -u greeter -f '/bin/(start-hyprland|Hyprland)'); do
                for fd in 1 2; do
                  case $(readlink /proc/$pid/fd/$fd) in /dev/tty*) exit 1;; esac
                done
              done"""
          )
          machine.succeed(
              "journalctl -b -t greeter-compositor --no-pager | grep -q ."
          )

          # The date and clock are the bright things on the screen: the status
          # rail and the power verbs rest near-invisible until the pointer
          # approaches them, so they are not something OCR can be asked for.
          # Use the date because OCR routinely reads the clock's colon as `?`.
          machine.wait_for_text(r"[A-Z][a-z]+ \d{1,2} [A-Z][a-z]+")

      with subtest("boot: watchdog restores the greeter after a compositor crash"):
          old_hyprland = machine.succeed(
              "pgrep -u greeter -f /bin/Hyprland | tail -n1"
          ).strip()
          old_greeter = machine.succeed(
              "pgrep -u greeter -x gjs | tail -n1"
          ).strip()
          machine.succeed(f"kill -KILL {old_hyprland}")
          machine.wait_until_succeeds(
              f"new_pid=$(pgrep -u greeter -f /bin/Hyprland | tail -n1); "
              f'test -n "$new_pid" && test "$new_pid" != "{old_hyprland}"',
              timeout=60,
          )
          machine.wait_until_succeeds(
              f"new_pid=$(pgrep -u greeter -x gjs | tail -n1); "
              f'test -n "$new_pid" && test "$new_pid" != "{old_greeter}"',
              timeout=60,
          )
          machine.wait_for_text(r"[A-Z][a-z]+ \d{1,2} [A-Z][a-z]+")

      with subtest("login: a wrong password is refused, not mistaken for a login"):
          # The screen used to read a refusal as a login: AstalGreet's login()
          # hands greetd's error back as a return value rather than raising it,
          # so nothing caught it. The screen then quit, as a screen must once a
          # session starts, and greetd — holding a greeter that was gone with no
          # session behind it — dropped the seat to black. One typo, one dead
          # machine, and nothing in the VM test typed a wrong password.
          machine.send_chars("not-the-password\n")
          # No -t: the screen's own lines are not tagged `greeter` despite
          # greeter.nix's systemd-cat --identifier. GJS writes structured
          # entries to the journal itself once systemd-cat has made its stderr
          # a journal stream, and tags them from its program name — they arrive
          # as `gjs`. The phrase is distinctive; the tag is not to be relied on.
          machine.wait_until_succeeds(
              "journalctl -b | grep -q 'greetd refused the login'",
              timeout=60,
          )
          machine.fail("journalctl -b -u greetd | grep -q 'without creating a session'")

      with subtest("login: through the greeter as genzo"):
          # Also the proof that the refused attempt was cancelled: greetd will
          # not open a second session while the first is still under
          # configuration, so a screen that forgot to cancel could never be
          # logged into again after one wrong password.
          #
          # No username to type. The screen opens on the password, for the one
          # account that has a graphical session — offering a choice whose
          # only other outcome is failure is the thing it deliberately drops.
          machine.send_chars("${nodes.machine.users.users.genzo.password}\n")
          machine.wait_until_succeeds(
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user is-active wayland-wm@hyprland.desktop.service'",
              timeout=120,
          )

      with subtest("terminal: the user's keybinding opens kitty"):
          # Input still belongs to the greeter's dying Hyprland for a moment
          # after the session target goes active; a keystroke sent too early
          # is lost.
          machine.wait_until_fails("pgrep -u greeter -f Hyprland", timeout=60)
          machine.send_key("meta_l-t")
          machine.wait_until_succeeds(
              """su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr) hyprctl clients -j' | grep -q '"class": "kitty"'""",
              timeout=120,
          )

      with subtest("ambient layer: the toolkit resolves in a real login shell"):
          for tool in ["rg", "tmux", "jq", "direnv"]:
              machine.succeed(f"su - genzo -c 'command -v {tool}'")

      with subtest("host-selected locker: required implementations are exposed"):
          machine.succeed("su - genzo -c 'command -v genzo-lock'")
          ${
            if host == "GEN-DPC" then
              ''
                machine.succeed("su - genzo -c 'command -v genzo-session-lock'")
                machine.fail("su - genzo -c 'command -v hyprlock'")
              ''
            else
              ''
                machine.succeed("su - genzo -c 'command -v hyprlock'")
                machine.succeed("su - genzo -c 'command -v genzo-session-lock'")
                machine.succeed("su - genzo -c 'grep -q /bin/hyprlock $(command -v genzo-lock)' ")
              ''
          }

      with subtest("default development environment: present in every interactive shell at any cwd"):
          machine.succeed("su - genzo -c 'bash -ic ${checkGlobal}'")

      with subtest("project environment layers over the default"):
          machine.succeed("su - genzo -c '${setupProjects}'")
          # First activation evaluates the fixture flake inside the VM;
          # give it room. Later activations replay nix-direnv's cache.
          machine.succeed("su - genzo -c 'direnv exec /home/genzo/proj-layer true'", timeout=600)
          machine.succeed("su - genzo -c 'bash -ic ${checkLayer}'")

      with subtest("project environment removes the default entirely"):
          machine.succeed("su - genzo -c 'bash -ic ${checkDrop}'")

      with subtest("plain sudo inherits the invoking shell's environment"):
          machine.succeed(
              """su - genzo -c 'bash -ic "${checkSudo} ${nodes.machine.users.users.genzo.password}"'"""
          )

      with subtest("systemd is healthy: is-system-running reports running"):
          state = machine.execute("systemctl is-system-running --wait")[1].strip()
          if state != "running":
              print(machine.execute("systemctl list-units --failed")[1])
          assert state == "running", f"systemd state: {state}"

      with subtest("user services are healthy: no failed units in the session"):
          # The raw-asset configs (waybar, hypridle, mako) run as user
          # units; a config broken enough to crash its daemon shows up
          # only here, since is-system-running covers the system manager.
          state = machine.execute(
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user is-system-running --wait'"
          )[1].strip()
          if state != "running":
              print(machine.execute("su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user list-units --failed'")[1])
          assert state == "running", f"user systemd state: {state}"
    '';
}
