# Feature Specification: UX optimise (Today board)

**Feature Branch**: `F010-ux-optimise`

**Created**: 2026-11-23

**Status**: Draft

**Input**: Draft [F010-ux-optimise.md](F010-ux-optimise.md) and screenshot [resources/time-slider.png](resources/time-slider.png): remove the time slider, remove pausing (live clock always on), remove the header Sign out, fold less-used board tools into a drop-down menu on narrow screens, and let the task dialog set color and an hours + minutes duration.

## Clarifications

### Session 2026-11-23

- Q: F010 is a Task draft with six changes. Write a full spec? → A: Yes, spec it as a feature.
- Q: Where should the header "Sign out" be removed? → A: From all page headers. Sign out stays on the Profile page.
- Q: On narrow screens, which tools stay visible? → A: "+ Add task" and "Reflection". Zoom, Gap clear, Reset day and Clean up go in the menu.
- Q: Where do hours + minutes and the color picker apply? → A: Hours + minutes in every task dialog, and the color picker on Today as well.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Always-live board, no time slider (Priority: P1)

On Today, the board always follows the real time. There is no time slider and no Pause / Resume, so the board can never be left showing a stale time.

**Why this priority**: It removes controls the user doesn't need and the "Paused" state that confuses them (see screenshot).

**Independent Test**: Open Today. There is no slider under the toolbar, no "Pause clock" / "Resume live" button, and no "Paused" label. The clock readout and the now-line move with real time.

**Acceptance Scenarios**:

1. **Given** Today is open, **When** the page loads, **Then** no time slider and no Pause / Resume button are shown.
2. **Given** Today is open, **When** a minute passes, **Then** the clock readout and the now-line move to the new time.
3. **Given** Reflection mode on a wide screen (Plan | Reality side by side), **When** the toolbar is shown, **Then** it has no slider or Pause either, and both now-lines follow real time.

---

### User Story 2 - No Sign out in page headers (Priority: P1)

The page header no longer has a "Sign out" button on any page. The user signs out from the Profile page.

**Why this priority**: It frees header space. Sign out is rare and already lives in Profile.

**Independent Test**: Visit Today, Default routine, Analytics and Profile. No header shows "Sign out". On Profile, the Sign out section still works.

**Acceptance Scenarios**:

1. **Given** any page in the app, **When** it is shown, **Then** its header has no "Sign out" button.
2. **Given** the Profile page, **When** the user presses Sign out there, **Then** they are signed out and taken to the sign-in screen.

---

### User Story 3 - Board tools fold into a menu on narrow screens (Priority: P2)

When the board toolbar is too narrow to show every tool on one row, "+ Add task" and "Reflection" stay visible. Zoom, Gap clear, Reset day and Clean up move into a "More" button that opens a drop-down list.

**Why this priority**: The toolbar wraps and gets crowded on smaller screens. The main actions should stay one tap away.

**Independent Test**: Narrow the window step by step. Once the tools no longer fit, the "More" button appears, and each hidden tool works from the list.

**Acceptance Scenarios**:

1. **Given** a wide toolbar, **When** Today is shown, **Then** all tools are visible and there is no "More" button.
2. **Given** a narrow toolbar, **When** Today is shown, **Then** "+ Add task", "Reflection" and "More" are visible, and the other tools are not.
3. **Given** the "More" list is open, **When** the user picks a tool (zoom in/out, Gap clear, Reset day, Clean up), **Then** it does the same as its toolbar button. Gap clear shows whether it is on.
4. **Given** the "More" list is open, **When** the user presses Escape, clicks outside or picks a tool, **Then** the list closes (zoom in/out may keep it open so the user can press it repeatedly) and focus returns to "More" when closed with Escape.
5. **Given** a keyboard user, **When** they Tab to "More" and press Enter, **Then** the list opens, and its items can be reached and used with the keyboard.

---

### User Story 4 - Task dialog: color and hours + minutes (Priority: P2)

When adding or editing a task, the user sets the duration as hours and minutes, not total minutes. On Today, they can also pick the task's color, as they already can on the Default routine.

