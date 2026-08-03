{ ... }:
{
  imports = [
    ./hibernation.nix
    ./boot.nix
    ./network.nix
    ./bluetooth.nix
    ./filesystem.nix
    ./polkit.nix
    ./localsend.nix
    ./samba.nix
    ./audio.nix
    ./packages/base-system.nix
    ./packages/fonts.nix
    ./ios-devices.nix
    ./docker.nix
    ./users.nix
    ./nix.nix
    ./locale.nix
    ./desktop.nix
    ./hardware.nix
    ./greeter.nix
    ./greeter-state.nix
    ./ssh.nix
    ./services.nix
    ./cowork.nix
  ];

  system.stateVersion = "25.11";

  # Kept in this top-level module: moving it into an imported module (e.g.
  # desktop.nix) reorders pathsToLink relative to home-manager's entries,
  # which changes the system hash for no functional reason.
  environment.pathsToLink = [
    "/share/xdg-desktop-portal"
    "/share/applications"
  ];
}
