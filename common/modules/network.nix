{ ... }:
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
  networking.firewall.allowedTCPPorts = [
    7860
    137
    138
    139
    445
  ];
}
