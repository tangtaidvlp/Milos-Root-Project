# Feature Specification: Onboarding Instruction

**Feature Branch**: `002-onboarding-instruction`

**Created**: 2026-11-19

**Status**: Implemented (2026-11-20)

**Input**: Ticket [F001 – Onboarding Instruction](./F001-onboarding-instruction.md): "Chain of screens for application use instructions", shown to users who have not finished onboarding. The decisions agreed in the ticket's Discussion log are included.

**Walkthrough script**: the exact slide and tour wording, and the step-by-step navigation, are in [walkthrough-script.md](./walkthrough-script.md).

**Visual design**: the desktop mockups for all 4 intro slides and all 5 tour steps are in [resources/](./resources/). The slides, the tour and the "How it works" entry MUST match these mockups in layout, content and order. Phone layouts are not designed yet; they follow the rules in the walkthrough script.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Learn what Milos is before setting up (Priority: P1)

A new user who has just registered (or a returning user who has not finished onboarding) lands in the app. Before they reach the routine setup, a short series of intro slides explains what Milos is for and how it works:

- Milos is a time-management app built around a default routine, one for weekdays and one for weekends.
- Each day, the matching default routine is copied into that day. The user can follow it as planned or change it.
- The app keeps track of how the user actually spends their time, and gives them an analysis of it whenever they ask.
- Routine Buddy (the AI chat) can do the setup for them, and later rearrange their time on request, so they don't have to plan every detail themselves.
- What to do first: set up the Weekday and Weekend default routines, by hand or by talking to Routine Buddy.

The user can step through the slides or skip them at any point.

**Why this priority**: This is the core of the feature. Without it, users (and the app owner presenting it to an interviewer) have no in-app explanation of the app's purpose or of the first step.

**Independent Test**: Register a new account. Confirm the intro slides appear before the setup screen, cover each point above, can be stepped through to the end, and can be skipped from any slide.

**Acceptance Scenarios**:

1. **Given** a user who has not finished onboarding, **When** they register, log in, or return to the app while still signed in, **Then** the intro slides are shown before the routine setup screen.
2. **Given** the intro slides are showing, **When** the user moves forward through them, **Then** they see, in order, what the app is, how daily copies of the default routine work, what tracking and analysis it offers, how Routine Buddy can help, and what to do first.
3. **Given** the intro slides are showing on any slide, **When** the user chooses Skip, **Then** the slides close and the user is on the routine setup screen.
4. **Given** the user reaches the last slide, **When** they choose to continue, **Then** the guided tour of the setup screen begins (User Story 2).

---

### User Story 2 - Guided tour of the setup screen (Priority: P2)

After the intro slides, a short guided tour points at the real controls on the routine setup screen one at a time, with a sentence or two each:

1. The Weekday / Weekend switch: "You have two default routines; set up both."
2. The routine board: "This is your default routine. Each day starts as a copy of it."
3. The add (+) button: "Add a task yourself."
4. Routine Buddy: "Or just tell Routine Buddy about your day and it will build the routine for you."
5. The finish button ("Ready to roll"): "When you are happy with both routines, finish here."

The user can go forward, go back, or end the tour at any step.

**Why this priority**: The slides explain the idea, and the tour connects it to the controls the user has to use. It is valuable but depends on the slides for context.

**Independent Test**: Go through the intro slides to the end. Confirm each tour step highlights the right control with its explanation, and that the tour can be ended at any step, leaving the setup screen usable.

**Acceptance Scenarios**:

1. **Given** the user has finished the intro slides, **When** the tour starts, **Then** each step visibly highlights one control on the setup screen and explains it.
2. **Given** the tour is on any step, **When** the user ends the tour, **Then** the highlight disappears and the setup screen works normally.
3. **Given** the user skipped the intro slides, **When** they reach the setup screen, **Then** the tour does not start automatically.
4. **Given** the tour is on any step after the first, **When** the user goes back, **Then** the previous step is shown again.

---

### User Story 3 - Progress is kept and instructions return until onboarding is done (Priority: P2)

A user starts setting up, either by hand or with Routine Buddy, then leaves part-way. When they come back (by logging in again, or by revisiting while still signed in), everything they set up is still there. Because they have not finished onboarding, the instructions are shown again, and they can skip straight to their saved setup. Once they finish onboarding, the instructions never appear on their own again.

**Why this priority**: Without this, users either lose work or are shown instructions forever. It defines exactly when the feature appears and when it goes away.

**Independent Test**: As a new user, add two tasks (one by hand, one through Routine Buddy), then log out and back in. Confirm the instructions reappear, Skip leads to the setup screen with both tasks present, and after finishing onboarding a further log-in shows no instructions.

**Acceptance Scenarios**:

1. **Given** a user who has made changes to their default routines but not finished onboarding, **When** they log in again or revisit, **Then** all their earlier changes are still present.
2. **Given** that same user, **When** they come back, **Then** the intro slides are shown again, starting from the first slide, with Skip available.
3. **Given** a user who has finished onboarding, **When** they log in, register, or revisit, **Then** no instructions are shown automatically.
4. **Given** a user who changes a task, **When** the change is accepted, **Then** it is saved right away, without waiting for onboarding to be finished.

---

### User Story 4 - Replay the instructions on demand (Priority: P3)

At any time, including after onboarding is finished, a user can open a clearly labelled "How it works" entry to replay the instructions. This helps users who forgot how the app works. It also lets the app owner walk an interviewer through the app's purpose during a showcase.

**Why this priority**: Useful for returning users and for showcases, but not needed for first-time onboarding.

**Independent Test**: As a user who has finished onboarding, open "How it works". Confirm the intro slides play from the first slide and can be closed, and that nothing in the user's routines changes.

