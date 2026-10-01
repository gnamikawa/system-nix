## Git

- Never push to `master` (or `main`).
- When working on a feature with the user, changes go to whatever branch is
  active at that moment. Do not create or switch branches unless the user names
  one.
- A job is finished only when its changes are committed. Before reporting work
  as done, commit it on the active branch and check `git status`, so no staged
  or unstaged change is left behind to be forgotten. If something must stay
  uncommitted, say exactly what and why.

## Agent skills

### Issue tracker

Issues are tracked on GitHub. External pull requests are not an automatic
triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

Triage uses the canonical state label names. See
`docs/agents/triage-labels.md`.

### Domain docs

`system-nix` is the NixOS consumer of the standalone user environment produced
by `dotfiles-nix`; both repositories' domain documentation may apply. See
`docs/agents/domain.md`.

### Coding style

Repository coding style — pipe-operator preference and multi-line
argument handling. See `STYLE.md`.
