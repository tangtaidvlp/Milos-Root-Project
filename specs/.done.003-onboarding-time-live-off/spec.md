# Feature Specification: Live Clock Off During Onboarding

**Feature Branch**: `003-onboarding-time-live-off`

**Created**: 2026-11-20

**Status**: Implemented (2026-11-20)

**Input**: User description: "for onboarding, I want the Time live feature is off"

**Visual reference**: the setup-screen board in [002 mockups](../002-onboarding-instruction/resources/) (for example "D · Tour 2 of 5 – Routine board") shows no clock, time slider or now-line, and the board opens at 06:00.

## Background

The routine board has a **live clock** ("Time live"). It shows the current time with a "Live" or "Manual" label, a "Pause clock" / "Resume live" button, a time slider, a now-line across the board, a highlight on the task happening right now, a "Now: <task>" status line, and it scrolls the board to the current time and keeps following it.

The same board is used in two places:

- the **setup screen** (onboarding), where the user edits their Weekday and Weekend **default routines**. These are templates, not a real day.
- the **daily dashboard**, where the user follows a real day's routine.

On the setup screen the live clock makes no sense. A template has no "now", so highlighting the "current" task and jumping to the current time confuses users. It also distracts from setting the routine up.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Set up routines without a live clock (Priority: P1)

A user on the setup screen edits their Weekday or Weekend routine. The board shows only the routine: the hours, the tasks and the editing controls. Nothing on it refers to the current time of day.

**Why this priority**: This is the whole request.

**Independent Test**: Open the setup screen at any time of day. Confirm that there is no clock readout, Live/Manual label, Pause clock / Resume live button, time slider, now-line, "current task" highlight or "Now: …" line, and that the board does not move by itself.

**Acceptance Scenarios**:

1. **Given** a user on the setup screen, **When** the board is shown, **Then** none of the live clock elements is visible: the clock readout, the Live/Manual label, the Pause clock / Resume live button, the time slider, the now-line and the "Now: …" status line.
2. **Given** a routine with a task that covers the current time of day, **When** the setup screen is shown, **Then** that task looks the same as every other task (no "active" highlight).
3. **Given** a user who has scrolled the board, **When** a minute or more passes, **Then** the board stays where the user left it.
4. **Given** the setup screen opens, or the user switches between Weekday and Weekend, **When** the board appears, **Then** it is scrolled to 06:00, whatever the time of day.
5. **Given** the live clock is off, **When** the user adds, edits, drags, resizes or deletes tasks, zooms, or uses Gap clear, **Then** all of these work exactly as before.

---

### User Story 2 - The daily dashboard keeps its live clock (Priority: P1)

A user on the daily dashboard still sees the live clock exactly as today: the clock, Pause/Resume, the slider, the now-line, the current-task highlight, the "Now: …" line and the scroll to the current time.

**Why this priority**: Turning the clock off on the setup screen must not remove it where it is useful.

**Independent Test**: Open the dashboard for today. Confirm every live clock element is present and works as before.

**Acceptance Scenarios**:

1. **Given** a user on the daily dashboard, **When** the board is shown, **Then** all live clock elements are present and behave exactly as before this change.

---

### Edge Cases

- **Routine starts before 06:00**: the board still opens at 06:00. The user scrolls up to see earlier tasks, as with any other part of the day.
- **Empty routine**: the board opens at 06:00 with no tasks and no clock elements.
- **Guided tour (feature 002)**: the tour step that highlights the routine board shows the board without any clock elements, matching the mockup.
- **Phone screens**: the same elements are hidden on the setup screen on phones.
- **"How it works" replay** on the dashboard does not affect the dashboard's live clock.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On the setup screen, the board MUST NOT show the clock readout, the Live/Manual label, the Pause clock / Resume live button, the time slider, the now-line, or the "Now: <task>" status line.
- **FR-002**: On the setup screen, the board MUST NOT mark any task as the current task because of the time of day.
- **FR-003**: On the setup screen, the board MUST NOT scroll or update by itself as time passes.
- **FR-004**: On the setup screen, the board MUST open scrolled to 06:00, both when the screen first loads and after switching between Weekday and Weekend.
- **FR-005**: All other board features on the setup screen (adding, editing, dragging, resizing and deleting tasks, zoom, Gap clear, Reset day) MUST keep working as before.
- **FR-006**: The daily dashboard's live clock MUST keep all of its current behaviour.
- **FR-007**: Turning the live clock off MUST NOT change any routine data.

### Key Entities

- **Live clock**: display-only behaviour of the routine board. Nothing is stored; it is on for a real day (dashboard) and off for a template (setup screen).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On the setup screen, 0 live clock elements are visible, at any time of day, on desktop and phone sizes.
- **SC-002**: With the setup screen left open for 5 minutes, the board's scroll position and appearance do not change.
- **SC-003**: The setup screen opens at 06:00 in 100% of loads and Weekday/Weekend switches.
- **SC-004**: On the dashboard, 100% of the live clock elements present before the change are still present and working.

## Assumptions

- "Time live feature" means the board's live clock described in Background, and "for onboarding" means the setup screen only. The dashboard is unchanged.
- "Off" means removed from view on the setup screen, not merely paused, because the mockups show none of these elements.
- The board opens at 06:00 because the mockups do. Earlier tasks are reached by scrolling up.
- Other differences between the setup-screen mockups and today's board (for example the "Reset day" button, which the mockups do not show, and the completion checkboxes) are out of scope for this feature.
