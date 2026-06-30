{ ... }:
{
  imports = [
    ./hardware.nix
  ];

  networking.hostName = "GEN-LPC";

  boot.loader.grub.device = "/dev/nvme0n1";
}
