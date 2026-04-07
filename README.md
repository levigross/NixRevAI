# ReEnv

[![CI](https://github.com/levigross/NixRevAI/actions/workflows/nix-ci.yml/badge.svg?branch=main)](https://github.com/levigross/NixRevAI/actions/workflows/nix-ci.yml)

A reproducible Nix flake for reverse engineering, firmware analysis, binary research, and AI-assisted workflows. 40+ tools organized into toggleable toolsets, packaged as a flake-parts module you can use standalone or import into your own flake.

## Quick start

### 1. Enter the environment

```bash
nix develop github:levigross/NixRevAI
```

Or from a local checkout:

```bash
nix develop
```

### 2. Optional: auto-load with direnv

```bash
echo 'use flake' > .envrc
direnv allow
```

### 3. Sanity check

```bash
command -v ghidra rizin uv
```

## Using ReEnv in your own flake

ReEnv is modular — consume as much or as little as you need. All of ReEnv's
internal inputs (pwndbg, nixpkgs-retdec, mcp-servers-nix, ghidra-mcp) travel
with the flake transparently; you only bring your own `nixpkgs`.

### Public flake outputs

| Output | Purpose |
|---|---|
| `reenv.overlays.default` | Standard nixpkgs overlay adding `pwndbg`, `pwndbg-lldb`, `bindiff`, `retdec`, `ghidra-bin`, `ghidra-mcp`, `ghidra-with-extensions`, and a pyghidra-enabled `python3`. |
| `reenv.packages.${system}.*` | Direct access to the custom packages above (bindiff is x86_64-linux only). |
| `reenv.flakeModules.default` | flake-parts module providing `devShells.default` and accepting `reenv.nixpkgs` / `reenv.extraOverlays` overrides. |
| `reenv.lib.toolsets.*` | Per-toolset builder functions (`reversing`, `debugging`, `binaryAnalysis`, `forensics`, `crypto`, `hardware`, `python`, `devTools`). Each takes `{ pkgs }` and returns a list of packages. |
| `reenv.devShells.${system}.default` | The full kitchen-sink dev shell built against ReEnv's pinned nixpkgs. |

### Option 1 — Grab individual packages

The most direct consumption. Use when you only want pwndbg (or retdec, or
bindiff, etc.) in your own shell and everything else is yours.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    reenv.url = "github:levigross/NixRevAI";
  };

  outputs = { nixpkgs, reenv, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          reenv.packages.${system}.pwndbg
          reenv.packages.${system}.pwndbg-lldb
          reenv.packages.${system}.retdec
        ];
      };
    };
}
```

### Option 2 — Apply ReEnv's overlay to your own nixpkgs

Use when you want the custom packages to appear on your own `pkgs` instance
(so `pkgs.pwndbg`, `pkgs.bindiff`, etc. are available alongside everything
else you normally use).

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";  # your own pin
    reenv.url = "github:levigross/NixRevAI";
  };

  outputs = { nixpkgs, reenv, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ reenv.overlays.default ];
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.pwndbg pkgs.ghidra-with-extensions ];
      };
    };
}
```

### Option 3 — Cherry-pick toolsets with `lib.toolsets`

