# packages/core.nix
# Core / Base System Packages
# Essential system foundation, package management, shell & text tools,
# init & boot, user & auth, filesystem, networking, logging, hardware, terminals, editors.
{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans # Noto CJK Japanese + Chinese + Korean
    ricty # Optional, good monospaced font for coding
  ];

  environment.systemPackages = with pkgs; [
    # ── System Foundation ─────────────────────────────────────────────────────
    coreutils # ls, cp, mv, rm, cat, echo, etc.
    util-linux # mount, umount, fdisk, lsblk, etc.
    bash
    bash-completion
    dash
    which
    patch
    time

    # ── Package Management ────────────────────────────────────────────────────
    # (NixOS uses nix/nixpkgs natively; no apt/dpkg equivalents needed)
    gnupg

    # ── Shell & Text Tools ────────────────────────────────────────────────────
    gnused
    gnugrep
    gawk
    diffutils
    findutils
    gnutar
    gzip
    bzip2
    xz
    lz4
    zstd
    zlib

    # ── User & Auth ───────────────────────────────────────────────────────────
    shadow # passwd / login tooling
    sudo
    pam

    # ── Filesystem & Storage ──────────────────────────────────────────────────
    e2fsprogs
    lvm2
    fuse
    fuse3

    # ── Networking ────────────────────────────────────────────────────────────
    iproute2
    iputils # ping, ping6
    iptables
    bridge-utils # brctl
    nettools # netstat, ifconfig, route
    ethtool
    wget
    curl
    openssh

    # ── Logging & Scheduling ─────────────────────────────────────────────────
    rsyslog
    logrotate
    cron
    at

    # ── Hardware & Devices ────────────────────────────────────────────────────
    udev # managed by systemd in NixOS; listed for reference
    pciutils # lspci
    usbutils # lsusb
    dmidecode
    acpid
    acpi

    # ── Desktop / WM ─────────────────────────────────────────────────────────
    libnotify
    gsettings-desktop-schemas
    glib

    # ── Terminals & Console ───────────────────────────────────────────────────
    ncurses

    # ── Editors ───────────────────────────────────────────────────────────────
    nano
    vim

    # ── Documentation ─────────────────────────────────────────────────────────
    man-db
    man-pages
    groff

    # ── Localization & Misc ───────────────────────────────────────────────────
    tzdata
    hostname
  ];
}
