# Context

Glossary of terms as used in this repository. Definitions here are canonical;
if code or conversation disagrees with this file, one of them is wrong.

## Terms

### System under test (SUT)
The **real host configuration** — the identical module set that
`nixosConfigurations.<host>` is built from, including external inputs
(dotfiles, home-manager, greeter). A stripped-down or synthetic
configuration is *not* the system under test; a guarantee proven against
one says nothing about the real machine.

### Carve-out
A deliberate, minimal, documented test-only deviation from the system
under test, permitted only for things that are **impossible in a VM**
(e.g. a physical GPU) or **unknowable to the test** (e.g. a user's real
password). Anything else diverging between test and real system is a bug
in the tests.

### Guarantee
A behaviour of the system under test that must hold on every host, proven
by a runtime VM test (never by eval-level inspection). The current
guarantees: the system boots (**booted** means the greeter is rendered
and awaiting input — not merely that init ran), a user can log in
**through the greeter**
(the same path used on real hardware, not a shortcut around it), a
terminal emulator can be launched **by the user's own keybinding** (the
real keystroke, not a synthetic exec), and systemd is healthy
(**healthy** means `systemctl is-system-running` reports `running`,
sampled after the full boot → login → terminal flow has completed; a
unit that fails only in the VM is fixed by an explicit carve-out, never
by weakening this predicate).

### Test credential
A fake, arbitrary password assigned to the real user account inside a test
VM only (a carve-out). It is fixture data, not a secret: it unlocks nothing
outside a throwaway VM. Real passwords never appear in this repository and
are never needed by a test.

### Host
A named machine this repository configures. Currently `GEN-DPC` (desktop,
NVIDIA GPU) and `GEN-LPC` (laptop). Every guarantee applies to every host.
