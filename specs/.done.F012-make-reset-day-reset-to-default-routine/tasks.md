# Tasks: Reset day to default routine

**Input**: `specs/F012-make-reset-day-reset-to-default-routine/` (plan, spec, research, data-model, contracts, quickstart)

**Tests**: Included. The draft asks for backend testing, and the constitution (II) requires component tests per flow and one e2e journey.

**Paths**: `BE` = `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/`, `BT` = `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/`, `FE` = `ui-personal-routine-manager/src/features/`.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

None. No new dependencies or schema.

## Phase 2: Foundational

- [X] T001 Make Reset day optional in `FE/onboarding/components/BoardToolbar.jsx`: add props `onResetDay` (optional) and `resetDisabled` (default false); render the Reset day button only when `onResetDay` is given, with `disabled={resetDisabled}`. Update the JSDoc.
- [X] T002 In `FE/onboarding/components/EditingBoard.jsx`: remove `handleResetSchedule`, the `resetSignal` prop, `lastResetSignalRef` and its effect; add optional props `onResetDay` and `resetDisabled` and pass them to `BoardToolbar`; update the JSDoc. (Do not touch `completedTasks`: it is still used for optimistic ticks.) After this, setup boards (Onboarding/Default routine) show no Reset day (FR-009).
- [X] T003 In `FE/reflection/components/CompareBoards.jsx`: remove `resetSignal` state and prop; accept `onResetDay` and `resetDisabled` props and pass them to `BoardToolbar`. Update the doc comment ("Reset day acts on the plan only").

**Checkpoint**: `pnpm lint && pnpm build` pass; no board shows Reset day yet.

---

## Phase 3: User Story 1 - Reset a day to its default routine (P1) 🎯 MVP

**Goal**: Reset day on Today, after confirmation, replaces the day's plan with a fresh copy of its default routine.

**Independent Test**: quickstart steps 1–5.

### Tests

- [X] T004 [US1] Component tests in `BT/component/DailyRoutineComponentTest.java` for `POST /api/routine-manager/daily-routine/{userId}/{date}/reset` (contract `contracts/reset-and-copy-api.md`), using the existing helpers and `MutableClock`:
  - weekday edited (task added, one moved, one completed) → 204, then GET returns exactly the Weekday template tasks (name, startTime, durationMinutes, color), all `completed=false`;
  - a Saturday with a Weekend routine that has tasks → equals the Weekend tasks; a Saturday with an empty Weekend routine → equals the Weekday tasks;
  - a future date with no stored day → 204 and the day is stored with the template tasks;
  - past date → 400 with the full `ApiError` body, message `Past days can't be reset`, and the day unchanged;
  - another user's `userId` (auth on) → 403 `ApiError`;
  - a day with a reflection → the reflection's tasks are unchanged after the reset.

### Implementation

