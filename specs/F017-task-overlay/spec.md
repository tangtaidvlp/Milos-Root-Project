# Feature Specification: Task overlay

**Feature Branch**: `feat/F017-task-overlay`

**Created**: 2026-11-27

**Status**: Draft

**Input**: Draft `F017-task-overlay.md`; design `resources/edit-task-overlay-toggle.png` (the "Overlay" row of the Edit task dialog).

## Clarifications

### Session 2026-11-27

- Q: When does a swap start while dragging? → A: When the dragged task covers at least half of the other task (same rule as the T002 Push mode swap).
- Q: Where does the dragged task land when the two durations differ? → A: The gap between the pair is kept (T002 swap rule), so a swap never creates a new overlap.
- Q: Whose setting counts? → A: The dragged task's. An Overlay-on task dropped on an Overlay-off task simply overlaps.
- Q: Push mode? → A: Push mode only pushes, every task, Overlay on or off; it never swaps, and it keeps shifting the whole rest of the day (T002 rule). Changed after feedback: \"Overlay-off never pushes\" made Push mode look broken, and the T002 swap cut every push short after half a task.
- Q: Resize into the next task? → A: An Overlay-off task stops at the next task's start.
- Q: Times typed in the dialog or set by Buddy? → A: Not checked; only dragging enforces the rule.
- Q: Existing tasks? → A: All become Overlay off; existing overlaps are left as they are.
- Q: Circle view? → A: Out of scope.
- Q: An Overlay-off task released while covering less than half of a task? → A: It stops at that task's edge (no overlap is left); if there is no room, it goes back to where it was.
- Q: Reflection "Reality" board? → A: Out of scope; reality tasks keep today's drag behaviour and the dialog hides the toggle there.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mark a task as allowed to overlap (Priority: P1)

A user opens a task (e.g. Sleep) and turns on "Overlay — Allow this task to overlap other tasks". New tasks have it off.

**Why this priority**: The setting is the base for the drag behaviour; without it no task could overlap.

**Independent Test**: Create a task, check the toggle is off; turn it on, save, reload; it is still on.

**Acceptance Scenarios**:

1. **Given** the user adds a new task, **When** the dialog opens, **Then** the Overlay toggle is off.
2. **Given** a task with Overlay off, **When** the user turns it on and saves, **Then** after a reload the toggle is still on.
3. **Given** a default-routine task with Overlay on, **When** a day is created or reset from the default routine, **Then** that day's copy also has Overlay on.

---

### User Story 2 - Dragging a normal task swaps instead of overlapping (Priority: P1)

The user drags an Overlay-off task onto another task. Once it covers at least half of it, the other task jumps into the dragged task's original slot. The dragged task keeps following the pointer; on release it lands in the other task's old position.

**Why this priority**: This is the problem being solved: tasks no longer overlap by accident.

**Independent Test**: Two tasks A (09:00–10:00) and B (10:30–11:00), both Overlay off. Drag A down over half of B; B shows at 09:00 during the drag; release; A shows at 10:00–11:00 and stays there after reload.

**Acceptance Scenarios**:

1. **Given** A (Overlay off) and B, **When** A is dragged over less than half of B, **Then** B does not move.
2. **Given** A (Overlay off) and B, **When** A covers at least half of B, **Then** B moves into A's original slot at once, and A keeps following the pointer.
3. **Given** a swap is showing, **When** the user releases, **Then** A lands in B's old position (gap between them kept) and both are saved.
4. **Given** a swap is showing, **When** the user drags A back off B (less than half), **Then** B returns to its own slot.
5. **Given** A is dragged past several tasks, **When** it covers at least half of each, **Then** it swaps with each in turn, nearest first; other tasks do not move.
6. **Given** Push mode is on, **When** any task is dragged, **Then** the rest of the day is pushed and nothing is swapped.

---

### User Story 3 - Overlay tasks keep overlapping; normal tasks don't grow into others (Priority: P2)

