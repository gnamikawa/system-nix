{ ... }:
{
  imports = [
    ./hardware.nix
  ];

  networking.hostName = "GEN-LPC";

  boot.loader.grub.device = "/dev/sda";
}
