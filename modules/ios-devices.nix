# iOS device support: mounting and talking to iPhones/iPads over USB.
# The tools always needed the usbmuxd daemon; it is enabled here explicitly
# rather than relying on the packages alone (which never started it).
{ pkgs, ... }:

{
  services.usbmuxd.enable = true;

  environment.systemPackages = with pkgs; [
    libimobiledevice # iOS device protocol library
    ifuse # mount iOS devices via FUSE
  ];
}
