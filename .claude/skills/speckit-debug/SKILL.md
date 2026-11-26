---
name: "speckit-debug"
description: "Diagnose and fix a bug: reproduce it, find the root cause, write a failing regression test, apply the smallest fix, and verify, recording everything in specs/<###-fix-name>/bugfix.md."
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

You **MUST** consider the user input before proceeding (if not empty).

The input is a bug report (symptom, error text, failing endpoint, or steps). It MAY start with a phase flag:

- `--phase diagnose`: run Steps 1-5 only (report, reproduce, root cause, failing test), then stop. Used by the `bugfix` workflow before its review gate.
- `--phase fix`: run Steps 6-8 only, resuming from the existing `bugfix.md`. The bug text after the flag (if any) identifies which bugfix directory to resume.
- No flag: run every step, pausing once for the user to confirm the root cause (Step 5).

## Pre-Execution Checks

**Check for extension hooks**: if `.specify/extensions.yml` exists, read `hooks.before_debug` (at start) and `hooks.after_debug` (at end) and handle them exactly as the other `speckit-*` skills do: skip entries with `enabled: false`, do not evaluate `condition` expressions (skip hooks that have one), map dots to hyphens in command names, print optional hooks as suggestions, and actually invoke mandatory (`optional: false`) hooks and wait for them. If the YAML cannot be parsed, tell the user (with the parser error) and continue. If the file does not exist, skip silently.

## Operating Principles

- **Root cause before code.** Do not edit application code until the root cause is confirmed with evidence. A fix that only hides the symptom (catch-and-ignore, null guard at the crash site, retry loop) is not acceptable unless the root cause analysis shows it is the correct fix.
- **Failing test first.** The regression test must fail for the reason identified in the root cause before the fix is applied, and pass after.
- **Smallest correct fix.** Change only what the root cause requires. Note unrelated problems under Follow-ups instead of fixing them.
- **Evidence over guesses.** Every hypothesis in the investigation table is marked confirmed or ruled out, with the evidence.
- **Constitution authority.** If `.specify/memory/constitution.md` is filled in (not the unfilled template), its MUST principles apply to the fix and the test. If it is still the template, skip this check.

## Project Context

Read the `CLAUDE.md` of each affected subproject before running anything. Known defaults for this workspace:

| Project | Run | Test | Lint/Build |
|---------|-----|------|------------|
| `ms-personal-routine-manager/` (Spring Boot, Java 25) | `SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun` (no DB) or `docker compose up -d database && ./gradlew bootRun` | `./gradlew test --tests "<FQCN>"`, then `./gradlew test` | `./gradlew build` |
| `ui-personal-routine-manager/` (React 19, Vite) | `pnpm dev` (calls the backend at `localhost:8080` via `VITE_API_BASE_URL`; no proxy) | `pnpm test` (Vitest: `*.test.ts` in Node, `*.test.tsx` in jsdom), `pnpm test:e2e` (Playwright; needs backend + `pnpm dev`) | `pnpm lint`, `pnpm build` |

Frontend regression tests follow `ui-personal-routine-manager/CLAUDE.md` ("Testing strategy"): put the test next to the code; use a unit test for a logic bug, a component test for a widget bug, and Playwright for a journey bug. Fake the backend at the feature's `api/` module with `vi.mock`; don't add MSW.

## Execution Steps

### 1. Set up the bugfix directory

Skip this step for `--phase fix`. Instead, find the directory: use `.specify/feature.json` if it points at a `*-fix-*` directory containing `bugfix.md`, otherwise the most recent `specs/*-fix-*/bugfix.md` matching the bug text. If none is found, STOP and tell the user to run `/speckit-debug --phase diagnose <bug>` first.

Otherwise:

