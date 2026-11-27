# Research: Timeline drag UX improvements

## R1. Hold-to-drag without breaking scroll

- **Decision**: `.ob-board-task` and its resize handle change from `touch-action: none` to `pan-y`, so the browser can scroll on a swipe. On `pointerdown`, store the press (no pointer capture yet) and start a 150 ms timer:
  - The pointer moves more than 5 px before the timer fires: cancel. On touch the browser scrolls and sends `pointercancel`; on a mouse nothing happens.
  - `pointerup` before the timer with less than 5 px of movement: it's a tap, so open the task dialog, as today.
  - The timer fires: arm the drag. Set `dragState` (the existing `.is-dragging` style is the highlight), call `setPointerCapture` on the task's `main` part (try/catch, since the pointer may be gone), and set `armedRef`. A `touchmove` listener on the scroll container, added with `{ passive: false }`, calls `preventDefault()` while armed, so the finger drags the task instead of the page.
  - `pointerup` after arming with no movement: clear, with no dialog and no save.
  - Long-press side effects are suppressed: `-webkit-touch-callout: none` and `user-select: none` on task cards, and `contextmenu` is prevented while a press is pending or armed.
- **Rationale**: this is how mature drag libraries delay a touch drag (a delay plus a tolerance, and a non-passive `touchmove` that cancels scrolling once active). React attaches `touchmove` as passive, so the listener must be added by hand in an effect.
- **Alternatives**: `touch-action: none` with a hand-written scroll (janky, and loses momentum scrolling); a drag library such as dnd-kit (a new dependency for one interaction; Constitution IX).

## R2. Instant result and blocking while saving

- **Decision**: on a valid drop, `pending = Map<taskId, {start, duration}>`, and the board renders positions from `pending` before the stored routine. It awaits `onPersistTaskChange(tasks)`. Every page already resolves that promise only after its routine state is reloaded (`useDailyPlan.persistTasks` → `afterChange`; `useDefaultRoutines.persistTaskChange` → `refreshRoutine`; `useReflectionMode.persistTasks` → `setReflection`), so clearing `pending` afterwards causes no flicker.
  - While `pending` is set, the section is `aria-busy`, the task layer has `pointer-events: none`, the track ignores clicks, and the toolbar wrapper is `inert`. A three-dot indicator with `role="status"` and hidden text "Saving…" is shown. Scrolling still works.
  - On failure: clear `pending` (the routine prop is unchanged, because a refused or failed save stores nothing) and show a `BoardNotice`. The message is the `ApiError` message for a 4xx, otherwise "Something went wrong. Your change wasn't saved."
  - `EditingBoard` no longer calls `onPersistError`: the board reports the error itself. This avoids a second message from the Default routine banner. `RadialBoard` keeps using `onPersistError`.
- **Alternatives**: patch the page's routine state optimistically (touches 3 hooks and duplicates logic per page); a request queue that allows edits while saving (the spec asks to block).

## R3. Push rules (pure function `dragPreview.ts`)

- **Decision**: `previewPositions(tasks, change, pushMode)` returns the new `{start, duration}` of every task that moves, the dragged one included.
  - **Move by d > 0**: the dragged task, plus (Push mode) every other task with `start ≥ originalStart`, moves by d.
  - **Move by d < 0**: the dragged task, plus (Push mode) every other task with `start ≤ originalStart`, moves by d.
  - **Resize longer by d**: (Push mode) every task with `start ≥ originalStart + originalDuration` moves by +d.
  - **Resize shorter**: no other task moves.
  - **Swap (Push mode, move only)**: if the live edge has reached a task's midpoint (down: midpoint > old end and ≤ live end; up: midpoint < old start and ≥ live start), no pushing. The dragged task swaps with each passed task in turn (nearest first), keeping the gap: down, the passed task takes the dragged task's current start and the dragged task ends where it ended; up, mirrored.
  - **Bounds**: d is clamped so every moved task starts within 00:00–23:55. The drag simply stops there, and ends may still pass 24:00 (F011).
- **Rationale**: this matches spec FR-013, and it's symmetric and easy to test. The board calls it on every move (the preview) and on the drop (the save list).

## R4. Overlap cap (UI `overlapCap.ts`, API `TaskTimeFunctions.requireOverlapCap`)

- **Decision**: count the tasks covering each minute of a 1440-slot cycle (an overnight task wraps). The cap is broken if any minute covered by a **changed** task (new, moved or resized) has more than 3 tasks. Unchanged tasks are never blamed, so a rename or a done-toggle can't fail on old data.
- **Rationale**: one simple, exact rule shared by both sides; O(n × 1440) is trivial for a day's tasks.
- **Alternatives**: event-sweep intervals (more code, no gain at this size); counting pairs of overlapping tasks (would wrongly refuse a long task that overlaps three short ones at different times; the spec says "at the same moment").

## R5. Backend: remove the auto-push, check the cap on the end result

- **Decision**: delete `shiftOverlappingTasks`, `standardiseTasks` and `shift` from `TaskTimeFunctions`, and add `requireOverlapCap(allTasks, changedTasks, start, duration)`, which throws `ResponseStatusException(409, "A time slot can hold at most 3 tasks.")`.
  - In `add{Daily,Default}Tasks`: add the new tasks to the routine's list, then check the cap with the new tasks as changed, then save.
  - In `update{Daily,Default}Tasks`: first apply every update (remember the tasks whose start or duration changed, per routine), then check each affected routine once, then save.
  - Because the methods are `@Transactional`, a 409 stores nothing (FR-019). `GlobalExceptionHandler` already maps `ResponseStatusException` to `ApiError` with the reason as `message`.
  - Buddy's tools call these services and already return `"Failed to …: " + e.getMessage()`, so Buddy hears why.
- **Scope**: the routine create/replace endpoints and reflection tasks never pushed and are unchanged.
- **Alternatives**: keep the server push and add a "no push" flag for drags (two behaviours; the draft asks to disable the default push).

## R6. Side-by-side lanes (`taskLanes.ts`)

- **Decision**: lay out the rendered segments (an overnight task's `main` and `wrap` parts are separate blocks).
  - Sort by start. A cluster continues while the next start is before the cluster's latest end.
  - Inside a cluster, give each block the first lane that is free (lane end ≤ start). `lanes` is the number of lanes the cluster uses.
  - Render `left: lane/lanes`, `width: 1/lanes`. A block with no overlap stays full width.
- **Rationale**: the standard calendar layout; at most 3 lanes, because of the cap.

## R7. Push mode label and notice

- **Decision**: rename the prop to `pushMode` / `onTogglePushMode` everywhere. The label is "Push mode" (`aria-pressed`, "✓ Push mode" when on), and the track outline class is renamed. `BoardToolbar` shows a `BoardNotice` (`role="status"`, auto-hide after 5 s, dismiss button) when the toggle goes from off to on: "Push mode is on: moving or resizing a task pushes the other tasks." The toolbar renders its tools twice (inline and "More"), so the notice is rendered once, outside them.
- `BoardNotice` reuses the `.ui-notice-region` / `.ui-notice` primitives (fixed at the bottom of the screen), with `role="alert"` for errors.
