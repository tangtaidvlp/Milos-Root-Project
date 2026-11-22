# F003 – Skill-test-No-functional-implementation

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
Test claude working with speckit
<!-- One or two sentences: what do you want to build? -->


## Problem / Motivation
I want to set a standard workflow working with Github speckit
I want to understand more about the document based and SDD (Spec Driven Development)
I want to improve my work with speckit
Later I want to compare with Matt Porock approach
<!-- What pain point or need does this address? Why now? -->


## Users
Me
<!-- Who uses this? (e.g., signed-in user, guest, admin) -->


## What the user should be able to do
Understand more about Github speckit workflow
<!-- Main flows, one per bullet, most important first. -->

- 

## Rules & Constraints

<!-- Business rules, limits, validations, things that must or must not happen. -->

- 

## Out of Scope
No project code change
<!-- What this feature explicitly does NOT include. -->

- 

## How we know it works
You can provide me some questions
<!-- Observable outcomes or acceptance examples. -->

- 

## Notes / Open Questions

<!-- Anything else: references, mockups, ideas, unknowns. -->


## Claude Working Notes

<!-- Maintained by /speckit-specify. Edit the sections above; Claude updates this one. -->

**Status**: Spec generated
**Last updated**: 2026-11-21

### My understanding
- This is a practice feature. Nothing in the app changes; the goal is to try the Spec Kit cycle end to end on a safe ticket.
- What gets "delivered" is your understanding of the Spec Kit workflow and of spec-driven development (SDD), plus a standard way of working you can repeat.
- "How we know it works" is a set of questions from Claude that you can answer, to check your understanding.
- Improving the Spec Kit setup (skills, templates) is part of the feature; app code is not.
- The comparison with Matt Pocock's approach is later, but the criteria for it are prepared now.

### Working plan
- [x] Agree on open questions
- [x] Generate spec at `specs/F003-skill-test-no-functional-implementation/spec.md`
- [x] Validate spec against the quality checklist
- [ ] Next: `/speckit-clarify` or `/speckit-plan`

### Assumptions
- Deliverables (guide, quiz, improvement log, comparison criteria) live in this feature folder.
- No files under `ms-personal-routine-manager/` or `ui-personal-routine-manager/` change.
- The only user is you, working alone in this workspace.

### Discussion log
- 2026-11-21 — **Deliverable**: what should the feature leave behind? Options: guide + quiz / quiz only / guide only. **Answer**: guide + quiz. **Decision**: produce a workflow guide and a quiz with an answer key.
- 2026-11-21 — **Scope**: does "no project code change" also forbid Spec Kit skill/template changes? Options: allowed as separate approved step / not allowed / allowed freely. **Answer**: allowed freely. **Decision**: skill and template improvements can be tasks in this feature; app projects stay untouched.
- 2026-11-21 — **Comparison**: include anything for the Matt Pocock comparison now? Options: out of scope / prepare criteria now. **Answer**: prepare criteria now. **Decision**: produce comparison criteria with Spec Kit observations; the comparison itself stays out of scope.

### Result
- Spec: `specs/F003-skill-test-no-functional-implementation/spec.md`
- Checklist: all 16 items pass on the first iteration (`checklists/requirements.md`).