1. Write a 2-4 word short name for the bug, prefixed with `fix-` (e.g. `fix-routine-timezone-shift`).
2. Run `.specify/scripts/bash/create-new-feature.sh --json --dry-run --short-name "<short-name>" "<bug summary>"` from the repo root and parse `BRANCH_NAME`. Use single-quote escaping for apostrophes ('I'\''m').
3. Create `specs/<BRANCH_NAME>/` and copy `.specify/templates/bugfix-template.md` to `specs/<BRANCH_NAME>/bugfix.md`. Do not create `spec.md`.
4. Write `.specify/feature.json` as `{"feature_directory": "specs/<BRANCH_NAME>"}` so a later `--phase fix` run can find it. If the file already exists, read it first and keep its existing key names, changing only the directory value.
5. Fill in Section 1 (Report) from the user input. If expected vs. actual behavior cannot be determined from the input or the code, ask the user (at most 2 questions) before continuing.

### 2. Reproduce

1. Identify the smallest way to trigger the bug: an existing test, a new test, a `curl` against the running backend, or a UI step sequence.
2. Run it and capture the actual output. Prefer the `fast` profile for backend repros unless the bug depends on PostgreSQL behavior.
3. Record Section 2. If the bug cannot be reproduced after a reasonable attempt, set Status to `Investigating`, record what was tried, and ask the user for the missing conditions (data, profile, timing) instead of guessing at a fix.

### 3. Investigate

1. Trace the code path from the entry point (controller under `com.tom.payment.routinemanager.api`, or the React route/component calling `src/lib/api.ts`) to the failure.
2. Form hypotheses and test each one with evidence: logs, a targeted test, reading the data, or a temporary debug statement. Remove all temporary debug code before finishing.
3. For cross-tier bugs, check the API contract first: compare the frontend request/response types with the backend DTOs.
4. Record each hypothesis in the Section 3 table.

### 4. Confirm the root cause

Fill in Section 4: exact location, the faulty logic or assumption, and the blast radius (search for other callers of the same code path).

**Escalation check.** If the correct fix needs any of the following, set Status to `Escalated`, write the reason in Section 4, and STOP. Recommend `/speckit-specify` with the bugfix directory as context:

- A database schema or migration change
- A breaking change to a public API request/response shape
- A redesign touching more than about 5 files or both tiers in non-trivial ways
- A product decision (the "expected behavior" is actually undecided)

### 5. Write the failing regression test

1. Add a test that reproduces the bug at the lowest level that shows it (unit before integration before app test). Backend: follow the existing test package layout under `src/test/java/com/tom/payment/routinemanager/`. Frontend: a `*.test.ts(x)` file next to the code (see Project Context).
2. Run it and confirm it fails **for the root-cause reason**, not for setup errors.
3. Record Section 5 with the failure output excerpt. Set Status to `Root cause confirmed`.
4. **Pause point.**
   - With `--phase diagnose`: report the root cause, the test, and the planned fix approach, then STOP (the workflow gate reviews it).
   - With no flag: present the root cause and planned fix in 3-5 lines and ask the user to confirm before editing application code.

### 6. Fix

1. Apply the smallest change that addresses the root cause.
2. Record Section 6, including alternatives considered.
3. If the fix changes a request/response shape (non-breaking), update both the backend DTO and the frontend type in `src/lib/api.ts` or its callers.

### 7. Verify

Run, in order, and record each result in the Section 7 checklist:

1. The regression test (must now pass).
2. The full test suite of each affected project. If a failure is unrelated to this change, show that it also fails without the change before marking it unrelated.
3. Lint/build of each affected project.
4. The original reproduction from Step 2.

If any step fails because of the fix, return to Step 6. After 3 failed fix attempts, STOP, set Status to `Investigating`, and report what was learned. The root cause is probably wrong, so go back to Step 3 with the user.

Set Status to `Fixed` when all checks pass.

### 8. Report

Output a short summary:

- Root cause (one sentence, with file link)
- Fix (files changed)
- Regression test (file link) and verification results
- Follow-ups, if any
- Path to `bugfix.md`

Do not commit. Suggest a commit message in the form `fix(<area>): <summary>` for the user to use.
