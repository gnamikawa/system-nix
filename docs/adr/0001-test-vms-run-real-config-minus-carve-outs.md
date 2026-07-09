# Test VMs run the real host configuration minus an explicit carve-out list

The VM tests must prove guarantees about the machines we actually use, so
the system under test is the identical module set `nixosConfigurations.<host>`
is built from — including dotfiles, home-manager, and the greeter — never a
stripped-down synthetic config. The only permitted deviations are an explicit
carve-out list, restricted to what is impossible in a VM or unknowable to a
test: `nvidia.nix` wholesale on GEN-DPC (no GPU exists in QEMU; carving the
whole module also drops the multi-GB CUDA userspace, which proves nothing
without a driver — we chose this over a surgical driver-only carve-out),
hibernation on both hosts (resume device/offset and swapfile size are
physical-disk properties), a fake test-only password on the real user
(the real password is not in the repo and never will be), and two
VM-environment consequences accepted during implementation: timesyncd off
(the qemu-vm framework disables it itself — the VM clock is host-managed)
and `WLR_RENDERER=pixman` (wlroots cannot use a GPU renderer without a
GPU). Everything else stays in, however heavy — notably Steam.
`tests/carve-out.nix` is the enforcing module; if it and this list ever
disagree, one of them is wrong.

## Consequences

- A unit that fails only in the VM is fixed by extending the carve-out list
  visibly, never by weakening a test's assertions.
- The GEN-DPC test proves nothing about NVIDIA/CUDA behaviour; regressions
  in that area (e.g. the Cintiq/wlroots issue) are invisible to this suite.
