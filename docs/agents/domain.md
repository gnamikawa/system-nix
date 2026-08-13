# Domain documentation

This project spans two repositories with a fixed dependency direction.
`dotfiles-nix` produces the user environment and can be deployed directly on
non-NixOS systems. `system-nix` is the NixOS entrypoint and consumes
`dotfiles-nix`.

Each repository owns its own domain documentation:

- `system-nix` uses `CONTEXT.md` and `docs/adr/` in this repository.
- `dotfiles-nix` uses `CONTEXT.md` and `docs/adr/` in
  `/home/genzo/repositories/dotfiles-nix`.

Read this repository's context and relevant architectural decision records
before exploring or changing it. When work affects the interface provided by
`dotfiles-nix`, the standalone user environment, or a domain term shared
across the boundary, also read the relevant context and decisions in
`dotfiles-nix`.

Use each repository's canonical terms. If the two repositories disagree,
surface the conflict instead of silently choosing one definition.
