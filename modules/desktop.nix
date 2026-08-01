{ pkgs, ... }:
{
  # Brings the Hyprland portal and, via withUWSM, the uwsm-managed
  # session entry (wayland-wm@hyprland.service).
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # Promptless GPU screen recording (Ctrl+Shift+5 -> hypr record.sh). Installs
  # gpu-screen-recorder and the setcap'd gsr-kms-server for KMS/NVENC capture,
  # so recording a monitor needs no xdg-desktop-portal picker.
  programs.gpu-screen-recorder.enable = true;

  # Disposable prerequisite for dotfiles-nix's AGS session-lock prototype.
  security.pam.services.astal-auth = { };

  # The greeter runs on its own Hyprland instance; sysc-greet supplies
  # the greetd session command, so no greetd override remains here.
  services.sysc-greet = {
    enable = true;
    compositor = "hyprland";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common.default = "*";
      hyprland.default = [
        "hyprland"
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
