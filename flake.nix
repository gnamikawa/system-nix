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
    {
      nixosConfigurations."GEN-DPC" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { };
        modules = [
          dotfiles-nix.nixosModules.default
          home-manager.nixosModules.home-manager
          sysc-greet.nixosModules.default
          ./dpc/hardware-configuration.nix
          ./dpc/system-configuration.nix
          ./common/hardware-configuration.nix
          ./common/system-configuration.nix
        ];
      };

      nixosConfigurations."GEN-LPC" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { };
        modules = [
          dotfiles-nix.nixosModules.default
          home-manager.nixosModules.home-manager
          sysc-greet.nixosModules.default
          ./lpc/hardware-configuration.nix
          ./lpc/system-configuration.nix
          ./common/hardware-configuration.nix
          ./common/system-configuration.nix
        ];
      };
    };
}
