# packages/utils.nix
# Standard System Utilities
# Corresponds to Debian's "Standard system utilities" task selection.
# File inspection, network diagnostics, archivers, process tools, disk tools.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [

    # ── File Inspection & Navigation ─────────────────────────────────────────
    file
    less
    moreutils
    tree
    yazi # TUI file manager
    bat # cat with syntax highlighting
    exiftool # Read/write file metadata

    # ── Search & Filtering ────────────────────────────────────────────────────
    ripgrep # rg — fast grep replacement
    fzf # Fuzzy finder

    # ── Clipboard ────────────────────────────────────────────────────────────
    xclip
    wl-clipboard # Wayland clipboard (wl-copy / wl-paste)

    # ── Math & Calculation ────────────────────────────────────────────────────
    bc
    jq # JSON processor
    yq # YAML/TOML processor

    # ── Process & System Monitoring ──────────────────────────────────────────
    lsof
    htop
    fastfetch
    procps # ps, top, vmstat, free
    psmisc # killall, pstree, fuser
    sysstat # iostat, sar, mpstat
    lm_sensors # Hardware temperature sensors
    inotify-tools # inotifywait / inotifywatch

    # ── Tracing & Debugging ───────────────────────────────────────────────────
    strace
    ltrace
    evtest # Input device event inspector

    # ── Networking & DNS ──────────────────────────────────────────────────────
    traceroute
    netcat # nc
    dnsutils # dig, nslookup
    whois
    nmap
    tcpdump
    rsync
    inetutils # telnet and basic inet tools

    # ── Wayland / Display Tools ───────────────────────────────────────────────
    wlr-randr # RandR-like tool for wlroots compositors
    wdisplays # Graphical display configurator

    # ── Launchers & Misc Desktop ─────────────────────────────────────────────
    stow # Symlink farm manager (dotfiles)
    crosspipe

    # ── Archivers ─────────────────────────────────────────────────────────────
    unzip
    zip
    unrar
    p7zip
    atool # Universal archive front-end

    # ── Document & Media Conversion ───────────────────────────────────────────
    poppler-utils # pdfinfo, pdftotext, etc.
    odt2txt # OpenDocument to text
    libcaca # ASCII-art image renderer
    zbar # Barcode / QR code scanner

    # ── Video & Camera ────────────────────────────────────────────────────────
    v4l-utils # Video4Linux utilities

    # ── iOS / Mobile Device Support ──────────────────────────────────────────
    libimobiledevice # iOS device protocol library
    ifuse # Mount iOS devices via FUSE

    # ── Terminal Multiplexers ─────────────────────────────────────────────────
    screen
    tmux

    # ── Hardware & Disk Tools ─────────────────────────────────────────────────
    lshw
    hwinfo
    hdparm
    smartmontools # smartctl
    parted

  ];
}
