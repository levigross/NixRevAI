# ReEnv

Modular Nix-based reverse-engineering development environment.

## What this repo provides

- A flake-based `devShell` for reverse engineering, debugging, firmware, crypto, and tooling workflows.
- Custom package overrides for edge cases (for example RetDec pinning and Python dependency compatibility).
- A module-oriented layout (`modules/`) to keep overlays, toolsets, and shell composition maintainable.

## Quick start

### Prerequisites

- Nix with flakes enabled

### Enter the environment

```bash
nix develop
```

### With direnv

```bash
direnv allow
```

## Repository layout

```text
modules/
  devshell/      # flake-parts module wiring the default shell
  overlays/      # custom nixpkgs overlay definitions
  pkgs/          # custom derivations
  toolsets/      # grouped package sets + composition
flake.nix        # flake entrypoint
flake.lock       # pinned inputs
```

## Local validation

```bash
nix flake show --no-write-lock-file
nix flake check --no-build --no-write-lock-file
nix develop -c true
```

## CI

GitHub Actions runs Nix evaluation checks on pushes and pull requests:

- `nix flake show --no-write-lock-file`
- `nix flake check --no-build --no-write-lock-file`
- `nix eval --raw .#devShells.x86_64-linux.default.inputDerivation.drvPath`
