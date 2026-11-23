---
name: "speckit-feature-init"
description: "Create a new work-item draft by type (Epic, Feature, Task under specs/F###-<slug>/; Defect under AI-project-docs/bugs/) for the user to fill in."
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

| Type | Meaning | Template | Created at | Next step |
|------|---------|----------|------------|-----------|
| Epic | Big change made of several features, often across services, delivered in phases | `.specify/templates/epic-request-template.md` | `specs/F###-<slug>/F###-<slug>.md` | List the features, then `/speckit-feature-init feature <name>` for each one, with its `**Epic**:` line set to this ID. An epic is never specified directly. |
| Feature | Function or enhancement made of several tasks | `.specify/templates/feature-request-template.md` | `specs/F###-<slug>/F###-<slug>.md` | `/speckit-specify F###` |
| Task | Small change, with optional steps | `.specify/templates/task-request-template.md` | `specs/F###-<slug>/F###-<slug>.md` | Fill in the steps, then ask Claude to implement the draft directly. There is no spec or plan. |
| Defect | Bug fix | `.specify/templates/bug-report-template.md` | `AI-project-docs/bugs/bug-####.MD` | `/speckit-debug AI-project-docs/bugs/bug-####.MD` |

## Steps

1. **Type**: if the first word of the input is `epic`, `feature`, `task` or `defect` (case-insensitive), that is the type, and the rest of the input is the name. Otherwise, ask the user for the type with AskUserQuestion, using the four types and their meanings from the table, and use the whole input as the name.
2. If the name is empty, tell the user: "Usage: `/speckit-feature-init [epic|feature|task|defect] <name>`" and **STOP**.
3. **Defect**:
   1. Search `AI-project-docs/bugs/` for files named `bug-[0-9][0-9][0-9][0-9].MD` or `.done.bug-[0-9][0-9][0-9][0-9].MD`. The new number is the highest + 1, zero-padded to 4 digits (`0001` if none are found).
   2. Copy the template to `AI-project-docs/bugs/bug-####.MD`. Replace `bug-####` and `<title>` in the first heading with the number and the name as typed, and `<date>` with today's date.
   3. Tell the user: "Created `AI-project-docs/bugs/bug-####.MD`. Describe the bug there, then run `/speckit-debug AI-project-docs/bugs/bug-####.MD`." Then **STOP**.
4. **Epic, Feature, Task**:
   1. **Slug**: lowercase the name, replace each run of non-alphanumeric characters with a single `-`, and trim leading and trailing `-`. For example, `Onboard feature` becomes `onboard-feature`.
   2. **Number**: search `specs/` recursively, including hidden folders, for files matching `F[0-9][0-9][0-9]-*.md` and for directories matching `F[0-9][0-9][0-9]-*` or `.done.F[0-9][0-9][0-9]-*` (closed items). This includes drafts already moved into their directories and features specified without a draft, so numbers are never reused. Take the highest number + 1, zero-padded to 3 digits. If none are found, use `F001`.
   3. Run `mkdir -p specs/F###-<slug>/resources`, then copy the type's template to `specs/F###-<slug>/F###-<slug>.md`. Replace the first heading with `# F### – <name as typed>`.
   4. Tell the user: "Created `specs/F###-<slug>/F###-<slug>.md` (<Type>). Describe it there and put any designs, screenshots or reference files in `specs/F###-<slug>/resources/`." Then give the type's next step from the table.
5. **STOP.** Do not run hooks, change `.specify/feature.json`, or write a spec.
