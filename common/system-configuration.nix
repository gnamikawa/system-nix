{ lib, pkgs, ... }:
{
  imports = [
    ./modules/network.nix
    ./modules/bluetooth.nix
    ./modules/filesystem.nix
    ./modules/polkit.nix
    ./modules/samba.nix
    ./modules/packages/core.nix
    ./modules/packages/java.nix
    ./modules/packages/dev.nix
    ./modules/packages/utils.nix
  ];

  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;
  services.upower.enable = true;
  users.users.genzo = {
    isNormalUser = true;
    description = "Genzo Namikawa";
    extraGroups = [
      "wheel"
      "video"
      "audio"
    ];
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "genzo" ];
    };
    gc.automatic = true;
    gc.dates = "daily";
    gc.options = "--delete-older-than 7d";
  };

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      config.common.default = "*";
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /media 0755 root root -"
      "d /media/%u 0755 %u users -"
    ];
  };

  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Tokyo";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
    extraLocales = [ "ja_JP.UTF-8/UTF-8" ];
    inputMethod = {
      enable = true;
      type = "fcitx5";
      enableGtk2 = true;
      enableGtk3 = true;
      fcitx5 = {
        addons = with pkgs; [
          fcitx5-gtk
          fcitx5-mozc-ut
        ];
        waylandFrontend = true;
      };
    };
  };

  security = {
    rtkit.enable = true;
    polkit = {
      enable = true;
    };
  };

  services = {
    sysc-greet = {
      enable = true;
      compositor = "sway";
    };
    greetd.settings.default_session.command = lib.mkForce "${pkgs.sway}/bin/sway -c /etc/greetd/sway-greeter-config --unsupported-gpu";

    printing.enable = true;
    pulseaudio.enable = false;
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    mpd.enable = true;
    usbmuxd.enable = true;
    libinput.enable = true;

    timesyncd = {
      enable = true;
      servers = [ "pool.ntp.org" ];
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish.enable = true;
      publish.userServices = true;
    };

    udisks2 = {
      enable = true;
      mountOnMedia = true;
    };

    flatpak.enable = true;
    xserver.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = true;
        UseDns = true;
        X11Forwarding = false;
        PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
      };
    };
  };

  programs = {
    gnupg.agent = {
      enable = true;
      pinentryPackage = with pkgs; pinentry-all;
      enableSSHSupport = true;
    };

    uwsm = {
      enable = true;
      waylandCompositors.sway = {
        prettyName = "Sway";
        comment = "User-defined sway compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/sway --unsupported-gpu > /dev/null 2>&1";
      };
    };

    sway = {
      enable = true;
      wrapperFeatures = {
        gtk = true;
        base = true;
      };
    };
  };

  environment = {
    extraInit = ''
      export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.stdenv.cc.cc.lib}/lib:/run/opengl-driver/lib:${pkgs.libglvnd}/lib:${pkgs.glib.out}/lib:${pkgs.zlib.out}/lib"
    '';

    pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];

    sessionVariables = {
      # GTK apps: try Wayland first, then X11
      GDK_BACKEND = "wayland,x11,*";

      # Qt apps: use Wayland, fallback to XCB
      QT_QPA_PLATFORM = "wayland;xcb";

      # SDL2 apps: use native Wayland
      SDL_VIDEODRIVER = "wayland";

      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
    };

    variables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
      TERMINAL = "kitty";
      FILE_BROWSER = "yazi";
    };
  };
}
