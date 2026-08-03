{ lib, ... }:
{
  options.hardware.primaryMonitor = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "desc:Viewteck Co. Ltd. GFV22CB";
    description = ''
      Hyprland monitor selector (as accepted by `monitor =`) identifying the
      host's primary display. The greeter pins this monitor to (0,0) so its
      warm surface lands there rather than on whichever output Hyprland's
      auto-placement puts first. `null` on hosts where the choice is trivial
      (single-display laptops) — the greeter falls back to auto.
    '';
  };
}
