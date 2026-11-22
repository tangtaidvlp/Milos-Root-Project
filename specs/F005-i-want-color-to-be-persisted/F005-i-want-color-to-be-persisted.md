# F005 – I want color to be persisted & the live mode doesn't drag the UI to the cursor each time it refresh during usage

<!--
  Describe the feature you want in plain language, then run `/speckit-specify F###` (this file's ID),
  or `/speckit-specify` with no arguments. The command reads this file as the feature description,
  writes `spec.md` next to this file in the same `specs/F###-<slug>/` folder.
  Put mockups, screenshots and other reference files in this folder's `resources/` subfolder; Claude reads them as part of the request.
  Claude discusses open questions with you and keeps its understanding, plan and decisions in a
  "Claude Working Notes" section at the end of this file. Edit your sections; leave that one to Claude.
  Focus on WHAT and WHY. Leave HOW (tech stack, APIs, code) to `/speckit-plan`.
  Delete any section you have nothing to say about. Only "Summary" is required.
-->

## Summary
Task color now vary on front-end, I want it to be persisted in backend
Color chosen decided by backend

The live mode issue: it drag UI to its position even when User is look at other point in the chart, fix this behaviour, it should only run once when page first render so user can see "what's task now"
<!-- One or two sentences: what do you want to build? -->


## Problem / Motivation
Inconsistent task color after React render
<!-- What pain point or need does this address? Why now? -->


## Users
end user
<!-- Who uses this? (e.g., signed-in user, guest, admin) -->


## What the user should be able to do
None, just color consistent after edit
Scroll freely on the daily routine chart without being interrupted by the "live mode auto focus dragging"
<!-- Main flows, one per bullet, most important first. -->

- 

## Rules & Constraints

<!-- Business rules, limits, validations, things that must or must not happen. -->

- 

## Out of Scope

<!-- What this feature explicitly does NOT include. -->

- 

## How we know it works
I will check myself
<!-- Observable outcomes or acceptance examples. -->

- 

## Notes / Open Questions

<!-- Anything else: references, mockups, ideas, unknowns. -->


## Claude Working Notes

<!-- Maintained by /speckit-specify. Edit the sections above; Claude updates this one. -->

**Status**: Implemented — browser check pending
**Last updated**: 2026-11-21

### My understanding
- Today a task without a saved color gets one of 8 tints chosen by its position in the list on screen, so its color changes when tasks are added, removed or reordered.
- The backend should pick and store each task's color, so a task keeps the same color across edits, reloads and devices.
- Two parts: (1) stable, stored task colors; (2) the live clock on the daily routine board should move the view to "now" only once when the page first opens, not on every minute tick.
- The backend assigns the color. The user can override it in the Default Routine edit dialog. Daily tasks copy the color of their default-routine task.
- Live mode scrolls to "now" once per board load. "Resume live" does not scroll either.

### Working plan
- [x] Agree on open questions
- [x] Generate spec at `specs/F005-i-want-color-to-be-persisted/spec.md`
- [x] Validate spec against the quality checklist
- [x] `/speckit-clarify` (5 questions + light/dark scope added)
- [x] `/speckit-plan`: plan.md, research.md, data-model.md, contracts/, quickstart.md
- [x] `/speckit-tasks`: tasks.md (52 tasks)
- [x] `/speckit-analyze` (4 fixes applied)
- [x] `/speckit-implement`: 50/52 tasks; T047 (dark-mode visual look) and T051 B–G (browser scenarios) need a person in a browser
- [ ] Next: run quickstart.md B–G in the browser, then deploy (DDL first)

### Spec
- `specs/F005-i-want-color-to-be-persisted/spec.md`: 4 user stories, 12 FRs, 6 SCs. Checklist (`checklists/requirements.md`): all 16 items pass, no clarification markers.

### Assumptions
- Colors come from the existing 8-tint app palette, so they still look right in light and dark themes.
- Tasks that already exist with no stored color get one assigned once, and keep it from then on.
- The live clock keeps updating the "now" line and the Now/Next footer every minute. Only the automatic scrolling changes.

### Discussion log
- **2026-11-21 — Who decides a task's color?** Options: backend assigns + user can override / backend only, remove picker. **Answer**: Backend assigns, user can override. **Decision**: new tasks get a stored color chosen by the backend; a user's pick in the edit dialog is stored and wins.
- **2026-11-21 — Do daily tasks keep their default-routine task's color?** Options: inherit / assign independently. **Answer**: Inherit. **Decision**: daily tasks created from the default routine copy its color; tasks added only to a day get a backend-assigned color.
- **2026-11-21 — When does live mode jump to "now"?** Options: first load + "Resume live" / first load only. **Answer**: First load only. **Decision**: auto-scroll to the current time happens once when the board first opens; minute ticks and "Resume live" never move the view.
- **2026-11-21 — /speckit-clarify session** (details in spec.md → Clarifications):
  - Old data: no special treatment, no migration, backfill or fallback logic; only new tasks are in scope.
  - The backend owns the task palette and serves it to the app.
  - The palette is theme-aware: each entry has an ID plus light and dark versions. A user-chosen color is stored as an exact value.
  - Buddy can set a color by palette name only.
  - **Scope added**: light/dark mode for the whole app. Until the user chooses, it follows the device. The choice is remembered per device, not on the account.
  - Color assignment goes round-robin in palette order. The manual-create dialog pre-selects the next round-robin color.
- **2026-11-21 — /speckit-analyze fixes** (user approved): FR-003 now says daily routines continue the Default Routine's color sequence, and that a picked color other than the next one doesn't move the sequence. FR-009 now says unresolved colors share one neutral default style. New edge case: changing the date on the Today page doesn't re-scroll the board.

### Release note
- Tasks created before F005 have no stored color and show a neutral grey card. Recolor them in the edit dialog if wanted. Nothing migrates them, by design.
- Deploy order: apply `ms-personal-routine-manager/db/F005-task-color.sql` to prod, then deploy the backend, then the frontend. The old frontend keeps working against the new backend because all new fields are additive.
- Your running local backend on :8080 must be restarted to pick up F005.
