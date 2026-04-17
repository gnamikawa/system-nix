{ lib, ... }:
{
  imports = [
    ./modules/hibernation.nix
  ];

  zramSwap = {
    enable = true;
    memoryPercent = 50; # uses 50% of RAM as compressed swap
  };

  boot.plymouth.enable = true;
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s31f6.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wwp0s20f0u6i12.useDHCP = lib.mkDefault true;
}
