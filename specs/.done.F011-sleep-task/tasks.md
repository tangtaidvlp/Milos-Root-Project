# Tasks: Sleep task (overnight tasks)

**Input**: `specs/F011-sleep-task/` (plan, spec, research, data-model, contracts/task-time.md, quickstart)

**Tests**: Required by Constitution II and listed in plan.md.

**Paths**:
- `BE` = `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/`
- `BT` = `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/`
- `FE` = `ui-personal-routine-manager/src/features/`

**Lanes** (plan "Execution"): backend tasks touch only `ms-personal-routine-manager/`, and frontend tasks touch only `ui-personal-routine-manager/`. The two lanes run in parallel.

## Phase 1: Setup

None. The branch is `feat/F011-sleep-task`, with no new dependencies and no schema change.

---

## Phase 2: Foundational (blocking)

- [X] T001 [P] Backend: add unit tests to `BT/unit/TaskTimeFunctionsTest.java`:
  - (a) a 05:30 task (30 min) overlapped by a new Sleep 22:00+480 is pushed to 06:00, for both template and daily variants;
  - (b) a 12:00 task is untouched by Sleep 22:00+480;
  - (c) a task ending exactly 24:00 (23:00+60) does not overlap a 00:00 task;
  - (d) a new task 23:00+60 overlapping an existing overnight 22:00+480 pushes it (existing rule).
  These tests must fail first.
- [X] T002 Backend: rewrite overlap in `BE/funcs/TaskTimeFunctions.java` on a 24h cycle (research R2). Compute with minutes, not `LocalTime` end: each task covers `[start, min(start+dur,1440))` plus `[0, start+dur−1440)` when overnight, and two tasks overlap if any of their ranges overlap. Keep the push rule (overlapping sibling `setStartTime(newTask.getEndTime())`, cascade unchanged). Share one private helper for both `standardiseTasks` and `shiftOverlappingTasks`. The helper takes `(startMin, endMin)` pairs, because the cascade grows `insertionEnd` while `insertionStart` stays put: `end <= start` means the range crosses midnight, and `end == start` means a full 24h task. T001 must pass.
- [X] T003 [P] Frontend: create `FE/onboarding/utils/taskSegments.ts` (research R5). It exports `taskSegments(startMinutes: number, durationMinutes: number): { part: 'main' | 'wrap'; start: number; end: number }[]`, returning `main` = `[start, min(start+dur,1440)]` and, only when `start+dur > 1440`, `wrap` = `[0, start+dur−1440]`. Add `FE/onboarding/utils/taskSegments.test.ts` covering: normal task (1 segment), ends exactly at 1440 (1 segment), 22:00+480 (2 segments: 1320–1440, 0–360), 00:00+1440 (1 segment), 06:00+1440 (2 segments).

**Checkpoint**: backend overlap and frontend segment logic are both tested.

---

## Phase 3: User Story 1 – Drag a task past midnight (P1) 🎯 MVP

**Goal**: dragging or stretching past 24:00 saves one overnight task, shown in two linked parts.

**Independent test**: on Default routine, stretch 22:00 to 06:00 and reload. There is one task in two parts.

### Backend lane
- [X] T004 [P] [US1] Component tests in `BT/component/DefaultRoutineComponentTest.java`:
  - POST a task `{"startTime":"22:00","durationMinutes":480}`: 200, a single stored task, response `endTime` `"06:00"`;
  - PUT the same task to 23:00+480: still one task;
  - POST `durationMinutes` 1441 and 0: 400 with the full `ApiError` body (`status`, `error`, `message` = `durationMinutes must be between 1 and 1440`, `timestamp`).
- [X] T005 [P] [US1] The same three cases in `BT/component/DailyRoutineComponentTest.java` for `POST /api/routine-manager/daily-routine/{routineId}/tasks` and `PUT /api/routine-manager/daily-routine/tasks`.
- [X] T006 [US1] Add the duration check `1 ≤ durationMinutes ≤ 1440` → `ResponseStatusException(BAD_REQUEST, "durationMinutes must be between 1 and 1440")` in `addDefaultTasks`/`updateDefaultTasks` (`BE/service/DefaultRoutineService.java`) and `addDailyTasks`/`updateDailyTasks` (`BE/service/DailyRoutineService.java`). Validate before any change is applied. T004 and T005 must pass.

