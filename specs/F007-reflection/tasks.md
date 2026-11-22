# Tasks: Daily Reflection (Plan vs Reality)

**Input**: `specs/F007-reflection/` (plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md)

**Tests**: Included. The project keeps integration tests per feature (backend) and Vitest logic and component tests (frontend).

Paths: `BE` = `ms-personal-routine-manager/`, `FE` = `ui-personal-routine-manager/`.

## Phase 1: Setup

- [X] T001 Write the prod DDL `BE/db/F007-daily-reflection.sql`. It must be idempotent and create:
  - `daily_reflection` (id UUID PK, user_id UUID NOT NULL FK users, reflection_date DATE NOT NULL, color_cursor INTEGER NOT NULL DEFAULT 0, feedback_text TEXT NULL, feedback_at TIMESTAMPTZ NULL, content_updated_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL, UNIQUE (user_id, reflection_date))
  - `reflection_task` (id UUID PK, daily_reflection_id UUID NOT NULL FK, planned_task_id UUID NULL with no FK, name VARCHAR(255) NOT NULL, description VARCHAR(255) NULL, start_time TIME NOT NULL, duration_minutes INTEGER NOT NULL, color VARCHAR(32) NULL)
  - the partial unique index `ux_chat_conv_reflection ON chat_conversation (user_id, routine_date) WHERE type = 'DAILY_REFLECTION'`

## Phase 2: Foundational (blocks all stories)

- [X] T002 [P] Create the entity `BE/src/main/java/com/tom/payment/routinemanager/model/DailyReflection.java`. It maps every column in T001. The user is `@JsonIgnore`. `tasks` is `@OneToMany(cascade ALL, orphanRemoval)` with `@JsonManagedReference`. `@PrePersist` sets createdAt and contentUpdatedAt.
- [X] T003 [P] Create the entity `BE/src/main/java/com/tom/payment/routinemanager/model/ReflectionTask.java`. Its fields are id, plannedTaskId (nullable, plain UUID), name, description, startTime (`@JsonFormat HH:mm`), durationMinutes and color (length 32), plus a `@JsonBackReference` reflection and a read-only `endTime` getter, the same as `DailyTask`.
- [X] T004 [P] Create the repositories `BE/.../repository/DailyReflectionRepository.java` (`findByUser_IdAndReflectionDate`) and `BE/.../repository/ReflectionTaskRepository.java`.
- [X] T005 [P] Create the DTO records in `BE/.../dto/`:
  - `ReflectionView`
  - `ReflectionComparison`, with nested `Counts`, `Item`, `TaskRef` and enum `Status` (AS_PLANNED, CHANGED, SKIPPED, UNPLANNED)
  - `ReflectionFeedbackView` (text, generatedAt, stale)
  - `ReflectionTaskInput` (id, name, description, startTime, durationMinutes, color)
  - `ReflectionChatRequest` (date, message)

  Shapes are defined in contracts/reflection-api.md.
- [X] T006 Implement the comparison in `BE/.../service/reflection/ReflectionComparisonService.java`, following the rules in research R3:
  - a planned task with no live link is SKIPPED
  - a linked task with the same startTime and durationMinutes is AS_PLANNED, otherwise CHANGED
  - a reflection task with no live link is UNPLANNED; this includes a dangling link, and any reflection task after the first that links to the same planned task

  Items are sorted by start time. It also computes plannedMinutes, actualMinutes and the counts.
- [X] T007 [P] Write the unit test `BE/src/test/java/com/tom/payment/routinemanager/ReflectionComparisonServiceTest.java`. It covers all four groups, a renamed task staying CHANGED or AS_PLANNED, a dangling link counting as UNPLANNED, a duplicate link, the totals, and an empty plan.

**Checkpoint**: The model and comparison are ready.

## Phase 3: User Story 1, record what really happened (P1) 🎯 MVP

**Independent test**: Toggle on today and get 4 copied tasks. Edit the reflection and the plan is unchanged. Edit the plan and the reflection is unchanged. Reload and the reflection persists.

