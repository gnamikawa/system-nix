# packages/fonts.nix
# System-wide fonts; per-user font choices belong in dotfiles-nix.
{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans # Noto CJK Japanese + Chinese + Korean
    ricty # Optional, good monospaced font for coding
  ];
}
