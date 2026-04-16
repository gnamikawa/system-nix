{ pkgs, ... }:
{
  boot.supportedFilesystems = {
    "ntfs" = true;
    "vfat" = true;
    "exfat" = true;
  };
  environment.systemPackages = with pkgs; [
    ntfs3g # NTFS read/write support
    exfatprogs # exFAT support
    dosfstools # FAT/FAT32 tools (fsck, mkfs)
  ];

  services.gvfs.enable = true; # Unified interface method to access an assorted set of independent protocols using URIs. Somewhat similar to the concept of fuse mounts but with URIs.
  services.tumbler.enable = true; # Thumbnailer

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  users.users.genzo.extraGroups = [
    "storage"
  ];
}
