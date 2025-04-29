{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvim-nix.url = "github:gnamikawa/nvim-nix";
  };

  outputs =
    { self, nixpkgs, nvim-nix }:
    let
      system = "x86_64-linux";  # Change if using a different architecture
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in
    {
      nixosConfigurations.GEN-DPC = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {
            system.stateVersion = "24.11";
            nix.settings.experimental-features = [ "nix-command" "flakes" ];

            imports = [ ./hardware-configuration.nix ]; # Keep hardware config separate

            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            networking.hostName = "GEN-DPC";
            networking.networkmanager.enable = true;

            time.timeZone = "Asia/Tokyo";

            i18n.defaultLocale = "en_US.UTF-8";
            i18n.extraLocaleSettings = { LC_ALL = "en_US.UTF-8"; };

            security.rtkit.enable = true;

            services = {
              displayManager.defaultSession = "sway";
              printing.enable = true;
              pulseaudio.enable = false;

              pipewire = {
                enable = true;
                alsa.enable = true;
                alsa.support32Bit = true;
                pulse.enable = true;
              };

              xserver = {
                enable = false;
                xkb.layout = "us";
                displayManager =
                  {
                    gdm.enable = true;
                  };
                desktopManager.gnome.enable = true;
                wacom.enable = true;
              };
            };

            programs.sway = {
              enable = true;
              wrapperFeatures.gtk = true;
            };
            hardware.graphics.enable = true;

            nix.gc.automatic = true;
            nix.gc.dates = "daily";
            nix.gc.options = "--delete-older-than 7d";

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
                hwinfo
                wineWowPackages.stable
                pcmanfm
                arandr
                libwacom
                xf86_input_wacom
                evtest
                krita
                blender
                discord
                rust-analyzer
                inotify-tools
                wlr-randr
                mako
                mpv
                grim
                wl-clipboard
                i3blocks
                i3status
                nvim-nix.defaultPackage.${system}
              ];

            };

            fonts.packages = with pkgs; [
              nerd-fonts.jetbrains-mono
            ];

          }
        ];
      };
    };
}
