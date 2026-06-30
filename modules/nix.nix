{ ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix = {
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      trusted-users = [ "genzo" ];
    };
    gc.automatic = true;
    gc.dates = "daily";
    gc.options = "--delete-older-than 7d";
  };
}
