# F001 – Onboarding Instruction

<!--
  Describe the feature you want in plain language, then run `/speckit-specify F###` (this file's ID),
  or `/speckit-specify` with no arguments. The command reads this file as the feature description,
  generates `specs/NNN-<short-name>/spec.md`, and moves this file into that folder.
  Focus on WHAT and WHY. Leave HOW (tech stack, APIs, code) to `/speckit-plan`.
  Delete any section you have nothing to say about. Only "Summary" is required.
-->


## Summary
Chain of screen for application use instructions
<!-- One or two sentences: what do you want to build? -->


## Problem / Motivation
<!-- What pain point or need does this address? Why now? -->
1. User is not sure how to use our app? What it is designed for?
- It's used to note user static & dynamic habit,
besides they can ask AI to manage their work times, mark as completed
- Having a report of their routine
- They don't have to think too much for time arrangement so it could reduce decision fatigue
- Why now ? Because me myself easily forget what's the app for, it's a reminder for me too, the app owner to remind about app usage, its purpose, so I could explain it to my interviewer when I use the website as a showcase

## Users
Our end user
Me
My interviwer when I use this as a show case
<!-- Who uses this? (e.g., signed-in user, guest, admin) -->


## What the user should be able to do

<!-- Main flows, one per bullet, most important first. -->
When onboarding process is not finished, we will start a chain of showcase showing them what's this app
and what to do first

1. What's this app?
Milos is designed for Time Management where you can set up a default routine for weekdays & weekend

2. What's to do first
- Set up default routine for Weekday & Weekend
User need to understand that everydays, there's a clone of that default routine to the new day
User can follow the plan or update
We will track user behaviour and give them a analytic whenever they ask for
- We need to tell that the set up can be completed by the AI chat window
The final goal is:
- They would know how they're behaving with their time
- They could learn some trick at decision making by the AI
- They can quickly tell AI to arrange their time without manually updating the 

## Rules & Constraints

<!-- Business rules, limits, validations, things that must or must not happen. -->

- Only when they complete their Onboard set up is not completed after login/register/silent-reauth (revisit)
- Save things on the go (everytime they update, we should store the update too)

## Out of Scope

<!-- What this feature explicitly does NOT include. -->

- 

## How we know it works
- There's introduction & instruction on how to use the App & Do the Onboard with AI
- We see the changes are persist even the onboard is not done yet (by re-login/re-visit)
- After done onboarding, that instruction doesn't appear any more

## Notes / Open Questions

<!-- Anything else: references, mockups, ideas, unknowns. -->


## Implementation Plan
<!-- HEY CLAUDE, PLEASE FILL YOUR IMPLEMENTATION PLAN IN HERE>

_High-level plan by Claude, 2026-11-19. `/speckit-plan` will turn this into a detailed `plan.md` and `/speckit-tasks` into tasks; update this section if they diverge._

**Scope**: mostly frontend (`ui-personal-routine-manager`). No backend change is needed for the instructions themselves. The Weekend routine gap (step 6) may need one.

1. **When it shows (no new data)**: `App.tsx` already sends users with unfinished onboarding to `/onboarding` after login, register and silent re-auth, using `GET /api/users/{id}/onboarding/complete`. The intro slides open every time `OnboardingPage` mounts. No "seen" flag is stored, which matches the decision to show them on every visit.
2. **Intro slides**: a new `IntroSlides` component in `features/onboarding/components/` shows 4 slides: what Milos is · daily copies of the default routine · tracking and analysis · Routine Buddy and what to do first. It has Next / Back / Skip, and Esc closes it. The slide text lives in one content file so it is easy to edit.
3. **Guided tour**: a new `GuidedTour` component. Each step highlights one element marked with a `data-tour` attribute: the Weekday/Weekend segmented control, the board card, the FAB, `BuddyChat` and "Ready to roll". On a phone, the chat step shows text only (or switches `mobileView`). The tour starts only when the slides were completed, not skipped.
4. **"How it works" button**: in the `OnboardingPage` top bar it replays the slides and then the tour. In the main app header (dashboard / daily page) it replays the slides only.
5. **Save as you go (verify and harden)**: manual edits and Routine Buddy edits are already saved per change. The fix needed is that failures are currently swallowed (`refreshDefaultRoutine` falls back to an empty routine, and create/update errors aren't shown). Add a visible "not saved" error so the app meets FR-011.
6. **Weekday/Weekend dependency**: `OnboardingPage` loads one routine from `/api/v1/default-routine/users/{id}`, so the toggle changes only the title. The backend already has a `WEEKEND` routine type (`User.getWeekendDefaultRoutine`, `DailyTaskSpawningJob`). Decide in `/speckit-plan` whether to wire up weekend loading and editing here or in its own ticket.
7. **Tests**: component tests for the slide and tour state (next / back / skip / end, and no tour after skip). A manual pass through each acceptance scenario in `spec.md`, including log out and log back in with saved tasks.

## Claude Working Notes

<!-- Maintained by /speckit-specify. Edit the sections above; Claude updates this one. -->

**Status**: Implemented
**Last updated**: 2026-11-20
**Spec**: [spec.md](./spec.md). Checklist: 16/16 passed, 0 clarification markers. One open dependency (Weekend routine, see Assumptions).
**Walkthrough script**: [walkthrough-script.md](./walkthrough-script.md), the slide and tour wording and navigation. Its open choices are resolved (decisions D1 to D4).
**Visual design**: [resources/](./resources/), desktop mockups for the 4 slides and 5 tour steps. The spec requires the build to match them.

### My understanding
- Users who haven't finished onboarding see a short chain of instruction screens. The screens explain what Milos is (time management built on a default Weekday and Weekend routine) and what to do first.
- The key ideas to teach: each day gets a copy of the default routine, which the user can follow or change. The app tracks behaviour and gives analytics on request. The AI chat can do the setup and later rearrange time on request.
- The instructions appear after login, register, or silent re-auth for as long as onboarding is unfinished, and never again once it is done.
- Setup progress is saved on every change, so leaving and coming back keeps everything.
- Audiences: end users, you (as a reminder of the app's purpose), and interviewers when the app is used as a showcase.

### Working plan
- [x] Agree on open questions (format, replay, repeat behaviour)
- [x] Generate spec at `specs/002-onboarding-instruction/spec.md`
- [x] Validate spec against the quality checklist
- [x] Fill in "Implementation Plan" above at a high level (details come from `/speckit-plan`)
- [x] `/speckit-plan`: [plan.md](./plan.md), with research, data model, contracts and quickstart. Weekend routine fix is in scope (D2).
- [x] `/speckit-tasks`: [tasks.md](./tasks.md), 49 tasks
- [x] `/speckit-implement`: all 49 tasks done, validated (see tasks.md "Validation notes")
- [ ] Next: review the changes in both repos, then commit

### Assumptions
- The instructions sit in front of the existing Onboarding page (the Weekday/Weekend board with Routine Buddy). They don't replace it.
- Manual task edits and AI chat edits on the Onboarding page are already saved one by one as they happen. This feature keeps that behaviour and adds no new kind of saving.
- Finishing onboarding still means pressing the existing "Ready to roll" button.
- Each visit while onboarding is unfinished restarts the slides from the first slide. No per-user "seen" record is kept.
- After onboarding is finished, a replay shows the slides only, because the setup screen (where the tour runs) is no longer shown.
- Users can finish onboarding without setting up both routines. The instructions recommend it but don't enforce it.
- Note from the code: the Weekday/Weekend toggle on the Onboarding page currently shows the same routine either way. If the instructions tell users to set up both, the spec needs to cover the Weekend routine for real (or flag it as a dependency).

### Discussion log
<!-- One entry per question: date, question, options offered, the user's answer, decision -->
- **2026-11-19 · Q1 Format**: How should the chain of instruction screens look? Options: intro slides then guided tour / intro slides only / guided tour only. **Answer**: intro slides, then a guided tour. **Decision**: 4 intro slides, then a tour that highlights the real controls on the setup screen.
- **2026-11-19 · Q2 Replay**: Can the instructions be replayed after onboarding is done? Options: yes, from a help button / no, never again. **Answer**: yes, from a help button. **Decision**: a "How it works" entry on the setup screen and in the main app. It is never shown automatically after onboarding.
- **2026-11-19 · Q3 Repeat**: How often do the instructions appear while onboarding is unfinished? Options: every visit with Skip / once, then on request / every visit, no skip. **Answer**: every visit, with Skip. **Decision**: the slides open on every visit until onboarding is done, and Skip goes straight to the saved setup.
- **2026-11-20 · Design added**: you added the mockups in `resources/` and asked for them to be used. **Decision**: they are the reference for layout and look (linked from spec.md and walkthrough-script.md, D4). They confirm "coming soon" for Slide 3, the two-routine wording, and the new Slide 2 text. Not designed yet: phone layouts, and the "How it works" entry in the main app after onboarding.
- **2026-11-20 · Plan**: [plan.md](./plan.md) is written. Key findings:
  - Adding a second routine per user would crash every `findByUser` lookup (7 call sites), so the plan replaces it with a type-aware lookup first (research R1).
  - Weekend days copy the Weekend routine only if it has tasks. Otherwise they fall back to Weekday, so existing users don't get empty weekends (R3).
  - Existing users get their Weekend routine created the first time it's requested (R2).
  - The slides and tour are custom, with no new library. Vitest is added for the logic tests (R6, R8).
- **2026-11-20 · Implemented**: all 49 tasks are done. What shipped:
  - the intro slides and the guided tour (`features/walkthrough/`), matching the mockups
  - "How it works" on the setup screen and the dashboard
  - real, separate Weekday and Weekend routines, end to end (backend `?type=`, `resolveTemplateFor`, two chats)
  - visible save and load errors
  - **existing bug fixed** in `App.tsx`: login read the wrong onboarding flag name, so onboarded users were always sent back to onboarding.

  Checks: frontend tests 29/29; backend tests 15 pass, with 2 stale tests failing as before this feature; scripted browser check 40/40 at desktop and phone width. Details and the small deviations from plan.md are in [tasks.md](./tasks.md), "Validation notes". Nothing is committed yet.