**Acceptance Scenarios**:

1. **Given** a user who has finished onboarding, **When** they open "How it works", **Then** the intro slides play from the first slide.
2. **Given** a user on the routine setup screen who has not finished onboarding, **When** they open "How it works", **Then** the intro slides play, followed by the guided tour.
3. **Given** a replay is showing, **When** the user closes it, **Then** they return to where they were, and their routines and onboarding status are unchanged.

---

### Edge Cases

- **Refresh or close mid-slides**: if the user refreshes or closes the app during the slides or the tour, the next visit starts again from the first slide (onboarding still unfinished). Nothing they set up is lost.
- **Save fails**: if a change cannot be saved (for example, the connection drops), the user is told it was not saved. It must not appear saved when it isn't.
- **Finish without setting up both routines**: a user who chooses "Ready to roll" without setting up both routines can still finish. The instructions recommend setting up both; they do not enforce it.
- **Small screens**: slides and tour steps stay readable and usable on phone-sized screens. On a phone, a tour step for a control that sits in a hidden panel (for example, the chat) still explains that control, without needing it on screen.
- **Onboarding finished elsewhere**: if a user finishes onboarding in one browser tab or device, their next visit anywhere shows no automatic instructions.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST show the intro slides automatically to a signed-in user whose onboarding is not finished, each time they enter the app: after registering, after logging in, and when returning while still signed in.
- **FR-002**: The system MUST NOT show the slides or the tour automatically to a user whose onboarding is finished.
- **FR-003**: The intro slides MUST explain:
  - (a) what the app is for (time management based on default Weekday and Weekend routines)
  - (b) that each day starts as a copy of the matching default routine, which the user can follow or change
  - (c) that the app tracks what the user planned and what they actually did, and that a breakdown of how they spend their time is coming soon (analysis on request is a later feature; Routine Buddy cannot read past days yet)
  - (d) that Routine Buddy can set up and later rearrange routines on request
  - (e) that the first step is to set up both default routines, by hand or with Routine Buddy
- **FR-004**: The intro slides MUST consist of no more than 4 slides, each readable in under 20 seconds.
- **FR-005**: Users MUST be able to move forward through the slides, go back to the previous slide, and skip the rest at any point with a single action.
- **FR-006**: After the last intro slide, the system MUST start a guided tour on the routine setup screen. The tour highlights, in order: the Weekday/Weekend switch, the routine board, the add button, Routine Buddy, and the finish button. Each step has a short explanation.
- **FR-007**: Users MUST be able to go forward, go back, and end the guided tour at any step. Ending it leaves the setup screen fully usable.
- **FR-008**: If the user skips the intro slides, the guided tour MUST NOT start automatically during that visit.
- **FR-009**: Every change a user makes to their default routines during onboarding MUST be saved as soon as it is accepted, whether it was made by hand or through Routine Buddy. Saving MUST NOT wait for the user to finish onboarding.
- **FR-010**: When a user returns before finishing onboarding, the system MUST show all of their previously saved changes on the routine setup screen.
- **FR-011**: If a change cannot be saved, the system MUST tell the user, and MUST NOT show the change as saved.
- **FR-012**: The system MUST provide a "How it works" entry. It is available on the routine setup screen and in the main app after onboarding, and it replays the instructions on demand.
- **FR-013**: A replay MUST start from the first intro slide. On the routine setup screen, the guided tour follows the replay. Elsewhere, the replay ends after the slides.
- **FR-014**: Viewing, skipping, or replaying the instructions MUST NOT change the user's routines or onboarding status.
- **FR-015**: The slides and the tour MUST be usable with a keyboard. They MUST also stay readable and usable on phone-sized screens.

### Key Entities

- **Onboarding status**: whether a user has finished onboarding. It already exists for each user and decides whether the instructions appear automatically.
- **Default routine**: the user's template routine for weekdays and for weekends. These are what the user sets up during onboarding, and each day is copied from one of them.
- **Instruction content**: the fixed text of the intro slides and the tour steps. It is the same for every user and is not stored per user.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of visits by users with unfinished onboarding show the intro slides first. 0% of visits by users with finished onboarding show them automatically.
- **SC-002**: A user can read all the intro slides in under 90 seconds, and can skip them from any slide in one action.
- **SC-003**: In a hallway test with at least 3 people who have never seen the app, at least 3 out of 3 can say in their own words, right after the slides, what the app is for and what to do first.
- **SC-004**: In 100% of test runs, routine changes made before leaving are present on return, both after logging in again and after revisiting while signed in.
- **SC-005**: The app owner can replay the full instructions for an interviewer in under 2 minutes, starting from any screen of the main app.

## Assumptions

- The instructions come before, and run on top of, the existing routine setup (Onboarding) screen. They do not replace it.
- Finishing onboarding still means choosing the existing "Ready to roll" button. This feature does not change how onboarding is finished.
- Each visit while onboarding is unfinished restarts the slides from the first slide. The feature does not remember how far the user got through the slides or the tour, and no per-user record of "instructions seen" is kept.
- After onboarding is finished, a replay shows the intro slides only, because the setup screen (where the tour runs) is no longer part of the main app.
- The instruction text is English only, like the rest of the app.
- **Dependency**: the instructions tell users to set up separate Weekday and Weekend routines. This relies on the setup screen really keeping the two routines apart. Today the Weekday/Weekend switch on that screen shows the same routine either way. Decision (2026-11-20): this gap is fixed as part of this feature (F001), so the two-routine wording stays.
- **Dependency**: FR-009 and FR-010 (save as you go) match how the setup screen saves manual and Routine Buddy changes today. This feature only has to check and keep that behaviour, not build it.
