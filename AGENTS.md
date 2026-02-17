# AGENTS.md

Instructions for coding agents working in this repository.

## Mission

Keep this repository secure, deterministic, and easy to maintain while evolving a modular Nix environment.

## Core rules

1. Prefer small, explicit changes over broad rewrites.
2. Preserve reproducibility: keep hashes pinned and avoid unreviewed version bumps.
3. Never commit secrets or machine-local artifacts.
4. Keep imports and relative paths coherent when moving modules.
5. Validate changes with Nix commands before finishing.

## Security defaults

1. Treat all external inputs as untrusted.
2. Do not introduce hardcoded credentials, tokens, or private URLs.
3. Use least privilege for CI permissions and shell behavior.
4. Keep supply-chain risk low: pin versions and hashes for fetched artifacts.

## Nix structure

- `modules/devshell/default.nix`: main flake-parts `perSystem` shell definition
- `modules/overlays/default.nix`: custom nixpkgs overlay
- `modules/toolsets/*.nix`: package groups
- `modules/toolsets/default.nix`: toolset composition
- `modules/pkgs/*.nix`: custom derivations

## Required checks

Run these before considering work complete:

```bash
nix flake show --no-write-lock-file
nix flake check --no-build --no-write-lock-file
nix develop -c true
```

## Git hygiene

1. Do not commit `.mcp.json`, `.direnv/`, or other local runtime artifacts.
2. Keep commits focused and reviewable.
3. Do not rewrite history unless explicitly requested.
