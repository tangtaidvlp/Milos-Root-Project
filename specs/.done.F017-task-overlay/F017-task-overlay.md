# F017 – Task overlay

**Type**: Feature

## Summary

A task gets an "Overlay" setting (off by default). Only tasks with Overlay on may overlap other tasks when dragged; dragging an Overlay-off task onto another swaps the two.

## Problem / Motivation

Tasks overlap by accident when dragged. Most tasks should never overlap; only a few (e.g. Sleep) should.

## Users

Signed-in user editing the Today board or a default routine (timeline view).

## What the user should be able to do

- Turn "Overlay — Allow this task to overlap other tasks" on or off in the Edit task dialog (design: `resources/edit-task-overlay-toggle.png`). New tasks have it off.
- Drag an Overlay-off task over another task: once it covers at least half of that task, the other task moves into the dragged task's original slot at once. The dragged task keeps following the pointer; on release it lands in the other task's old position.
- Drag an Overlay-on task over other tasks: it overlaps, as today (max 3 at the same moment).

## Rules & Constraints

- The dragged task's setting decides. Dropping an Overlay-on task on an Overlay-off task just overlaps.
- Swap trigger: the dragged task covers at least half of the other task (same rule as the T002 Push mode swap).
- Landing: keep the gap between the pair, like the T002 swap (down: the other task starts at the dragged task's original start, the dragged task ends at the other task's old end; up: mirrored). Passing several tasks swaps with each in turn, nearest first. A swap never creates a new overlap.
- Applies in Normal and Push mode. In Push mode, Overlay-on tasks keep pushing.
- Resize: an Overlay-off task cannot be stretched into the next task; it stops at its edge.
- The setting is saved on default-routine and daily tasks and copied when a day is created or reset from the default routine.
- Existing tasks become Overlay off; no data is rewritten (existing overlaps stay).

## Out of Scope

- Validating overlaps typed in the dialog or created by Buddy (only drag enforces the rule; no backend check).
- Circle (radial) view.

## How we know it works

- New task: Overlay toggle is off. Turning it on and saving keeps it on after reload.
- Overlay off: drag A down onto B past half → B shows in A's old slot during the drag; on release A sits where B was; reload shows the same.
- Overlay on: drag over another task → they overlap side by side.
- Overlay off: resizing into the next task stops at its start.
