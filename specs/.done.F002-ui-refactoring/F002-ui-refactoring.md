# F002 – UI refactoring

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
UI update - Add side bar for web version
Side bar include others features
- Daily Routine 
- Default Routine
- Routine Analytic
Update style following new design (color code should be centralized and reused later for styling consistency)
<!-- One or two sentences: what do you want to build? -->


## Problem / Motivation
UI atm is primitive & unprofessional
It's not inituitive
<!-- What pain point or need does this address? Why now? -->


## Users
End user
Me
My interviewer
<!-- Who uses this? (e.g., signed-in user, guest, admin) -->


## What the user should be able to do
Web version:
Sides bar is visible by default (can be hidden)
When click, we would access pages corresponding
- Daily Routine (open daily routine page)
- Default Routine (open default routine set up page)
- Routine Analytic (coming soon, leave some place holder)
<!-- Main flows, one per bullet, most important first. -->

- 

## Rules & Constraints
Follow design provided in resources
The side bar only visible after Onboarding Completion
<!-- Business rules, limits, validations, things that must or must not happen. -->

- 

## Out of Scope

<!-- What this feature explicitly does NOT include. -->

- 

## How we know it works
We can access 3 different UIs
- Default Routine Setting
- Daily Routine (appear first when access the page after completion done)
<!-- Observable outcomes or acceptance examples. -->

- 

## Notes / Open Questions

<!-- Anything else: references, mockups, ideas, unknowns. -->


## Claude Working Notes

<!-- Maintained by /speckit-specify. Edit the sections above; Claude updates this one. -->

**Status**: Implemented
**Last updated**: 2026-11-21

### My understanding
- After onboarding is complete, the web app gets a persistent left sidebar (shown by default, collapsible) that links to Daily Routine, Default Routine and Routine Analytics.
- Daily Routine is the landing page after login for onboarded users (today's `/dashboard`).
- Default Routine is a page where an onboarded user can view and edit their default routine (add, edit, delete tasks) using the same editing board as onboarding, without the "complete onboarding" step.
- Routine Analytics is a "coming soon" placeholder.
- On narrow (mobile) screens a burger button opens the sidebar; choosing an item hides it and switches to that page (like the Android version).
- The whole app gets a visual refresh driven by one central set of colour/style tokens, so future screens stay consistent.

### Working plan
- [x] Agree on open questions (design added: `resources/Sidebar-Design.png`)
- [x] Generate spec at `specs/F002-ui-refactoring/spec.md`
- [x] Validate spec against the quality checklist
- [x] Next: `/speckit-plan` (done 2026-11-20: `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)
- [x] `/speckit-tasks` (done 2026-11-20: `tasks.md`, 47 tasks)
- [x] `/speckit-implement` (done 2026-11-21: 47/47 tasks; see `tasks.md` implementation notes and the validation run in `quickstart.md`)
- [ ] Next: manual check with a real account (quickstart §2 sign-in/out, §5 saves, §6 regression list)

### Assumptions
- The sidebar is not shown on sign-in/sign-up or during onboarding.
- The sidebar's shown/hidden choice is remembered on the same device.
- Sign-out stays in the page header (as in the design), not in the sidebar.
- Design shows more than the draft listed: "Milos" brand mark, "Replay tour" and user name + today's routine type at the bottom of the sidebar. These are in the spec.
- The design restyles existing Daily Routine features (live clock, zoom, gap clear, clean up, Routine Buddy); nothing is removed.
- Sign-in, sign-up and onboarding are restyled with the shared style values too.
- Routine Buddy stays on Daily Routine only. Analytics is a placeholder only.

### Discussion log
- **2026-11-20 – Design reference.** Q: `resources/` is empty though the draft says to follow the design there. Options: add it now / spec without it / describe in text. **Answer: user will add it now.** Decision: pause; re-run `/speckit-specify F002` once the design is in `resources/`.
- **2026-11-20 – Default Routine page scope.** Q: what can an onboarded user do there? Options: view and edit / view only / edit incl. Buddy chat. **Answer: view and edit.** Decision: same editing board as onboarding (add, edit, delete default tasks), no Buddy chat, no "complete onboarding" step.
- **2026-11-20 – Mobile behaviour.** Q: how does the sidebar behave on narrow screens? Options: hidden overlay / out of scope / same as desktop. **Answer (custom): burger button opens it, like the Android version; picking an item hides the sidebar and switches to that page.** Decision: on mobile widths the sidebar starts hidden and opens from a burger button.
- **2026-11-20 – Design received.** `resources/Sidebar-Design.png` added (Daily Routine, wide screen). No further questions; remaining unmocked screens follow the same style (see Assumptions).

### Result
- Spec: `specs/F002-ui-refactoring/spec.md` (4 user stories, 19 FRs, 7 success criteria).
- Checklist: `specs/F002-ui-refactoring/checklists/requirements.md`. All items pass on the first pass and no clarification markers remain.
- **2026-11-21 – Implementation deviations.** Kept "Reset day" and the time slider as secondary controls; active-nav text uses a darker blue than the mock (contrast); shared classes use a `ui-` prefix. Details in `tasks.md` → Implementation notes.
- **2026-11-21 – Change request: chat always visible.** User: "The default routine or whatever screen should have the AI chat screen visible all the time." Decision: Routine Buddy added to the Default routine page (one chat per Weekday/Weekend routine); on Today, Default routine and onboarding the chat stays beside the board from 761px up (was: hidden behind a button below 1200px); phones keep the board ⇄ chat swap. Analytics has no chat (no routine to act on). Spec FR-013 changed, FR-013a added.