- [X] T008 [US1] Implement `BE/.../service/reflection/ReflectionService.java`:
  - `getView(userId, date)`: read only
  - `ensure(userId, date)`: 400 if `date > LocalDate.now()`. It copies the plan from `DailyRoutineRepository.findByUserAndDate` without ever creating a plan, copying name, description, startTime, durationMinutes, color and plannedTaskId = task id. The cursor comes from the plan, else 0. It handles a unique-constraint race by re-reading.
  - `addTasks`, `updateTasks`, `deleteTasks`: validation is name not blank and trimmed, startTime required, durationMinutes 1–1440, and color via `TaskColorService` (assign on add; null keeps it on update). Each method requires the reflection to exist (404) and the date ≤ today (400). Every id must belong to this reflection (404, nothing written). There is no overlap shifting. Each method touches `contentUpdatedAt`.
  - `toView`: builds tasks, plannedTasks, comparison, feedback with stale = feedbackAt < contentUpdatedAt, and nextColor.
- [X] T009 [US1] Implement the controller `BE/.../api/DailyReflectionController.java` at `/api/routine-manager/daily-reflection/{userId}/{date}`, with GET, POST, POST /tasks, PUT /tasks and DELETE /tasks?taskIds=. Each endpoint calls `CurrentUserGuard.requireUser` first and returns a ReflectionView (contracts/reflection-api.md).
- [X] T010 [US1] Write the integration test `BE/src/test/java/com/tom/payment/routinemanager/ReflectionIntegrationTest.java` (`fast` profile, `spring.ai.active=false`, MockMvc). It covers:
  - the copy matches the plan and repeating POST is idempotent
  - edits to the reflection leave `daily_task` unchanged, and plan edits leave the reflection unchanged
  - a future date returns 400
  - a past date with no plan gives an empty reflection, and no `daily_routine` row is created
  - another reflection's task id returns 404
  - validation errors return 400
  - GET never creates a reflection
- [X] T011 [P] [US1] Add the frontend types `FE/src/features/reflection/types/reflection.ts` (ReflectionTask, ReflectionView, ReflectionComparison, ComparisonStatus, ReflectionFeedback), mirroring the contract.
- [X] T012 [P] [US1] Add the API module `FE/src/features/reflection/api/reflection.ts` using `apiRequest`: `fetchReflection`, `ensureReflection`, `createReflectionTasks`, `updateReflectionTasks`, `deleteReflectionTasks`, `requestReflectionFeedback`.
- [X] T013 [P] [US1] Add the helpers `FE/src/features/reflection/utils/reflectionAvailability.ts` (`isFutureDate(date, today)`, `canReflect`) and `FE/src/features/reflection/utils/reflectionAvailability.test.ts`.
- [X] T014 [US1] Update `FE/src/features/daily/pages/DailyRoutinePage.jsx`:
  - a Plan/Reality segmented toggle (`.ui-segmented`), disabled for future dates with the hint "You can reflect once the day has happened"
  - `reflectionOn` state that persists across date changes; the effective mode is `reflectionOn && !future`
  - in reflection mode, `ensureReflection` runs on entry, and the board shows reflection tasks with no `onToggleComplete` and only "+ Add task"
  - the task modal, drag and delete handlers route to the reflection API
  - a "Reality" badge and `data-reflection="on"` on the page root
- [X] T015 [US1] Add the styles `.rf-*` (toggle row, Reality badge, reflection accent on the canvas card) to `FE/src/App.css`, using semantic tokens only and including the ≤ 760px layout.

**Checkpoint**: US1 is usable on its own.

## Phase 4: User Story 2, plan vs reality and gentle feedback (P2)

**Independent test**: With a reflection where one task was changed, one skipped and one added, the panel shows the right groups and totals. Requesting a note gives an encouraging note, which is stored and marked stale after an edit.

