{ lib, pkgs, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures = {
      gtk = true;
      base = true;
    };
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors.sway = {
      prettyName = "Sway";
      comment = "User-defined sway compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/sway --unsupported-gpu > /dev/null 2>&1";
    };
  };

  services.sysc-greet = {
    enable = true;
    compositor = "sway";
  };
  services.greetd.settings.default_session.command = lib.mkForce "${pkgs.sway}/bin/sway -c /etc/greetd/sway-greeter-config --unsupported-gpu";

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common.default = "*";
      sway.default = lib.mkForce [
        "wlr"
        "gtk"
      ];
    };
  };

  services.xserver.enable = true;
  services.libinput.enable = true;

  environment.sessionVariables = {
    # GTK apps: try Wayland first, then X11
    GDK_BACKEND = "wayland,x11,*";

    # Qt apps: use Wayland, fallback to XCB
    QT_QPA_PLATFORM = "wayland;xcb";

    # SDL2 apps: use native Wayland
    SDL_VIDEODRIVER = "wayland";
  };

  environment.variables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "kitty";
    FILE_BROWSER = "yazi";
  };
}
