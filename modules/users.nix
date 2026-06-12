{ ... }:
{
  users.users.genzo = {
    isNormalUser = true;
    description = "Genzo Namikawa";
    extraGroups = [
      "wheel"
      "video"
      "audio"
    ];
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
}