- [X] T005 [US1] In `BE/service/DailyRoutineService.java`: extract the template→`DailyTask` copy from `createDailyRoutineFromDefault` into a private `copyTemplateTasks(DefaultRoutine template, DailyRoutine target)` (sets `completed=false`, the colour, `dailyRoutine`; sets `target.colorCursor` = the template's). Add `@Transactional public void resetToDefault(User user, LocalDate date)`: if `DayRules.isPast(date, LocalDate.now(clock))`, throw `ResponseStatusException(BAD_REQUEST, "Past days can't be reset")`; find the day by user+date, or `createDailyRoutineFromDefault` and return; otherwise `routine.getTasks().clear()` (orphanRemoval), `defaultRoutineService.resolveTemplateFor(user, date)`, `copyTemplateTasks`, save. Do not touch the reflection or chat.
- [X] T006 [US1] In `BE/api/DailyRoutineController.java`: inject `CurrentUserGuard`; add `@PostMapping("/daily-routine/{userId}/{date}/reset")` (`@DateTimeFormat(iso = DATE) LocalDate date`), which calls `resetToDefault(userGuard.requireUser(userId), date)` and returns `ResponseEntity.noContent()`. Run T004 → green.
- [X] T007 [P] [US1] In `FE/daily/api/dailyRoutineTasks.ts`: add `resetDailyRoutine(userId: string, date: string): Promise<void>`, a POST to `/api/routine-manager/daily-routine/${userId}/${date}/reset` via `apiRequest`, following the file's existing URL pattern.
- [X] T008 [US1] In `FE/daily/pages/DailyRoutinePage.jsx`: add `resetConfirmOpen` and `isResetting` state, and `ConfirmDialog` (`components/ConfirmDialog.tsx`) with the message "Replace all tasks on this day with a fresh copy of your default routine? Your reflection stays as it is." and `confirmLabel="Reset day"`. On confirm, call `resetDailyRoutine(userId, selectedDate)`, then `afterPlanChange()` (which reloads the plan and the reflection), then close. On error, keep the board, show the page's existing error message pattern, and close. Compute `isPast = selectedDate < todayValue`. Pass `onResetDay={() => setResetConfirmOpen(true)}` and `resetDisabled={isPast}` to both `EditingBoard` (single) and `CompareBoards` (compare).
- [X] T008a [US1] In `ui-personal-routine-manager/src/components/ConfirmDialog.tsx` (FR-003, FR-010): Escape calls `onCancel` (unless `isLoading`); when it opens, focus goes to the Cancel button; when it closes, focus returns to the element that had focus before. Add a `loadingLabel` prop (default `'Deleting...'`, so the existing delete dialog is unchanged).
- [X] T008b [US1] In `FE/daily/pages/DailyRoutinePage.jsx` (FR-004): add `resetError` state, shown as `<p role="alert">` above the board ("Couldn't reset the day. Nothing was changed."); clear it on the next reset attempt and on a date change.
- [X] T009 [US1] Add a reset journey to `ui-personal-routine-manager/e2e/today-board.spec.ts`: after onboarding, add a task on Today → open "More" if needed → Reset day → dialog → Cancel (task still there) → Reset day → confirm → the added task is gone and the default tasks are shown; reload → same. Also check that the button is disabled after choosing yesterday.

**Checkpoint**: US1 works end to end (quickstart 1–5).

---

## Phase 4: User Story 2 - Copy Weekday routine to Weekend (P2)

**Goal**: The "Copy Weekday to Weekend" button replaces the Weekend routine's tasks with copies of the Weekday ones, after confirmation.

**Independent Test**: quickstart steps 6–7.

### Tests

- [X] T010 [P] [US2] Component tests in `BT/component/DefaultRoutineComponentTest.java` for `POST /api/v1/default-routine/users/{userId}/copy-weekday-to-weekend`: different Weekday/Weekend routines → 204; Weekend tasks now equal Weekday tasks (name, description, startTime, durationMinutes, color); the old Weekend tasks are gone; Weekday is unchanged. An empty Weekday → empty Weekend. Another user's `userId` (auth on) → 403 `ApiError`.

### Implementation

- [X] T011 [US2] In `BE/service/DefaultRoutineService.java`: add `@Transactional public void copyWeekdayToWeekend(User user)`: load DAILY by user (404 `Default routine not found` if missing); get-or-create WEEKEND by user (reuse the `getOrCreateDefaultRoutine` logic); `weekend.getTasks().clear()`; add a new `RoutineTaskTemplate` for each DAILY task, copying name, description, startTime, durationMinutes and color; set `weekend.colorCursor` = DAILY's; save.
- [X] T012 [US2] In `BE/api/DefaultRoutineController.java`: inject `CurrentUserGuard`; add `@PostMapping("/users/{userId}/copy-weekday-to-weekend")`, which calls `copyWeekdayToWeekend(userGuard.requireUser(userId))` and returns 204. Run T010 → green.
- [X] T013 [P] [US2] In `FE/onboarding/api/defaultRoutine.ts`: add `copyWeekdayToWeekend(userId: string): Promise<void>` (POST via `apiRequest` to `/api/v1/default-routine/users/${userId}/copy-weekday-to-weekend`).
- [X] T014 [US2] In `FE/onboarding/components/DefaultRoutineEditor.tsx`: add a "Copy Weekday to Weekend" button (`ui-btn ui-btn-ghost`) through `EditingBoard`'s `toolbarMenuActions` (folds into "More" on narrow screens), and a `ConfirmDialog` with the message "Replace all Weekend tasks with a copy of your Weekday routine?" and `confirmLabel="Copy"`. On confirm, call `copyWeekdayToWeekend(userId)`, then `routines.refreshRoutine('weekend')`. On error, call `routines.handleSaveError(error)`. Disable the button while copying. This covers both the Onboarding and Default routine pages.

**Checkpoint**: quickstart 6–7 pass.

---

## Phase 5: Polish

- [X] T015 [P] Update `ui-personal-routine-manager/CLAUDE.md`: "Board API" (remove `resetSignal`; add `onResetDay`/`resetDisabled`), the daily bullet (Reset day replaces the plan from the default routine after a confirm, disabled on past days), and the default routine editor bullet (Copy Weekday to Weekend).
- [X] T016 [P] Update `ms-personal-routine-manager/CLAUDE.md` endpoint notes with the two new endpoints, if it lists endpoints.
- [X] T017 Run `./gradlew test` (backend), then `pnpm lint && pnpm test && pnpm test:e2e` (frontend). Walk through quickstart 1–8 by hand. (Automated runs green 2026-11-24; the visual walkthrough is left to the owner.)

---

## Dependencies & Execution Order

- Phase 2 (T001→T002→T003) blocks the frontend tasks of both stories. The backend tasks of US1/US2 can start right away.
- US1: T004 → T005 → T006; T007 ∥ backend; T008 after T002, T003, T007; T009 after T006 and T008.
- US2 is independent of US1: T010 → T011 → T012; T013 ∥; T014 after T002 and T013.
- Polish after both stories.

## Parallel Examples

- US1: T004 (BE test) ∥ T007 (FE api).
- US2: T010 (BE test) ∥ T013 (FE api); the whole US2 backend can run alongside US1.

## Implementation Strategy

MVP = Phase 2 + US1 (the button finally works on Today). Then US2. Ship them together or one after the other; both are additive and backward compatible.
