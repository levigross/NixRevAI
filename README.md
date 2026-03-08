# ReEnv

[![CI](https://github.com/levigross/NixRevAI/actions/workflows/nix-ci.yml/badge.svg?branch=main)](https://github.com/levigross/NixRevAI/actions/workflows/nix-ci.yml)

A reproducible Nix flake for reverse engineering, firmware analysis, binary research, and AI-assisted workflows. 40+ tools organized into toggleable toolsets, packaged as a flake-parts module you can use standalone or import into your own flake.

## Automated updates

This repo includes a scheduled workflow at `.github/workflows/weekly-flake-update.yml` that runs every Monday at 08:00 UTC and opens a PR when `nix flake update` changes `flake.lock`.

The workflow validates the updated lockfile before opening the PR by running:

```bash
nix flake show --no-write-lock-file
nix flake check --no-build --no-write-lock-file
nix develop -c bash tests/unit/devshell_unit.sh
```

If you want the generated PR to trigger the repo's normal `push` and `pull_request` workflows, add an optional `PR_AUTOMATION_TOKEN` repository secret with permission to write contents and pull requests. Without that secret, the workflow still opens or updates the PR using the default `GITHUB_TOKEN`, but GitHub suppresses follow-on workflow runs created by that token.

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

### As a dev shell dependency

The simplest integration: inherit ReEnv's full environment in your own shell via `inputsFrom`.

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    reenv.url = "github:levigross/NixRevAI";
  };

  outputs = { nixpkgs, reenv, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        inputsFrom = [ reenv.devShells.${system}.default ];

        # Add your own packages on top
        packages = [ pkgs.yara ];
      };
    };
}
```

### As a flake-parts module

For flake-parts projects, import the module directly and configure which toolsets are enabled.

```nix
# flake.nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    reenv.url = "github:levigross/NixRevAI";

    # Required: ReEnv's module needs these inputs.
    nixpkgs-retdec.url = "github:NixOS/nixpkgs/nixos-25.05";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      imports = [ inputs.reenv.flakeModules.default ];

      # All options default to true. Set to false to exclude a group.
      reenv.enableDevTools = true;
      reenv.enablePythonToolset = true;
      reenv.enableHardwareToolset = false;
    };
}
```

The module provides `devShells.default` per system. It also exposes `reenvToolsets` (the grouped package lists) and `pkgs` (with overlays applied) as flake-parts module args, so downstream modules can reference them.

### Configuration options

| Option | Type | Default | Description |
|---|---|---|---|
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
| JADX | Android DEX/APK decompiler |
| Krakatau2 | Java bytecode disassembly and decompilation |
| BinDiff (x86_64 only) | Binary diffing to compare functions between builds |
| Wine + Mono (x86_64 only) | Run Windows PE binaries and .NET RE tools on Linux (stableFull with Mono and Gecko) |

### Debugging

| Tool | Description |
|---|---|
| gdb | GNU debugger |
| GEF | GDB enhancement framework for exploit/RE workflows |
| lldb | LLVM debugger |
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
| squashfsTools | SquashFS firmware filesystem extraction |
| jefferson | JFFS2 filesystem extraction |
| ubi_reader | UBI/UBIFS parsing for embedded firmware |
| scalpel | File carving and recovery |
| sleuthkit | Filesystem forensics (`fls`, `icat`, etc.) |
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
