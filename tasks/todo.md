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
