---
description: "Tasks for T002 timeline drag UX improvements"
---

# Tasks: Timeline drag UX improvements

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/)

**Tests**: included. The constitution (Principle II) requires unit tests for pure rules, component tests for API flows, and Playwright for touched journeys.

**Paths**: `ms/` = `ms-personal-routine-manager/`, `ui/` = `ui-personal-routine-manager/`, `pkg/` = `ms/src/main/java/com/tom/payment/routinemanager/`, `tpkg/` = `ms/src/test/java/com/tom/payment/routinemanager/`.

## Phase 1: Setup

None: the branches `feat/T002-timeline-drag-ux` already exist in the root repo, `ms/` and `ui/`.

---

## Phase 2: Foundational (blocks all stories)

**Backend track**: no auto-push, plus the 3-task cap (FR-017–FR-019, research R4/R5, [contracts/task-save-api.md](contracts/task-save-api.md))

- [X] T001 In `pkg/funcs/TaskTimeFunctions.java`, delete `standardiseTasks`, `shiftOverlappingTasks`, `shift` and their helpers. Keep `requireValidDuration`. Add `public static final int MAX_PARALLEL_TASKS = 3`, `public static final String OVERLAP_CAP_MESSAGE = "A time slot can hold at most 3 tasks."` and `public static <T> void requireOverlapCap(Collection<T> allTasks, Collection<T> changedTasks, Function<T, LocalTime> start, ToIntFunction<T> durationMinutes)`:
  - Count tasks per minute on a 1440-slot cycle (each task covers `[start, start + duration)`, wrapping past midnight; skip null start).
  - Throw `new ResponseStatusException(HttpStatus.CONFLICT, OVERLAP_CAP_MESSAGE)` when any minute covered by a changed task has more than `MAX_PARALLEL_TASKS` tasks.
  - Update the class Javadoc.
- [X] T002 Rewrite the shift tests in `tpkg/unit/TaskTimeFunctionsTest.java` as cap tests, and keep the duration tests. Cover:
  - 3 at once is OK; a 4th at the same moment → 409 with the message.
  - Touching ends (10:00–11:00 and 11:00–12:00) don't overlap.
  - An overnight task (22:00 + 480) counts at 23:00 and at 05:00.
  - A long task over three short tasks at different times is OK.
  - An unchanged 4-deep cluster elsewhere doesn't fail a changed task.
  - A 1440-minute task covers every minute.
- [X] T003 In `pkg/service/DailyRoutineService.java` (`addDailyTasks`, `updateDailyTasks`) and `pkg/service/DefaultRoutineService.java` (`addDefaultTasks`, `updateDefaultTasks`), remove the push calls.
  - **Add**: append every new task to the routine's task list, call `requireOverlapCap(routine.getTasks(), newTasks, …)`, then `saveAll`.
  - **Update**: first apply every update. A task is "changed" when its `startTime` or `durationMinutes` differs from the stored value; group changed tasks by routine. Then call `requireOverlapCap(routine.getTasks(), changed, …)` once per routine, then `saveAll`.
  - Keep `@Transactional`, so a 409 stores nothing.
- [X] T004 Update the component tests: every refusal check uses `andExpect(error(HttpStatus.CONFLICT))` and also checks the message text.
  - `tpkg/component/DefaultRoutineComponentTest.java`: replace the "one overlap shift" test with "overlapping tasks keep their times" and "a 4th task at the same moment → 409, nothing stored".
  - `tpkg/component/DailyRoutineComponentTest.java`, two tests:
    - A `PUT /api/routine-manager/daily-routine/tasks` batch that moves 2 tasks together and is valid only as a whole → 200, both stored.
    - A batch that leaves 4 tasks at one moment → 409, and neither task changed.

**UI track**: pure rules and the notice (research R2, R3, R4, R6)

- [X] T005 [P] Create `ui/src/features/board/utils/dragPreview.ts` and `dragPreview.test.ts`:
  - `type TimedTask = { id: string | undefined; start: number; duration: number }` (minutes) and `type DragChange = { mode: 'move' | 'resize'; taskId: string | undefined; originalStart: number; originalDuration: number; liveStart: number; liveDuration: number }`.
  - `previewPositions(tasks: TimedTask[], change: DragChange, pushMode: boolean): Map<string | undefined, { start: number; duration: number }>` returns the dragged task plus every pushed task.
  - **Move by d > 0**: (push) other tasks with `start ≥ originalStart` move +d.
  - **Move by d < 0**: (push) other tasks with `start ≤ originalStart` move d.
  - **Resize longer by d**: (push) tasks with `start ≥ originalStart + originalDuration` move +d.
  - **Resize shorter**: nothing else moves.
  - **Bounds**: clamp d so every moved start stays within 0–1435.
  - Tests cover each rule with Push mode on and off, plus both bounds.
- [X] T006 [P] Create `ui/src/features/board/utils/overlapCap.ts` and `overlapCap.test.ts`:
  - `export const MAX_PARALLEL_TASKS = 3`, `export const OVERLAP_CAP_MESSAGE = 'A time slot can hold at most 3 tasks.'` and `breaksOverlapCap(tasks: TimedTask[], changedIds: Set<string | undefined>): boolean`.
  - Same rule as T001: 1440-minute cycle, only changed tasks checked.
  - Tests mirror T002.