Use when you want a curated bundle (e.g. the whole debugging toolset) without
pulling in everything. Each toolset function takes `{ pkgs }` (the overlay
should be applied first so packages like `pwndbg` resolve) and returns a plain
list you can drop into `buildInputs`.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    reenv.url = "github:levigross/NixRevAI";
  };

  outputs = { nixpkgs, reenv, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ reenv.overlays.default ];
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs =
          (reenv.lib.toolsets.debugging { inherit pkgs; })
          ++ (reenv.lib.toolsets.forensics { inherit pkgs; })
          ++ [ pkgs.your-own-tool ];
      };
    };
}
```

### Option 4 — As a flake-parts module

Use when you already have a flake-parts project and want the entire ReEnv
devshell dropped into it. Bring your own `nixpkgs`; ReEnv picks up everything
else from its own bundled lock.

```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";  # your own pin
    reenv.url = "github:levigross/NixRevAI";
  };

  outputs = inputs @ { flake-parts, reenv, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      imports = [ reenv.flakeModules.default ];

      # Override the nixpkgs ReEnv builds against. Defaults to ReEnv's own pin
      # if you omit this.
      reenv.nixpkgs = inputs.nixpkgs;

      # Optional: stack your own overlays on top of ReEnv's.
      # reenv.extraOverlays = [ (final: prev: { my-pkg = ...; }) ];

      # All toolset toggles default to true.
      reenv.enableHardwareToolset = false;
    };
}
```

The module provides `devShells.default` per system. It also exposes
`reenvToolsets` (the grouped package lists) and `pkgs` (with overlays applied)
as flake-parts module args, so downstream modules can reference them.

### Configuration options

| Option | Type | Default | Description |
|---|---|---|---|
| `reenv.nixpkgs` | flake input | ReEnv's bundled nixos-25.11 | Nixpkgs source used to build the dev shell. |
| `reenv.extraOverlays` | list of overlays | `[]` | Extra overlays stacked on top of ReEnv's overlay. |
| `reenv.enableDevTools` | `bool` | `true` | General development tools (git, gcc, go, jq, etc.) |
| `reenv.enablePythonToolset` | `bool` | `true` | Python RE stack (angr, pwntools, lief, etc.) |
| `reenv.enableHardwareToolset` | `bool` | `true` | Hardware and emulation tools (qemu, openocd, etc.) |

### Environment variables set by the shell

| Variable | Purpose |
|---|---|
| `GHIDRA_INSTALL_DIR` | Path to the base Ghidra installation |
| `NIX_GHIDRAHOME` | Path to `Ghidra/` inside the extension-bundled Ghidra |
| `JAVA_HOME` | JDK 21 |
| `SLEIGHHOME` | Rizin rz-ghidra SLEIGH processor specs |
| `CGO_ENABLED` | Set to `0` (cgo disabled by default) |
| `LD_LIBRARY_PATH` | Includes libstdc++ and Boost for native tool compatibility |

## Tool reference

### Reversing

| Tool | Description |
|---|---|
| Ghidra (+ extensions) | GUI + headless RE suite with MCP, FindCrypt, firmware-utils, ret-sync, Go analyzer, and SLEIGH devtools |
| Rizin (+ plugins) | CLI disassembler/analysis with jsdec, rz-ghidra decompilation, and sigdb |
| radare2 | Low-level RE framework and scripting interface |
| retdec | LLVM-based machine-code decompiler |
| Cutter | GUI front-end for Rizin/radare |
| Binary Ninja Free | Secondary disassembler/decompiler for cross-checking |
| Apktool | Android APK decode/rebuild workflow for manifests, resources, and smali |
| JADX | Android DEX/APK decompiler |
| Krakatau2 | Java bytecode disassembly and decompilation |
| BinDiff (x86_64 only) | Binary diffing to compare functions between builds |
| Wine + Mono (x86_64 only) | Run Windows PE binaries and .NET RE tools on Linux (stableFull with Mono and Gecko) |

### Debugging

| Tool | Description |
|---|---|
| gdb | GNU debugger |
| bpftrace | eBPF tracing for kernel and userland behavior |
| Frida tools | Dynamic instrumentation and runtime API hooking |
| GEF | GDB enhancement framework for exploit/RE workflows |
| lldb | LLVM debugger |
| pwndbg (gdb) | Exploit-focused GDB plugin, shipped via upstream flake since nixpkgs removed it |
| pwndbg-lldb | LLDB-flavored pwndbg variant from the upstream flake |
| rr | Record/replay debugger for deterministic analysis |
| strace | Syscall tracing |

### Binary analysis

| Tool | Description |
|---|---|
| bintools | ELF/object inspection (`objdump`, `readelf`, etc.) |
| aflplusplus | Coverage-guided fuzzing toolkit |
| unicorn | CPU emulation engine for dynamic analysis |
| keystone | Multi-arch assembler engine |
| libllvm | LLVM libraries for analysis/decompilation |

### Forensics

| Tool | Description |
|---|---|
| binwalk | Firmware/image extraction and signature scanning |
| foremost | File carving from raw images |
| mitmproxy | Interactive interception and replay for HTTP(S) traffic |
| squashfsTools | SquashFS firmware filesystem extraction |
| jefferson | JFFS2 filesystem extraction |
| ubi_reader | UBI/UBIFS parsing for embedded firmware |
| scalpel | File carving and recovery |
| sleuthkit | Filesystem forensics (`fls`, `icat`, etc.) |
| Volatility 3 | Memory forensics framework for Windows, Linux, and macOS images |
| Wireshark / TShark | GUI and CLI packet inspection for protocol analysis |
| YARA-X (`yr`) | Rule-based scanning and triage for firmware, malware, and extracted filesystems |
| p7zip | 7z archive extraction |
| rar | RAR archive handling |

### Crypto

| Tool | Description |
|---|---|
| hashcat | GPU/CPU password hash cracking engine |
| hashcat-utils | Wordlist/rule helpers for hashcat |
| openssl | Cryptographic utilities, cert parsing, conversions |

### Hardware

| Tool | Description |
|---|---|
| qemu | Full-system emulation for firmware and architecture testing |
| openocd | On-chip debugging/programming for embedded targets |
| pciutils | PCI device inspection (`lspci`) |
| usbutils | USB device inspection (`lsusb`) |

### Dev tools

| Tool | Description |
|---|---|
| bat | `cat` with syntax highlighting |
| bun | JS/TS runtime and package manager |
| bison / flex | Parser and lexer generators |
| cmake | Build system generator |
| dig | DNS query utility |
| gcc | C/C++ compiler toolchain |
| gh / glab | GitHub and GitLab CLIs |
| git | Source control |
| gnumake | `make` build runner |
| go | Go toolchain |
| gradle | JVM build automation |
| jdk21 | Java toolchain for RE tool plugins |
| jq | JSON query/transform |
| just | Task runner |
| lsof | Open-file and socket inspection |
| nil / nixd | Nix language server and lint |
| nodejs | Node runtime for JS tooling |
| pkg-config | Build dependency resolver |
| psmisc | Process utilities (`pstree`, `killall`) |
| ripgrep | Fast code search (`rg`) |
| sqlite | SQLite CLI |
| tree | Directory visualization |
| uv | Python package/project manager |

### Python libraries

| Package | Description |
|---|---|
| httpx | HTTP client for scripts and API automation |
| ghidra-bridge | Python bridge for Ghidra scripting |
| pyghidra | Native CPython integration with Ghidra |
| r2pipe | Script interface for radare2/rizin |
| unicorn | Emulator bindings for analysis scripts |
| pyyaml | YAML parsing |
| pwntools | Exploit dev and binary interaction toolkit |
| lief | Binary parsing/modification framework |
| cryptography | Cryptographic primitives and x509 handling |
| mcp | MCP client/server helpers for AI tool wiring |
| angr | Symbolic execution and binary analysis framework |
| angrcli | CLI helpers for angr workflows |

## Project layout

```text
modules/
  devshell/      # flake-parts module (devShell, options, shellHook)
  overlays/      # nixpkgs overlays (bindiff, pyghidra/jpype1 pins)
  pkgs/          # custom derivations (ghidra-bin, ghidra-mcp, bindiff, etc.)
  toolsets/      # grouped package lists and composition logic
