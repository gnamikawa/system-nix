{
  config,
  pkgs,
  lib,
  ...
}:
{
  nix.settings.substituters = lib.mkBefore [
    "https://cache.nixos-cuda.org"
  ];
  nix.settings.trusted-public-keys = lib.mkBefore [
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
  ];

  services.xserver = {
    enable = true;
    videoDrivers = lib.mkBefore [ "nvidia" ];
  };

  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = true;
    videoAcceleration = true;
    modesetting.enable = true;
  };

  boot.kernelParams = lib.mkBefore [
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
    systemPackages = lib.mkBefore [ pkgs.cudaPackages.cuda_nvcc ];
  };
}
