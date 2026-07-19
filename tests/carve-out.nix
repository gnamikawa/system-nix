# Test-only deviations from the real host configuration. Governed by
# docs/adr/0001: only what is impossible in a VM or unknowable to a test
# may appear here; a unit that fails only in the VM is fixed by extending
# this list, never by weakening a test's assertions.
{ lib, dotfiles, ... }:
{
  # The dotfiles working tree cannot exist in the VM, so the flake source
  # stands in for it, read-only. This is what puts the real raw-asset
  # configs (dotfiles ADR-0005) behind the out-of-store symlinks: those
  # configs are invisible to nix flake check by design, making this VM
  # run their only automated coverage — broken config surfaces here as
  # session crashes and failed units that the guarantee assertions catch
  # implicitly. If a live-edit guarantee is ever added, upgrade the
  # symlink to a writable copy of the same source.
  systemd.tmpfiles.rules = [
    "d /home/genzo/repositories 0755 genzo users -"
    "L+ /home/genzo/repositories/dotfiles-nix - - - - ${dotfiles}"
  ];
  # No GPU exists in QEMU. Wholesale: also drops the CUDA userspace and
  # binary cache, which prove nothing without a driver. A no-op on hosts
  # that don't import the module (GEN-LPC).
  disabledModules = [ ../hosts/GEN-DPC/nvidia.nix ];

  # Without a GPU, Hyprland (greeter and user session) needs software GL —
  # aquamarine has no pixman renderer, so llvmpipe stands in for the old
  # WLR_RENDERER=pixman knob.
  environment.sessionVariables.LIBGL_ALWAYS_SOFTWARE = "1";
  systemd.services.greetd.environment.LIBGL_ALWAYS_SOFTWARE = "1";

  # Hibernation resume device/offset and the swapfile size are properties
  # of the physical disks; the swapfile alone would overflow the VM disk.
  swapDevices = lib.mkForce [ ];
  boot.resumeDevice = lib.mkForce "";

  # The VM clock is managed by QEMU; the test framework itself disables
  # timesyncd and conflicts with network.nix enabling it.
  services.timesyncd.enable = lib.mkForce false;

  # Test credential: fixture, not a secret (see CONTEXT.md).
  users.users.genzo.password = "test";
}
