{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dotfiles-nix = {
      # Tip of dotfiles-nix#25's narrative (tree-identical to 4c728e5).
      # Becomes .../master with no content change when #25 fast-forwards;
      # flip the ref then. See docs/adr/0006.
      url = "github:gnamikawa/dotfiles-nix/e96c400d7d538fe97ae2a33c93bea82ea7378b78";
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
      sharedModules = [
        dotfiles-nix.nixosModules.default
        home-manager.nixosModules.home-manager
        sysc-greet.nixosModules.default
        ./modules
      ];
      # Single source of truth for what each host is made of; the VM tests
      # import the same lists so the system under test cannot drift from the
      # real configuration (docs/adr/0001).
      hostModules = {
        "GEN-DPC" = sharedModules ++ [ ./hosts/GEN-DPC ];
        "GEN-LPC" = sharedModules ++ [ ./hosts/GEN-LPC ];
      };
    in
    {
      nixosConfigurations =
        hostModules
        |> builtins.mapAttrs (name: modules: nixpkgs.lib.nixosSystem { inherit system modules; });

      checks.${system} =
        {
          inherit pkgs hostModules;
          # For the project-environment layering guarantee: the tests build
          # an offline-evaluable fixture from the real devshell list and the
          # locked nixpkgs source (tests/guarantees.nix).
          dotfiles = dotfiles-nix;
          nixpkgsSrc = nixpkgs;
        }
        |> import ./tests;
    };
}
