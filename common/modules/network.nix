{ ... }:
{
  networking.networkmanager = {
    enable = true;
    # Set connection retry timeout (in seconds)
    connectionConfig = {
      "connection.autoconnect-retries" = 0; # number of attempts (0 = infinite)
      "connection.autoconnect-retry-delay" = 3; # seconds between retries
    };
  };
}
