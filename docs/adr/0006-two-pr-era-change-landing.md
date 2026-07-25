# 0006 — Land the era change as two pull requests, sway-coherent in between

Status: accepted
Decided: 2026-07-25, on [PR #4](https://github.com/gnamikawa/system-nix/pull/4)
(maintainer comments of 03:26 and 08:42; classification confirmed 08:22).

## Context

`updates` accumulated four months of work on top of a `master` that never
moved: the `hosts/`/`modules/` restructure, the VM guarantee harness, feature
work (docker, cuda, ollama, steam, pipewire, bluetooth, hibernation, samba,
nix-ld, kernel tuning) — and, at the tip, the sway→Hyprland cutover. Landing
it as one pull request buries a compositor change inside ~55 unrelated
commits. Rebasing only the cutover onto `master` is not possible either: the
cutover commits are authored against directories (`modules/`, `tests/`,
`docs/`) that the restructure creates.

Two flake-input defects complicated the split (#5, and the poisoned lock
described on PR #4): from `1655488` onward `flake.nix` — and later the lock
itself — pointed `dotfiles-nix` at a machine-local path, so most of the branch
resolves on exactly one machine.

## Decision

1. **PR A — everything else.** The 55 commits `master..6f2f539`, unchanged
   (the maintainer asked for a clean narrative on the parity work only),
   closed by a final commit that repoints `dotfiles-nix` at its GitHub remote,
   pinned at `2b5c042` — the Geist-theme commit of dotfiles-nix#25's
   rewritten narrative, the last rev before that repo adopts Hyprland.
2. **PR B — parity.** The three cutover commits (`0b9913a`, `8dd864f`,
   `c2dcbfb`), based on PR A's head, with a dedicated commit advancing the
   dotfiles pin across the Rewrite immediately before the session cutover.
3. Interleaved commits `4e49bc1`, `6e8536d`, `6f2f539` and `11dd7ba` are all
   everything-else (none touches the compositor); `6538e1c` is a lock-only
   snapshot bump superseded by PR A's re-pin and is not extracted.

## Consequences

- Between the two merges, `master` is **sway-coherent**: system config and
  dotfiles both still speak sway. At no point does `master` carry Hyprland
  user config under a sway session.
- The pin is an explicit rev on a branch under review. Until
  dotfiles-nix#25 merges (fast-forward), a force-push there would orphan
  `2b5c042`; PR B must not land before that merge, and PR A should land
  close to it.
- Commits of PR A other than its tip still carry the poisoned lock and do
  not evaluate off the original machine; bisecting inside PR A's range needs
  `--override-input dotfiles-nix`. Accepted on PR #4 rather than rewriting
  55 commits.
- The intermediate state of PR B (dotfiles advanced, session still sway)
  evaluates but is not a configuration anyone should deploy; it exists only
  inside the branch.
