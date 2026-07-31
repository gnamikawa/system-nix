# greeter-state.nix — the greeter keeps nothing (docs/adr/0005).
#
# /var/lib/greeter is wiped and rebuilt on every boot, and there is no longer
# an allowlist beside it: the AGS screen presents no choice, so it has no
# preference to remember. sysc-greet did — a session picker, a last-user, a
# theme — and /var/cache/sysc-greet existed to carry them across the wipe.
# Session by-products (GLCache, wireplumber state, flatpak scaffolding, …)
# still appear during a session — they just die at the next boot instead of
# rotting. Post-mortem note: Hyprland crash reports land in ~/.cache/hyprland
# and are therefore lost on reboot; the coredump in journald survives and was
# sufficient to diagnose the incident that produced this module.

{ ... }:
{
  # Pin the uid. `isSystemUser` uids are allocated dynamically and are
  # forgotten if the user is ever dropped from the configuration; a later
  # generation can hand the number to a different account, orphaning every
  # file the greeter ever wrote (this happened: see ADR-0005). 988 is the
  # value the running systems already use, so pinning it is a no-op on disk.
  users.users.greeter.uid = 988;
  users.groups.greeter.gid = 988;

  # The account itself comes from NixOS's greetd module, which declares it
  # without a home; a Hyprland instance and a GTK app both write to one, so
  # it is named here and reset below rather than left pointing at /var/empty.
  users.users.greeter.home = "/var/lib/greeter";

  systemd.tmpfiles.rules = [
    # Boot-time reset of the greeter home ('!' lines run only at boot).
    # Removal runs as root, so orphaned foreign-uid state is deleted too.
    "R! /var/lib/greeter"
    "d /var/lib/greeter 0700 greeter greeter -"
    "d /var/lib/greeter/.cache 0755 greeter greeter -"

    # Collect the durable store the old greeter left behind. Deleting this
    # line once both hosts have booted past the cutover is safe; leaving
    # greeter-owned state around with nothing to claim it is the exact shape
    # of the incident ADR-0005 records.
    "R! /var/cache/sysc-greet"
  ];
}
