---
description: "Tasks for F013 Personal Goals"
---

# Tasks: Personal Goals (F013)

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: These are included because the constitution (Principle II) requires a component test per flow, unit tests per rule, and frontend unit, component and e2e tests.

**Paths**: `BE` = `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/`, `BT` = `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/`, `FE` = `ui-personal-routine-manager/src/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1, US2 or US3 from spec.md

---

## Phase 1: Setup

- [X] T001 Write the idempotent prod DDL `ms-personal-routine-manager/db/F013-personal-goals.sql` exactly as in data-model.md §1 (`personal_goal`: `id UUID PRIMARY KEY`, `user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE`, `goal_text VARCHAR(150) NOT NULL`, `how_to_help VARCHAR(500)` nullable, `created_at`/`updated_at TIMESTAMP WITH TIME ZONE NOT NULL`, index `idx_personal_goal_user (user_id, created_at)`), with the same header style as `db/F006-user-settings.sql`

---

## Phase 2: Foundational (blocks all stories)

- [X] T002 [P] Create the pure rule `BE/funcs/GoalRules.java`. Constants `MAX_GOALS = 3`, `GOAL_MAX = 150`, `HELP_MAX = 500`. `normalize(String goal, String howToHelp)` returns a record `(goal, howToHelp)`: trim both; blank help → null. It throws `IllegalArgumentException` with exactly `Goal is required.` / `Goal must be 150 characters or fewer.` / `How Buddy should help must be 500 characters or fewer.` (lengths counted after trim)
- [X] T003 [P] Unit test `BT/unit/GoalRulesTest.java`: null, empty or whitespace goal; exactly 150 and 151 characters; help null, blank (→ null), 500 and 501 characters; trimming of both fields
- [X] T004 [P] Create entity `BE/model/PersonalGoal.java` (table `personal_goal`; fields `id` UUID `GenerationType.UUID`, `userId` UUID `user_id`, `goal` → `goal_text` length 150 not null, `howToHelp` → `how_to_help` length 500 nullable, `createdAt`/`updatedAt` `OffsetDateTime`; no relation to `User`; index annotation for `(user_id, created_at)`; Lombok like `UserSetting`)
- [X] T005 [P] Create `BE/repository/PersonalGoalRepository.java`: `findByUserIdOrderByCreatedAtAscIdAsc(UUID)`, `findByIdAndUserId(UUID, UUID)`, `countByUserId(UUID)`
- [X] T006 [P] Add `@Lock(LockModeType.PESSIMISTIC_WRITE) Optional<User> findLockedById(UUID id)` (`@Query("select u from User u where u.id = :id")`) to `BE/repository/UserRepository.java`
- [X] T007 [P] Create DTO records: `BE/dto/GoalRequest.java` `(String goal, String howToHelp)`; `BE/dto/GoalView.java` `(UUID id, String goal, String howToHelp, OffsetDateTime createdAt, OffsetDateTime updatedAt)` with a static `of(PersonalGoal)`; `BE/dto/GoalListView.java` `(List<GoalView> goals, int limit)`
- [X] T008 Create `BE/service/PersonalGoalService.java` (depends on T002 and T004–T007):
  - `list(UUID userId)` (read-only)
  - `create(UUID userId, GoalRequest)` (`@Transactional`): `findLockedById`, `countByUserId >= MAX_GOALS` → 409 `You can have up to 3 goals.`, normalise (IllegalArgumentException → 400 with its message), timestamps from the injected `Clock`
  - `update(UUID userId, UUID goalId, GoalRequest)` (`@Transactional`): 404 `Goal not found` when not the user's; sets `updatedAt`
  - `delete(UUID userId, UUID goalId)` (`@Transactional`): 404 `Goal not found`
  - Errors use `ResponseStatusException`

**Checkpoint**: goals can be stored and validated.

---

## Phase 3: User Story 1 – Set my goals (P1) 🎯 MVP

**Goal**: a Personal Target page where users add, edit and delete up to 3 goals.

**Independent Test**: quickstart A1–A6 and B1. Goals survive a reload and a new sign-in, and a 4th goal is refused.

### Tests

- [X] T009 [P] [US1] Component test `BT/component/PersonalGoalComponentTest.java` (extends `BaseComponentTest`, real sign-in with `newUser()`/`as(...)`). Per [goals-api.md](contracts/goals-api.md):
  - GET when empty → `{goals:[],limit:3}`
  - POST → 201 with trimmed fields, and the stored row is checked
  - 3 POSTs then a 4th → 409 `You can have up to 3 goals.`
  - Blank goal and 151 characters → 400 with the message
  - PUT changes texts and `updatedAt`
  - DELETE → 204, then the row is gone
  - Another user's goal id → 404 on PUT and DELETE
  - Other user's path → 403; no token → 401
  - Every refusal uses `error(HttpStatus.X)`
- [X] T010 [P] [US1] Frontend unit test `FE/features/personal-target/utils/goalRules.test.ts`: the same cases as T003 for the TS mirror

### Implementation

- [X] T011 [US1] Create `BE/api/PersonalGoalController.java`: `GET/POST /api/v1/users/{userId}/goals`, `PUT/DELETE /api/v1/users/{userId}/goals/{goalId}`. Each calls `CurrentUserGuard.requireUser(userId)` first. POST returns 201 + `GoalView`, DELETE returns 204, GET returns `GoalListView(goals, GoalRules.MAX_GOALS)`
- [X] T012 [P] [US1] Create `FE/features/personal-target/types/goal.ts` with `Goal`, `GoalList`, `GoalInput`, and `GoalProposal`/`BuddyReply` types for US3 (contract shapes)
- [X] T013 [P] [US1] Create `FE/features/personal-target/utils/goalRules.ts`: `GOAL_MAX = 150`, `HELP_MAX = 500`, `MAX_GOALS = 3`, and `validateGoal(input)` → `{ ok: true, value: {goal, howToHelp|null} } | { ok: false, message }`, with the backend messages verbatim
- [X] T014 [P] [US1] Create `FE/features/personal-target/api/goals.ts`: `fetchGoals`, `createGoal`, `updateGoal` and `deleteGoal` through `apiRequest` with full `/api/v1/users/{id}/goals` paths, following `settings/api/userSettings.ts`. Normalise the response into the `goal.ts` types
- [X] T015 [P] [US1] Add `TargetIcon` to `FE/components/icons/Icons.tsx` and export it in `FE/components/icons/index.ts`, following the existing icon style
- [X] T016 [US1] Add the nav entry `{ id: 'personal-target', label: 'Personal Target', path: '/personal-target', icon: TargetIcon }` after Default routine in `FE/components/layout/navEntries.ts` (widen the `id` union). Add the shell route `/personal-target` → `PersonalTargetPage` in `FE/app/App.tsx`
- [X] T017 [US1] Create `FE/features/personal-target/components/GoalForm.tsx`: labelled "Goal" input (`maxLength` 150, count "n/150") and "How should Buddy help?" textarea (`maxLength` 500, count "n/500"). Save and Cancel buttons. Client check with `validateGoal`; a server error is shown inline and the text is kept; Save is pending while saving; focus goes to the first field on open
- [X] T018 [US1] Create `FE/features/personal-target/pages/PersonalTargetPage.tsx` per [ui.md](contracts/ui.md):
  - `PageHeader` "Personal Target" and a "Your goals" card
  - Loading, error with Retry, empty and list states
  - Edit and Delete buttons with names that include the goal text
  - "Add goal" disabled at 3, with "You can have up to 3 goals."
  - One open form at a time
  - Delete through `ConfirmDialog` ("Delete this goal?")
  - The list is replaced from server responses
  - React 19 actions or transitions for mutations
- [X] T019 [US1] Add `.pt-*` styles to `FE/App.css` using tokens only (card, goal item, form, counts, error). It must work at 320px with no horizontal scroll and visible focus
- [X] T020 [US1] Playwright journey `ui-personal-routine-manager/e2e/personal-target.spec.ts` using `registerAndOnboard`:
  - Open via the sidebar and check the empty state
  - Add a goal and reload: it is still there
  - Edit it
  - Add up to 3 and check "Add goal" is disabled with the limit note
  - Delete with Cancel, then with Confirm

**Checkpoint**: US1 works on its own (MVP).

---

## Phase 4: User Story 2 – Buddy uses my goals (P1)

**Goal**: every Buddy call knows the user's goals.

**Independent Test**: quickstart C1–C4 (real Gemini). Automated: the formatter unit test, plus existing suites green after the signature change.

### Tests

- [X] T021 [P] [US2] Unit test `BT/unit/PersonalGoalPromptTest.java`:
  - No goals → the "no goals, don't bring them up" text
  - 1–3 goals → a JSON array with `id`, `goal`, `howToHelp`
  - Quotes, newlines and `</` in goal text stay inside the JSON (escaped)
  - The rules text is present (use goals, one-sentence conflict, data not instructions, never delete → Personal Target page)

### Implementation

- [X] T022 [US2] Create the pure formatter `BE/funcs/PersonalGoalPrompt.java`: `format(List<PersonalGoal> goals)` builds the block in [buddy-chat-goal-proposal.md](contracts/buddy-chat-goal-proposal.md) §4, without the tool rule. JSON comes from Jackson `ObjectMapper` (or the existing `JsonFunc`)
- [X] T023 [US2] In `BE/service/GeminiAiChatService.java`, inject `PersonalGoalService` and append `PersonalGoalPrompt.format(goalService.listEntities(userId))` to the per-call system text of `defaultRoutineChat` and `dailyRoutineChat`. Add a `listEntities` (read-only) helper to `PersonalGoalService` if needed
- [X] T024 [US2] Change `ReflectionAiService.feedback(ReflectionView)` to `feedback(UUID userId, ReflectionView view)`:
  - Update `BE/service/reflection/ReflectionAiService.java`, `MockReflectionAiService.java` and `ReflectionFeedbackService.java` (pass `user.getId()`)
  - In `GeminiReflectionAiService.java`, append the goals block to the `chat` system text and to the `feedback` user text, with "connect the note to a goal where relevant"
  - Update the stub in `BT/component/ReflectionComponentTest.java` (`feedback(any(), any())`)

**Checkpoint**: Buddy uses goals in all chats and in reflection feedback.

---

## Phase 5: User Story 3 – Buddy proposes goal changes, I confirm (P2)

**Goal**: Buddy can suggest adding or changing a goal; the user confirms or dismisses it in a chat card.

**Independent Test**: quickstart D1–D6. Automated: the proposal component test and the card component test.

### Tests

- [X] T025 [P] [US3] Component test `BT/component/GoalProposalComponentTest.java`:
  - **Tool rules** (call `GoalProposalTool` methods directly, which is allowed for Buddy tools), per contract §3:
    - A valid add records ADD
    - The 4th add is refused
    - An unknown or foreign `goalId` is refused
    - A malformed id is refused
    - Invalid text gives the GoalRules message
    - A second call in a reply is refused and the first is kept
    - An UPDATE with blank help keeps the current help, and `current` comes from the DB
    - No DB rows change
  - **Chat mapping**: stub the `aiChatService` spy to return `new BuddyReply("ok", proposal)` for `dailyRoutineChat`. POST `/api/ai/chat/daily-routine/{id}` → the body has `goalProposal`, and chat history stores only `"ok"`. Without a proposal → `goalProposal` is null
- [X] T026 [P] [US3] Frontend unit test `FE/features/personal-target/utils/buddyReply.test.ts`:
  - String reply only
  - A valid ADD or UPDATE proposal
  - A malformed proposal (bad action, missing goal, UPDATE without goalId) is dropped and the text kept
  - A non-string reply throws as the current APIs do
- [X] T027 [P] [US3] Component test `FE/features/personal-target/components/GoalProposalCard.test.tsx` (jsdom, `vi.mock('../api/goals.ts')`):
  - ADD + Confirm → `createGoal` called, then "Saved to your goals."
  - UPDATE shows Now/Proposed, Confirm → `updateGoal`
  - Dismiss → "Not saved.", no API call
  - 409/404 → the server message, with buttons gone
  - Network error (status 0) → the message, with buttons still usable

### Implementation

- [X] T028 [P] [US3] Create `BE/dto/GoalProposalView.java`: record `(String action, UUID goalId, String goal, String howToHelp, Current current)` with a nested `record Current(String goal, String howToHelp)`. Add the nullable field `GoalProposalView goalProposal` to `BE/dto/ChatResponse.java`
- [X] T029 [P] [US3] Create `BE/service/BuddyReply.java`: `record BuddyReply(String text, GoalProposalView goalProposal)` with `static BuddyReply text(String)`
- [X] T030 [US3] Create `BE/service/aitools/GoalProposalTool.java`. It is not a Spring bean: one instance per request, built with `(UUID userId, PersonalGoalService)`. It has one `@Tool proposeGoal(goal, howToHelp [required=false], goalId [required=false])` with the exact results in contract §3. It validates with `GoalRules`, reads goals through the service, never writes, and exposes `Optional<GoalProposalView> proposal()`
- [X] T031 [US3] Change `BE/service/AiChatService.java` so `defaultRoutineChat` and `dailyRoutineChat` return `BuddyReply`, and remove the unused `chat(UUID, String)` (research R6):
  - `MockAiChatService.java`: wrap the text with `BuddyReply.text(...)`
  - `GeminiAiChatService.java`: build a `GoalProposalTool` per call, pass it with `.tools(tool)`, and return `new BuddyReply(content, tool.proposal().orElse(null))`
  - Verify that Spring AI 2.0 merges request tools with `defaultTools`; if it doesn't, pass the default tools with the call too (research R5)
- [X] T032 [US3] Change `ReflectionAiService.chat` to return `BuddyReply`: update `MockReflectionAiService.java`, and add the per-call `GoalProposalTool` in `GeminiReflectionAiService.java`
- [X] T033 [US3] Add the tool rule to `PersonalGoalPrompt` (an overload or flag for chats: "to add or change a goal, call proposeGoal; the user confirms it in the app; you can't delete goals"). The three chat calls use it and feedback does not. Extend `PersonalGoalPromptTest` for the flag
- [X] T034 [US3] In `BE/api/AIController.java`, the three POST handlers take `BuddyReply`, store `reply.text()` with `appendExchange`, and return `ChatResponse{reply, goalProposal}`. Change the message and reply `logger.info` lines in these handlers to `logger.debug`
- [X] T035 [US3] Update the AI stubs and verifies in `BT/component/ChatHistoryComponentTest.java` and `BT/component/ChatCompactionComponentTest.java` for the `BuddyReply` return type
- [X] T036 [P] [US3] Create `FE/features/personal-target/utils/buddyReply.ts`: `parseBuddyReply(data)` → `BuddyReply`. It throws on a missing string `reply` with the same message the APIs use today, and validates the `goalProposal` shape (otherwise null)
- [X] T037 [US3] Return `BuddyReply` via `parseBuddyReply` from `FE/features/default-routine/api/defaultRoutineChat.ts`, `FE/features/onboarding/api/completeOnboarding.ts` (chat function), `FE/features/daily/api/dailyRoutineTasks.ts` (`submitDailyRoutineChat`) and `FE/features/reflection/api/reflection.ts` (reflection chat). Make the reflection `onSend` wrapper in `FE/features/daily/pages/DailyRoutinePage.jsx` return the full reply
- [X] T038 [US3] Create `FE/features/personal-target/components/GoalProposalCard.tsx` per [ui.md](contracts/ui.md): New/Change goal title; Now/Proposed for UPDATE; Confirm → `createGoal`/`updateGoal` with the user id from `AuthContext`; Dismiss; a `role="status"` outcome; a "Saved" link to `/personal-target`; 4xx final, status 0 retryable
- [X] T039 [US3] In `FE/features/onboarding/components/BuddyChat.jsx`, `onSend` may return `string | BuddyReply`. Store `goalProposal` on the bot message and render `GoalProposalCard` under it. Update the JSDoc type. Add `.pt-proposal*` styles to `FE/App.css`

**Checkpoint**: all three stories work.

---

## Phase 6: Polish & cross-cutting

- [X] T040 [P] Add the new test classes to `ms-personal-routine-manager/docs/test-flows.md`
- [X] T041 [P] Update `ms-personal-routine-manager/CLAUDE.md`: PersonalGoal in Domain model, the goals endpoint row, the AI integration note (goals block, `GoalProposalTool`, `BuddyReply`, `chat()` removed, `feedback(userId, view)`), and the `db/F013-personal-goals.sql` mention
- [X] T042 [P] Update `ui-personal-routine-manager/CLAUDE.md`: route table, the personal-target feature behaviour, `BuddyChat` `onSend` → `BuddyReply`, and the new e2e journey
- [X] T043 Backend gate `./gradlew build -PtestDb=postgres` (or `./gradlew test` if Docker is unavailable, with the reason noted). Frontend gate `pnpm lint && pnpm build && pnpm test`, and `pnpm test:e2e personal-target` against the `fast` backend
- [X] T044 Run the quickstart scenarios that don't need real Gemini (A1–A6, B1, D card via the component test). Leave C1–C4 and D1–D6 (real Buddy) for the user's manual check

- [X] T045 Analyze remediation E1: PostgreSQL concurrency test `BT/integration/GoalLimitLockingIntegrationTest.java` (`@RequiresPostgres`; 6 parallel creates with 2 goals stored → exactly one 201, five 409, 3 goals). Analyze remediation F1: phone chat view stays open for a proposal card ([ui.md](contracts/ui.md))

**Results (2026-11-24)**: backend `./gradlew build -PtestDb=postgres` passes 178/178; frontend lint (no new warnings), build and 208 unit/component tests pass; Playwright 9/9 journeys pass, including `personal-target`. Quickstart C1–C4 and D1–D6 need real Gemini and are left for the user's manual check.


## Phase 7: Iteration – Buddy chat on Personal Target (US4, 2026-11-24)

**Goal**: the shared Buddy chat on the Personal Target page, with its own goals conversation; Buddy can only propose goals there ([research.md](research.md) R11, [personal-target-chat-api.md](contracts/personal-target-chat-api.md)).

**Independent Test**: quickstart E1–E4; automated by `PersonalTargetChatComponentTest` and the `personal-target` e2e journey.

- [X] T046 [US4] Add `PERSONAL_TARGET` to `BE/model/ChatConversationType.java` and `ChatConversation.forPersonalTarget(User)`; add `findByUser_IdAndType` to `BE/repository/ChatConversationRepository.java` (only for one-per-user types); add `findPersonalTargetConversation(userId)` and `getOrCreatePersonalTargetConversation(user)` to `BE/service/chat/ChatConversationService.java`
- [X] T047 [P] [US4] Append to `ms-personal-routine-manager/db/F013-personal-goals.sql`: `CREATE UNIQUE INDEX IF NOT EXISTS ux_chat_conv_personal_target ON chat_conversation (user_id) WHERE type = 'PERSONAL_TARGET';`
- [X] T048 [US4] Add `PERSONAL_TARGET_CHAT(true, DEEP)` to `BE/service/BuddyCall.java`
- [X] T049 [US4] Create `BE/service/PersonalTargetAiService.java` (`BuddyReply chat(UUID userId, ChatContext context, String userMessage, LocalTime localTime)`), `GeminiPersonalTargetAiService.java` (own client from a fresh `ChatClient.Builder`, no default tools; system prompt: help shape clear, realistic goals, propose with `proposeGoal`, never change plans or routines here and point to the Today/Default routine chat, stay on topic; plus `promptBlock(userId, PERSONAL_TARGET_CHAT, localTime)` and the summary; per-call `GoalProposalTool`) and `MockPersonalTargetAiService.java` (echo)
- [X] T050 [US4] Create `BE/dto/PersonalTargetChatRequest.java` (record `message`, `localTime`). In `BE/api/AIController.java` add `POST /api/ai/chat/personal-target/{userId}` and `GET /api/ai/chat/personal-target/{userId}/messages` (guard, blank message → 400, store only the text, DEBUG logs)
- [X] T051 [US4] Add the `personalTargetAi` spy to `BT/support/BaseComponentTest.java`. Component test `BT/component/PersonalTargetChatComponentTest.java`: a message is answered and stored, and history returns it; `localTime` reaches the AI; a stubbed proposal is returned as `goalProposal`; blank message 400; other user 403; unknown user 404. Add `PERSONAL_TARGET_CHAT` to the deep-rule check in `BuddyContextComponentTest`
- [X] T052 [P] [US4] Create `FE/features/personal-target/api/personalTargetChat.ts`: `submitPersonalTargetChat(userId, message)` → `BuddyReply` (sends `localTime`), `fetchPersonalTargetChatHistory(userId, before?)`
- [X] T053 [US4] `GoalProposalCard` gets an optional `onSaved` prop (called after a successful save); `BuddyChat` passes its optional `onGoalSaved` prop to it. Add a case to `GoalProposalCard.test.tsx`
- [X] T054 [US4] In `FE/features/personal-target/pages/PersonalTargetPage.tsx`, add `BuddyChat` beside the cards (`loadHistory`, `onSend`, `onGoalSaved` → reload goals) with the phone toggle per [ui.md](contracts/ui.md); add the `.pt-layout` styles to `FE/App.css`
- [X] T055 [US4] Extend `e2e/personal-target.spec.ts`: chat with Buddy on the page (mock AI reply shown) and the message is still there after a reload
- [X] T056 [P] Update `docs/test-flows.md` and both `CLAUDE.md` files (conversation type, endpoints, per-screen chat setup)
- [X] T057 Gates: `./gradlew build -PtestDb=postgres`; `pnpm lint && pnpm build && pnpm test`; `pnpm test:e2e`

**Results (iteration, 2026-11-24)**: backend `./gradlew build -PtestDb=postgres` 223/223 (analyze fix: the goals chat returns 503 on AI failure, constitution V); frontend lint (no new warnings), build and 220 tests pass; Playwright 11/11 (new chat journey included). With AI on, the app starts and the goals chat reaches Gemini, but the local key is rejected, so quickstart E1–E4 with real Buddy are left for the user.


## Phase 8: Iteration – Buddy reviews goals before saving (US5, 2026-11-24)

**Goal**: every new or changed goal is checked by Buddy (realistic, achievable, safe) and refused goals are not saved ([research.md](research.md) R12, [goals-api.md](contracts/goals-api.md), [ui.md](contracts/ui.md)).

**Independent Test**: quickstart F1–F6; automated by `GoalReviewRulesTest`, `GoalReviewComponentTest` and the `personal-target` e2e journey.

- [X] T058 [P] [US5] Create the pure rule `BE/funcs/GoalReviewRules.java`: `clean(accepted, reason, suggestedGoal, suggestedHowToHelp)` → `GoalReview` (accepted → accepted; refused → reason trimmed to ≤ 300 chars, `DEFAULT_REASON` if blank; suggestion kept only if it passes `GoalRules.normalize`). Unit test `BT/unit/GoalReviewRulesTest.java`
- [X] T059 [US5] Create `BE/service/GoalReviewer.java` (`GoalReview review(UUID userId, GoalRules.Normalized goal)`; throws on failure), `GeminiGoalReviewer.java` (own tool-less client; prompt per R12; structured output → `GoalReviewRules.clean`; null answer → exception) and `MockGoalReviewer.java` (refuses text containing "impossible")
- [X] T060 [US5] `PersonalGoalService.create/update` return `GoalSaveResult(goal, review)`: rules (400) → create: limit pre-check (409) / update: owned goal (404) and "unchanged" shortcut → review outside a transaction (failure → 503 `REVIEW_UNAVAILABLE`) → the locked write via `TransactionTemplate`. Add DTOs `GoalSaveView`, `GoalReviewView`; `PersonalGoalController` returns 201/200 per the contract
- [X] T061 [US5] Add "Only propose goals that are realistic, achievable and safe" to `BE/funcs/PersonalGoalPrompt.java` (in-chat rules) and its unit test
- [X] T062 [US5] Add the `goalReviewer` spy to `BT/support/BaseComponentTest.java`. Update `PersonalGoalComponentTest` to the `GoalSaveView` shape. Component test `BT/component/GoalReviewComponentTest.java`: refused create → 200 `review`, nothing stored; accepted → 201; refused update → goal unchanged; unchanged update → no review; reviewer failure → 503, nothing stored; invalid text 400 and limit 409 never call the reviewer
- [X] T063 [P] [US5] FE: types `GoalReview`, `GoalSaveResult`; `api/goals.ts` `createGoal/updateGoal` return `GoalSaveResult` via `utils/goalSaveResult.ts` (`parseGoalSaveResult`, unit tested)
- [X] T064 [US5] `GoalForm`: `onSave` returns `GoalReview | null`; "Checking…" + status line; refusal box with reason, suggestion and "Use suggestion". `PersonalTargetPage` handlers return the review. Component test `GoalForm.test.tsx` (refusal shown, suggestion fills the fields, text kept)
- [X] T065 [US5] `GoalProposalCard`: a refusal shows reason + suggestion (final); 503 retryable. Update `GoalProposalCard.test.tsx`
- [X] T066 [US5] e2e `personal-target.spec.ts`: "Do the impossible every day" is refused; "Use suggestion" then Save saves it
- [X] T067 [P] Update `docs/test-flows.md`, both `CLAUDE.md` files and the epic
- [X] T068 Gates: `./gradlew build -PtestDb=postgres`; `pnpm lint && pnpm build && pnpm test`; `pnpm test:e2e`

**Results (review iteration, 2026-11-24)**: backend `./gradlew build -PtestDb=postgres` 231/231; frontend lint (no new warnings), build and 228 tests pass; Playwright 12/12 (new review journey included). With AI on, a goal save reaches the Gemini reviewer; the local key is rejected, so it returns 503 and saves nothing, as FR-024 requires. Quickstart F1–F5 (real Buddy verdicts) are left for the user.

---

## Dependencies & Execution Order

- Setup (T001) → Foundational (T002–T008) → US1, US2 and US3.
- US1 (T009–T020) depends only on Foundational.
- US2 (T021–T024) depends only on Foundational.
- US3 (T025–T039) depends on Foundational. It touches the same Gemini files as US2, so run it after US2. T033 needs T022.
- Polish runs after all stories.

## Parallel examples

- Foundational: T002, T003, T004, T005, T006 and T007 together, then T008.
- US1: T009, T010, T012, T013, T014 and T015 together. Then T011 and T016 → T017 → T018 → T019 → T020.
- US3: T025–T029 and T036 together, then T030 → T031/T032 → T033 → T034 → T035, and T037 → T038 → T039.

## Implementation strategy

1. MVP = Setup + Foundational + US1 (the page works without Buddy).
2. Add US2 (Buddy reads the goals).
3. Add US3 (proposals with confirmation).
4. Polish: docs and the full gates.
