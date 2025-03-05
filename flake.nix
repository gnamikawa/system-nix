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
          ({ config, ... }: {
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
                wacom.enable = true;

                windowManager.i3 = {
                  enable = true;
                  extraPackages = with pkgs; [ dmenu i3status i3blocks ];
                };
              };
            };

            # Use xsetwacom commands in a startup script
            systemd.user.services.wacom-fix =
              let
                monitor = "DP-1";
              in
              {
                enable = true;
                description = "Fix Wacom mapping on startup";
                after = [ "graphical-session.target" ];
                wantedBy = [ "default.target" ];
                serviceConfig = {
                  ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.xorg.xinput}/bin/xinput map-to-output \"Wacom Cintiq Pro 22 Finger\" ${monitor} && ${pkgs.xorg.xinput}/bin/xinput map-to-output \"Wacom Cintiq Pro 22 Pen Pen (0x23606a19)\" ${monitor}'";
                  Restart = "always";
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
                hwinfo
                wineWowPackages.stable
                pcmanfm
                arandr
                libwacom
                xf86_input_wacom
                evtest
                krita
                blender
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
