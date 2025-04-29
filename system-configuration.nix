{
  lib,
  pkgs,
  pkgs2511,
  constants,
  ...
}:
{
  system.stateVersion = "25.11";

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

  users.users.genzo = {
    isNormalUser = true;
    description = "Genzo Namikawa";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "bluetooth"
    ];
  };

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      config.common.default = "*";
    };
  };

  systemd = {
    targets = {
      sway-session = {
        description = "Sway session proxy";
      };
    };
    services = {
      udiskie = {
        description = "Udiskie automounter";
        wantedBy = [ "default.target" ];

        serviceConfig = {
          ExecStart = "${pkgs.udiskie}/bin/udiskie --automount --notify";
          Restart = "always";
        };
      };
    };

    tmpfiles.rules = [
      "d /media 0755 root root -"
      "d /media/%u 0755 %u users -"
      "d /usr/share/sysc-greet/ascii_configs 0755 root root -"
      "L /usr/share/sysc-greet/ascii_configs/sway.conf 0644 root root - ${./assets/usr/share/sysc-greet/ascii_configs/sway.conf}"
    ];
  };

  networking.hostName = constants.hostName;
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Tokyo";

  i18n = {
    defaultLocale = "en_US.UTF-8";
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
    blueman.enable = true;
    dbus.enable = true;
    mpd.enable = true;
    usbmuxd.enable = true;
    libinput.enable = true;

    samba = {
      enable = true;
      smbd.enable = true;
      nmbd.enable = false;
    };

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

    flatpak = {
      enable = true;
    };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      wacom.enable = true;
    };

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
      # waylandCompositors.sway = {
      #   prettyName = "Sway";
      #   comment = "User-defined sway compositor managed by UWSM";
      #   binPath = "/run/current-system/sw/bin/sway";
      # };
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
      export PATH=$PATH:${pkgs.cudaPackages.cuda_nvcc.out}/bin
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

    systemPackages = with pkgs; [
      busybox
      # terminator
      htop
      wget
      clang
      ranger
      stow
      ripgrep
      fzf
      xclip
      chromium
      cargo
      unzip
      i3
      hwinfo
      wineWow64Packages.stable
      libwacom
      xf86_input_wacom
      evtest
      rust-analyzer
      inotify-tools
      wlr-randr
      mako
      grim
      wl-clipboard
      i3blocks
      i3status
      pciutils
      dmenu
      grim
      slurp
      pavucontrol
      qpwgraph
      wdisplays
      blueman
      crosspipe
      networkmanagerapplet
      pa_applet
      python314
      pkgs2511.python310
      python313
      libnotify
      zbar
      v4l-utils
      libimobiledevice
      ifuse
      atool
      unrar
      p7zip
      poppler-utils
      transmission_4-qt6
      odt2txt
      libcaca
      exiftool
      ueberzug
      fastfetch
      bat

      # ============================================================
      # Core userland (assumed everywhere)
      # ============================================================
      coreutils
      util-linux
      findutils
      gnugrep
      gawk
      gnused
      diffutils
      patch
      bc
      time

      # ============================================================
      # Filesystems / storage
      # ============================================================
      e2fsprogs
      dosfstools
      ntfs3g
      exfat
      fuse
      fuse3
      udisks

      # ============================================================
      # Compression / archives
      # ============================================================
      gnutar
      gzip
      bzip2
      xz
      lz4
      zstd
      zip
      unzip
      p7zip

      # ============================================================
      # Networking
      # ============================================================
      iproute2
      iputils
      bridge-utils
      nettools
      ethtool
      tcpdump
      curl
      wget
      rsync
      openssh

      # ============================================================
      # Process / system inspection
      # ============================================================
      procps
      psmisc
      lsof
      strace
      file
      which
      htop
      sysstat
      lm_sensors

      # ============================================================
      # Hardware / firmware inspection
      # ============================================================
      pciutils
      usbutils
      dmidecode
      acpi
      smartmontools
      hdparm

      # ============================================================
      # Text / terminal UX
      # ============================================================
      less
      moreutils
      nano # swap for vim if you want
      man-db
      man-pages

      # ============================================================
      # Build essentials (Arch base-devel / Debian build-essential)
      # ============================================================
      gcc
      gnumake
      binutils
      pkg-config
      cmake
      meson
      ninja
      autoconf
      automake
      libtool
      gdb
      strace
      patchelf

      # ============================================================
      # Version control & patching
      # ============================================================
      git
      git-lfs
      diffstat
      patchutils

      # ============================================================
      # Language-agnostic dev glue
      # ============================================================
      python3
      python3Packages.pip
      python3Packages.virtualenv
      nodejs
      yarn
      jq
      yq
      shellcheck
      shfmt

      # ============================================================
      # Shell quality-of-life
      # ============================================================
      bash
      bash-completion
      direnv
      nix-direnv

      (pkgs.writeTextFile {
        name = "monkeypatches";
        destination = "/share/wayland-sessions/sway.desktop";
        text = lib.readFile ./assets/share/wayland-sessions/sway.desktop;
      })
    ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans # Noto CJK Japanese + Chinese + Korean
    ricty # Optional, good monospaced font for coding
  ];
}
