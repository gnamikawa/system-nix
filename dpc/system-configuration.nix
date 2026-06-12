{ ... }:
{
  imports = [
    ./modules/ollama.nix
    ./modules/steam.nix
  ];

  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "GEN-DPC";
}
