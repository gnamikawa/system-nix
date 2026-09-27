{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.lxqt.lxqt-openssh-askpass ];

  environment.sessionVariables.SUDO_ASKPASS = "${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass";
}
