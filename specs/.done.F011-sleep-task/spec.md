# Feature Specification: Sleep task (overnight tasks)

**Feature Branch**: `feat/F011-sleep-task`

**Created**: 2026-11-23

**Status**: Draft

**Input**: Draft [F011-sleep-task.md](F011-sleep-task.md): "Sleep task usually crosses midnight (e.g. 22:00 → 06:00 next day). Today it must be split into 2 tasks, which is confusing. Dragging past 24:00 should create one overnight task; the UI wraps the overflow to the top of the schedule; the backend stores it as one task."

## Clarifications

### Session 2026-11-23

- Q: On the Daily schedule, where should the after-midnight part of an overnight task be shown? → A: Top of the same day's board (each day is a 24h cycle, same as Default routine).
- Q: What happens to sleep tasks already split into two pieces? → A: Leave as is; no automatic merge.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Drag a task past midnight (Priority: P1)

A user drags or stretches a task (e.g. Sleep, 22:00) past 24:00 on the board. It becomes one overnight task. The part before midnight stays at the bottom of the board, and the part after midnight shows at the top, from 00:00 to the end time.

**Why this priority**: This is the core pain. Sleep is one activity and should be one task.

**Independent Test**: On the Default routine board, stretch a 22:00 task to 06:00, reload, and check that there is one task shown as two linked parts.

**Acceptance Scenarios**:

1. **Given** a 22:00–23:00 task, **When** the user stretches its end to 06:00, **Then** one task 22:00–06:00 (8h) is saved, shown as 22:00–24:00 at the bottom and 00:00–06:00 at the top.
2. **Given** a 1h task at 23:00, **When** the user moves it down by 2h, **Then** it becomes 01:00–02:00 (no longer overnight). A move that ends past 24:00 wraps; it is no longer clamped at 24:00.
3. **Given** an overnight task, **When** the user opens, edits or deletes either part, **Then** the action applies to the whole task.
4. **Given** an overnight task, **When** the page is reloaded, **Then** it still shows as one task in two parts.

---

### User Story 2 - Create or edit an overnight task without dragging (Priority: P2)

The user sets start 22:00 and duration 8h in the task edit form, or asks Buddy ("add sleep from 10pm to 6am"). The result is one overnight task.

**Why this priority**: The same need through the other ways to enter tasks.

**Independent Test**: Create "Sleep 22:00, 8h" through the form, and separately through Buddy. Each gives one task 22:00–06:00.

**Acceptance Scenarios**:

1. **Given** the edit form, **When** the user saves start 22:00, duration 8h, **Then** one overnight task is saved and the form shows its end as 06:00 (next day).
2. **Given** Buddy chat, **When** the user asks for sleep from 22:00 to 06:00, **Then** Buddy creates one task, not two.

---

### User Story 3 - Overnight task on the Daily schedule (Priority: P2)

An overnight task in the Weekday/Weekend routine is copied into each day's schedule as one task, wrapped on that same day's board. The "Now / Next" view treats it as current between 22:00–24:00 and between 00:00–06:00.

**Why this priority**: The Daily schedule is used every day, so it must show the overnight task correctly.

**Independent Test**: Put an overnight Sleep task in the default routine, let the day's schedule be created, and check that it shows one wrapped task and that Now/Next at 02:00 shows Sleep as current.

**Acceptance Scenarios**:

1. **Given** an overnight task in the default routine, **When** the day's schedule is created, **Then** it contains that task once, wrapped.
2. **Given** an overnight Sleep task 22:00–06:00, **When** it is 02:00, **Then** Now shows Sleep.
3. **Given** an overnight task, **When** the user marks it done or reflects on it, **Then** it counts as one task.

### Edge Cases

- A task ending exactly at 24:00 is not overnight. It does not wrap.
- Maximum duration stays 24h. A task can never overlap itself.
- The wrapped part overlaps an early-morning task (e.g. a 05:30 task under Sleep 22:00–06:00). The existing overlap rule applies to the wrapped part the same way as to any other task.
- Existing split sleep tasks (22:00–24:00 + 00:00–06:00) stay as two tasks until the user merges them by hand.
- Weekday → weekend: Friday's overnight task wraps to the top of Friday's own board. It does not carry into Saturday.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to move or stretch a task past 24:00 on the Default routine (Weekday and Weekend) board and on the Daily board. The end time wraps past midnight instead of being clamped.
- **FR-002**: The system MUST store an overnight task as one task (start time + duration), never as two.
- **FR-003**: The board MUST show an overnight task as two visually linked parts: start → 24:00 at the bottom, and 00:00 → end at the top. Both parts show the same name and the full time range (e.g. "22:00 – 06:00").
- **FR-004**: Selecting, editing, moving, completing or deleting either part MUST act on the whole task.
- **FR-005**: The task edit form and Buddy MUST accept a start time and duration that cross midnight and save one task. The duration limit stays 1 minute to 24 hours.
- **FR-006**: Overlap handling MUST treat the after-midnight part as occupied time, using the same rule as any other overlap.
- **FR-007**: Daily schedules created from a default routine MUST copy an overnight task as one task.
- **FR-008**: "Now / Next" on the Daily page MUST show an overnight task as current during both parts.
- **FR-009**: Existing tasks MUST NOT be changed automatically. Split pieces are not merged.

### Key Entities

- **Task** (routine task and daily task): name, start time, duration. It is overnight when start time + duration goes past 24:00. The end time is shown as a time of day, marked "next day" when the task is overnight.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can set up a 22:00–06:00 sleep task as one task in a single drag, with no second task.
- **SC-002**: 100% of overnight tasks show as one task in two linked parts after reload, on both the Default routine and Daily boards.
- **SC-003**: Every action on an overnight task (edit, move, delete, complete) affects exactly one task.

## Assumptions

- Each day's board is a 24h cycle. The after-midnight part is shown on the same board, not on the next date's board.
- Out of scope: showing the tail on the next day's board, auto-merging existing split tasks, tasks longer than 24h, and multi-day tasks.
- Analytics and reflection count an overnight task once, on the day it belongs to.
- Overnight tasks follow the existing overlap and push-down behavior. No new conflict rule is added.
