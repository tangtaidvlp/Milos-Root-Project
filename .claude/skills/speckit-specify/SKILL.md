---
name: "speckit-specify"
description: "Create the feature specification (spec.md) from a feature draft or a natural language feature description."
argument-hint: "F### | T### | <feature description> | (empty)"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/specify.md (locally trimmed: drafts, F### naming, up to 5 questions)"
user-invocable: true
disable-model-invocation: false
---


## User Input

```text
$ARGUMENTS
```

## Scope

This command writes **one** `spec.md`: what users need and why, not how to build it. Other steps belong to other skills: `/speckit-init` creates drafts, `/speckit-clarify` refines a spec, `/speckit-plan` designs, `/speckit-close` closes. Do not do their work here.

## 1. Get the feature description

- **ID (`F###`, `T###`) or empty input**: use a draft, `specs/<ID>-<slug>/<ID>-<slug>.md` (or a loose `specs/<ID>-<slug>.md`), whose folder has no `spec.md` yet.
  - A draft's `## Summary` is **filled** when it has text left after removing HTML comments and blank lines.
  - ID given: use that draft. If it does not exist, say so and **STOP**. If its folder already has `spec.md`, tell the user to use `/speckit-clarify` and **STOP**. If its `## Summary` is not filled, tell the user the draft is still empty (name the file) and to describe the feature there first, then **STOP**.
  - **Type**: a draft whose `**Type**:` line is `Epic` is never specified. If one is given, tell the user to split it into features with `/speckit-init feature <name>` and **STOP**. Drafts typed `Task` are implemented directly from the draft, so specify one only when it is given by its `T###` ID. Drafts with no `**Type**:` line are features.
  - Empty: ignore `Epic` and `Task` drafts. If no draft has a filled `## Summary`, tell the user to run `/speckit-init <name>` and **STOP**. If one draft is filled, use it. If several are, ask which one (AskUserQuestion).
  - If the draft is loose in `specs/`, move it into `specs/<ID>-<slug>/`. Make sure `specs/<ID>-<slug>/resources/` exists.
  - The feature description is the draft's content with HTML comments removed. Read every file in `resources/` too (designs, screenshots, documents); they are part of the description.
- **Any other input**: the input is the feature description. The feature ID is the highest `F###` found in `specs/` (search recursively, including `.done.F###-*` folders and `F###-*.md` files) + 1, zero-padded (`F001` if none). The folder is `specs/F###-<short-name>/`, where `<short-name>` is 2-4 words in kebab-case. Stop if that folder already exists.

`FEATURE_DIR` is `specs/<ID>-<slug>/` (`specs/F###-<short-name>/` for a new feature), and `SPEC_FILE` is `FEATURE_DIR/spec.md`. Never overwrite an existing `spec.md`.

## 2. Hooks (before)

If `.specify/extensions.yml` is missing, or has no `hooks.before_specify` entries, skip silently. Otherwise:

- If the file cannot be parsed, tell the user (include the parser error) that no hooks were checked, naming any mandatory (`optional: false`) hooks you can still see in it, then **continue** with step 3.
- A hook counts as enabled unless it says `enabled: false`; a hook with no `enabled` field is enabled.
- Skip hooks that have a non-empty `condition` (the hook executor evaluates those, not you).
- Command name: replace dots with hyphens (`speckit.git.branch` → `/speckit-git-branch`).
- `optional: false`: run the hook yourself and wait for it to finish before continuing.
- `optional: true`: only list it for the user (extension, command, description).

## 3. Ask (up to 5 questions)

Read `.specify/memory/constitution.md` if it exists. Find the open decisions in the description that would change the spec, ranked by impact: scope > security/privacy > user experience (including whether a UI design/mockup exists) > data/technical details.

- Ask a question only if no reasonable default exists, or if the answers would lead to clearly different specs. Use a sensible default for everything else and list it under Assumptions.
- Ask **at most 5** questions with AskUserQuestion. It accepts at most 4 per call, so put a 5th in a second call. Each question has 2-4 options, and the recommended option comes first.
- If nothing important is open, ask nothing.
- If the user declines to answer, **STOP** without writing a spec.

## 4. Write the spec

1. Run `.specify/scripts/bash/resolve-template.sh spec-template --json` and take `TEMPLATE_CONTENT`. If this fails, report the error and **STOP**.
2. `mkdir -p FEATURE_DIR` and fill the template into `SPEC_FILE`. Keep the template's section order. Remove optional sections that don't apply (don't write "N/A").
3. If you asked questions, add `## Clarifications` → `### Session YYYY-MM-DD` with one line per question: `- Q: <question> → A: <answer>`. This is the format `/speckit-clarify` uses.
4. Write `.specify/feature.json` as `{ "feature_directory": "specs/F###-<slug>" }`.

Writing rules:
- Say WHAT and WHY only. Leave out tech stack, APIs and code structure. Write for non-technical readers.
- Every functional requirement must be testable. Number them `FR-001`, `FR-002`, ….
- Success criteria must be measurable, user-facing and technology-agnostic (e.g. "Users finish setup in under 2 minutes", not "API < 200ms").
- Leave no `[NEEDS CLARIFICATION]` markers. Step 3 already settled those decisions, or you used a default and listed it under Assumptions.
- If you used resources, reference them as the design/source of truth.

## 5. Validate

Write `FEATURE_DIR/checklists/requirements.md` and check the spec against it:

```markdown
# Specification Quality Checklist: [FEATURE NAME]

**Created**: [DATE] · **Feature**: [spec.md](../spec.md)

- [ ] No implementation details (languages, frameworks, APIs)
- [ ] Focused on user value; readable by non-technical stakeholders
- [ ] All mandatory sections completed
- [ ] No [NEEDS CLARIFICATION] markers remain
- [ ] Requirements are testable and unambiguous
- [ ] Success criteria are measurable and technology-agnostic
- [ ] Acceptance scenarios cover the primary flows
- [ ] Edge cases identified
- [ ] Scope clearly bounded (in/out)
- [ ] Dependencies and assumptions identified
```

Fix the spec for every item that fails and check again, at most 3 times. Note anything still failing in the checklist.

## 6. Hooks (after)

Do the same as step 2, with every rule unchanged (missing `enabled` = enabled, parse error = warn and continue to step 7), using `hooks.after_specify`.

## 7. Report

Report:
- `FEATURE_DIR` and `SPEC_FILE`
- the draft and resources used, if any
- the questions asked and the decisions made
- the checklist result
- the next step: `/speckit-clarify` (optional) or `/speckit-plan`
