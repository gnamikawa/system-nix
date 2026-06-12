{ ... }:
{
  zramSwap = {
    enable = true;
    memoryPercent = 50; # uses 50% of RAM as compressed swap
  };

  boot.plymouth.enable = true;
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
  };
}
