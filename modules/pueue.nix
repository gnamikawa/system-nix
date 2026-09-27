{
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.pueue ];

  systemd.user.services.pueued = {
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.pueue}/bin/pueued -vv";
      Restart = "on-failure";
    };
  };
}