- [X] T016 [US2] Add the AI interface `BE/.../service/reflection/ReflectionAiService.java` with `String feedback(ReflectionView view)` and `String chat(UUID userId, LocalDate date, ReflectionView view, ChatContext context, String message)`.
- [X] T017 [P] [US2] Add `BE/.../service/reflection/MockReflectionAiService.java` (`@ConditionalOnProperty spring.ai.active=false, matchIfMissing`). Its feedback is a deterministic warm note built from the counts: a positive opening, at most 2 suggestions, and a reassuring close. Its chat returns an echo reply.
- [X] T018 [US2] Add `BE/.../service/reflection/GeminiReflectionAiService.java` (`spring.ai.active=true`). It builds its own `ChatClient` from an injected `ChatClient.Builder`, using the tone rules from research R5 for feedback. Feedback uses no tools.
- [X] T019 [US2] Add `ReflectionService.generateFeedback(userId, date)`. It returns 404 if there is no reflection. It calls `ReflectionAiService.feedback`, then stores feedbackText and feedbackAt. If the AI fails, it returns 503 "Buddy is unavailable right now" and keeps the old note. Also add the endpoint `POST {base}/feedback` in `DailyReflectionController.java`.
- [X] T020 [US2] Extend `ReflectionIntegrationTest.java` to check that the comparison appears in the view, the feedback is stored and returned, an edit makes it stale, and an AI failure gives 503 with the old note kept.
- [X] T021 [P] [US2] Add the helper `FE/src/features/reflection/utils/formatMinutes.ts` (e.g. `1h 30m`, signed difference) and `formatMinutes.test.ts`.
- [X] T022 [US2] Build the component `FE/src/features/reflection/components/ReflectionPanel.tsx`. It shows the totals (planned vs actual), the count chips per group, a collapsible per-task list (status chip, planned vs actual time), and Buddy's note card with "Get Buddy's note" or "Refresh note" when stale, loading and friendly error states. Add `ReflectionPanel.test.tsx` (jsdom).
- [X] T023 [US2] Mount `ReflectionPanel` above the board in reflection mode in `DailyRoutinePage.jsx`, and add the panel and status chip `.rf-*` styles to `FE/src/App.css` (tokens only, both themes).

## Phase 5: User Story 3, tell Buddy what happened (P3)

**Independent test**: In Reality mode, a chat message changes only the reflection. Reflection and plan chat histories stay separate after a reload.

- [X] T024 [US3] Add `DAILY_REFLECTION` to `BE/.../model/ChatConversationType.java`, plus `ChatConversation.forDailyReflection(user, date)` and the `ChatConversationService` methods `findReflectionConversation` and `getOrCreateReflectionConversation`.
- [X] T025 [US3] Add the AI tools `BE/.../service/aitools/ReflectionAiTools.java`: `addReflectionTasks`, `updateReflectionTasks` and `deleteReflectionTasks` (userId, date, ...). They delegate to `ReflectionService`, validate palette ids like the daily tools, and return friendly error strings.
- [X] T026 [US3] Implement chat in `GeminiReflectionAiService`. Its default tools are only `ReflectionAiTools`. The system prompt contains the user id, the date, and the reflection view JSON. Buddy must confirm what it changed and ask a short follow-up question when unsure which task the user means.
- [X] T027 [US3] Add the endpoints `POST /api/ai/chat/daily-reflection/{userId}` and `GET /api/ai/chat/daily-reflection/{userId}/{date}/messages` to `BE/.../api/AIController.java`. Each runs the guard, rejects a blank message or a missing or future date with 400, and returns 404 if there is no reflection. The exchange is stored after the reply.
- [X] T028 [US3] Extend `ReflectionIntegrationTest.java` to check that the reflection chat stores into its own conversation, that the daily history does not include it, that history pages work, and that a future date gives 400.
- [X] T029 [US3] Add the frontend chat API (`submitReflectionChat`, `fetchReflectionChatHistory`) to `FE/src/features/reflection/api/reflection.ts`. In `DailyRoutinePage.jsx`, BuddyChat is keyed `${date}:${mode}`, and in reflection mode it uses the reflection greeting, placeholder, history and send, then refreshes the reflection after each send.

## Phase 6: Polish

- [X] T030 [P] Update `BE/CLAUDE.md` with the reflection domain model, endpoints and the DDL `db/F007-daily-reflection.sql`.
- [X] T031 [P] Update `FE/CLAUDE.md` with the `features/reflection` module and the Daily page reflection mode.
- [X] T032 Run the checks: `./gradlew test` (BE), and `pnpm test && pnpm lint && pnpm build` (FE). Fix any failures.

## Dependencies

- Phase 1 → Phase 2 → US1 → US2 and US3. US2 and US3 both need the reflection created in US1. They are independent of each other, apart from both editing `DailyRoutinePage.jsx` and `AIController`/`ReflectionService`, so do them one after the other.
- Within US1: T008 → T009 → T010. The FE tasks T011–T013 can run in parallel with the backend, and T014 needs T011–T013.

