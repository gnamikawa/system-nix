# greeter-state.nix — the greeter is stateless except declared preference
# paths (docs/adr/0005).
#
# /var/lib/greeter is wiped and rebuilt on every boot; the only thing that
# survives is the allowlist below, symlinked into /var/cache/sysc-greet
# (which tmpfiles re-owns each boot, so uid drift can never orphan it).
# Session by-products (GLCache, wireplumber state, flatpak scaffolding, …)
# still appear during a session — they just die at the next boot instead of
# rotting. Post-mortem note: Hyprland crash reports land in
# ~/.cache/hyprland and are therefore lost on reboot; the coredump in
# journald survives and was sufficient to diagnose the incident that
# produced this module.

{ ... }:
{
  # Pin the uid. `isSystemUser` uids are allocated dynamically and are
  # forgotten if the user is ever dropped from the configuration; a later
  # generation can hand the number to a different account, orphaning every
  # file the greeter ever wrote (this happened: see ADR-0005). 988 is the
  # value the running systems already use, so pinning it is a no-op on disk.
  users.users.greeter.uid = 988;
  users.groups.greeter.gid = 988;

  systemd.tmpfiles.rules = [
    # Durable preference store, ownership re-asserted every boot.
    "d /var/cache/sysc-greet 0755 greeter greeter -"
    "d /var/cache/sysc-greet/prefs 0755 greeter greeter -"

    # Boot-time reset of the greeter home ('!' lines run only at boot).
    # Removal runs as root, so orphaned foreign-uid state is deleted too.
    "R! /var/lib/greeter"
    "d /var/lib/greeter 0700 greeter greeter -"
    "d /var/lib/greeter/.cache 0755 greeter greeter -"

    # Persistence allowlist. sysc-greet hardcodes $HOME/.cache/sysc-greet
    # for its preferences/session files (it ignores XDG_CACHE_HOME); the
    # symlink routes those writes into the durable store. Deliberately
    # narrow: ~/.config/sysc-greet/themes (custom themes) is not
    # allowlisted until it is actually used.
    "L+ /var/lib/greeter/.cache/sysc-greet - - - - /var/cache/sysc-greet/prefs"
  ];
}
