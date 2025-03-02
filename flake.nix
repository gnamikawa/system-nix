{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvim-nix.url = "github:gnamikawa/nvim-nix";
  };

  outputs =
    { self, nixpkgs, nvim-nix, ... }@inputs:
    let
      system = "x86_64-linux";  # Change if using a different architecture
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in
    {
      nixosConfigurations.GEN-DPC = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ config, pkgs, ... }: {
            nix.settings.experimental-features = [ "nix-command" "flakes" ];

            imports = [ ./hardware-configuration.nix ]; # Keep hardware config separate

            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            networking = {
              hostName = "GEN-DPC";
              # wireless.enable = true;
              networkmanager.enable = true;
            };

            time.timeZone = "Asia/Tokyo";

            i18n.defaultLocale = "en_US.UTF-8";
            i18n.extraLocaleSettings = { LC_ALL = "en_US.UTF-8"; };

            security.rtkit.enable = true;


            services = {
              displayManager.defaultSession = "none+i3";
              printing.enable = true;
              pulseaudio.enable = false;

              pipewire = {
                enable = true;
                alsa.enable = true;
                alsa.support32Bit = true;
                pulse.enable = true;
              };

              xserver = {
                enable = true;
                xkb.layout = "us";
                displayManager.gdm.enable = true;
                desktopManager.gnome.enable = true;

                windowManager.i3 = {
                  enable = true;
                  extraPackages = with pkgs; [ dmenu i3status i3lock i3blocks ];
                };
              };
            };

            users.users.genzo = {
              isNormalUser = true;
              description = "Genzo Namikawa";
              extraGroups = [ "networkmanager" "wheel" ];
            };

            programs.firefox.enable = true;
            programs.neovim = {
              enable = true;
              defaultEditor = true;
            };

            environment = {
              variables = {
                EDITOR = "nvim";
                BROWSER = "firefox";
                TERMINAL = "terminator";
              };

              systemPackages = with pkgs; [
                terminator
                htop
                wget
                clang
                git
                ranger
                stow
                ripgrep
                fzf
                xclip
                cargo
                nodejs_23
                unzip
                i3
                wineWowPackages.stable
                nvim-nix.defaultPackage.${system}
              ];

            };

            fonts.packages = with pkgs; [
              nerd-fonts.jetbrains-mono
            ];

            system.stateVersion = "24.11";
          })
        ];
      };
    };
}
