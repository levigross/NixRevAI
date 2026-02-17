# NixRevAI
[![CI](https://github.com/levigross/NixRevAI/actions/workflows/nix-ci.yml/badge.svg?branch=main)](https://github.com/levigross/NixRevAI/actions/workflows/nix-ci.yml)

A ready-to-use Nix flake for reverse engineering, firmware analysis, binary research, and AI-assisted workflows.

## Who this is for

Use this flake if you want a reproducible RE environment with Ghidra, Rizin, debuggers, forensics tools, and a Python stack preloaded for automation.

## Quick start

### 1. Enter the environment

```bash
nix develop
```

### 2. Optional: auto-load with direnv

```bash
direnv allow
```

### 3. Sanity check

```bash
command -v ghidra rizin uv
```

## Common usage

```bash
# Open Ghidra
nix develop -c ghidra

# Start Rizin
nix develop -c rizin

# Use the Python RE stack
nix develop -c python -c "import pyghidra, angr, lief"
```

## Tool reference

### Core RE and CLI tools

| Tool | Group | Why it is included |
|---|---|---|
| Ghidra (+ bundled extensions) | reversing | Primary GUI + headless reverse engineering suite with custom extensions. |
| Rizin (+ jsdec/rz-ghidra/sigdb plugins) | reversing | Fast CLI disassembler/analysis with decompilation support. |
| radare2 | reversing | Alternative low-level RE framework and scripting interface. |
| retdec | reversing | LLVM-based machine-code decompiler for static analysis. |
| Cutter | reversing | GUI front-end for Rizin/radare workflows. |
| Binary Ninja Free | reversing | Secondary disassembler/decompiler for cross-checking analysis. |
| JADX | reversing | Android DEX/APK decompiler for Java/Kotlin recovery. |
| Krakatau2 | reversing | Java bytecode disassembly and decompilation tooling. |
| BinDiff (x86_64 only) | reversing | Binary diffing to compare functions between builds/samples. |
| gdb | debugging | GNU debugger for userland/native debugging. |
| GEF | debugging | GDB enhancement framework for exploit/RE workflows. |
| lldb | debugging | LLVM debugger for modern multi-platform debugging. |
| rr | debugging | Record/replay debugger for deterministic bug analysis. |
| strace | debugging | Syscall tracing for runtime behavior inspection. |
| bintools | binary-analysis | Core ELF/object inspection tools (`objdump`, `readelf`, etc.). |
| aflplusplus | binary-analysis | Coverage-guided fuzzing toolkit. |
| unicorn (native engine) | binary-analysis | CPU emulation engine for dynamic analysis and lifting tasks. |
| keystone | binary-analysis | Multi-arch assembler engine for shellcode/prototyping. |
| libllvm | binary-analysis | LLVM libraries used by analysis/decompilation tooling. |
| binwalk | forensics | Firmware/image extraction and signature scanning. |
| foremost | forensics | File carving from raw images. |
| squashfsTools | forensics | Extract/create SquashFS firmware filesystems. |
| jefferson | forensics | JFFS2 filesystem extraction. |
| ubi_reader | forensics | UBI/UBIFS parsing for embedded firmware. |
| scalpel | forensics | Fast file carving and recovery tool. |
| sleuthkit | forensics | Filesystem forensics toolkit (`fls`, `icat`, etc.). |
| p7zip | forensics | 7z archive extraction/packing. |
| rar | forensics | RAR archive handling. |
| hashcat | crypto | GPU/CPU password hash cracking engine. |
| hashcat-utils | crypto | Wordlist/rule helpers for hashcat workflows. |
| openssl | crypto | Cryptographic utilities, cert parsing, and conversions. |
| qemu | hardware | Emulation for firmware and architecture testing. |
| openocd | hardware | On-chip debugging/programming for embedded targets. |
| pciutils | hardware | PCI device inspection (`lspci`). |
| usbutils | hardware | USB device inspection (`lsusb`). |
| bat | dev-tools | Better `cat` with syntax highlighting for quick code reading. |
| bun | dev-tools | Fast JS/TS runtime and package manager. |
| bison | dev-tools | Parser generator for language tooling work. |
| cmake | dev-tools | Build system generator used by native projects. |
| dig | dev-tools | DNS query/debug utility. |
| flex | dev-tools | Lexer generator often paired with Bison. |
| gcc | dev-tools | C/C++ compiler toolchain. |
| glab | dev-tools | GitLab CLI for API and project operations. |
| gh | dev-tools | GitHub CLI for repo/PR/actions operations. |
| git | dev-tools | Source control. |
| gnumake | dev-tools | `make` build runner. |
| go | dev-tools | Go toolchain. |
| gradle | dev-tools | Build automation for JVM/Android projects. |
| jdk21 | dev-tools | Java toolchain for Java-based RE tools/plugins. |
| jq | dev-tools | JSON query/transform tool. |
| just | dev-tools | Task runner via `justfile`. |
| lsof | dev-tools | Open-file and socket inspection. |
| nil | dev-tools | Nix language tooling/lint support. |
| nixd | dev-tools | Nix language server. |
| nodejs | dev-tools | Node runtime for JS tooling compatibility. |
| pkg-config | dev-tools | Build dependency metadata resolver. |
| psmisc | dev-tools | Process utilities (`pstree`, `killall`, etc.). |
| ripgrep | dev-tools | Fast code/text search (`rg`). |
| sqlite | dev-tools | SQLite CLI for quick data inspection. |
| tree | dev-tools | Directory tree visualization. |
| uv | dev-tools | Fast Python package/project manager. |

### Python libraries in the shell

| Package | Why it is included |
|---|---|
| httpx | HTTP client for scripts and API automation. |
| ghidra-bridge | Python bridge integration for Ghidra scripting. |
| pyghidra | Native CPython integration with Ghidra internals. |
| r2pipe | Script interface for radare2/rizin workflows. |
| unicorn (Python bindings) | Emulator bindings for analysis scripts. |
| pyyaml | YAML parsing for tooling config and pipelines. |
| pwntools | Exploit dev and binary interaction toolkit. |
| lief | Binary parsing/modification framework. |
| cryptography | Core cryptographic primitives and x509 handling. |
| mcp | MCP client/server helpers for AI tool wiring. |
| angr | Symbolic execution and binary analysis framework. |
| angrcli | CLI helpers around angr workflows. |

## Project layout

```text
modules/
  devshell/      # flake-parts module for the default shell
  overlays/      # nixpkgs overlays and package overrides
  pkgs/          # custom derivations
  toolsets/      # grouped packages and composition
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
<summary>Contribution Guidelines</summary>

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