## Parallel examples

- Phase 2: T002, T003, T004, T005 and T007 together.
- US1: T011, T012 and T013 alongside T008–T010.
- US2: T017 and T021 together.

## Implementation strategy

MVP = Phases 1–3: manual reflection with plan independence. Then US2 adds comparison and feedback, and US3 adds the AI chat. Each phase finishes with its tests passing.

## Implementation notes (2026-11-22)

- Feedback lives in `ReflectionFeedbackService` (not `ReflectionService`) to avoid the bean cycle ReflectionService → AI service → ReflectionAiTools → ReflectionService.
- The Plan/Reality toggle sits under the date row (not in the header actions), so the date row doesn't wrap at phone width.
- Extra: `ui-personal-routine-manager/e2e/reflection.spec.ts` (Playwright) covers quickstart scenarios 1, 2, 4 and 6.
- `./gradlew test`: all reflection tests pass. The 2 `OnboardingRoutineTest` failures already happen on `main` (an old `/api/routine-manager/default-routine` URL returns 404) and are unrelated to F007.

---

## Phase 7: Enhancement 2026-11-22: side-by-side layout and compact Reflection toggle (frontend only)

`FE` = `ui-personal-routine-manager`. Spec: FR-001, FR-012, FR-012a, FR-012b, FR-017a. Plan: "Enhancement 2026-11-22". Research: R11–R16. Contract: `contracts/reflection-ui.md`.

**Independent test**: quickstart scenarios 9–13.

### Foundations

- [X] T033 [P] Create `FE/src/hooks/useMediaQuery.ts` (based on `matchMedia` with a change listener; returns false when `matchMedia` is missing) and `useMediaQuery.test.ts`.
- [X] T034 [P] Create `FE/src/features/onboarding/hooks/useBoardClock.ts`. Move `currentTime`/`isLive` and the 60s ticker out of `EditingBoard`. It returns `{ currentTime, isLive, setIsLive, setCurrentTime }`. Add `useBoardClock.test.ts` with fake timers.
- [X] T035 [P] Create `FE/src/features/reflection/hooks/useSyncedScroll.ts`. `register(el)` is a ref callback, and a scroll on one element copies its `scrollTop` to the others, with a re-entrancy guard. Add `useSyncedScroll.test.ts`.
- [X] T036 [P] Create `FE/src/features/reflection/utils/comparisonLookup.ts` (`itemForActualTask(view, taskId)`) and `comparisonLookup.test.ts`.
- [X] T037 Extract the toolbar and slider JSX from `EditingBoard.jsx` into `FE/src/features/onboarding/components/BoardToolbar.jsx`. In `EditingBoard`:
  - add the optional props `showToolbar = true`, `clock`, `gapClearMode` and `scrollContainerRef`;
  - use `useBoardClock` when no `clock` is passed.
  Single-board behaviour and markup must stay the same, and the existing tests and e2e must still pass.
- [X] T038 Add the optional props `topSlot` (rendered between the header and the thread) and `compactHeader` (class `ob-buddy-head-compact`) to `FE/src/features/onboarding/components/BuddyChat.jsx`.

### Reflection components

- [X] T039 [P] Create `FE/src/features/reflection/components/ReflectionToggle.tsx`: a button named "Reflection" with `aria-pressed`, `disabled`, and a `title` hint. Add a test.
- [X] T040 [P] Split `ReflectionPanel.tsx` into `ReflectionSummaryStrip.tsx` (`region` "Plan vs reality"; one-line totals, diff and chips; collapsed "Task by task") and `ReflectionNote.tsx` (note, stale hint, get/refresh, 503 message). Move the tests over (`ReflectionSummaryStrip.test.tsx`, `ReflectionNote.test.tsx`) and delete `ReflectionPanel.tsx` and its test.
- [X] T041 [P] Create `FE/src/features/reflection/components/ReflectionTaskPopup.tsx`: a `dialog` named after the task, with a status chip, the planned name if renamed, planned vs actual start time and duration, and "Edit" and "Close" buttons. It closes on Escape. Add a test.
- [X] T042 Create `FE/src/features/reflection/components/CompareBoards.jsx`. It renders one `BoardToolbar` (shared `useBoardClock` clock, gap clear and the toolbar actions including the toggle), then a two-column grid:
  - a `region` "Plan" with header actions "Add to plan" and "Clean up", and an `EditingBoard` (`showToolbar={false}`, shared clock, `gapClearMode`);
  - a `region` "Reality" with "Add to reality", and an `EditingBoard` (`showToolbar={false}`, shared clock, `gapClearMode={false}`).
  Both boards use `useSyncedScroll`.

