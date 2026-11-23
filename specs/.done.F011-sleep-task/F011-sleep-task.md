# F011 – Sleep task

**Type**: Feature
**Epic**: <!-- optional: F### of the parent epic -->

<!--
  Describe the feature you want in plain language, then run `/speckit-specify F###` (this file's ID),
  or `/speckit-specify` with no arguments. The command reads this file as the feature description,
  writes `spec.md` next to this file in the same `specs/F###-<slug>/` folder.
  Put mockups, screenshots and other reference files in this folder's `resources/` subfolder; Claude reads them as part of the request.
  Claude asks up to 5 questions about open decisions and records the answers under "Clarifications" in spec.md.
  Focus on WHAT and WHY. Leave HOW (tech stack, APIs, code) to `/speckit-plan`.
  Delete any section you have nothing to say about. Only "Summary" is required.
-->

## Summary

<!-- One or two sentences: what do you want to build? -->
Sleep task is usual cross the 00:00 midnight  
eg: 10:00 -> next day 6:00 AM

## Problem / Motivation

<!-- What pain point or need does this address? Why now? -->
Sleep task now are split into 2 tasks separatedly
That's confuse me

## Users

<!-- Who uses this? (e.g., signed-in user, guest, admin) -->
Me
End-user

## What the user should be able to do

<!-- Main flows, one per bullet, most important first. -->
When a user drags a task on the schedule UI past 24:00 (midnight), both the UI and Backend should recognize it as a single overnight task crossing midnight:

UI: Wrap the overflowing portion to the top of the schedule, rendering it from 00:00 up to the overflow end time.

Backend: Treat and store it as a single task entity, not two separate tasks.


## Rules & Constraints

<!-- Business rules, limits, validations, things that must or must not happen. -->

- 

## Out of Scope

<!-- What this feature explicitly does NOT include. -->

- 

## How we know it works

<!-- Observable outcomes or acceptance examples. -->

- 

## Notes / Open Questions

<!-- Anything else: references, mockups, ideas, unknowns. -->

