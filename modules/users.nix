{ ... }:
{
  users.users.genzo = {
    isNormalUser = true;
    # Pinned (it is what auto-allocation already gave) so mount options such
    # as the ntfs3 uid= in hosts/GEN-DPC/hardware.nix can name it.
    uid = 1000;
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