**Why this priority**: Typing "90" minutes for 1 h 30 is awkward, and Today tasks couldn't be given a color.

**Independent Test**: On Today, add a task with 1 h 30 min and a chosen color. The board shows a 1.5-hour block in that color. Do the same on Default routine.

**Acceptance Scenarios**:

1. **Given** the task dialog on any screen, **When** it opens for a new task, **Then** duration is two fields, hours and minutes, defaulting to 0 h 30 min.
2. **Given** an existing 95-minute task, **When** its dialog opens, **Then** it shows 1 h 35 min.
3. **Given** the dialog on Today, **When** it opens, **Then** the color choices are shown (palette plus Custom), with the task's current color selected when editing.
4. **Given** a new Today task with no color picked, **When** it is saved, **Then** it gets the next automatic color, as today.
5. **Given** a duration of 0 h 0 min or more than 24 h, **When** the user saves, **Then** an error says the duration must be between 1 minute and 24 hours, and nothing is saved.

### Edge Cases

- Tab hidden or computer asleep, then back: the board shows the real current time at once.
- Window resized across the narrow/wide point while "More" is open: the list closes or stays valid, and no tool is lost or shown twice.
- Minutes field above 59 (e.g. 0 h 90 min): it is accepted as 1 h 30 min, or the user is told minutes must be 0–59. Either way, the saved duration matches what the user meant.
- Profile page with no other way to sign out: the Profile Sign out section must stay reachable on phone width.
- The setup (onboarding) board has no live clock today. That stays unchanged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The board toolbar MUST NOT show a time slider on any screen.
- **FR-002**: The board MUST NOT offer Pause / Resume, and its clock MUST always follow real time. The "Paused" label MUST never appear.
- **FR-003**: Page headers MUST NOT show a "Sign out" button on any page. The Profile page MUST keep a working Sign out.
- **FR-004**: When the board toolbar cannot fit all tools on one row, it MUST show "+ Add task", "Reflection" and a "More" button, and put zoom, Gap clear, Reset day and Clean up in a drop-down list opened by "More".
- **FR-005**: Each tool in the "More" list MUST behave exactly like its toolbar version, including disabled states (e.g. zoom limits, Reflection on future days) and the Gap clear on/off state.
- **FR-006**: The "More" button and list MUST work with keyboard and screen readers: an accessible name, open state announced, Escape closes it, focus visible, and targets at least 24×24 px.
- **FR-007**: When all tools fit, the toolbar MUST show them all and MUST NOT show "More".
- **FR-008**: The task dialog MUST take duration as hours (0–24) and minutes (0–59) on every screen, saving the total of 1–1440 minutes. Existing durations MUST be shown split into hours and minutes.
- **FR-009**: The task dialog on Today MUST offer the same color choices as on the Default routine. A task saved without a picked color MUST keep today's automatic color behaviour.
- **FR-010**: Layouts MUST keep working from 320px width with no horizontal scrolling (constitution VI).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On Today, the board never shows a time other than the real current time (no slider, no Paused state) in any session.
- **SC-002**: No page header shows "Sign out", and the user can still sign out from Profile in at most 2 taps from any page.
- **SC-003**: From 320px to desktop width, the board toolbar never wraps onto a second row of tools, and every tool stays reachable in at most 2 taps.
- **SC-004**: The user can create a 1 h 30 min colored task on Today in one dialog without converting hours to minutes.

## Assumptions

- "Narrow" means the toolbar can't fit all its tools on one row. There is no fixed screen-width breakpoint. The same rule applies to the shared toolbar in the Plan | Reality compare view.
- In the compare view, Clean up and "+ Add task" are not in the toolbar today ("Add to plan" / "Add to reality" sit on each board). The menu only holds tools that are present.
- The clock readout and the "Live" badge stay. Only the Paused state goes.
- Reset day stays. It no longer has a paused time to reset against, and keeps its current meaning for task completion state.
- Removing pausing doesn't change how the board scrolls: it still scrolls to now once when opened, and the user scrolls freely after that.
- No backend or data change is expected: tasks already store a color and a duration in minutes.
