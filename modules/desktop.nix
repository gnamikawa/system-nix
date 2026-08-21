{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The user-session parallel of greeter.nix's VT-silencing for the greeter
  # compositor: greetd hands its session the seat VT for stdio, so anything
  # uwsm or Hyprland's own init prints before Hyprland grabs the VT for
  # graphics flashes onto the greeter as text — the same shape of bug that
  # already put a banner on the login screen for the greeter side. The
  # upstream hyprland package installs hyprland-uwsm.desktop into its
  # share/wayland-sessions, which the greeter reads out of
  # /run/current-system/sw/share/wayland-sessions (see greeter.nix:100-106
  # for why that path, not XDG_DATA_DIRS). Rebuilding hyprland just to
  # substitute one line is wasteful, so this ships an identical desktop
  # entry wrapped in systemd-cat and wins the system-path buildEnv
  # collision via lib.hiPrio — hyprland itself is untouched. Landing this
  # in environment.systemPackages (not services.displayManager.session-
  # Packages) is deliberate: sessionPackages feeds a separate bundle used
  # by XDG-aware display managers, and the greeter here reads system-path
  # directly. The identifier is a hint, not a promise; grep the journal
  # for the message, never for the tag (see greeter.nix for the GJS caveat,
  # which does not apply here but documents the same reasoning).
  hyprlandUwsmSession = lib.hiPrio (
    pkgs.writeTextFile {
      name = "hyprland-uwsm-desktop-cat";
      destination = "/share/wayland-sessions/hyprland-uwsm.desktop";
      text = ''
        [Desktop Entry]
        Name=Hyprland (uwsm-managed)
        Comment=An intelligent dynamic tiling Wayland compositor
        Exec=${config.systemd.package}/bin/systemd-cat --identifier=user-compositor ${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop
        TryExec=${lib.getExe pkgs.uwsm}
        DesktopNames=Hyprland
        Type=Application
      '';
    }
  );
in
{
  # Brings the Hyprland portal and, via withUWSM, the uwsm-managed
  # session entry (wayland-wm@hyprland.service).
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  environment.systemPackages = [ hyprlandUwsmSession ];

  # Astal Auth authenticates the production AGS session lock through this
  # dedicated PAM service. The lock package lives in dotfiles-nix; the system
  # owns the authentication boundary.
  security.pam.services.astal-auth = { };

  # Promptless GPU screen recording (Ctrl+Shift+5 -> hypr record.sh). Installs
  # gpu-screen-recorder and the setcap'd gsr-kms-server for KMS/NVENC capture,
  # so recording a monitor needs no xdg-desktop-portal picker.
  programs.gpu-screen-recorder.enable = true;

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
