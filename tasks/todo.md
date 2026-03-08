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
