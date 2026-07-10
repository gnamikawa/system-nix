# Desktop hosts use heuristic memory overcommit, pinned explicitly

`vm.overcommit_memory = 2` (strict accounting: every virtual reservation
is charged against a hard ceiling of swap + `overcommit_ratio`% of RAM)
was copied onto GEN-DPC unvetted during the configuration overhaul
(80633f4) and survived every refactor since. On a 16 GB / 39 GB-swap
machine the ceiling is ~50 GB, and a normal desktop session sits just
under it: browsers and JS runtimes reserve enormous virtual ranges they
never touch, so `Committed_AS` reached 48 GB while only ~4 GB of RAM was
in use. Any further reservation was denied by the kernel
(`__vm_enough_memory` in the journal), which SIGBUS-crashed Firefox
whenever dragging a tab out spawned a new window and renderer, and
denied Node.js its address-space reservations outright.

Strict mode has a real use — servers that prefer explicit allocation
failure over the OOM killer's unpredictability — but desktop software
assumes overcommit exists. We choose heuristic overcommit (mode 0, the
kernel default) and rely on zram plus the swapfile for memory pressure.
The sysctl is pinned to 0 explicitly in `hosts/GEN-DPC/hardware.nix`
rather than deleted, with a comment pointing here, because that file is
exactly where a future tuning pass would re-add strict mode.

## Consequences

- Memory pressure is handled by zram + swap and, in the worst case, the
  kernel OOM killer; nothing replaces strict mode's explicit-failure
  behaviour, and nothing needs to on a desktop.
- `amd_pstate=disable` and `iommu.strict=0` entered the config in the
  same unvetted tuning pass (31cf6b5) and remain unreviewed. They are
  deliberately out of scope here — reverting them blind would change
  CPU frequency scaling and IOMMU behaviour with no symptom to justify
  it — but they should not be mistaken for vetted settings.
- GEN-LPC never set the sysctl and is unaffected; new hosts should not
  set `vm.overcommit_memory = 2` without an ADR superseding this one.
