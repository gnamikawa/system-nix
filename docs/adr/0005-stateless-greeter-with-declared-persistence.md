# The greeter is stateless except declared persistence paths

The greeter's home (`/var/lib/greeter`) is wiped and rebuilt at every boot
by tmpfiles rules (`modules/greeter-state.nix`); the only state that
survives is an explicit allowlist symlinked into `/var/cache/sysc-greet`
(currently just `~/.cache/sysc-greet` — the theme/session/username memory
sysc-greet writes there, hardcoded relative to `$HOME`, ignoring
`XDG_CACHE_HOME`). The greeter's uid/gid are pinned to 988.

## Context

The 2026-07-20 GEN-DPC boot failure after The Rewrite (dotfiles-nix#1):
greetd's Hyprland session aborted four times in a row and the machine
never rendered a greeter, while the VM guarantee "booted means greeter is
rendered" passed. The coredump named the cause verbatim:
`filesystem error: status: Permission denied
[/var/lib/greeter/.local/share/icons/default/cursors]`.

Causal chain, each link verified on the machine:

1. The greeter is `isSystemUser` with a dynamically allocated uid. NixOS
   forgets the allocation if the user is ever absent from a generation;
   somewhere between 2026-04-15 (last successful preference write) and the
   2026-07-18 rebuild, the uid was reallocated — the greeter's old uid now
   belongs to `systemd-oom`, and greeter came back as 988.
2. Every file the old-uid greeter had written since Dec 2025 (`.cache`,
   `.config`, `.local` — ordinary session by-products: wireplumber state,
   flatpak scaffolding, NVIDIA GLCache, sysc-greet preferences) became
   foreign-owned; `.local` is 0700, so greeter could no longer traverse it.
3. sway's C XCursor loader treats an unreadable directory as "no theme
   here" and moves on, so the sway-era greeter booted over this rot for
   months. Hyprland's `CXCursorManager::themePaths` walks the same
   candidate paths with throwing `std::filesystem` calls and no catch:
   EACCES became `terminate` became a dead greeter. (Hyprland's own crash
   reporter then failed to write its report — into the same foreign-owned
   `.cache` — and aborted via `exitWithError`, which is why frames 1–2 of
   the stack are the reporter itself.)
4. The VM test could not see any of this: every run creates a fresh disk
   image, so the greeter home is always pristine. The guarantee had only
   ever been proven against first-boot state (see the **World state**
   glossary term this incident introduced).

## Decision

Rather than repairing ownership once (fixes the machine, leaves the class
alive) or only pinning the uid (fixes this cause, leaves any other state
rot undefended), make undeclared greeter state structurally impossible:

- **Pin uid/gid 988** — kills the root cause (reallocation) even during
  windows where the user is briefly undeclared. 988 is the value already
  live, so the pin is a no-op on disk.
- **Wipe `/var/lib/greeter` at boot** (`R!` tmpfiles rule, runs as root,
  so orphaned foreign-uid files are removed too). No manual `chown` was
  needed on GEN-DPC; the first boot with this module deletes the rot.
- **Declared persistence allowlist**: `~/.cache/sysc-greet →
  /var/cache/sysc-greet/prefs`, so login-screen theme/session/username
  choices survive boots and rebuilds. The allowlist is deliberately
  narrow; `~/.config/sysc-greet/themes` (custom themes) joins it when
  actually used, not before.

One-time migration on hosts with existing preferences: copy
`preferences` and `session` into `/var/cache/sysc-greet/prefs` before the
first reboot under this module (ownership is corrected by tmpfiles).

## Consequences

- The VM's fresh greeter home and the real machine's are now equal **by
  construction**; for the greeter, the pristine-world gap between test and
  reality is closed rather than papered over.
- The allowlist couples us to sysc-greet's internal paths. If upstream
  moves its cache dir, theme memory silently stops persisting — the
  planned preference-persistence guarantee (write prefs, reboot, assert
  they survive) exists to catch exactly that.
- Session by-products (shader caches, wireplumber state) are rebuilt each
  boot: a few milliseconds of greeter startup cost, accepted.
- Hyprland crash reports under `~/.cache/hyprland` do not survive a
  reboot; journald's coredump capture does, and proved sufficient to
  diagnose this incident.
- Anything that ever legitimately needs greeter persistence must be added
  to the allowlist visibly, never by weakening the wipe — the same shape
  as ADR-0001's carve-out rule.

## Amendment (2026-07-31, dotfiles-nix#49)

sysc-greet is gone, replaced by an AGS login screen that presents no
choice — no session picker, no last user, no theme. With nothing to
remember, the allowlist has no members, so it was deleted rather than
emptied: `~/.cache/sysc-greet → /var/cache/sysc-greet/prefs` and both
`/var/cache/sysc-greet` directory rules are removed, with no transitional
cleanup rule. Any directory left by an older generation is inert: nothing
in the current system reads, writes, or claims it, so it is stray data rather
than undeclared greeter persistence.

What survives unchanged is everything the incident actually turned on:
the pinned uid/gid, the boot-time wipe, and the rule that persistence is
declared or it does not exist. The title is now literally true rather
than true-except-for-a-list.

Two consequences above are retired with the allowlist: the coupling to
sysc-greet's internal cache paths, and the preference-persistence
guarantee planned to catch upstream moving them. Neither has anything
left to protect. The greeter's home is still named and still reset —
`/var/lib/greeter` is where a Hyprland instance and a GTK app write —
but the account itself now comes from NixOS's own greetd module, which
declares it without a home, so `modules/greeter-state.nix` names one.
