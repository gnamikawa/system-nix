{ pkgs, ... }:
{
  users.users.genzo.extraGroups = [
    "storage"
    "plugdev"
    "disk"
  ];

  environment.systemPackages = with pkgs; [
    polkit_gnome
  ];
}
