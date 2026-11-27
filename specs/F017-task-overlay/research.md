# Research: Task overlay

## R1 Storage and "absent keeps"

- **Decision**: `Boolean overlay` on `DailyTask` and `RoutineTaskTemplate`, column `boolean not null default false` (same pattern as `color_cursor`). `@PrePersist` sets null to false. Updates change it only when sent (null keeps), like `color` (F005 R4). Copies (day from default routine, reset day, Weekday → Weekend) copy it.
- **Rationale**: several UI paths send partial tasks (done toggle, drag save) and the AI tools build update objects without it; a primitive would silently reset it to false.
- **Alternatives**: primitive `boolean` + always send from every caller (fragile); DTO refactor (out of scope).

## R2 Drag rules (UI, `dragPreview.ts`)

`TimedTask` gains `overlay?: boolean`. Only `overlay === false` uses the new rules; `true` or missing (Reality tasks) keeps T002 behaviour.

- **Move** (Normal mode only; Push mode keeps T002 for every task): run the T002 `swapPassed` (half rule, gap kept, nearest first). Nothing is pushed.
  - Passed tasks: they move at once (preview).
  - Dropped slot of the dragged task: the swap result.
  - No task passed: dropped slot = live slot, then **edge stop** (FR-011): if it overlaps a task it did not overlap at its original slot, snap against that task's near edge (down: end = its start; up: start = its end). If the snapped slot still overlaps such a task or leaves 00:00–24:00, use the original slot.
- **Resize, Normal mode**: end clamped to the start of the nearest task that starts at or after the original end. Push mode: T002 push.
- **Rendering**: while dragging an Overlay-off task, the dragged task is drawn at the pointer (live start); the map holds its drop slot, which is what is saved. Overlay-on keeps T002 rendering (snaps to the map slot).
- **Rationale**: reuses tested T002 code; "pre-existing overlap ignored" keeps old data from jumping.

## R3 Dialog

- **Decision**: a row under Duration: label "Overlay", description "Allow this task to overlap other tasks", native `<input type="checkbox" role="switch">` styled as a switch with tokens (`TaskEditModal.module.css`). New `showOverlay` prop (default true); the Reality dialog passes false. The value is sent as `overlay` on create and edit.
- **Design**: `resources/edit-task-overlay-toggle.png` (only this row; other mockup differences are out of scope).
