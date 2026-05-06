{ ... }:
{
  users.users.genzo.extraGroups = [
    "input"
  ];
  services.xserver = {
    enable = true;
    wacom.enable = true;
  };
}
