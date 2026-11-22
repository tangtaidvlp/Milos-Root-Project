# F006 – User profile & configuration store

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

<!-- One or two sentences: what do you want to build? -->
When I click profile icon at the sidebar bottom left, we will navigate to user profile screen
Exposing functions relating to their account include
- View profile information
- View subscription plan
- Sign out button

The configuration they used should be stored on backend includes:
- Light/Dark mode (default Light mode)
- The tasks board Zoom level
- Others in the future
## Problem / Motivation

<!-- What pain point or need does this address? Why now? -->
UI configuration is not consistent during usage

## Users

<!-- Who uses this? (e.g., signed-in user, guest, admin) -->
End users

## What the user should be able to do

<!-- Main flows, one per bullet, most important first. -->
Change UI configuration and got persistent, so refresh page does not reset everything to default value (eg: theme, zoom level)
- 

## Rules & Constraints

<!-- Business rules, limits, validations, things that must or must not happen. -->

- 

## Out of Scope

<!-- What this feature explicitly does NOT include. -->

- 

## How we know it works

<!-- Observable outcomes or acceptance examples. -->
Perform React Test

## Notes / Open Questions

<!-- Anything else: references, mockups, ideas, unknowns. -->
What technology do you use to test ReactJS atm?
Can you do the manual test by opening browser?
Opening browser vs Headless Browser testing, which do you prefer?

## Claude Working Notes

<!-- Maintained by /speckit-specify. Edit the sections above; Claude updates this one. -->

**Status**: Implemented
**Last updated**: 2026-11-21

### My understanding
- Clicking the user block (avatar + name) at the bottom of the sidebar opens a new **Profile** screen inside the app shell.
- The Profile screen shows account info (name, email), the user's subscription plan, and a Sign out button.
- UI preferences — light/dark theme and the task-board zoom level — are saved to the user's account on the server, so they survive a refresh and follow the user to other devices.
- Subscription plan is shown as a static "Free plan"; one zoom level is shared by all boards; theme is account-wide and follows the OS until chosen.
- The preference store must be open-ended so new settings can be added later without redesigning it.

### Working plan
- [x] Agree on open questions
- [x] Generate spec at `specs/F006-user-profile-configuration-store/spec.md`
- [x] Validate spec against the quality checklist — all 16 items pass (`checklists/requirements.md`)
- [x] Clarify, plan, tasks, analyze (×2)
- [x] Implement (`/speckit-implement`): all 52 tasks; results in `quickstart.md` → "Validation results"
- [ ] **Deploy**: apply `ms-personal-routine-manager/db/F006-user-settings.sql` to the prod DB **before** the new backend image starts (prod `ddl-auto: validate`), then deploy the frontend

### Assumptions
- Today the theme is stored per device (`localStorage["milos.theme"]`, absent = follow OS, from F005) and zoom is not stored at all (always 100%). This feature replaces both with an account-level setting.
- Default for a user with no saved setting: theme follows the OS (changed from the draft's "default Light", see Q2), zoom 100%.
- A theme already chosen on a device before this feature is copied to the account on first sign-in if the account has none.
- Save failures don't block: the change applies for the session and a non-blocking notice is shown.
- Profile information is read-only in this feature (no editing name/email/password).
- The existing Sign out button in each page header stays; the Profile screen adds another one.

### Answers to the draft's testing questions
- **What tests React today?** Vitest, for pure logic only (`*.test.ts` next to the code, no DOM). UI behaviour is checked by hand using each feature's `quickstart.md`. There is no React Testing Library or browser test runner yet.
- **Can Claude test manually in a browser?** Yes, partly: Claude can drive a headless browser (e.g. Playwright) against `pnpm dev` + backend, click through flows and take screenshots. It can't see your own browser window unless a browser extension is connected.
- **Opening a browser vs headless?** Recommended: headless, scripted tests (repeatable, run in CI, no human needed) for the key flows — e.g. "change theme → reload → still dark". Keep a short manual check in `quickstart.md` for visual polish. How exactly is decided in `/speckit-plan`.

### Discussion log
- **2026-11-21 Q1 — Subscription plan**: options: static "Free plan" / stored plan field / drop from F006. **Answer**: static "Free plan". **Decision**: Profile shows "Free plan" for everyone, no upgrade action, nothing new stored.
- **2026-11-21 Q2 — Theme behaviour once on the account**: options: account-wide default Light / account-wide default follow OS / per device with server backup. **Answer**: account-wide, default follow OS. **Decision**: one theme per account; until the user chooses, follow the OS (overrides the draft's "default Light").
- **2026-11-21 Q3 — Zoom scope**: options: one shared zoom / per page. **Answer**: one shared zoom. **Decision**: one zoom level for Today, Default routine and Onboarding boards.

**Spec**: `specs/F006-user-profile-configuration-store/spec.md`. 3 user stories (P1 settings kept across reloads and devices, P2 Profile screen, P3 open-ended settings store), 17 FRs, 6 success criteria. Checklist: 16/16 pass, no clarification markers.
