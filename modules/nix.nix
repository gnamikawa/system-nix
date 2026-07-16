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
    # `dotfiles` flake alias for development environments
    # (`use flake dotfiles#<env>` in .envrc files, `nix develop
    # dotfiles#<env>` ad hoc). Standalone machines get the same alias from
    # a dotfiles-nix asset instead.
    registry.dotfiles.to = {
      type = "path";
      path = "/home/genzo/repositories/dotfiles-nix";
    };
    gc.automatic = true;
    gc.dates = "daily";
    gc.options = "--delete-older-than 7d";
  };
}
