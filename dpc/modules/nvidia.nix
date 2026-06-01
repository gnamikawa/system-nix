{ config, pkgs, ... }:
{
  nix.settings.substituters = [
    "https://cache.nixos-cuda.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
  ];

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