tests/
  unit/          # shell-level unit tests
flake.nix        # flake entrypoint
flake.lock       # pinned dependencies
```

## Local validation

```bash
nix flake show --no-write-lock-file
nix flake check --no-build --no-write-lock-file
nix develop -c bash tests/unit/devshell_unit.sh
```

<details>
<summary>Contribution guidelines</summary>

### Workflow

1. Create a feature branch from `main`.
2. Keep changes focused and avoid unrelated refactors.
3. Run validation locally before opening a PR.
4. Open a PR with a clear problem statement and change summary.

### Required checks before PR

```bash
nix flake show --no-write-lock-file
nix flake check --no-build --no-write-lock-file
nix develop -c bash tests/unit/devshell_unit.sh
```

### Nix-specific expectations

- Keep fetched artifacts pinned with hashes.
- Preserve reproducibility and avoid ad-hoc, unpinned upgrades.
- Update module imports/paths consistently when moving files.

### Commit and PR quality

- Use descriptive commit messages.
- Document behavior changes in `README.md` when user-facing.
- Do not commit local runtime artifacts (for example `.direnv/` and `.mcp.json`).

</details>

<details>
<summary>Automated updates</summary>

This repo includes a scheduled workflow at `.github/workflows/weekly-flake-update.yml` that runs every Monday at 08:00 UTC and opens or refreshes a PR when `nix flake update` changes `flake.lock`.

The PR is then validated by the repo's normal `nix-ci` pull request workflow. If `nix-ci` succeeds for the automation branch, `.github/workflows/merge-weekly-flake-update.yml` merges the PR automatically. If `nix-ci` fails, the PR stays open for investigation and follow-up fixes.

This flow requires a repository secret named `PR_AUTOMATION_TOKEN` with permission to write contents and pull requests. Prefer a GitHub App token or a fine-grained PAT scoped to this repository only. The automation uses that token both to create the PR and to merge it after successful CI so that the PR's `pull_request` workflows actually run.

The normal PR validation for update PRs remains:

```bash
nix flake show --no-write-lock-file
nix flake check --no-build --no-write-lock-file
nix develop -c bash tests/unit/devshell_unit.sh
```

</details>
