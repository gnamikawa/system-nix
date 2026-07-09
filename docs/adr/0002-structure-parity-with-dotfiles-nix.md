# Structure parity with dotfiles-nix

dotfiles-nix (the home-manager flake this repository consumes) mirrors this
repository's project structure, so that both repos answer "where does X
live?" with the same rule. The twin of this decision lives in dotfiles-nix
as `docs/adr/0002-structure-parity-with-system-nix.md`; a structural change
in either repository should be reflected in the other.

Shared conventions: flat one-concern-one-file `modules/` with a
`modules/default.nix` aggregator, `modules/packages/` for install-only
bundles, `hosts/<NAME>/` directories for everything host-specific, a
canonical-glossary `CONTEXT.md`, and numbered ADRs in `docs/adr/`.

Documented deviations on the dotfiles side: `assets/` (out-of-store
symlinked raw configs), `constants/` (theme data via `extraSpecialArgs`),
`modules/sway/` as a directory because it carries an asset tree, and no
`tests/` — this repository's VM tests already exercise the real host
configurations including dotfiles-nix (see ADR 0001).