An Overlay-on task can still be dragged over other tasks (side by side, max 3 at the same moment, as today). An Overlay-off task cannot be stretched into the next task.

**Why this priority**: Keeps the existing overlap for the tasks that need it, and closes the other way to overlap by accident.

**Independent Test**: Drag an Overlay-on task over another; they show side by side. Resize an Overlay-off task down into the next task; it stops at that task's start.

**Acceptance Scenarios**:

1. **Given** an Overlay-on task, **When** it is dragged over an Overlay-off task, **Then** they overlap side by side and the other task does not move.
2. **Given** an Overlay-off task, **When** the user resizes it past the start of the next task, **Then** its end stops at that start.
3. **Given** an Overlay-on task in Push mode, **When** it is moved or resized, **Then** it pushes other tasks as today.

### Edge Cases

- Exactly half covered counts as covered (swap happens).
- The dragged task already overlapped the other task before the drag (old data): that pair is left as it is (no swap, no edge stop).
- Releasing exactly at the original position after a swap was shown and undone: nothing changes and nothing is saved.
- Overnight tasks (crossing midnight) follow the same rules on the part being dragged.
- A swap that would put a task before 00:00 or after 23:55 is clamped to the day.
- Save fails after a swap: both tasks return to their original slots and the error message shows (as today).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every task (default routine and daily) MUST have an Overlay setting, off by default.
- **FR-002**: The Edit task dialog MUST show an "Overlay" toggle with the text "Allow this task to overlap other tasks" (design: `resources/edit-task-overlay-toggle.png`), and save its value with the task.
- **FR-003**: A day created or reset from the default routine MUST copy each task's Overlay setting.
- **FR-004**: When an Overlay-off task is moved and covers at least half of another task, that task MUST move into the dragged task's original slot immediately, while the dragged task keeps following the pointer.
- **FR-005**: On release, the dragged task MUST land in the swapped task's old position with the gap between them kept (down: the dragged task ends where the other task ended; up: it starts where the other task started), and both MUST be saved.
- **FR-006**: Passing several tasks MUST swap with each in turn, nearest first; tasks not passed MUST NOT move.
- **FR-007**: FR-004–FR-006, FR-009 and FR-011 apply in Normal mode only. In Push mode every task, Overlay on or off, is pushed (the rest of the day shifts, as in T002) and nothing is swapped.
- **FR-008**: An Overlay-on task MUST keep the current behaviour: overlap in Normal mode, push in Push mode, max 3 tasks at the same moment.
- **FR-009**: In Normal mode, resizing an Overlay-off task MUST stop its end at the start of the next task. In Push mode it pushes as today (no overlap is created).
- **FR-012**: While a task is dragged (move or resize), the time column MUST show its start and end time with red marks and its duration between them (design: `resources/drag-time-indicator.png`); they disappear on release.
- **FR-011**: An Overlay-off task released while covering less than half of another task MUST land against that task's edge; if that slot overlaps another task too, it MUST return to its original slot. Overlaps that already existed before the drag are ignored.
- **FR-010**: Existing tasks MUST read as Overlay off; no existing task times are changed.

### Key Entities

- **Task** (default-routine task and daily task): gains **Overlay** (yes/no, default no).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Dragging an Overlay-off task never leaves it overlapping another task (checked across move, swap and resize).
- **SC-002**: A user can swap two tasks with one drag, without opening a dialog.
- **SC-003**: The Overlay setting survives reload and day creation in 100% of cases.

## Assumptions

- Only the Overlay row from the design is in scope; other differences in the mockup (duration shortcuts, start → end line, header layout) are not part of this feature.
- Overlaps typed in the dialog or created by Buddy are not checked (no server-side rule).
- Circle (radial) view drag is unchanged.
- Reflection "Reality" tasks have no Overlay setting and keep today's drag behaviour.
- Builds on T002 (hold-to-drag, Push mode, swap rule, overlap cap of 3), which is not merged yet.
