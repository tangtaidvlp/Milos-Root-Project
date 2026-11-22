# F007 – Reflection

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
A clone of our daily task but with our note reflect the reality
Like we input what actualy happened (the real routine we're doing)
So we can know where are we on the track
What can we improve
But we need to ease user that everything's okay, don't be too harsh, keep it up and improve ourself everyday

## Problem / Motivation

<!-- What pain point or need does this address? Why now? -->
User can keep track how they're going, data could be collected and be used by analytic

## Users

<!-- Who uses this? (e.g., signed-in user, guest, admin) -->

End user
## What the user should be able to do

<!-- Main flows, one per bullet, most important first. -->
Toggle ON reflection which clone the current daily task first
Then user could modify that one to reflect their real day (or ask AI to do that for them by telling AI what is going on with their life currently)
- 

## Rules & Constraints

<!-- Business rules, limits, validations, things that must or must not happen. -->

- 

## Out of Scope

<!-- What this feature explicitly does NOT include. -->

- 

## How we know it works

<!-- Observable outcomes or acceptance examples. -->
Testing
- 

## Notes / Open Questions

<!-- Anything else: references, mockups, ideas, unknowns. -->


## Claude Working Notes

<!-- Maintained by /speckit-specify. Edit the sections above; Claude updates this one. -->

**Status**: Implemented (incl. 2026-11-22 side-by-side enhancement). Next: verify, then `/speckit-close F007`
**Last updated**: 2026-11-22

### My understanding
- For a given day, the user can switch on "Reflection". This makes a copy of that day's planned tasks, which the user then edits to match what actually happened.
- The user edits the reflection by hand, or by telling Buddy what really happened and letting Buddy change it.
- Seeing the plan and the reality together shows how the user is tracking and what to improve.
- Feedback must be gentle and encouraging: "everything's okay, keep it up, improve a little each day". It must never be harsh.
- Reflections are kept as data so later analytics can use them.
- Reflection is a mode toggle on the existing Daily Routine page. In reflection mode the page shows plan vs reality, and Buddy's chat edits the reflection.

### Working plan
- [x] Agree on open questions
- [x] Generate spec at `specs/F007-reflection/spec.md`
- [x] Validate spec against the quality checklist (all 16 items pass, see `checklists/requirements.md`)
- [x] Plan, tasks and implementation (`plan.md`, `tasks.md`; all 32 tasks done)
- [ ] Next: apply `db/F007-daily-reflection.sql` to prod before deploying, then `/speckit-close F007`

### Assumptions
- One reflection per user per day. It is created on demand (when toggled on), never automatically.
- The reflection copies the daily plan once, when created. Later changes to the plan do not change the reflection, and edits to the reflection never change the plan.
- Reflection tasks have the same fields as daily tasks: name, description, start time, duration, color.
- Analytics dashboards are out of scope. This feature only stores the data.
- Reflection chat has its own saved thread per day, separate from the planning chat (proposed by Claude after Q3; open to revision).
- The plan's "completed" checkbox stays independent of reflection.

### Discussion log
- **2026-11-21 Q1: Which days can be reflected?** Options: today + past days / today only / any day. **Answer**: today + past days. **Decision**: future days are blocked.
- **2026-11-21 Q2: How should progress and improvement be shown?** Options: comparison + AI note / comparison only / AI note only. **Answer**: comparison + AI note. **Decision**: plan vs reality groups and totals, plus an encouraging Buddy note (at most 2 suggestions).
- **2026-11-21 Q3: Should reflection chat have its own history?** Options: own history / share daily chat / no history. **Answer**: "Have it live on the Daily Routine page; reflection just toggles on the comparison view. Is there a better approach?" **Decision**: reflection is a toggle mode on the Daily Routine page (agreed as the better approach). In that mode, Buddy edits the reflection and uses a separate per-day reflection thread (Claude's proposal; the user may revise it).

- **2026-11-22 Enhancement (via /speckit-clarify)**: The user asked for a side-by-side Plan/Reality view on large screens and a compact "Reflection" toggle instead of tabs. **Decisions**: both boards are editable; the toggle goes in the board toolbar; Buddy's note goes at the top of a shorter Buddy chat panel, and the totals become a slim strip; one shared toolbar with synced scroll and zoom; side by side from 1280px; smaller screens swap the single board, and tapping a task opens a status pop-up. See spec.md Clarifications, FR-001, FR-012 to FR-012b and FR-017a.

**Spec**: `specs/F007-reflection/spec.md`. The checklist passes all 16 items, with no [NEEDS CLARIFICATION] markers.
