# Lessons

- When automating dependency update PRs, separate "create the PR" from "validate and merge the PR". Do not gate PR creation on pre-PR checks if the requirement is to leave failing update PRs open for follow-up fixes.
- After a PR is merged, do not continue landing new work on the same branch. Check the merge state first, then start a fresh branch from `main` for any follow-up changes that still need review.
- Before pushing a follow-up change, re-fetch and confirm whether the target PR has already merged. If it has, open a new branch and PR immediately instead of assuming the old review thread is still active.
