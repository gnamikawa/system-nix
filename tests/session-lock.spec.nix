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

    security.pam.services.astal-auth = { };

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

      # Enter the real user session without inspecting rendered output.
      machine.wait_until_succeeds("pgrep -u greeter -f sysc-greet")
      machine.sleep(2)
      machine.send_chars("genzo\n")
      machine.sleep(1)
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

      with subtest("session-lock lifecycle survives output changes"):
          physical = json.loads(hyprctl("-j monitors"))[0]["name"]
          hyprctl(f"keyword monitor {physical},preferred,0x0,1")

          machine.succeed(
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 "
              "systemd-run --user --unit=session-lock-test "
              "--property=Type=exec genzo-session-lock'"
          )
          machine.wait_until_succeeds(user_service_active("session-lock-test"))
          machine.wait_until_succeeds(
              "journalctl _UID=1000 --since='-30 seconds' --no-pager "
              "| grep -q 'Wayland session got locked'",
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
          machine.succeed(user_service_active("session-lock-test"))

          # Blank submission is inert. Two immediate nonblank submissions
          # still start exactly one PAM attempt, and failure leaves the same
          # lock alive and accepting a later retry.
          machine.send_chars("\n")
          machine.sleep(1)
          machine.succeed(user_service_active("session-lock-test"))
          machine.send_chars("definitely-wrong\nsecond-wrong\n")
          machine.wait_until_succeeds(
              "journalctl _UID=1000 _SYSTEMD_USER_UNIT=session-lock-test.service "
              "--no-pager | grep -q 'authentication:'",
              timeout=30,
          )
          machine.succeed(
              "test $(journalctl _UID=1000 "
              "_SYSTEMD_USER_UNIT=session-lock-test.service --no-pager "
              "| grep -c 'authentication:') -eq 1"
          )
          machine.succeed(user_service_active("session-lock-test"))

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
          machine.succeed(user_service_active("session-lock-test"))

          # Keyboard input remains owned by the interactive lock even when
          # pointer focus moves onto a blank secondary lock surface.
          hyprctl("dispatch movecursor 2500 500")
          machine.send_chars("secondary-focus-probe\n")
          machine.wait_until_succeeds(
              "test $(journalctl _UID=1000 "
              "_SYSTEMD_USER_UNIT=session-lock-test.service --no-pager "
              "| grep -c 'authentication:') -eq 2",
              timeout=15,
          )
          machine.succeed(user_service_active("session-lock-test"))

          hyprctl(f"output remove {secondary}")
          machine.wait_until_succeeds(
              "test $(su - genzo -c '"
              "XDG_RUNTIME_DIR=/run/user/1000 "
              "HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr) "
              "hyprctl -j monitors | jq length') -eq 1"
          )
          machine.succeed(user_service_active("session-lock-test"))

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
          machine.succeed(user_service_active("session-lock-test"))

          # Successful retry proves the promoted coordinator remains usable;
          # HITL owns reconnect placement and the full presentation.
          machine.send_chars("${password}\n")
          machine.wait_until_fails(
              user_service_active("session-lock-test"), timeout=30
          )
          machine.succeed(
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 "
              "systemctl --user show session-lock-test.service "
              "--property=Result --value | grep -x success'"
          )
    '';
}
