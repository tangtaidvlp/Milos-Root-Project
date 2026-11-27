# Tasks: Task overlay (F017)

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/task-overlay.md](contracts/task-overlay.md), [quickstart.md](quickstart.md)

Paths: `ms/` = `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/`, `ms-test/` = `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/`, `ui/` = `ui-personal-routine-manager/`.

Tests are included (constitution II).

## Phase 1: Setup

None. Branches `feat/F017-task-overlay` already exist in root, `ms-` and `ui-`.

## Phase 2: Foundational (blocks all stories)

- [X] T001 [P] Add `overlay` to `ms/model/DailyTask.java` and `ms/model/RoutineTaskTemplate.java`: `Boolean overlay`, `@Column(nullable = false, columnDefinition = "boolean not null default false")`, plus `@PrePersist` that sets null to `false` (research R1). JSON name `overlay`.
- [X] T002 [P] Add `overlay?: boolean` to `BoardTask` in `ui/src/features/board/types/board.ts` and to the daily / default-routine task types (`ui/src/features/daily/types/`, `ui/src/features/default-routine/types/`), if they don't inherit from `BoardTask`.

## Phase 3: User Story 1 – Mark a task as allowed to overlap (P1)

**Goal**: toggle in the dialog, saved, copied. **Independent test**: quickstart rows 1–3.

- [X] T003 [US1] Component tests in `ms-test/component/DailyRoutineComponentTest.java` and `ms-test/component/DefaultRoutineComponentTest.java`: create without `overlay` → response `false`; create with `true` → `true`; PUT without `overlay` keeps `true`; PUT with `false` sets it; reset day / day created from default copies `true`; Copy Weekday to Weekend copies `true`.
- [X] T004 [US1] In `ms/service/DailyRoutineService.java` (`updateDailyTasks`, `copyTemplateTasks`) and `ms/service/DefaultRoutineService.java` (`updateDefaultTasks`, `copyWeekdayToWeekend`): copy `overlay` on copies; on update set it only when not null ("null on update → unchanged"). Make T003 pass.
- [X] T005 [US1] `ui/src/features/board/components/TaskEditModal.tsx` (+ `TaskEditModal.module.css`): `TaskFormValue.overlay?: boolean`; new prop `showOverlay?: boolean` (default `true`); row under Duration matching `resources/edit-task-overlay-toggle.png`: label "Overlay", text "Allow this task to overlap other tasks", native `<input type="checkbox" role="switch">` styled as a switch (tokens only, ≥ 24px target, visible focus). Starts from `draftTask.overlay ?? false`; sent as `overlay` on create and edit (only when `showOverlay`).
- [X] T006 [US1] Pass `overlay` through the create/update paths: `ui/src/features/daily/hooks/useDailyPlan.ts` (`submitTask`), `ui/src/features/default-routine/hooks/useDefaultRoutines.ts` (`submitTask`), and the draft built when opening the dialog for an existing task (Daily page, `DefaultRoutineEditor`). In `ui/src/features/daily/pages/DailyRoutinePage.tsx` pass `showOverlay={modalTarget !== 'reality'}`.

## Phase 4: User Story 2 – Overlay-off drag swaps (P1)

**Goal**: swap on half, no push, edge stop, dragged task follows pointer. **Independent test**: quickstart rows 4–7.

- [X] T007 [US2] Unit tests in `ui/src/features/board/utils/dragPreview.test.ts` for `overlay: false` dragged task: swap down/up with gap kept (Normal and Push mode); less than half → no other task moves and drop slot snaps to the neighbour's edge (down: end = its start; up: start = its end); edge slot still overlapping another task → original slot; pre-existing overlap ignored; several passed → successive swaps; Overlay-on and missing `overlay` unchanged (T002 results).
- [X] T008 [US2] Implement in `ui/src/features/board/utils/dragPreview.ts`: `TimedTask.overlay?: boolean`; when the dragged task has `overlay === false` and mode is `move`, use `swapPassed` in both modes, else the edge stop (research R2); never push. Make T007 pass.
- [X] T009 [US2] `ui/src/features/board/components/EditingBoard.tsx`: include `overlay` in the `TimedTask` list given to `previewPositions`; during an active move of an Overlay-off task, draw the dragged task at the live pointer start (others from the preview map); save from the map as today.

## Phase 5: User Story 3 – Overlay-on overlaps; Overlay-off resize stops (P2)

**Goal**: FR-008, FR-009. **Independent test**: quickstart rows 8–9.

- [X] T010 [US3] Unit tests in `ui/src/features/board/utils/dragPreview.test.ts`: Overlay-off resize in Normal mode clamps the end to the start of the nearest task starting at or after the original end; Push mode resize pushes as T002; Overlay-on move over an Overlay-off task overlaps (no swap).
- [X] T011 [US3] Implement the resize clamp in `ui/src/features/board/utils/dragPreview.ts`. Make T010 pass.

## Phase 6: Polish

- [X] T012 E2E in `ui/e2e/today-board.spec.ts`: new test — the dialog shows Overlay off for a new task; turn it on, save, reopen → on; two Overlay-off tasks, mouse-drag one over the other by more than half → swapped times shown and kept after reload.
- [X] T013 Docs: `ui-personal-routine-manager/CLAUDE.md` (timeline drag bullet: Overlay rule; board API `showOverlay`; status line F017), `ms-personal-routine-manager/CLAUDE.md` if it lists task fields.
- [X] T014 Run `./gradlew test` (ms), `pnpm lint && pnpm test && pnpm build`, `pnpm test:e2e e2e/today-board.spec.ts` (ui).
- [X] T015 Feedback: during a drag the dragged task stays out of the side-by-side lanes and floats full width, so other tasks never shift sideways (`EditingBoard.tsx`).
- [X] T016 Feedback: drag time indicator — red start/end marks and duration in the time column while dragging (`EditingBoard.tsx`, `EditingBoard.module.css`; design `resources/drag-time-indicator.png`).
- [X] T017 Feedback: Push mode pushes every task again, Overlay on or off (T002 rule); the Overlay-off rules apply in Normal mode only (`dragPreview.ts` + tests, spec FR-007).
- [X] T018 Feedback: Push mode never swaps (the T002 half-way swap cut the push short); it keeps shifting the whole rest of the day (`dragPreview.ts` + tests; T002/F017 specs).

## Dependencies

- T001 → T003 → T004. T002 → T005 → T006; T002 → T007 → T008 → T009; T008 → T010 → T011.
- US1 backend (T001, T003, T004) and UI (T002, T005–T011) can run in parallel.
- T012 needs T004, T006, T009. T014 last.

## Parallel examples

- T001 ∥ T002.
- Backend T003–T004 ∥ UI T005–T009.

## Implementation strategy

MVP = US1 + US2 (the setting and the swap). US3 is a small follow-up on the same util.
