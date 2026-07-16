# Lean ambient layer, toolchains in a devshell catalog

Toolchains never live in the ambient layer — not in this repository's
`environment.systemPackages`, not in dotfiles-nix's `home.packages`. This
repository keeps only the base system (CONTEXT.md): tools that are part of
the system itself — hardware, devices, the kernel, administration — which
must work under sudo and exist before any user profile. Everything else
moved: the interactive toolkit to dotfiles-nix's ambient layer, toolchains
to its `devshells/` catalog. The twin of this decision lives in
dotfiles-nix as `docs/adr/0004-lean-ambient-layer-devshell-catalog.md`.

Why this shape:

- The old `packages/{core,dev,utils,java}.nix` imitated Debian's task
  selection, which on NixOS installed inert packages: NixOS-base
  duplicates (coreutils, sudo, which…), daemon binaries whose services
  were never enabled (cron, at, rsyslog, logrotate, acpid — `crontab -e`
  silently never ran anything), and `.dev` headers that no global search
  path ever saw. As mkShell buildInputs in the cpp devshell, the same
  headers work.
- The Debian *feel* is kept but delivered by the layer that travels with
  the user (home.packages, devShells); `environment.systemPackages`
  travels nowhere. Guide-compatibility tools that guides invoke under
  sudo (nettools, bridge-utils, inetutils) stay system-side, annotated,
  because home.packages is not on sudo's PATH.
- A default development environment (make, python3) stays active in every
  interactive shell — at any working directory — as a prebuilt profile
  prepended to PATH by shell init, so ambient leanness costs no scripting
  ergonomics. It remains a removable layer, never ambient: the claiming
  shell exports the profile path in `DEFAULT_DEV_ENV`, project direnv
  environments layer in front of it, and a one-line helper
  (`drop_default_env`) strips it for projects that need it absent. Root
  login shells (`sudo -i`) are deliberately out of scope — root gets the
  base system only; plain `sudo <cmd>` inherits the caller's PATH, NixOS
  setting no `secure_path`. Rejected alternatives: a fat ambient layer
  with all toolchains; per-shell `nix develop` evaluation in bashrc
  (slow, uncached, nests shells — a prebuilt profile path costs none of
  that); a managed, whitelisted `~/.envrc` (direnv only reaches
  descendants of a `.envrc`, so every path outside `$HOME` loses the
  layer); a `.envrc` at the filesystem root (unwritable by home-manager,
  machine-global for a per-user concern, and it makes direnv load-bearing
  for every shell everywhere); and `environment.systemPackages` (not a
  layer — nothing a project can shadow cleanly or remove).

Consequences: `modules/packages/` shrank to `base-system.nix` and
`fonts.nix`; iOS device tools moved to `modules/ios-devices.nix` and gained
the `services.usbmuxd.enable` they had always silently required; the VM
tests gain guarantees that ambient tools resolve in a real login shell,
that the default development environment is present in every interactive
shell (proven outside `$HOME`), that a project environment layers over it
and can remove it entirely, and that plain `sudo` inherits the invoking
shell's environment.
