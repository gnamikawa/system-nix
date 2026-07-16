# packages/base-system.nix
# Base system (CONTEXT.md): tools that exist because they are part of the
# system itself — hardware, devices, the kernel, and administration. They
# must work under sudo and exist before any user profile; user-level tools
# live in dotfiles-nix, toolchains in its devshell catalog (ADR 0004).
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ── Networking ────────────────────────────────────────────────────────────
    iproute2
    iputils # ping, ping6
    iptables
    ethtool
    dnsutils # dig, nslookup
    traceroute
    tcpdump
    nmap
    nethogs

    # Guide compatibility (CONTEXT.md): external documentation still assumes
    # these under sudo; ip/ss/bridge and nc are the habitual tools.
    nettools # netstat, ifconfig, route
    bridge-utils # brctl
    inetutils # telnet

    # ── Filesystem & Storage ──────────────────────────────────────────────────
    e2fsprogs
    lvm2
    fuse
    fuse3
    parted
    hdparm
    smartmontools # smartctl

    # ── Hardware & Devices ────────────────────────────────────────────────────
    pciutils # lspci
    usbutils # lsusb
    dmidecode
    acpi
    lshw
    hwinfo
    lm_sensors # hardware temperature sensors
    evtest # input device event inspector
    v4l-utils # Video4Linux utilities

    # ── Kernel & System Observation ───────────────────────────────────────────
    sysstat # iostat, sar, mpstat

    # ── Documentation ─────────────────────────────────────────────────────────
    man-pages
  ];
}
