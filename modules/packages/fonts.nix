# packages/fonts.nix
# System-wide fonts; per-user font choices belong in dotfiles-nix.
{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    # System-wide and not a user font, because the login screen is drawn by
    # the greeter user and names "Geist"/"Geist Mono" with no fallback chain
    # (dotfiles-nix greeter/style.css): a missing font is meant to be a
    # visible defect, not a near-miss substitute.
    geist-font
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans # Noto CJK Japanese + Chinese + Korean
    ricty # Optional, good monospaced font for coding
  ];
}
