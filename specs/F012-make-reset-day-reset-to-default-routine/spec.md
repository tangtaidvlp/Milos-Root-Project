# Feature Specification: Reset day to default routine

**Feature Branch**: `F012-make-reset-day-reset-to-default-routine`

**Created**: 2026-11-23

**Status**: Draft

**Input**: Draft [F012-make-reset-day-reset-to-default-routine.md](F012-make-reset-day-reset-to-default-routine.md): "Click Reset day, a confirm panel appears; yes → change every daily task back to the default routine, no → do nothing. Weekend day resets to weekend. On Onboarding/Default routine pages, a button copies all Weekday tasks to the Weekend routine."

## Clarifications

### Session 2026-11-23

- Q: Which default routine does a day reset to? → A: A weekend day resets to the Weekend routine; a weekday resets to the Weekday routine.
- Q: When a day with a reflection is reset, what happens to the reflection? → A: Keep it unchanged; only the plan resets (Claude's recommendation, the user asked for one).
- Q: Which dates can be reset on Today? → A: Today and future dates only.
- Q: What does "Copy Weekday to Weekend" do? → A: After the user confirms, it replaces all Weekend tasks with a copy of the Weekday tasks.
- Q: What happens to "Reset day" on the Onboarding/Default routine pages? → A: Remove it there.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reset a day to its default routine (Priority: P1)

On Today, the user's day has drifted from their usual routine. They press "Reset day", confirm, and the day's plan becomes a fresh copy of the matching default routine.

**Why this priority**: Today the button does nothing visible there. This is the core of the feature.

**Independent Test**: Edit a day's tasks on Today, press Reset day, confirm, and check that the board matches the default routine exactly, including after a reload.

**Acceptance Scenarios**:

1. **Given** a weekday whose plan was edited (tasks added, moved, deleted, ticked done), **When** the user presses Reset day and confirms, **Then** the plan shows exactly the Weekday default routine's tasks (name, start, duration, colour), none marked done, and this persists after reload.
2. **Given** a Saturday or Sunday and a Weekend routine with tasks, **When** the user resets and confirms, **Then** the plan matches the Weekend default routine.
3. **Given** the confirm panel is open, **When** the user cancels (or presses Escape / closes it), **Then** nothing changes.
4. **Given** a past date is selected, **Then** Reset day is disabled.
5. **Given** a day with a reflection, **When** the user resets the plan, **Then** the Reality board is unchanged and the plan-vs-reality comparison reflects the new plan.

---

### User Story 2 - Copy Weekday routine to Weekend (Priority: P2)

On the Onboarding or Default routine page, the user wants their weekend to start from the weekday routine. They press "Copy Weekday to Weekend", confirm, and the Weekend routine becomes a copy of the Weekday routine.

**Why this priority**: It saves time when setting up, but it isn't needed for the reset flow.

**Independent Test**: Set different Weekday and Weekend routines, press the button, confirm, and check that Weekend now equals Weekday and Weekday is unchanged.

**Acceptance Scenarios**:

1. **Given** Weekday and Weekend routines with different tasks, **When** the user presses Copy Weekday to Weekend and confirms, **Then** the Weekend routine contains exactly the Weekday tasks, its old tasks are gone, and the Weekday routine is unchanged.
2. **Given** the confirm panel is open, **When** the user cancels, **Then** nothing changes.
3. **Given** the Onboarding or Default routine page, **Then** no "Reset day" button is shown.

### Edge Cases

- An empty Weekend routine: a weekend day resets to the Weekday routine (the same rule used when a day is created). An empty Weekday routine resets a weekday to no tasks. Copying an empty Weekday routine empties the Weekend routine.
- The reset or copy fails (network or server error): an error is shown and the day/routine stays exactly as it was. There is never a half-replaced state.
- Overnight tasks in the default routine are copied as they are.
- Already-existing days that were created from an older version of the default routine are reset to the **current** default routine.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On Today, pressing Reset day MUST open a confirm panel that states all of the day's tasks will be replaced by a fresh copy of the default routine.
- **FR-002**: On confirm, the system MUST replace all of the selected day's plan tasks with a copy of the matching default routine (Saturday/Sunday → Weekend, other days → Weekday), with no task marked done.
- **FR-003**: Cancel, Escape or closing the panel MUST leave everything unchanged.
- **FR-004**: The reset MUST be all-or-nothing; on failure, the user sees an error and the day is unchanged.
- **FR-005**: Reset day MUST be disabled for past dates and enabled for today and future dates.
- **FR-006**: The reset MUST NOT change the day's reflection (Reality), the default routines or other days.
- **FR-007**: In side-by-side (Plan | Reality) view, Reset day MUST act on the plan only.
- **FR-008**: The Onboarding and Default routine pages MUST offer "Copy Weekday to Weekend", which opens a confirm panel and on confirm replaces all Weekend routine tasks with a copy of the Weekday routine tasks. The copy MUST be all-or-nothing.
- **FR-009**: The Onboarding and Default routine pages MUST NOT show Reset day.
- **FR-010**: Both confirm panels MUST be keyboard-accessible, with focus moving into the panel and back to the button on close.

### Key Entities

- **Daily plan**: The tasks for one date. Reset replaces all of them.
- **Default routine (Weekday / Weekend)**: The template each day is copied from. Copy replaces the Weekend one's tasks.
- **Reflection (Reality)**: What actually happened that day. Neither action touches it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After confirming, a reset day matches its default routine task-for-task in 100% of checks, including after a reload.
- **SC-002**: A user can reset a day in two clicks (Reset day → Confirm).
- **SC-003**: No reset or copy that the user cancels or that fails changes any data.

## Assumptions

- Saturday and Sunday are weekend days, using the same rule that already decides which routine a new day is copied from.
- Gap clear and the Buddy chat history for the day are not affected.
- The reset doesn't move the board's scroll position.
- Out of scope: undo after a reset, copying Weekend → Weekday, and partial resets (single tasks).
- Testing: backend tests cover the replace logic and the all-or-nothing behaviour. The `today-board` e2e journey covers the confirm → reset flow.
