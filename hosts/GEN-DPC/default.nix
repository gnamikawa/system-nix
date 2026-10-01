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

  # A desktop never leaves its network, so a failed Wi-Fi connection is retried
  # forever. NetworkManager's default is four tries followed by a five-minute
  # pause in which it does not try at all. 0 = forever.
  networking.networkmanager.settings.main.autoconnect-retries-default = 0;

  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
