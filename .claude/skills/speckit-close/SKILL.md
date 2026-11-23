---
name: "speckit-close"
description: "Close a finished feature or bugfix: rename specs/<dir>/ to specs/.done.<dir>/ so agents skip it, fix path references, and clear the active feature pointer."
argument-hint: "<ID: E###|F###|T###> | <spec dir name> | (empty = current feature) [--force]"
compatibility: "Requires spec-kit project structure with .specify/ directory"
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

The input is one or more targets separated by spaces, plus an optional `--force` flag. A target is a work-item ID (`F005`, `T001`, `E001`), a spec number (`003`), or a directory name under `specs/` (`002-onboarding-instruction`). If no target is given, the target is the directory in `.specify/feature.json`.

## Why

A spec folder whose name starts with `.done.` is closed. Agents ignore it unless the user names it, the same way bugs in `AI-project-docs/bugs/` are closed with a `.done.` prefix. The dot also hides the folder from `ls`, ripgrep and glob searches by default, so finished specs stop using up tokens.

## Steps

1. **Resolve targets.** Match each target against the directories directly in `specs/`: an exact directory name, or a directory whose name starts with `<target>-` (case-insensitive). Skip directories that already start with `.done.` and say that they are already closed. If a target matches nothing, or matches more than one directory, tell the user and skip that target. If there are no targets left, **STOP**.

2. **Check that each target is finished.** Unless `--force` was given:
   - If `tasks.md` exists, list every unchecked task (`- [ ]`).
   - If `bugfix.md` exists, read its `**Status**:` line. Only `Fixed` counts as finished.
   - If the folder has a draft (`E###-*.md`, `F###-*.md` or `T###-*.md`) but no `spec.md`, it was never specified. Skip this check for drafts whose `**Type**:` is `Epic` or `Task`, since those are never specified. For a `Task` draft, list its unchecked steps (`- [ ]`) instead.
   If any of these apply, show what is unfinished and ask the user with AskUserQuestion whether to close it anyway or skip it. Do not tick tasks or change the status yourself.

3. **Rename.** For each target, run `mv specs/<dir> specs/.done.<dir>` from the repo root. Never delete, merge or edit the folder's contents.

4. **Clear the active feature pointer.** If `.specify/feature.json` points at a closed directory, delete `.specify/feature.json`. Leaving it would make the next `speckit-*` command work in a closed folder.

5. **Fix references.** Search the repo for `specs/<dir>` (and abbreviated forms such as `specs/<dir-prefix>-…`), leaving out `node_modules/`, `dist/`, `build/`, `.git/`, `milos.github.io/` and the `.done.*` folders. In `CLAUDE.md` files and other docs, replace the path with `specs/.done.<dir>` so the pointer still works. Do not touch source code comments unless they hold the exact path. List every file you changed.

6. **Report.** Give a table with columns: old path, new path, open tasks/status at close time, references updated. Remind the user that `/speckit-close` can be undone with `mv specs/.done.<dir> specs/<dir>`.

## Rules

- Closed folders still count for numbering. When picking the next `F###`, the `speckit-feature-init` and `speckit-specify` skills also match `.done.F###-*`.
- Do not run hooks, commit, or change any spec file's contents.
