# Task Plan

- [x] Review existing CI workflows and repo context.
- [x] Design a weekly automation path that updates pinned flake dependencies via PR.
- [x] Implement the weekly PR automation workflow.
- [x] Implement post-CI merge behavior for successful automation PRs.
- [x] Document the PR-first build-and-merge behavior in the repository.
- [x] Validate workflow syntax and relevant repo checks.
- [x] Commit the updated change set and refresh the pull request.

## Review

- Updated `.github/workflows/weekly-flake-update.yml` so lockfile changes always create or refresh the automation PR instead of gating PR creation on pre-PR checks.
- Added `.github/workflows/merge-weekly-flake-update.yml` to merge the automation PR only after `nix-ci` completes successfully for `automation/weekly-flake-update`.
- Documented the required `PR_AUTOMATION_TOKEN` secret and the PR-first build-and-merge flow in `README.md`.
- `nix run nixpkgs#actionlint -- .github/workflows/nix-ci.yml .github/workflows/weekly-flake-update.yml .github/workflows/merge-weekly-flake-update.yml`: passed.
- `nix flake show --no-write-lock-file`: passed.
- `nix flake check --no-build --no-write-lock-file`: passed.
- `nix develop -c bash tests/unit/devshell_unit.sh`: fails on this branch because `sleuthkit` is missing from the devShell PATH, so automation PRs will stay open until that baseline CI issue is fixed.
- Updated PR `#2` with the PR-first build-and-merge workflow changes.

## Follow-up: Fix sleuthkit devShell test

- [x] Trace the failing `sleuthkit` assertion to the forensics toolset.
- [x] Patch the unit test or shell composition at the narrowest correct point.
- [x] Re-run the devShell unit test and supporting repo checks.
- [x] Commit and push the fix to PR `#2`.

### Follow-up Review

- Updated `tests/unit/devshell_unit.sh` to assert real Sleuth Kit executables (`fls` and `icat`) instead of a nonexistent `sleuthkit` wrapper command.
- `nix develop -c bash tests/unit/devshell_unit.sh`: passed (`46 assertions`).
- `nix flake show --no-write-lock-file`: passed.
- `nix flake check --no-build --no-write-lock-file`: passed.
- Pushed the fix to PR `#2` and refreshed the PR description to remove the stale baseline-failure note.

## Follow-up: Harden GitHub Actions security

- [x] Audit workflow files and repository Actions settings for code-injection and token-exposure risks.
- [x] Pin all third-party actions to immutable SHAs and tighten checkout behavior.
- [x] Reduce default workflow token permissions and strengthen privileged merge provenance checks.
- [x] Apply repository-level GitHub Actions restrictions that match the pinned workflow set.
- [x] Re-run local workflow validation and update PR `#2`.

### Security Hardening Review

- Pinned `actions/checkout`, `DeterminateSystems/nix-installer-action`, and `peter-evans/create-pull-request` to full commit SHAs.
- Set `persist-credentials: false` and `fetch-depth: 1` on all checkout steps.
- Reduced `GITHUB_TOKEN` permissions in the write-capable workflows so writes happen through the scoped `PR_AUTOMATION_TOKEN` only.
- Hardened `.github/workflows/merge-weekly-flake-update.yml` to verify base branch, head branch, head repository, cross-repo status, and exact validated head SHA before merge.
- Updated repository Actions settings with `allowed_actions=selected`, `sha_pinning_required=true`, and an explicit allowlist for `DeterminateSystems/nix-installer-action@*` and `peter-evans/create-pull-request@*`.
- Updated fork PR workflow approval policy to `all_external_contributors`.
- `nix run nixpkgs#actionlint -- .github/workflows/nix-ci.yml .github/workflows/weekly-flake-update.yml .github/workflows/merge-weekly-flake-update.yml`: passed.
- `nix flake show --no-write-lock-file`: passed.
- `nix flake check --no-build --no-write-lock-file`: passed.
- `nix develop -c bash tests/unit/devshell_unit.sh`: passed (`46 assertions`).

## Follow-up: Add Recommended RE Tools

- [x] Map the requested tools to existing toolset categories and confirm package/command names.
- [x] Add the requested tools to Nix toolsets and update docs/tests.
- [x] Re-run repo validation and open a fresh PR from `main`.

### Tool Addition Review

