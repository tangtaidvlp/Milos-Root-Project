---
name: "speckit-init"
description: "Create a new work-item draft by type (Epic E###, Feature F###, Task T### under specs/<ID>-<slug>/; Defect B### under AI-project-docs/bugs/) for the user to fill in."
argument-hint: "[epic|feature|task|defect] <name>"
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

The input is an optional work type followed by the name, e.g. `feature Onboard feature` or `Onboard feature`.

## Work types

The types come from the task taxonomy in `~/.claude/CLAUDE.md`.

| Type | Prefix | Meaning | Template | Created at | Next step |
|------|--------|---------|----------|------------|-----------|
| Epic | `E` | Big change made of several features, often across services, delivered in phases | `.specify/templates/epic-request-template.md` | `specs/E###-<slug>/E###-<slug>.md` | List the features, then `/speckit-init feature <name>` for each one, with its `**Epic**:` line set to this ID. An epic is never specified directly. |
| Feature | `F` | Function or enhancement made of several tasks | `.specify/templates/feature-request-template.md` | `specs/F###-<slug>/F###-<slug>.md` | `/speckit-specify F###` |
| Task | `T` | Small change, with optional steps | `.specify/templates/task-request-template.md` | `specs/T###-<slug>/T###-<slug>.md` | Fill in the steps, then ask Claude to implement the draft directly. There is no spec or plan. |
| Defect | `B` | Bug fix | `.specify/templates/bug-report-template.md` | `AI-project-docs/bugs/B###.MD` | `/speckit-debug AI-project-docs/bugs/B###.MD` |

## Parallel work

Drafts are always created in the main checkout (`MAIN_ROOT`), even when run from a worktree. `MAIN_ROOT` is `$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")`. When finding the next number, search `specs/` (and `AI-project-docs/bugs/` for defects) in **every** path from `git worktree list --porcelain`, so two worktrees never get the same ID.

## Steps

1. **Type**: if the first word of the input is `epic`, `feature`, `task` or `defect` (case-insensitive), that is the type, and the rest of the input is the name. Otherwise, ask the user for the type with AskUserQuestion, using the four types and their meanings from the table, and use the whole input as the name.
2. If the name is empty, tell the user: "Usage: `/speckit-init [epic|feature|task|defect] <name>`" and **STOP**.
3. **Defect**:
   1. Search `AI-project-docs/bugs/` for files named `B###.MD` or `bug-####.MD` (legacy), with or without the `.done.` prefix. The new number is the highest + 1 across both, zero-padded to 3 digits (`B001` if none are found).
   2. Copy the template to `AI-project-docs/bugs/B###.MD`. Replace `bug-####` and `<title>` in the first heading with `B###` and the name as typed, and `<date>` with today's date.
   3. Tell the user: "Created `AI-project-docs/bugs/B###.MD`. Describe the bug there, then run `/speckit-debug AI-project-docs/bugs/B###.MD`." Then **STOP**.
4. **Epic, Feature, Task**:
   1. **Slug**: lowercase the name, replace each run of non-alphanumeric characters with a single `-`, and trim leading and trailing `-`. For example, `Onboard feature` becomes `onboard-feature`.
   2. **ID**: `P` is the type's prefix from the table. Each prefix has its own counter. Search `specs/` recursively, including hidden folders, for files matching `P[0-9][0-9][0-9]-*.md` and for directories matching `P[0-9][0-9][0-9]-*` or `.done.P[0-9][0-9][0-9]-*` (closed items), so numbers are never reused. Take the highest number + 1, zero-padded to 3 digits (`P001` if none are found). `<ID>` below is the result, e.g. `T001`.
   3. Run `mkdir -p specs/<ID>-<slug>/resources`, then copy the type's template to `specs/<ID>-<slug>/<ID>-<slug>.md`. Replace the first heading with `# <ID> – <name as typed>`.
   4. Tell the user: "Created `specs/<ID>-<slug>/<ID>-<slug>.md` (<Type>). Describe it there and put any designs, screenshots or reference files in `specs/<ID>-<slug>/resources/`." Then give the type's next step from the table.
5. **STOP.** Do not run hooks, change `.specify/feature.json`, or write a spec.