### Frontend lane
- [X] T007 [US1] In `FE/onboarding/components/EditingBoard.jsx`:
  - Use `task.durationMinutes` for the stored duration (remove the `endTime`-based calculation at line ~432).
  - Move: limit start to `0..MINUTES_PER_DAY − SNAP_MINUTES` (the end may pass 24:00). Resize: limit duration to `MIN_DURATION_MINUTES..MINUTES_PER_DAY`. In gap-clear mode, shift tasks with the same start limit.
  - Render each `taskSegments(...)` segment as its own block with the same pointer handlers, `key` `${task.id}-${part}`.
  - Both parts show `formatTime(start) – formatTime(end) · duration`.
  - The done check and delete button go on the `main` part only. The resize handle goes on the last segment.
  - `isActive` is true when now falls inside any segment.
- [X] T008 [P] [US1] Add a CSS hint in `ui-personal-routine-manager/src/App.css` that links the two parts: on `.ob-board-task[data-part="wrap"]`, a square top edge and a dashed top border using existing tokens (no raw colours). Set `data-part` on the segment blocks in T007.

**Checkpoint**: US1 works end to end on both boards.

---

## Phase 4: User Story 2 – Create or edit without dragging (P2)

**Goal**: the form and Buddy create one overnight task.

**Independent test**: "Sleep 22:00, 8h" via the form or via Buddy gives one task 22:00–06:00.

- [X] T009 [P] [US2] Backend: in `BE/service/aitools/DefaultRoutineAiTools.java` (addDefaultRoutineTasks `@Tool` description) and `BE/service/aitools/DailyRoutineAiTools.java` (addDailyRoutineTasks description), replace "If a task crosses midnight, split it into 2 tasks with the SAME name so they share a color." with "A task may cross midnight: create ONE task with its startTime and full durationMinutes (e.g. sleep 22:00 with 480 minutes ends 06:00). Never split it."
- [X] T010 [P] [US2] Frontend: in `FE/onboarding/components/TaskEditModal.tsx`, under the Duration fieldset, show the read-only text `Ends HH:MM (next day)` when start + duration > 1440, and `Ends HH:MM` otherwise. Compute it during render with no new state. Validation stays 1–1440.

---

## Phase 5: User Story 3 – Overnight task on the Daily schedule (P2)

**Goal**: daily copies keep one task, and Now/Next handles the wrap.

**Independent test**: an overnight task in the default routine gives one task in the day's schedule, and Now at 02:00 is Sleep.

- [X] T011 [P] [US3] Backend: component test in `BT/component/DailyRoutineComponentTest.java`. A default routine with Sleep 22:00+480 → creating the day's routine gives exactly one Sleep task with `durationMinutes` 480 and `endTime` `"06:00"`.
- [X] T012 [P] [US3] Frontend: in `FE/daily/utils/nowAndNext.ts`, treat `end <= start` as overnight: current when `minutesOfDay >= start || minutesOfDay < end`, and `minutesLeft = (end − minutesOfDay + 1440) % 1440 || 1440`. The existing `00:00` end rule must keep passing. Add cases to `FE/daily/utils/nowAndNext.test.ts`: Sleep 22:00–06:00 at 23:00 → now Sleep, 420 min left; at 02:00 → now Sleep, 240 min left; at 07:00 → not now.

---

## Phase 6: Polish & cross-cutting

- [X] T013 E2E in `ui-personal-routine-manager/e2e/today-board.spec.ts`: on Today, add "Sleep" at 22:00 with 8h via the task form. Both parts show "22:00 – 06:00", and after a reload there is still one Sleep task (one delete button named "Delete Sleep").
- [X] T014 [P] Update `ms-personal-routine-manager/CLAUDE.md` (overnight tasks: one row; overlap on a 24h cycle; duration 1–1440 → 400) and `ui-personal-routine-manager/CLAUDE.md` (board draws overnight tasks as `main` + `wrap` parts via `taskSegments`; `endTime` may be earlier than `startTime`).
- [X] T015 Gates (done; the manual quickstart walkthrough and Postgres-backed tests are still to do): backend `./gradlew build`; frontend `pnpm build && pnpm lint && pnpm test`; `pnpm test:e2e` for `today-board` (needs a running backend). Walk through the manual steps in quickstart.md.

---

## Dependencies

- T001 → T002. T004/T005 → T006. T003 → T007 → T008.
- US1 needs Phase 2. US2 and US3 depend only on Phase 2 and can run alongside US1.
- T013 needs T006 and T007 (both lanes done). T015 comes last.

## Parallel execution

| Backend sub-agent | Frontend sub-agent |
|---|---|
| T001 → T002 → T004, T005 → T006 → T009 → T011 → backend part of T014 | T003 → T007 → T008 → T010 → T012 → frontend part of T014 |

After both lanes finish: T013, then T015.

## Implementation strategy

MVP = Phase 2 + US1 (T001–T008). US2 and US3 are small and ship in the same release. Backend and UI must deploy together (contract, "Compatibility").
