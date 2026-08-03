{
  hostModules,
  dotfiles,
  ...
}:
{
  name = "session-lock";

  node.pkgsReadOnly = false;

  nodes.machine = {
    imports = hostModules.GEN-DPC ++ [ ./carve-out.nix ];

    _module.args.dotfiles = dotfiles;

    virtualisation = {
      memorySize = 4096;
      cores = 2;
      qemu.options = [ "-vga none -device virtio-gpu-pci" ];
    };
  };

  testScript =
    { nodes, ... }:
    let
      password = nodes.machine.users.users.genzo.password;
    in
    ''
      import json

      machine.start()
      machine.wait_for_unit("graphical.target")

      # Enter the real user session without inspecting rendered output. The
      # AGS screen opens directly on the one graphical user's password; there
      # is no username step or session picker.
      machine.wait_until_succeeds(
          "XDG_RUNTIME_DIR=/run/user/988 "
          "HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/988/hypr) "
          "hyprctl layers | grep -q 'namespace: greeter'"
      )
      machine.send_chars("${password}\n")
      machine.wait_until_succeeds(
          "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user is-active wayland-wm@hyprland.desktop.service'",
          timeout=120,
      )
      machine.wait_until_fails("pgrep -u greeter -f Hyprland", timeout=60)

      def hyprctl(arguments):
          return machine.succeed(
              "su - genzo -c '"
              "XDG_RUNTIME_DIR=/run/user/1000 "
              "HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr) "
              f"hyprctl {arguments}'"
          ).strip()

      def user_service_active(unit):
          return (
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 "
              f"systemctl --user is-active {unit}.service'"
          )

      with subtest("production cutover contract"):
          machine.succeed("test -s /etc/pam.d/astal-auth")
          machine.succeed("su - genzo -c 'command -v genzo-lock'")
          machine.succeed("su - genzo -c 'command -v genzo-session-lock'")
          machine.fail("su - genzo -c 'command -v hyprlock'")
          machine.succeed("grep -Fx '    lock_cmd = genzo-lock' /home/genzo/.config/hypr/hypridle.conf")
          machine.succeed("grep -Fx '    before_sleep_cmd = genzo-lock' /home/genzo/.config/hypr/hypridle.conf")
          machine.succeed(
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 "
              "systemctl --user show genzo-session-lock.service "
              "--property=Restart --value | grep -x no'"
          )

      with subtest("session-lock lifecycle survives output changes"):
          physical = json.loads(hyprctl("-j monitors"))[0]["name"]
          hyprctl(f"keyword monitor {physical},preferred,0x0,1")

          # The documented manual command starts the selected implementation.
          machine.succeed("su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 genzo-lock'")
          machine.wait_until_succeeds(user_service_active("genzo-session-lock"))
          machine.wait_until_succeeds(
              "journalctl _UID=1000 --since='-30 seconds' --no-pager "
              "| grep -q 'Wayland session got locked'",
              timeout=30,
          )

          # Hypridle's logind and pre-suspend entry points invoke the same
          # selected command. The service is already active, so both calls are
          # harmless no-ops after proving the path reaches genzo-lock.
          invocations = int(machine.execute(
              "journalctl _UID=1000 _SYSTEMD_USER_UNIT=hypridle.service "
              "--no-pager | grep -c 'Executing genzo-lock'"
          )[1].strip() or "0")
          machine.succeed("loginctl lock-session $(loginctl --no-legend list-sessions | awk '$3 == \"genzo\" { print $1; exit }')")
          machine.wait_until_succeeds(
              "test $(journalctl _UID=1000 _SYSTEMD_USER_UNIT=hypridle.service "
              "--no-pager | grep -c 'Executing genzo-lock') -gt " + str(invocations),
              timeout=30,
          )
          invocations += 1
          machine.succeed(
              "busctl emit /org/freedesktop/login1 "
              "org.freedesktop.login1.Manager PrepareForSleep b true"
          )
          machine.wait_until_succeeds(
              "test $(journalctl _UID=1000 _SYSTEMD_USER_UNIT=hypridle.service "
              "--no-pager | grep -c 'Executing genzo-lock') -gt " + str(invocations),
              timeout=30,
          )

          # A second client must fail acquisition without disturbing the lock.
          machine.succeed(
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 "
              "systemd-run --user --unit=session-lock-contender "
              "--property=Type=exec genzo-session-lock'"
          )
          machine.wait_until_fails(
              user_service_active("session-lock-contender"), timeout=30
          )
          machine.wait_until_succeeds(
              "journalctl _UID=1000 _SYSTEMD_USER_UNIT=session-lock-contender.service "
              "--no-pager | grep -q 'could not acquire the compositor lock'",
              timeout=30,
          )
          machine.succeed(user_service_active("genzo-session-lock"))

          # Blank submission is inert. Two immediate nonblank submissions
          # still start exactly one PAM attempt, and failure leaves the same
          # lock alive and accepting a later retry.
          machine.send_chars("\n")
          machine.sleep(1)
          machine.succeed(user_service_active("genzo-session-lock"))
          machine.send_chars("definitely-wrong\nsecond-wrong\n")
          machine.wait_until_succeeds(
              "journalctl _UID=1000 _SYSTEMD_USER_UNIT=genzo-session-lock.service "
              "--no-pager | grep -q 'authentication:'",
              timeout=30,
          )
          machine.succeed(
              "test $(journalctl _UID=1000 "
              "_SYSTEMD_USER_UNIT=genzo-session-lock.service --no-pager "
              "| grep -c 'authentication:') -eq 1"
          )
          machine.succeed(user_service_active("genzo-session-lock"))

          # Adding and removing a secondary output must not terminate or
          # replace the active session lock.
          hyprctl("output create headless")
          machine.wait_until_succeeds(
              "test $(su - genzo -c '"
              "XDG_RUNTIME_DIR=/run/user/1000 "
              "HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr) "
              "hyprctl -j monitors | jq length') -eq 2"
          )
          monitors = json.loads(hyprctl("-j monitors"))
          secondary = next(
              monitor["name"] for monitor in monitors if monitor["name"] != physical
          )
          hyprctl(f"keyword monitor {secondary},1920x1080@60,1920x0,1")
          machine.succeed(user_service_active("genzo-session-lock"))

          # Keyboard input remains owned by the interactive lock even when
          # pointer focus moves onto a blank secondary lock surface.
          hyprctl("dispatch movecursor 2500 500")
          machine.send_chars("secondary-focus-probe\n")
          machine.wait_until_succeeds(
              "test $(journalctl _UID=1000 "
              "_SYSTEMD_USER_UNIT=genzo-session-lock.service --no-pager "
              "| grep -c 'authentication:') -eq 2",
              timeout=15,
          )
          machine.succeed(user_service_active("genzo-session-lock"))

          hyprctl(f"output remove {secondary}")
          machine.wait_until_succeeds(
              "test $(su - genzo -c '"
              "XDG_RUNTIME_DIR=/run/user/1000 "
              "HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr) "
              "hyprctl -j monitors | jq length') -eq 1"
          )
          machine.succeed(user_service_active("genzo-session-lock"))

          # Make a newly-added output the logical primary, then remove it. The
          # surviving physical surface must take over keyboard interaction.
          hyprctl("output create headless")
          machine.wait_until_succeeds(
              "test $(su - genzo -c '"
              "XDG_RUNTIME_DIR=/run/user/1000 "
              "HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr) "
              "hyprctl -j monitors | jq length') -eq 2"
          )
          monitors = json.loads(hyprctl("-j monitors"))
          primary = next(
              monitor["name"] for monitor in monitors if monitor["name"] != physical
          )
          hyprctl(f"keyword monitor {physical},preferred,1920x0,1")
          hyprctl(f"keyword monitor {primary},1920x1080@60,0x0,1")
          hyprctl(f"output remove {primary}")
          machine.wait_until_succeeds(
              "test $(su - genzo -c '"
              "XDG_RUNTIME_DIR=/run/user/1000 "
              "HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr) "
              "hyprctl -j monitors | jq length') -eq 1"
          )
          machine.succeed(user_service_active("genzo-session-lock"))

          # The promoted coordinator remains usable. Keep this lock acquired
          # so the next subtest can prove fail-closed death and restoration.
          machine.succeed(user_service_active("genzo-session-lock"))

      with subtest("abandoned lock stays closed and the TTY procedure restores it"):
          machine.succeed(
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 "
              "systemctl --user kill --signal=KILL genzo-session-lock.service'"
          )
          machine.wait_until_fails(user_service_active("genzo-session-lock"), timeout=30)

          machine.succeed(
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 "
              "systemd-run --user --unit=session-lock-after-crash "
              "--property=Type=exec genzo-session-lock'"
          )
          machine.wait_until_fails(
              user_service_active("session-lock-after-crash"), timeout=30
          )
          machine.wait_until_succeeds(
              "journalctl _UID=1000 _SYSTEMD_USER_UNIT=session-lock-after-crash.service "
              "--no-pager | grep -q 'could not acquire the compositor lock'",
              timeout=30,
          )

          machine.succeed(
              "su - genzo -c '"
              "export XDG_RUNTIME_DIR=/run/user/$(id -u); "
              "export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 $XDG_RUNTIME_DIR/hypr); "
              "hyprctl keyword misc:allow_session_lock_restore true; "
              "systemctl --user restart genzo-session-lock.service'"
          )
          machine.wait_until_succeeds(user_service_active("genzo-session-lock"))
          machine.sleep(3)
          machine.succeed(user_service_active("genzo-session-lock"))
          machine.succeed(
              "su - genzo -c '"
              "export XDG_RUNTIME_DIR=/run/user/$(id -u); "
              "export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 $XDG_RUNTIME_DIR/hypr); "
              "hyprctl keyword misc:allow_session_lock_restore false'"
          )
          machine.send_chars("${password}\n")
          machine.wait_until_fails(user_service_active("genzo-session-lock"), timeout=30)
          machine.succeed(
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 "
              "systemctl --user show genzo-session-lock.service "
              "--property=Result --value | grep -x success'"
          )
    '';
}