### Page integration

- [X] T043 Refactor the `DailyRoutinePage.jsx` handlers to take a target (`'plan' | 'reality'`) for create, edit, persist, delete and the modal's submit/saved/delete. The modal state stores its target. Plan changes made while Reflection is on also refresh the reflection.
- [X] T044 Update the `DailyRoutinePage.jsx` layout:
  - Remove the `.rf-mode` tablist and the intro paragraph.
  - Put `ReflectionToggle` into the board toolbar actions (single board) or into the `CompareBoards` toolbar.
  - Show the future hint as a small line under the date row only when the toggle is on and the day is in the future.
  - Add `data-layout="single|compare"`, using `useMediaQuery('(min-width: 1280px)')`.
  - Show `ReflectionSummaryStrip` above the board(s), and keep "Reflect on this day" and the error line.
  - Put `ReflectionNote` in the reflection `BuddyChat` `topSlot`, with `compactHeader`.
  - On narrow screens in reflection mode, a reality task click opens `ReflectionTaskPopup`, and its "Edit" opens `TaskEditModal`.
- [X] T045 Update `FE/src/App.css`:
  - Remove the `.rf-mode*`/`.rf-intro*`/`.rf-panel` rules that are no longer used.
  - Add `.rf-toggle` (pressed state using accent tokens), `.rf-strip` (single line, wraps at narrow widths) and `.rf-compare` (a 2-column grid with column headers; each column keeps a dashed outline for Reality).
  - Add `.ob-buddy-head-compact`, `.rf-note` in the chat top slot (scrolls itself, max-height 30%), and `.rf-popup`.
  Use semantic tokens only, so that `noRawColors` and the contrast tests pass.

### Tests and docs

- [X] T046 Rewrite `FE/e2e/reflection.spec.ts` for the toggle (`getByRole('button', { name: 'Reflection' })` with `aria-pressed`). Add:
  - a side-by-side test at 1400×900 (both regions visible; "Add to reality" changes only Reality; the plan edit updates the strip);
  - a pop-up test at 900×800 (click a reality card → dialog with a status chip → Edit opens the editor).
- [X] T047 [P] Update `FE/CLAUDE.md` with the reflection layout: the toggle in the toolbar, compare at ≥ 1280px, the note in the chat top slot, the pop-up on narrow screens, and the new hooks.
- [X] T048 Run `pnpm test && pnpm lint && pnpm build` and the reflection e2e against a test stack. Check light and dark screenshots at 1400px, 900px and 390px for no horizontal overflow. Fix any failures.

### Phase 7 dependencies

- T033–T036 can run in parallel. T037 needs T034. T038 is independent.
- T039–T041 can run in parallel after T036. T042 needs T035 and T037.
- T043 → T044 (needs T038–T042) → T045 → T046 → T048.

### Phase 7 implementation notes (2026-11-22)

- Extra fix: Reality boards used to show "Mark as done" checks. The first F007 build only claimed to hide them. `EditingBoard` now has `showCompletion`, and both Reality boards turn it off. The e2e tests check this.
- `EditingBoard` also gained `resetSignal`, so the shared "Reset day" can clear the Plan board's local completion state.
- When the toggle is on but the day has no reflection yet, the single board shows the plan view-only, so reflection mode never edits the plan.
- Checks:
  - Vitest: 170/170 pass, with no lint errors (only the existing exhaustive-deps warnings), and the build passes.
  - E2E: 5/5 pass (3 reflection + 2 others), run against a test backend (port 8081, `SPRING_AI_ACTIVE=false`) and Vite (port 5178).
  - Screenshots at 1400px (light and dark), 900px (with the pop-up) and 390px show no horizontal overflow.
