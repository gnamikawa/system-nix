{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dotfiles-nix = {
      # url = "github:gnamikawa/dotfiles-nix/master";
      url = "path:/home/genzo/repositories/dotfiles-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sysc-greet = {
      url = "github:Nomadcxx/sysc-greet?ref=v1.1.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      dotfiles-nix,
      nur,
      sysc-greet,
    }:
    let
      constants = import ./constants.nix;
    in
    {
      nixosConfigurations.${constants.hostName} = nixpkgs.lib.nixosSystem {
        system = constants.system;
        specialArgs = {
          inherit constants;
        };
        modules = [
          (
            { config, pkgs, ... }:
            {
              nixpkgs.overlays = [ nur.overlays.default ];
            }
          )
          dotfiles-nix.nixosModules.default
          home-manager.nixosModules.home-manager
          sysc-greet.nixosModules.default
          ./hardware-configuration.nix
          ./system-configuration.nix
          ./packages/core.nix
          ./packages/java.nix
          ./packages/dev.nix
          ./packages/utils.nix
        ];
      };
    };
}
