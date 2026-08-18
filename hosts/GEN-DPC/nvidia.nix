{ config, pkgs, ... }:
{
  nix.settings.substituters = [
    "https://cache.nixos-cuda.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = true;
    videoAcceleration = true;
    modesetting.enable = true;
    # NVIDIA's S3/S4 wiring. On this host (open driver, v>=595) it sets
    # NVreg_PreserveVideoMemoryAllocations=1 and NVreg_UseKernelSuspendNotifiers=1
    # rather than installing the nvidia-suspend/hibernate/resume systemd
    # units — kernelSuspendNotifier defaults true for that combo, so the
    # driver hooks into the kernel PM notifier chain directly. Without this,
    # resume leaves DRM/KMS stuck: every atomic commit is rejected with
    # "Cannot commit when a page-flip is awaiting", freezing whatever
    # wlroots compositor is drawing after wake.
    powerManagement.enable = true;
  };
  hardware.nvidia-container-toolkit.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      wayland-protocols
    ];
  };

  environment.variables = {
    XDG_SESSION_TYPE = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvml_dev
    cudaPackages.cuda_nvcc
    cudaPackages.cudnn
    cudaPackages.nccl
    cudaPackages.libcublas
    cudaPackages.libcurand
    cudaPackages.cuda_nvrtc
  ];
}
