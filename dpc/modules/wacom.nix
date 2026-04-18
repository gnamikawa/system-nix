{ pkgs, ... }:
{
  users.users.genzo.extraGroups = [
    "input"
  ];
  boot.kernelModules = [
    "wacom"
    "hid_wacom"
  ];
  environment.systemPackages = with pkgs; [
    libwacom
    xf86_input_wacom
  ];
  services.xserver = {
    enable = true;
    wacom.enable = true;
  };
}
