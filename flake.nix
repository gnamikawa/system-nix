{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dotfiles-nix = {
      url = "github:gnamikawa/dotfiles-nix/2844c47b685ed7e710b4019fe8e073cc7d1b013b";
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
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      sharedModules = [
        dotfiles-nix.nixosModules.default
        home-manager.nixosModules.home-manager
        ./modules
        # The login screen, as a bin. It rides in the module list rather than
        # in nixosSystem's specialArgs because the VM tests build their node
        # from these same lists (docs/adr/0001) and get their specialArgs from
        # the test framework, not from here.
        { _module.args.greeterPackage = dotfiles-nix.packages.${system}.greeter; }
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
