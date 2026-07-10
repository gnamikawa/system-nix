{ ... }:
{
  # Host prerequisites for Claude Desktop's Cowork feature, which boots a
  # KVM guest. The app's capability probe (see the claude-desktop-nix flake)
  # requires an accessible /dev/kvm and /dev/vhost-vsock; the packaging
  # provides qemu/OVMF/virtiofsd, but the device access is a host concern.
  #
  # vhost_vsock backs /dev/vhost-vsock (the host end of the guest's virtio
  # vsock transport). kvm-amd / kvm-intel are already loaded per host.
  boot.kernelModules = [ "vhost_vsock" ];

  users.users.genzo.extraGroups = [ "kvm" ];
}
