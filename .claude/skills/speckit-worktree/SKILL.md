---
name: "speckit-worktree"
description: "Start a work item (F###/T###/B###/E### feature) in its own git worktree so it runs in parallel with other work without sharing branch, submodules or feature pointer."
argument-hint: "<ID or spec dir name> [base-ref, default main]"
metadata:
  author: "local"
  source: "custom (not managed by spec-kit; upgrades will not touch this file)"
user-invocable: true
disable-model-invocation: true
---

## User Input

```text
$ARGUMENTS
```

## Steps

1. **Resolve the directory.** Match the ID against directories in `specs/` of the main checkout (exact name, or name starting with `<ID>-`, case-insensitive, not `.done.*`). For a bug `B###` with no spec folder yet, use `B###-fix-<slug>` with the slug from the bug title in `AI-project-docs/bugs/B###.MD`. If nothing or several match, tell the user and **STOP**.
2. Run `.specify/scripts/bash/new-worktree.sh <dir> [base-ref]` from the repo root. If it fails, show the error and **STOP**.
3. Tell the user, briefly:
   - Worktree path and branch from the script output.
   - Next: open that folder in a **new** Claude session (`cd <path> && claude`, or a new VS Code window) and run the speckit steps there.
   - When the work is merged: `git worktree remove <path>` from the main checkout.

## Rules

- Do not run any other speckit step here. This session's feature pointer and branch stay unchanged.
- Do not commit or push.
