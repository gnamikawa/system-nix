{ pkgs, ... }:
{
  services = {
    upower.enable = true;
    printing.enable = true;
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    usbmuxd.enable = true;
    flatpak.enable = true;
  };

  programs.nix-ld.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = with pkgs; pinentry-all;
    enableSSHSupport = true;
  };
}
