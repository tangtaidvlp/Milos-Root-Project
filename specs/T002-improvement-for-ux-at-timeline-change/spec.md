# Feature Specification: Timeline drag UX improvements

**Feature Branch**: `T002-improvement-for-ux-at-timeline-change`

**Created**: 2026-11-26

**Status**: Draft

**Input**: Draft [T002-improvement-for-ux-at-timeline-change.md](T002-improvement-for-ux-at-timeline-change.md): dragging a task fights with scrolling the board, and after a drop the task jumps back to its old spot until the save returns.

## Clarifications

### Session 2026-11-26

- Q: Which timeline boards get the new drag behaviour? → A: All timeline boards (Today, Default routine, Onboarding, Reflection compare). The circle view is out of scope.
- Q: Does the 0.1s hold apply to every input or only to touch? → A: Touch only (phone browsers). With a mouse, the drag starts once the pointer moves past a few pixels; a click still opens the task.
- Q: What if a Push mode move passes another task? → A: Once the dragged task has passed at least half of another task, it swaps with it instead of pushing (gap kept, other tasks stay put). *(Removed by F017: Push mode only pushes; swapping is the Normal mode rule for Overlay-off tasks.)*
- Q: What happens when a drag would put a 4th task in the same time slot? → A: Show an error that 4 tasks can't run in parallel. The change is not applied.
- Q: How should Gap clear work? → A: Rename it to "Push mode", off by default. Turning it on tells the user that Push mode is on and changing a task's size or position pushes other tasks. Other tasks move live while dragging.
- Q: Does Push mode push only down? → A: No, it pushes both ways. Dragging up pushes the tasks before the task up; dragging down pushes the tasks after it down.
- Q: What about the server's automatic push, which moves an overlapped task to after the one just saved? → A: Remove it everywhere (board, task dialog, Buddy). It is the "default push tasks mode" the draft asks to disable, and it would undo overlaps and scramble Push mode saves. The 3-task cap is checked when saving instead.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Hold to drag, swipe to scroll (Priority: P1)

A user scrolls the board by swiping, without picking up a task by accident. To move or resize a task on a phone, they press and hold it for 0.1s (with a mouse, they just drag). The task is then highlighted to show it can be dragged.

**Why this priority**: This is the main complaint. Today any touch on a task starts a drag, so scrolling a busy board is frustrating.

**Independent Test**: On a board full of tasks, swipe quickly across tasks. The board scrolls and no task moves. Press and hold a task: it is highlighted, and dragging it moves it.

**Acceptance Scenarios**:

1. **Given** a board with tasks, **When** the user swipes quickly starting on a task, **Then** the board scrolls and the task stays where it was.
2. **Given** a task, **When** the user presses and holds it for 0.1s, **Then** the task is highlighted as ready to drag, and moving the pointer moves it (or resizes it, from the resize handle).
3. **Given** a task, **When** the user taps or clicks it without holding or moving, **Then** the task dialog opens as it does today.
4. **Given** a task is ready to drag, **When** the user releases it without moving, **Then** the highlight goes away and nothing changes.

---

### User Story 2 - Instant result on drop (Priority: P1)

When the user drops a task, the board shows the new layout at once and keeps it. While the change saves, the board shows a small waiting indicator (three bouncing dots) and doesn't accept other edits. If the save fails, the board goes back to how it was before the drag and shows an error at the bottom of the screen.

**Why this priority**: Today the task jumps back to its old spot and then jumps again when the save returns. This looks broken.

**Independent Test**: Drag a task to a new time and drop it. It stays at the new time with no jump. With the backend stopped, repeat: the board shows the old layout and an error appears.

**Acceptance Scenarios**:

1. **Given** a task being dragged, **When** the user drops it, **Then** it stays at the dropped position (and any pushed tasks stay at their new positions), with no flicker back to the old position.
2. **Given** a drop is saving, **When** the user tries to drag, resize, add, edit or delete a task on that board, **Then** nothing happens, and the waiting indicator is visible.
3. **Given** a drop is saving, **When** the save succeeds, **Then** the indicator goes away and the board can be edited again. The layout stays the same.
4. **Given** a drop is saving, **When** the save fails, **Then** every task returns to its position from before the drag, and an error message shows at the bottom of the screen: the reason when there is one (for example the 3-task cap), otherwise "Something went wrong. Your change wasn't saved."

---

### User Story 3 - Overlapping tasks, at most 3 at once (Priority: P2)

