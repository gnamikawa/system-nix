# The guarantee flow for one host, as one sequential VM run:
# boot (greeter rendered) → login (through the greeter) → terminal (the
# user's own keybinding) → systemd health. Definitions in CONTEXT.md;
# carve-out policy in docs/adr/0001.
host:
{ hostModules, ... }:
{
  name = "guarantees-${host}";
  enableOCR = true;

  # The host config sets nixpkgs.config itself (e.g. allowUnfree for steam),
  # which the framework's default read-only pkgs would reject.
  node.pkgsReadOnly = false;

  nodes.machine = {
    imports = hostModules.${host} ++ [ ./carve-out.nix ];

    # VM sizing and a KMS-capable virtual GPU (sway cannot start on the
    # default -vga std).
    virtualisation = {
      memorySize = 4096;
      cores = 2;
      qemu.options = [ "-vga none -device virtio-gpu-pci" ];
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
          machine.wait_for_text("Username")

      with subtest("login: through the greeter as genzo"):
          machine.send_chars("genzo\n")
          machine.wait_for_text("Password")
          machine.send_chars("${nodes.machine.users.users.genzo.password}\n")
          machine.wait_until_succeeds(
              "su - genzo -c 'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user is-active wayland-wm@sway.service'",
              timeout=120,
          )

      with subtest("terminal: the user's keybinding opens kitty"):
          # Input still belongs to the greeter's dying sway for a moment after
          # the session target goes active; a keystroke sent too early is lost.
          machine.wait_until_fails("pgrep -u greeter sway", timeout=60)
          machine.send_key("meta_l-t")
          machine.wait_until_succeeds(
              """su - genzo -c 'swaymsg -s $(ls /run/user/1000/sway-ipc.*) -t get_tree' | grep -q '"app_id": "kitty"'""",
              timeout=120,
          )

      with subtest("systemd is healthy: is-system-running reports running"):
          state = machine.execute("systemctl is-system-running --wait")[1].strip()
          if state != "running":
              print(machine.execute("systemctl list-units --failed")[1])
          assert state == "running", f"systemd state: {state}"
    '';
}
