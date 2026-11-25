# Feature Specification: Radial 24H View

**Feature Branch**: `feat/F016-radial-24h-view`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "A radial 24 hour view so users see the overview of their daily routine. The vertical chart is too big to see the overview. Applies to Daily Routine, Reflection and Default Routine. Users switch between vertical and radial. Reuse one radial chart everywhere. The Buddy chat can be hidden by a button, the same way as the left sidebar." Draft: [F016-radial-24h-view.md](F016-radial-24h-view.md).

**Design reference**: [resources/radial-24h-chart.png](resources/radial-24h-chart.png) is a sketch for layout only: a 24-hour clock face, tasks as slices, task names and times outside the circle. Colors and fonts follow the app's current style, not the sketch. The final look follows [resources/radial-24h-clock-elegant.png](resources/radial-24h-clock-elegant.png) (clock) and [resources/radial-24h-piece-information-elegant.png](resources/radial-24h-piece-information-elegant.png) (task list).

## Clarifications

### Session 2026-11-25

- Q: What can the user do with tasks on the radial chart? → A: Overview plus click to edit: clicking a slice does what clicking the task does on the vertical board. No dragging on the circle.
- Q: How does Reflection show Plan and Reality in radial view? → A: Two circles side by side, the same layout as today (one at a time on narrow screens).
- Q: How do task names stay readable on thin slices? → A: As in the mock: all text sits outside the circle. The circle may shrink, but the text must always be clear.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See my day as a 24-hour circle (Priority: P1)

On Daily Routine, the user switches from the vertical board to a radial view. The whole day fits on screen as one circle, so they can see at a glance how the day is split between sleep, work, rest and free time.

**Why this priority**: This is the problem in the draft: the vertical board is too tall to give an overview.

**Independent Test**: Open a day with tasks, switch to radial, and check that every task appears as a slice in the right place, its name and time readable outside the circle.

**Acceptance Scenarios**:

1. **Given** a day with tasks, **When** the user picks the radial view, **Then** a 24-hour circle shows each task as a slice from its start to its end time, with midnight at the top and time running clockwise.
2. **Given** the radial view, **When** the user looks at any task, **Then** its name and time range appear outside the circle, joined to the slice by a line, and stay readable even for a 15-minute task.
3. **Given** the radial view, **When** the user clicks or taps a slice (or focuses it with the keyboard and presses Enter), **Then** the same thing happens as clicking that task on the vertical board (today: the task edit dialog opens).
4. **Given** the radial view, **When** the user switches back to vertical, **Then** the vertical board shows the same day with nothing changed.
5. **Given** the user chose radial, **When** they reload the page or come back later on the same device, **Then** radial is still selected.

---

### User Story 2 - Radial view in Default Routine and Reflection (Priority: P2)

The same view switch and the same radial chart are on Default Routine (Weekday and Weekend) and in Reflection mode.

**Why this priority**: The draft asks for all three places and for one chart reused everywhere. Daily alone already gives value.

**Independent Test**: Switch to radial on Default Routine and in Reflection, and check that the chart looks and behaves the same as on Daily.

**Acceptance Scenarios**:

1. **Given** Default Routine in radial view, **When** the user switches between Weekday and Weekend, **Then** the circle shows that routine's tasks.
2. **Given** Reflection is on and a reflection exists, on a wide screen, **When** radial view is chosen, **Then** a Plan circle and a Reality circle show side by side.
3. **Given** Reflection on a narrow screen, **When** radial view is chosen, **Then** one circle shows at a time, the same way one board shows today.
4. **Given** Reflection in radial view, **When** the user clicks a Reality slice, **Then** the same thing happens as clicking that task on the Reality board (today: the reflection task popup opens).

---

### User Story 3 - Hide the Buddy chat (Priority: P2)

On a wide screen the user hides the Buddy chat panel with a button, the same way they collapse the left sidebar, so the board or circle gets the space. Another press shows the chat again.

**Why this priority**: More room makes both views easier to read. It does not depend on the radial view.

**Independent Test**: On a wide screen, hide the chat, check that the board area grows, reload, check that it is still hidden, then show it again.

**Acceptance Scenarios**:

1. **Given** the chat is shown on Daily Routine, Reflection or Default Routine, **When** the user presses the hide button, **Then** the chat panel collapses and the board or circle area grows.
2. **Given** the chat is hidden, **When** the user presses the show button, **Then** the chat is back with its conversation and any unsent text unchanged.
3. **Given** the chat is hidden, **When** the user reloads or opens another of these pages on the same device, **Then** the chat stays hidden.