Users can place tasks at the same time (for example "Lunch" during "Podcast"), from the board, the task dialog or Buddy. The app no longer pushes other tasks out of the way on its own (today it moves an overlapped task to after the one just saved). At most 3 tasks can run at the same moment. A change that would put 4 tasks at the same moment is refused with an error.

**Why this priority**: Real routines have parallel activities. A cap keeps the board readable.

**Independent Test**: Drag a task onto another task: both show side by side. Make 3 tasks overlap, then drag a 4th onto the same time: an error shows and the 4th task goes back.

**Acceptance Scenarios**:

1. **Given** two tasks at different times, **When** the user drops one so the two overlap, **Then** both stay, shown side by side so both names can be read.
2. **Given** 3 tasks that share a moment, **When** the user drops or resizes a 4th task so it also covers that moment, **Then** the change is not applied, the task returns to where it was, and an error says a time slot can hold at most 3 tasks.
3. **Given** a drag that would break the cap, **While** the user is still dragging, **Then** the board shows that the drop isn't allowed there.
4. **Given** a task at 12:00–13:00, **When** the user adds or edits another task to 12:30–13:30 in the task dialog, or asks Buddy to, **Then** both tasks keep their times and show side by side.
5. **Given** 3 tasks that share a moment, **When** the user adds a 4th at that moment in the task dialog or through Buddy, **Then** nothing is saved. The dialog shows the cap error, and Buddy replies that the slot is full.

---

### User Story 4 - Push mode with live preview (Priority: P2)

"Gap clear" is renamed "Push mode" and stays off by default. When the user turns it on, a notice says: "Push mode is on: moving or resizing a task pushes the other tasks." In Push mode a task pushes the tasks in the direction it moves: dragging down pushes the tasks after it down, and dragging up pushes the tasks before it up. Tasks on the other side stay put. The pushed tasks slide along live (animated), so the user sees the result before dropping.

**Why this priority**: Push mode already exists. This makes it clear when it's on and shows its effect before the drop.

**Independent Test**: Turn on Push mode and check that the notice appears. Drag a task down by 30 min: the tasks after it slide down by 30 min while dragging and stay there after the drop. Drag a task up by 30 min: the tasks before it slide up by 30 min the same way.

**Acceptance Scenarios**:

1. **Given** Push mode is off, **When** the user drags a task, **Then** only that task moves.
2. **Given** the board, **When** the user turns Push mode on, **Then** a notice says Push mode is on and that changing a task's size or position pushes the tasks after it, and the toolbar shows Push mode as active.
3. **Given** Push mode is on, **When** the user moves a task down by N minutes, **Then** every task that started at or after the dragged task's original start moves down by N minutes, animated live during the drag. Tasks before it stay put.
4. **Given** Push mode is on, **When** the user moves a task up by N minutes, **Then** every task that started at or before the dragged task's original start moves up by N minutes, animated live during the drag. Tasks after it stay put.
5. **Given** Push mode is on, **When** the user makes a task N minutes longer, **Then** every task that started at or after the task's original end moves down by N minutes. Making a task shorter moves no other task.
6. **Given** Push mode is on, **When** the user drags a task so that it passes at least half of another task, **Then** the two swap places (the gap between them is kept, nothing else is pushed), and the dragged task shows in its new slot at once. *(Removed by F017: Push mode only pushes; swapping is the Normal mode rule for Overlay-off tasks.)*
7. **Given** Push mode is on, **When** the pushed result would put 4 tasks at the same moment, **Then** the same error as Story 3 applies and nothing changes.

### Edge Cases