- Added `apktool` to the reversing toolset.
- Added `bpftrace` and `frida-tools` to the debugging toolset.
- Added `mitmproxy`, `volatility3`, `wireshark`, and `yara-x` to the forensics toolset.
- Updated `README.md` and `tests/unit/devshell_unit.sh` to document and validate the new commands.
- `nix develop -c bash tests/unit/devshell_unit.sh`: passed (`53 assertions`).
- `nix flake show --no-write-lock-file`: passed.
- `nix flake check --no-build --no-write-lock-file`: passed.
- Replaying this tool-addition change on a fresh branch because the earlier branch had already been merged.
- Opened follow-up PR `#3` from `feat/add-re-tools`.

## Follow-up: Add pwndbg (gdb + lldb flavored)

- [x] Add `pwndbg` flake input (github:pwndbg/pwndbg) with `nixpkgs` follows the project input.
- [x] Expose `pwndbg` and `pwndbg-lldb` via `modules/overlays/default.nix` so toolsets can reference `pkgs.pwndbg` / `pkgs.pwndbg-lldb`.
- [x] Add both packages to `modules/toolsets/debugging.nix` (alongside gdb, gef, lldb — all kept).
- [x] Extend `tests/unit/devshell_unit.sh` with `lldb`, `pwndbg`, and `pwndbg-lldb` assertions.
- [x] Document the new debugger entries in `README.md`.
- [x] Run `nix flake show`, `nix flake check --no-build`, and the devshell unit test.

### pwndbg Addition Review

- pwndbg was removed from nixpkgs in commit `4f0353c2` (2025-02-09) because its unicorn/uv dependency pinning is too burdensome for nixpkgs. Per the removal note, upstream's flake is the recommended consumption path.
- Added `pwndbg` as a flake input in `flake.nix` with `inputs.nixpkgs.follows = "nixpkgs"`. All of pwndbg's transitive inputs (pyproject-nix, uv2nix, pyproject-build-systems) also follow the project's nixpkgs, keeping evaluation efficient.
- Exposed `pwndbg` (gdb-flavored) and `pwndbg-lldb` (lldb-flavored) via the existing overlay in `modules/overlays/default.nix`, mirroring how `bindiff` is wired.
- Added `pkgs.pwndbg` and `pkgs.pwndbg-lldb` to `modules/toolsets/debugging.nix`. `gdb`, `gef`, and `lldb` are kept — gef and pwndbg coexist fine at the package level; users pick one via their gdbinit.
- Intentionally did **not** add the `pwndbg.cachix.org` substituter — per user preference, pwndbg builds from source.
- Added `assert_cmd lldb`, `assert_cmd pwndbg`, and `assert_cmd pwndbg-lldb` to `tests/unit/devshell_unit.sh` (lldb was missing despite being in the toolset).
- Documented both pwndbg variants in the Debugging table in `README.md`.
- `nix flake lock`: successfully added the pwndbg input and followers.
- `nix flake show --no-write-lock-file`: passed.
- `nix flake check --no-build --no-write-lock-file`: passed.
- `nix develop -c bash tests/unit/devshell_unit.sh`: passed (`56 assertions`, pwndbg + pwndbg-lldb built from source successfully).
- `nix fmt`: all edited Nix files conform to alejandra style.

## Follow-up: Modularize ReEnv as a reusable flake

Goal: other flakes (plain or flake-parts) should be able to consume ReEnv as a library — using the custom packages, the overlay, individual toolsets, or the full devshell — without inheriting ReEnv's internal input names.

- [x] Refactor `modules/overlays/default.nix` into `{ reenvInputs }: final: prev: { ... }` (standard overlay shape; system resolved via `final.stdenv.hostPlatform.system`).
- [x] Hoist `ghidra-bin`, `ghidra-mcp`, `ghidra-extensions`, and `ghidra-with-extensions` into the overlay so they're available as `pkgs.*`.
- [x] Normalize all toolset files to return plain package lists; `reversing.nix` no longer needs a `{meta,packages}` shape because ghidra paths are now read from `pkgs.*`.
- [x] Refactor `modules/devshell/default.nix` into `{ reenvInputs }: { lib, config, ... }: { ... }` with new options `reenv.nixpkgs` (defaulting to `reenvInputs.nixpkgs`) and `reenv.extraOverlays` (defaulting to `[]`). Switch all `inputs.*` references to `reenvInputs.*`. Read ghidra env-var paths from `pkgs.*` directly.
- [x] Update `modules/toolsets/default.nix` to drop `reversingMeta` since ghidra paths now live on `pkgs.*`.
- [x] Update `flake.nix` to expose: `overlays.default`, `flakeModules.default`, `lib.toolsets.*` (function per toolset), and `packages.${system}.{bindiff,pwndbg,pwndbg-lldb,retdec,ghidra-bin,ghidra-mcp,ghidra-with-extensions}`. Both in-flake imports and exported flakeModule close over `reenvInputs = inputs`.
- [x] Add a "Consuming ReEnv as a flake" section to `README.md` with examples for plain flakes, flake-parts consumers, and cherry-picking toolsets.
- [x] Validate: `nix flake show`, `nix flake check --no-build`, `nix develop -c bash tests/unit/devshell_unit.sh`, `nix fmt`.

