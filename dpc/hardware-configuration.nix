{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./modules/wacom.nix
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.hibernation.devUUID = "864978b2-784f-4528-8aa0-b1d2b84e1e12";
  boot.hibernation.resumeOffset = "9314304";

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
    ];
    extraModulePackages = [ ];
    kernelModules = [
      "kvm-amd"
      "uinput"
    ];
    kernelParams = [
      # "nvidia-drm.modeset=1"
      "quiet"
      "loglevel=0"
      "splash"
    ];

    kernel.sysctl = {
      "vm.overcommit_memory" = 2;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/864978b2-784f-4528-8aa0-b1d2b84e1e12";
    fsType = "ext4";
  };
  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-uuid/3F02C6C0060C36FF";
    fsType = "ntfs3";
    options = [
      "nofail"
      "x-systemd.automount"
    ];
  };
  fileSystems."/mnt/windows-ssd" = {
    device = "/dev/disk/by-uuid/524C612E40789B22";
    fsType = "ntfs3";
    options = [
      "nofail"
      "x-systemd.automount"
    ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B442-5062";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  hardware = {
    uinput.enable = true;
    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      nvidiaSettings = true;
      videoAcceleration = true;
      modesetting.enable = true;
      gsp.enable = true;
    };
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    opentabletdriver = {
      enable = true;
      daemon.enable = true;
    };
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        mesa
        wayland-protocols
      ];
    };
  };

  environment.variables = {
    XDG_SESSION_TYPE = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
