---
name: pr-review
description: Fetch and review a GitHub pull request by number or URL. Analyzes diff, checks for issues, and provides structured feedback.
allowed-tools: Bash, Read, Grep, Glob, WebFetch
argument-hint: "<pr-number-or-url> [--repo owner/repo]"
---

Review a GitHub pull request by fetching its diff and providing structured analysis.

## Process

Parse `$ARGUMENTS` for a PR number or full GitHub PR URL. If `--repo` is specified, use that. Otherwise, detect the repo from the current git remote.

1. **Fetch PR metadata and diff**:
   ```bash
   # If a full URL like https://github.com/owner/repo/pull/123
   # extract owner/repo and number from it.
   # If just a number, use current repo context.
   gh pr view <number> --repo <owner/repo> --json title,body,author,baseRefName,headRefName,files,additions,deletions,state,reviewDecision,labels
   gh pr diff <number> --repo <owner/repo>
   ```

2. **Analyze the diff** for:

   ### Critical (always flag)
   - **Security**: exposed secrets, credentials, tokens in code or config
   - **Correctness**: broken references, mismatched selectors/labels, invalid YAML/JSON
   - **Data loss**: missing PVC retention, destructive migrations, missing backups
   - **Breaking changes**: API version bumps, removed fields, incompatible upgrades

   ### Important (flag if confident)
   - Missing resource limits/requests in k8s manifests
   - Hardcoded values that should be parameterized
   - Missing error handling in scripts (no `set -e`, unquoted variables)
   - Terraform state risks (destroy-and-recreate resources)
   - Large files or binaries that shouldn't be committed

   ### Context
   - Check if CI checks are passing: `gh pr checks <number> --repo <owner/repo>`
   - Note review status and any existing review comments

3. **Output format**:

```
## PR #<number>: <title>
**Author:** <author> | **Base:** <base> ← <head> | **Files changed:** <count> (+<add>/-<del>)

## Summary
<2-3 sentence summary of what this PR does>

## Issues Found

### Critical (must fix)
- **[description]** — `file:line` — explanation and suggested fix

### Important (should fix)
- **[description]** — `file:line` — explanation and suggested fix

### Nits (optional)
- Minor observations, if any

## CI Status
<passing/failing, which checks>

## Verdict
[APPROVE | REQUEST CHANGES | COMMENT — and why]
```

4. If no issues are found, output a brief approval with a one-line summary.

## Notes

- If the PR has more than 1000 lines of diff, focus on the most critical files and note that a full review may require multiple passes.
- If `gh` is not authenticated, tell the user to run `gh auth login`.
- Do NOT approve or submit a review on GitHub — this is advisory output only.
