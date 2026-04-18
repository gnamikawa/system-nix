{ config, pkgs, ... }:
{
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
  };

  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = true;
    videoAcceleration = true;
    modesetting.enable = true;
  };

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1"; # fixes cursor rendering on Nvidia+Wayland
    NIXOS_OZONE_WL = "1"; # tells Electron apps to use Wayland
    XDG_SESSION_TYPE = "wayland";
    systemPackages = [ pkgs.cudaPackages.cuda_nvcc ];
  };
}
