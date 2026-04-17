{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  boot.hibernation.devUUID = "664ef959-7503-45fa-bfe0-64efe81293cf";
  boot.hibernation.resumeOffset = "14514176";
  boot.hibernation.swapSize = 8;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/664ef959-7503-45fa-bfe0-64efe81293cf";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
