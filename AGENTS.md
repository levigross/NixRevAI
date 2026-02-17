# AGENTS.md

Practical guidance for agents using this repository as a reverse-engineering environment.

## Purpose

This repo provides a reproducible Nix flake for RE work. Use it to analyze binaries and firmware safely, document findings clearly, and keep changes deterministic.

## Fast start

1. Enter the environment:

```bash
nix develop
```

2. Confirm key tooling is available:

```bash
command -v ghidra rizin uv binwalk gdb
```

3. Keep investigation artifacts under `.tmp/` unless the user asks to track them in git.

## Recommended reverse-engineering workflow

### 1. Intake and triage

1. Compute hashes for target inputs (`sha256sum`, `sha1sum`, `md5sum` as needed).
2. Identify file types and container layers (`file`, `binwalk`, `7z`, `readelf`).
3. Record exact sample path and hash in notes before deeper analysis.

### 2. Unpack and normalize

1. Extract firmware/archive layers into `.tmp/<case>/extracted/`.
2. Preserve originals read-only; never overwrite source samples.
3. Normalize names so follow-up steps are scriptable and repeatable.

### 3. Static analysis first

1. Start with fast CLI inspection (`rizin`, `radare2`, `strings`, `objdump`, `readelf`).
2. Move to Ghidra for cross-references, decompilation, and type recovery.
3. Use JADX/Krakatau for Android/JVM targets when relevant.
4. Use BinDiff for patch/version comparisons (x86_64 hosts only).

### 4. Dynamic analysis when justified

1. Use `gdb`/`lldb`/`rr` for runtime behavior and control-flow validation.
2. Use `strace` to inspect syscalls and runtime dependencies.
3. Use `qemu` for architecture or firmware emulation when native execution is unavailable.

### 5. Script and automate

1. Use the included Python stack (`pyghidra`, `r2pipe`, `angr`, `lief`, `pwntools`) for repeatable analysis.
2. Save reusable scripts under a user-approved path (default: `.tmp/<case>/scripts/`).
3. Prefer deterministic scripts over one-off manual operations.

### 6. Report findings

For each meaningful finding, capture:

1. What was found (behavior, vulnerability, protocol, key, IOC).
2. Evidence (offsets, function names, strings, xrefs, screenshots/logs).
3. Confidence and limitations.
4. Reproduction steps and exact commands.

## Tool selection guide

- `ghidra`: deep static analysis, xrefs, decompilation, large codebases.
- `rizin`/`radare2`: quick triage, scriptable analysis, byte-level patching.
- `jadx`: Android APK/DEX decompilation.
- `binwalk`, `jefferson`, `ubi_reader`, `squashfsTools`: firmware extraction.
- `gdb`, `lldb`, `rr`, `strace`: runtime and behavioral validation.
- `angr`, `unicorn`, `lief`: symbolic/dynamic scripting and binary rewriting support.
- `hashcat`: credential/hash recovery tasks when explicitly authorized.

## Security and safety rules

1. Treat all samples as untrusted and potentially malicious.
2. Do not execute unknown binaries on the host unless explicitly approved.
3. Prefer isolated execution (emulation, controlled containers/VMs).
4. Never embed secrets, credentials, or private data in commits.
5. Never download or exfiltrate samples without explicit user consent.

## Repo modification rules

1. Keep Nix reproducibility intact: pin versions and hashes for fetched artifacts.
2. Prefer minimal, reviewable diffs; avoid unrelated refactors.
3. Update docs when behavior or workflows change.
4. Do not commit local runtime files (`.mcp.json`, `.direnv/`, transient case data).

## Validation before finishing changes

```bash
nix flake show --no-write-lock-file
nix flake check --no-build --no-write-lock-file
nix develop -c bash tests/unit/devshell_unit.sh
```

## Output quality bar for agent responses

1. Use exact file paths and command lines.
2. Distinguish facts from hypotheses.
3. Call out unknowns and propose the next highest-value verification step.
4. Keep reports concise, evidence-driven, and reproducible.
