# packages/java.nix
# Java — JDK and headless JRE
# Only include this module if you need Java development or runtime support.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [

    # ── JDK ──────────────────────────────────────────────────────────────────
    jdk                # Full Java Development Kit (includes javac, jar, etc.)

    # ── Headless JRE (runtime only, no GUI libs) ─────────────────────────────
    # jre_headless     # Uncomment if you only need a JRE, not the full JDK.
    #                  # On NixOS `jdk` includes the runtime, so this is usually
    #                  # redundant unless targeting a minimal server image.

  ];
}