### Modularization Review

- **Core mechanism**: The devshell module and overlay are now function factories closed over `reenvInputs` at flake evaluation time. `flake.nix` instantiates them with `reenvInputs = inputs` and passes the resulting module/overlay to both the in-flake `imports = [...]` and to the exported `flake.flakeModules.default` / `flake.overlays.default`. This means foreign flakes consuming ReEnv no longer need to declare matching `nixpkgs-retdec`/`pwndbg`/`mcp-servers-nix` inputs of their own — ReEnv's bundled lock travels with it transparently.
- **Consumer surface** (all new, closed over bundled inputs):
  - `reenv.overlays.default` — standard `final: prev:` overlay exposing `pwndbg`, `pwndbg-lldb`, `bindiff`, `retdec`, `ghidra-bin`, `ghidra-mcp`, `ghidra-extensions`, `ghidra-with-extensions`, and a pyghidra-enabled `python3`.
  - `reenv.packages.${system}.*` — direct access to each of those custom packages (bindiff gated to x86_64-linux via `lib.optionalAttrs`).
  - `reenv.lib.toolsets.{reversing,debugging,binaryAnalysis,forensics,crypto,hardware,python,devTools}` — per-toolset builder functions `{ pkgs }: [packages]`. All toolset files normalized to plain-list shape.
  - `reenv.flakeModules.default` — flake-parts module with two new options: `reenv.nixpkgs` (defaults to bundled nixpkgs; override to bring your own) and `reenv.extraOverlays` (stack extra overlays on top of ReEnv's).
  - `reenv.devShells.${system}.default` and `reenv.formatter.${system}` — unchanged from before.
- **Ghidra hoisting**: `ghidra-bin`, `ghidra-mcp`, and `ghidra-with-extensions` moved out of `modules/toolsets/reversing.nix` into the overlay. Reversing toolset now just references `pkgs.ghidra-with-extensions`. The devshell reads `GHIDRA_INSTALL_DIR` / `NIX_GHIDRAHOME` directly from `pkgs.ghidra-bin` / `pkgs.ghidra-with-extensions` instead of the old `reversingMeta` attr, which was dropped.
- **Bundled (non-overridable) inputs**: `nixpkgs-retdec` (cmake/gcc workaround), `pwndbg` upstream flake, `mcp-servers-nix`, `ghidra-mcp` (src fetch). These are ReEnv implementation details; consumers never see them.
- **Pre-existing dead code noted but not fixed**: the `ghidra-mcp` flake input is declared but unused — `modules/pkgs/ghidra-mcp.nix` does its own `fetchFromGitHub` with the same revision hardcoded. Out of scope for this refactor.
- **Behavioral neutrality proof**: pre- and post-refactor `nix flake check` produce the exact same devShell derivation (`/nix/store/njd0r209gn64xf36axp02dmlq426c97p-nix-shell.drv`), confirming nothing changed functionally for existing users.
- **End-to-end smoke tests**:
  - `nix eval .#lib.toolsets --apply builtins.attrNames` → all 8 toolsets present.
  - `nix eval .#lib.toolsets.debugging { pkgs=...; }` with overlay-applied pkgs → returns 9-package list including pwndbg.
  - `import nixpkgs { overlays = [ reenv.overlays.default ]; }` in a separate eval → `pkgs.pwndbg`, `pkgs.bindiff`, `pkgs.ghidra-bin`, etc. all resolve.
- **Validation**:
  - `nix flake show --no-write-lock-file`: passed, shows new `overlays`, `packages.${system}`, `lib` outputs.
  - `nix flake check --no-build --no-write-lock-file`: passed, including the `overlays.default` shape check.
  - `nix develop -c bash tests/unit/devshell_unit.sh`: passed (`56 assertions`).
  - `nix fmt` on the 5 edited files: clean.
- **README updated** with four consumption patterns: direct packages, overlay application, `lib.toolsets` cherry-pick, and flake-parts module import with `reenv.nixpkgs` override.
