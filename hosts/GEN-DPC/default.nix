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

  # A desktop never leaves its network, so while disconnected it scans for it
  # every 5 seconds, forever. iwd is the Wi-Fi engine because it is the one
  # with a scan-interval setting: NetworkManager's own schedule with
  # wpa_supplicant is fixed in its source at 3 seconds growing to 120. iwd
  # doubles the interval from the first value up to the second, so equal values
  # mean no slowing down. iwd also does the connecting, and NetworkManager's
  # autoconnect-retries settings are ignored under it.
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.settings.Scan = {
    InitialPeriodicScanInterval = 5;
    MaximumPeriodicScanInterval = 5;
  };

  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