- [X] T007 [P] Create `ui/src/features/board/utils/taskLanes.ts` and `taskLanes.test.ts`:
  - `layoutLanes(blocks: { key: string; start: number; end: number }[]): Map<string, { lane: number; lanes: number }>`.
  - Clusters are transitively overlapping blocks sorted by start. Each block gets the first free lane (lane end ≤ start), and `lanes` is the number of lanes the cluster uses.
  - Touching ends don't overlap.
  - Tests: no overlap gives 1 lane; 2 and 3 parallel blocks; a chain A–B, B–C where A and C don't touch (2 lanes, C reuses lane 0); separate clusters are independent.
- [X] T008 [P] Create `ui/src/features/board/components/BoardNotice.tsx`, a bottom-of-screen message reusing `.ui-notice-region` / `.ui-notice` (like `features/settings/components/SettingsSaveNotice.tsx`):
  - Props `{ message: string | null; tone: 'error' | 'info'; onDismiss: () => void }`.
  - The region is always rendered, with `role="alert"` for error and `role="status"` for info.
  - Auto-dismiss after 5 s; a "Dismiss" icon button (`XIcon`).

**Checkpoint**: the backend saves overlaps and enforces the cap; the UI rules are unit-tested.

---

## Phase 3: User Story 1 — Hold to drag, swipe to scroll (P1) 🎯 MVP

**Goal**: a 0.3s hold starts a drag (mouse and touch); a swipe scrolls; a tap opens the dialog.

**Independent Test**: quickstart rows 1–3.

- [X] T009 [US1] In `ui/src/features/board/components/EditingBoard.tsx`, replace the immediate `beginDrag` with the research R1 flow (constants `HOLD_TO_DRAG_MS = 300`; tolerance = the existing `CLICK_DISTANCE_THRESHOLD_PX`):
  - **`pointerdown`** (task body → move, resize handle → resize): store the press in a ref and start the timer. No capture yet. Keep `stopPropagation`.
  - **`pointermove` before arming**: past the tolerance, cancel the press.
  - **`pointerup` before arming**: within the tolerance, call `onRequestEditTask` (move mode only).
  - **Timer fires**: set `dragState` and `armedRef = true`, and `setPointerCapture` on the task's `main` part inside try/catch.
  - **`pointerup` after arming with no change**: clear only.
  - **`pointercancel`**: clear all. Clear the timer on unmount.
  - In an effect, add a `touchmove` listener with `{ passive: false }` on the scroll container that calls `preventDefault()` while `armedRef.current`, and a `contextmenu` listener on the track that prevents the menu while a press is pending or armed.
  - Keep the existing `ignoreTrackClickRef` and `mainPartsRef` behaviour (F011).
- [X] T010 [P] [US1] In `ui/src/App.css`:
  - `.ob-board-task` and `.ob-board-task-resize-handle`: `touch-action: pan-y` (was `none`).
  - `.ob-board-task`: add `user-select: none; -webkit-user-select: none; -webkit-touch-callout: none;`.

**Checkpoint**: US1 works on its own: the save path is unchanged and still reloads.

---

## Phase 4: User Story 2 — Instant result on drop (P1)

**Goal**: the drop shows at once; the board is locked with three dots while saving; a failure reverts it with a bottom message.

**Independent Test**: quickstart rows 4–5.

- [X] T011 [US2] In `ui/src/features/board/components/EditingBoard.tsx` and `EditingBoard.module.css` (research R2, [contracts/board-ui.md](contracts/board-ui.md)):
  - **Pending state**: `pending: Map | null`. A task's displayed `{start, duration}` = drag preview ?? pending ?? stored. On a valid drop, set `pending`, build the update list (same fields as today), and `await onPersistTaskChange`.
    - Success, or no `onPersistTaskChange`: `pending = null`.
    - Failure: `pending = null`, and set the notice to the `ApiError` message when `error instanceof ApiError && status ∈ [400, 500)`, else "Something went wrong. Your change wasn't saved."
    - Remove the `onPersistError` call.
  - **While pending**:
    - The section gets `aria-busy="true"`.
    - Wrap the toolbar in a `<div inert>`.
    - The track gets `data-saving` (CSS: the task layer gets `pointer-events: none`), `handleTrackClick` ignores clicks, and pointerdown is ignored.
    - Render a three-dot indicator with `role="status"` and `<span className="visually-hidden">Saving…</span>`: a pill over the board, using bouncing dots from tokens, with the animation off under `prefers-reduced-motion`.
  - **Notice**: render `<BoardNotice tone="error" …>`.
  - **Props doc**: update the `onPersistTaskChange` / `onPersistError` docs in `ui/src/features/board/types/board.ts` to match the contract.

**Checkpoint**: US1 + US2 give a non-jumping drag.

---

## Phase 5: User Story 3 — Overlapping tasks, at most 3 at once (P2)

**Goal**: overlaps are shown side by side; a 4th parallel task is refused on the board (and on the server via Phase 2).

