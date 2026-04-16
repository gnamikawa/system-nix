{ ... }:
{
  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      Policy = {
        ReconnectAttempts = 20;
        ReconnectIntervals = "1,2,4,8";
      };
    };
  };
  users.users.genzo.extraGroups = [
    "bluetooth"
  ];
}
