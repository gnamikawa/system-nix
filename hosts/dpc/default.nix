{ ... }:
{
  imports = [
    ./hardware.nix
    ./nvidia.nix
    ./wacom.nix
    ./steam.nix
    ./ollama.nix
  ];

  networking.hostName = "GEN-DPC";

  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