**Independent Test**: quickstart rows 6–8.

- [X] T012 [US3] In `ui/src/features/board/components/EditingBoard.tsx`, compute the segment blocks from the displayed positions (`taskSegments`) and call `layoutLanes`. Each block's inline style gets `left: lane*100/lanes %`, `width: 100/lanes %` and `right: auto` when `lanes > 1`.
- [X] T013 [US3] In `ui/src/features/board/components/EditingBoard.tsx`, check the cap during the drag with `breaksOverlapCap` (changed ids = every task in the preview map whose position differs from stored).
  - While broken, the dragged block gets `data-blocked="true"`.
  - A blocked drop: clear the drag, save nothing, and show the notice `OVERLAP_CAP_MESSAGE`.
  - In `ui/src/App.css`, `.ob-board-task[data-blocked='true']` gets a danger outline and `cursor: not-allowed`, from tokens only.

---

## Phase 6: User Story 4 — Push mode with live preview (P2)

**Goal**: "Gap clear" becomes "Push mode": it pushes both ways, previews live with animation, and shows a notice when turned on.

**Independent Test**: quickstart rows 9–11 and 13.

- [X] T014 [US4] Rename `gapClearMode` → `pushMode` and `onToggleGapClear` → `onTogglePushMode` in:
  - `ui/src/features/board/types/board.ts`
  - `ui/src/features/board/components/EditingBoard.tsx` (own state too)
  - `ui/src/features/board/components/EditingBoard.module.css` (`.track.gapClear` → `.track.pushMode`)
  - `ui/src/features/board/components/BoardToolbar.tsx`: label `{pushMode ? '✓ Push mode' : 'Push mode'}`, `aria-pressed`, title "When on, moving or resizing a task pushes the other tasks".
  - `ui/src/features/reflection/components/CompareBoards.jsx`
  - `ui/src/features/radial-view/components/RadialBoard.tsx`
  - Comments that mention Gap clear.
- [X] T015 [US4] In `ui/src/features/board/components/BoardToolbar.tsx`, when the toggle goes from off to on, show `<BoardNotice tone="info" message="Push mode is on: moving or resizing a task pushes the other tasks." …>`, rendered once, outside the inline/"More" duplicates.
- [X] T016 [US4] In `ui/src/features/board/components/EditingBoard.tsx`, use `previewPositions(allTasks, change, pushMode)` for the live preview and the drop: the save list = every task in the map, replacing the old Gap clear block. The dragged task's live start/duration come from the clamped map result.
  - In `ui/src/App.css`, `.ob-board-task` transitions `top, height, left, width` over about 0.2s.
  - `.ob-board-task.is-dragging`: no transition on those properties.
  - Inside `@media (prefers-reduced-motion: reduce)`, no transition.

---

## Phase 7: Polish & Cross-Cutting

- [X] T017 Update `ui/e2e/today-board.spec.ts`:
  - Rename the `'Gap clear'` locators to `'Push mode'` (`/Push mode/` when on).
  - Add the test "today board: hold to drag, push mode notice, failed save reverts", with the mouse:
    - Quick press-move-release on a task: its time label is unchanged.
    - Press, wait 400 ms, move down by 1 hour's pixels, release: the label shows the new time and keeps it after reload.
    - Turn Push mode on: the status notice is visible.
    - With `page.route('**/daily-routine/tasks', r => r.abort())`, hold-drag again: the label returns to its old time and the alert is visible.
- [X] T018 [P] Docs:
  - `ui/CLAUDE.md`: the board section covers hold-to-drag, pending save, lanes, cap, Push mode and `BoardNotice`; rename "Gap clear" mentions.
  - `ms/CLAUDE.md`: replace the "Task overlap handling" bullet with "no auto-push; 3-task cap → 409 on add/update (end result, one transaction)".
  - `ms/docs/test-flows.md`: update the `DefaultRoutineComponentTest` / `DailyRoutineComponentTest` rows and the `TaskTimeFunctionsTest` row, with counts.
- [X] T019 Verify:
  - `cd ms && ./gradlew test`
  - `cd ui && pnpm lint && pnpm test && pnpm build`
  - `pnpm test:e2e e2e/today-board.spec.ts` (backend `SPRING_PROFILES_ACTIVE=fast` and `pnpm dev` running)
  - Fix failures.

---

## Dependencies & Execution Order

- The backend track (T001 → T002, T003 → T004) and the UI track (T005–T008 [P]) are independent: run them in parallel.
- **UI stories** touch the same file (`EditingBoard.tsx`), so run them in order T009 → T011 → T012 → T013 → T014 → T015 → T016. T010 [P] can run any time.
- **Polish** (T017–T019) runs after both tracks.

## Parallel Example

```text
Agent A (backend): T001 → T002 → T003 → T004
Agent B (UI):      T005 ∥ T006 ∥ T007 ∥ T008 → T009 → T010 → T011 → … → T016 → T017
Then: T018, T019
```

## Implementation Strategy

MVP = Phase 2 + US1 + US2 (the natural drag). US3 and US4 build on the same board code.