---

### Edge Cases

- **Many short tasks close together** (for example a morning of 15-minute tasks): each has its own arc (a dot when too short for a rounded arc) and its own label; labels spread around the ring without overlapping.
- **Task crossing midnight** (for example sleep 23:00–07:00): one continuous arc over the top of the clock, one list row.
- **Overlapping tasks**: the track splits into thinner lanes so both arcs stay visible.
- **Empty day or routine**: the circle shows only the hour marks. Add-task controls work as usual.
- **Narrow screen (320px)**: the circle shrinks, the text keeps a readable size, and the page does not scroll sideways.
- **Small board** (phone, tablet, or a narrow desktop window such as Reflection compare): when labels around the ring would make the clock too small, the clock fills the width and the labels list under it, without lines.
- **Completed tasks (Daily)**: a completed task looks different from an open one, as it does on the vertical board.
- **Mobile**: the chat is already reached through its own button (board/chat swap), so the hide button applies to wide screens only.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Daily Routine, Reflection and Default Routine MUST each have a control to switch between the vertical view and the radial view. Vertical is the default.
- **FR-002**: The view choice MUST be remembered on the device and apply to all three pages.
- **FR-003**: The radial view MUST show a 24-hour clock centred in its board area: midnight at the top, time running clockwise, hour ticks and numbers outside a track ring (00, 06, 12, 18 emphasised). Each task is a rounded arc on the track from its start to its end time, in its task colour. With a live clock (Today) it also shows a now hand with a knob on the track, a thin arc for the time elapsed today, and in the centre the date, the time, the current task and "until HH:mm · Xh left" (or the next task).
- **FR-004**: Each task's information MUST sit around the clock on a label ring (1.2× the clock radius, at least clear of the hour numbers), joined to its arc by a line in the task's pastel colour that passes under the hour numbers. Each label shows a colour bar, name, `HH:mm – HH:mm · duration`, and a **Now** or **Done** badge, in the style of [resources/radial-24h-piece-information-elegant.png](resources/radial-24h-piece-information-elegant.png) at a compact height. Labels MUST NOT overlap. When the clock would get too small, the labels list under it without lines. All text MUST stay readable from 320px up; the clock shrinks, the text does not.
- **FR-005**: Clicking or tapping a task's arc or label MUST do the same as clicking that task on the vertical board for that page and mode. Labels MUST be reachable and usable by keyboard, with a visible focus.
- **FR-006**: The radial view MUST NOT offer drag to move or resize. Existing add-task controls (button, floating button, Buddy) MUST keep working in radial view.
- **FR-007**: All three pages MUST use the same radial chart, so it looks and behaves the same everywhere.
- **FR-008**: In Reflection, the radial view MUST show Plan and Reality as two circles side by side where the boards are side by side today, and one at a time where one board shows today.
- **FR-009**: Any change to tasks (edit dialog, Buddy, reset day) MUST show on the radial view without a reload.
- **FR-010**: On wide screens, Daily Routine, Reflection and Default Routine MUST have a button that hides and shows the Buddy chat panel. When hidden, the board or circle takes the freed space.
- **FR-011**: Hiding the chat MUST NOT lose the conversation or unsent text. The hidden/shown choice MUST be remembered on the device.
- **FR-012**: The radial view, view switch and chat hide button MUST meet the app's accessibility rules (WCAG 2.2 AA): labelled controls, keyboard use, AA contrast in light and dark themes, 24×24px minimum targets.

### Key Entities

- **View preference**: per device, vertical or radial, shared by the three pages.
- **Chat panel preference**: per device, shown or hidden on wide screens.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a laptop screen (1366×768 or larger) the whole 24-hour day is visible in radial view without scrolling the board area.
- **SC-002**: Every task name and time on the circle is readable at 320px, 768px and 1366px widths, with no overlapping labels. This includes a day with eight 15-minute tasks in a row.
- **SC-003**: A user switches views or hides/shows the chat in one click, and the choice is still there after a reload.
- **SC-004**: The radial chart looks and behaves the same on all three pages, and in both Plan and Reality in Reflection.

## Assumptions

- Out of scope: drag to move or resize on the circle, and any change to tasks, routines or chat on the server. This feature is display only.
- Colors, fonts and spacing follow the app's current design tokens and both themes. The sketch is for layout only.
- The view and chat-hide choices are stored per device, the same way as the sidebar's collapsed state. They are not synced across devices.
- Free time between tasks shows as empty circle space.
