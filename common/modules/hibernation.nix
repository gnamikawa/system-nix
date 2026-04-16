{ lib, config, ... }:
{
  options.boot.hibernation = {
    devUUID = lib.mkOption {
      type = lib.types.str;
      description = "UUID of the swap device for hibernation";
    };
    resumeOffset = lib.mkOption {
      type = lib.types.str;
      description = "Swap file offset for hibernation";
    };
  };

  config = {
    # The UUID of the device (partition) that contains /swapfile — NOT the swapfile itself
    boot.resumeDevice = "/dev/disk/by-uuid/${config.boot.hibernation.devUUID}"; # findmnt -no UUID -T /swapfile
    boot.kernelParams = [
      "resume_offset=${config.boot.hibernation.resumeOffset}" # sudo filefrag -v /swapfile | awk 'NR==4{print $4}' | tr -d '.'
      "mem_sleep_default=deep"
    ];
    powerManagement.enable = true;
    swapDevices = [
      {
        device = "/swapfile";
        size = 8 * 1024;
      }
    ];

    services.power-profiles-daemon.enable = true;
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandlePowerKey = "hibernate";
      HandlePowerKeyLongPress = "poweroff";
    };

    systemd.sleep.settings.Sleep = {
      SuspendState = "mem";
      AllowSuspend = "yes";
      AllowHibernation = "yes";
      AllowSuspendThenHibernate = "yes";
      HibernateDelaySec = "5min";
    };
  };
}
