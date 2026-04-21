{ ... }:
{
  services = {
    samba = {
      enable = true;
      openFirewall = true;
      smbd.enable = true;
      nmbd.enable = false;
      shares = {
        genzo = {
          path = "/home/genzo";
          "valid users" = "genzo";
          writable = "yes";
          browseable = "yes";
        };
      };
    };
    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
  };
}