- Push mode swap: exactly half passed counts as passed; passing several tasks swaps with each in turn, nearest first. *(Removed by F017: Push mode only pushes; swapping is the Normal mode rule for Overlay-off tasks.)*
- The pointer is released or cancelled (for example by an incoming call or a tab switch) during the 0.1s hold or during a drag: no change is made and the highlight clears.
- The user moves more than a few pixels before 0.1s: this counts as a scroll and no drag starts.
- Push mode pushes a task past 24:00: it wraps to the next morning as an overnight task, as dragging does today (F011).
- Push mode would push a task above 00:00: the drag stops there, since no task can start before 00:00.
- An overnight task (two blocks) counts as covering both its evening and morning times for the overlap cap.
- The user changes the date or the Weekday/Weekend tab while a save is pending: the save finishes against the board it was made on, and an error only shows if it fails.
- The Reflection compare view: Push mode acts on the plan board only (same as Gap clear today). The hold, instant result and overlap cap apply to both boards.
- The user has "reduce motion" turned on: tasks move to their new positions without the slide animation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A drag (move or resize) MUST start only after the user presses and holds a task for 0.1s without moving more than a few pixels. This applies to mouse and touch.
- **FR-002**: Moving the pointer before the 0.1s hold is over MUST scroll the board and MUST NOT move the task (touch).
- **FR-003**: When the hold completes, the task MUST be visibly highlighted as ready to drag until the drag ends.
- **FR-004**: A tap or click with no hold and no movement MUST still open the task dialog.
- **FR-005**: On drop, the board MUST show the dropped layout immediately and keep it while the change saves.
- **FR-006**: While a drop is saving, the board MUST show a three-dot waiting indicator and MUST block drag, resize, add, edit, delete and mark-as-done on that board.
- **FR-007**: If the save fails, every changed task MUST return to its position before the drag, and an error message MUST show at the bottom of the screen, giving the reason when there is one (for example the 3-task cap).
- **FR-008**: Tasks MUST be allowed to overlap in time. Overlapping tasks MUST be shown side by side, each with a readable name.
- **FR-009**: No moment of the day MUST be covered by more than 3 tasks. A move or resize that breaks this MUST be refused: no save is sent, the board returns to its state before the drag, and an error says a time slot can hold at most 3 tasks.
- **FR-010**: During a drag that would break FR-009, the board MUST show that the drop isn't allowed there.
- **FR-011**: "Gap clear" MUST be renamed "Push mode". It is off by default, and the toolbar MUST show whether it is on.
- **FR-012**: Turning Push mode on MUST show a notice that Push mode is on and that changing a task's size or position pushes the other tasks.
- **FR-013**: In Push mode, moving a task down by N minutes MUST shift every task that started at or after its original start down by N, and moving it up by N minutes MUST shift every task that started at or before its original start up by N. Making a task N minutes longer MUST shift every task that started at or after its original end down by N. Tasks on the other side of the drag MUST stay where they are, and making a task shorter MUST NOT move any other task. Exception: when a move passes at least half of another task (its midpoint is at or behind the dragged task's live leading edge), nothing is pushed; the dragged task swaps places with each passed task, nearest first, keeping the gap between each pair. *(Removed by F017: Push mode only pushes; swapping is the Normal mode rule for Overlay-off tasks.)*
- **FR-014**: In Push mode, the tasks being pushed MUST move live during the drag with a slide animation. The animation MUST be skipped when the user's device asks for reduced motion.
- **FR-015**: FR-001 to FR-014 MUST apply to every timeline board: Today, Default routine, Onboarding and Reflection compare. The circle view keeps its current behaviour.
- **FR-016**: Moving and resizing MUST still be possible without dragging, through the task dialog (as today).
- **FR-017**: Saving a task, from the board, the task dialog or Buddy, MUST keep it at exactly the time given and MUST NOT move any other task. Only Push mode moves other tasks.
- **FR-018**: Every save MUST be checked against the 3-task cap, however the change was made. A refused save changes nothing and gives the reason "A time slot can hold at most 3 tasks."
- **FR-019**: All tasks changed by one drag, pushed tasks included, MUST be saved together. The cap is checked on the end result, not task by task, and either every task is saved or none is.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A quick swipe that starts on a task scrolls the board and moves no task, in 10 out of 10 tries on a phone.
- **SC-002**: After a drop, the task never shows at its old position before the save completes (no visible jump back).
- **SC-003**: When a save fails, the board shows the pre-drag layout and an error within 1 second of the failure.
- **SC-004**: A 4th task is never saved into a moment that already has 3 tasks.
- **SC-005**: In Push mode, the user can see where every pushed task will land before releasing the drag.
- **SC-006**: The owner confirms the new drag feel by hand on phone and desktop (the draft's "Done when").

## Assumptions

- This needs a backend change. Every task add and update (board, task dialog, Buddy) runs an automatic push today. That push is removed, and the server checks the 3-task cap instead (FR-017 to FR-019). Days saved before the change have no overlaps, because the push kept tasks apart, so no data fix is needed.
- Reality (reflection) tasks were never pushed by the server. The board applies the cap to them, but the server does not check it there.
- Side by side means the board column is split into up to 3 lanes where tasks overlap. Tasks that don't overlap keep the full width.
- After a successful save, the board reloads from the server as today. If the server's result is the same as the preview, nothing moves.
- The error message reuses the app's existing bottom-of-screen notice style. If none fits, a simple message bar at the bottom is used.
- "A few pixels" means the current 5px click threshold.
- The Push mode notice is shown each time Push mode is turned on and disappears on its own or when dismissed. It is not shown on page load.
- Out of scope: new drag behaviour for the circle (radial) view. Its saves still follow FR-017 and FR-018.
