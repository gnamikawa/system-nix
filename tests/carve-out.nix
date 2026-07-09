# Test-only deviations from the real host configuration. Governed by
# docs/adr/0001: only what is impossible in a VM or unknowable to a test
# may appear here; a unit that fails only in the VM is fixed by extending
# this list, never by weakening a test's assertions.
{ lib, ... }:
{
  # No GPU exists in QEMU. Wholesale: also drops the CUDA userspace and
  # binary cache, which prove nothing without a driver. A no-op on hosts
  # that don't import the module (GEN-LPC).
  disabledModules = [ ../hosts/GEN-DPC/nvidia.nix ];

  # Without a GPU, wlroots (greeter sway and user sway) needs the software
  # renderer.
  environment.sessionVariables.WLR_RENDERER = "pixman";
  systemd.services.greetd.environment.WLR_RENDERER = "pixman";

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
