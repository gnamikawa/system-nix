{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
      sysc-greet,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        "GEN-DPC" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            dotfiles-nix.nixosModules.default
            home-manager.nixosModules.home-manager
            sysc-greet.nixosModules.default
            ./hosts/dpc
            ./modules
          ];
        };
        "GEN-LPC" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            dotfiles-nix.nixosModules.default
            home-manager.nixosModules.home-manager
            sysc-greet.nixosModules.default
            ./hosts/lpc
            ./modules
          ];
        };
      };

      checks.${system} = { inherit pkgs; } |> import ./tests;
    };
}
