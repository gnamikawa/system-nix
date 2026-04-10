# packages/dev.nix
# Developer Packages — Compilers, Build Tools, Scripting, VCS, Debugging
# Equivalent to Debian's build-essential + common dev toolchain.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [

    # ── Compilers & Build Tools ───────────────────────────────────────────────
    gcc
    clang
    gccStdenv.cc # g++
    gnumake
    binutils # as, ld, ar, nm, objdump, etc.
    pkg-config
    patchelf

    # ── Autotools, CMake & Meson ──────────────────────────────────────────────
    autoconf
    automake
    libtool
    cmake
    meson
    ninja

    # ── Scripting & Interpreted Languages ────────────────────────────────────
    perl
    python3
    python313
    python314
    python3Packages.pip
    python3Packages.virtualenv
    nodejs
    yarn

    # ── Rust ──────────────────────────────────────────────────────────────────
    cargo
    rust-analyzer

    # ── Version Control ───────────────────────────────────────────────────────
    git
    git-lfs
    diffstat
    patchutils

    # ── Debugging & Profiling ─────────────────────────────────────────────────
    gdb
    valgrind

    # ── Shell & Script Tooling ────────────────────────────────────────────────
    shellcheck
    shfmt
    direnv
    nix-direnv

    # ── Core Libraries (dev headers) ─────────────────────────────────────────
    openssl.dev # libssl-dev
    zlib.dev # zlib1g-dev
    libffi.dev
    readline.dev
    ncurses.dev
    sqlite.dev
    libxml2.dev
    curl.dev # libcurl4-openssl-dev
    glib.dev # libglib2.0-dev
    pcre.dev # libpcre3-dev

  ];
}
