---
name: "speckit-feature-init"
description: "Create a new feature request draft (specs/F###-<slug>/F###-<slug>.md plus a resources/ folder) for the user to fill in before running /speckit-specify."
argument-hint: "<feature name>"
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

The whole input is the feature name, e.g. `Onboard feature`.

## Steps

1. If the name is empty, tell the user: "Usage: `/speckit-feature-init <feature name>`" and **STOP**.
2. **Slug**: lowercase the name, replace each run of non-alphanumeric characters with a single `-`, and trim leading and trailing `-`. For example, `Onboard feature` becomes `onboard-feature`.
3. **Number**: search `specs/` recursively, including hidden folders, for files matching `F[0-9][0-9][0-9]-*.md` and for directories matching `F[0-9][0-9][0-9]-*` or `.done.F[0-9][0-9][0-9]-*` (closed features). This includes drafts already moved into feature directories and features specified without a draft, so numbers are never reused. Take the highest number + 1, zero-padded to 3 digits. If none are found, use `F001`.
4. Create the feature folder right away, so the user has a place for mockups and other files while drafting: `mkdir -p specs/F###-<slug>/resources`, then copy `.specify/templates/feature-request-template.md` to `specs/F###-<slug>/F###-<slug>.md`. Replace the first heading `# Feature Request` with `# F### – <feature name as typed>`.
5. Tell the user: "Created `specs/F###-<slug>/F###-<slug>.md`. Describe your feature there and put any designs, screenshots or reference files in `specs/F###-<slug>/resources/`, then run `/speckit-specify F###` (or `/speckit-specify` with no arguments)."
6. **STOP.** Do not run hooks, change `.specify/feature.json`, or write a spec.
