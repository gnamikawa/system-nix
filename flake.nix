{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dotfiles-nix = {
      # Pinned to an explicit rev, not a branch: gnamikawa/dotfiles-nix#25
      # (updates -> master) has not landed yet, so `master` still points at
      # pre-Rewrite content. #25 is a fast-forward, so master will become this
      # exact rev on merge — at which point this becomes `.../master` with no
      # content change. See system-nix#5.
      url = "github:gnamikawa/dotfiles-nix/4c728e5939f315b5881e25f78fbec655f6c21fa7";
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
