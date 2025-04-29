{
  description = "System configuration";

  inputs = {
    nixpkgs2511.url = "github:NixOS/nixpkgs/9da7f1cf7f8a6e2a7cb3001b048546c92a8258b4?narHash=sha256-SlybxLZ1/e4T2lb1czEtWVzDCVSTvk9WLwGhmxFmBxI%3D";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dotfiles-nix = {
      url = "github:gnamikawa/dotfiles-nix/master";
      # url = "path:/home/genzo/repositories/dotfiles-nix";
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
      nixpkgs2511,
      home-manager,
      dotfiles-nix,
      nur,
      sysc-greet,
    }:
    let
      constants = import ./constants.nix;
      pkgs2511 = (import nixpkgs2511) { system = constants.system; };
    in
    {
      nixosConfigurations.${constants.hostName} = nixpkgs.lib.nixosSystem {
        system = constants.system;
        specialArgs = {
          inherit constants;
          inherit pkgs2511;
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
        ];
      };
    };
}
