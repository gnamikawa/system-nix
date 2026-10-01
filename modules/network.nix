{ lib, ... }:
{
  users.users.genzo.extraGroups = [
    "networkmanager"
  ];
  networking.networkmanager = {
    enable = true;
    # Set connection retry timeout (in seconds)
    connectionConfig = {
      "connection.autoconnect-retries" = 0; # number of attempts (0 = infinite)
      "connection.autoconnect-retry-delay" = 3; # seconds between retries
    };
  };

  # Boot does not wait for Wi-Fi. smbd and docker are ordered after
  # network-online.target by their upstream units, but neither needs the network
  # up to start: smbd listens on every address and docker starts fine offline.
  systemd.services.NetworkManager-wait-online.enable = false;

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [
    7860
    137
    138
    139
    445
  ];

  services.timesyncd = {
    enable = true;
    servers = [ "pool.ntp.org" ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    publish.enable = true;
    publish.userServices = true;
  };
}
