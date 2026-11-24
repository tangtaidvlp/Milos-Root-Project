---
description: "Tasks for F015 Context-Aware Tone"
---

# Tasks: Context-Aware Tone (F015)

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/buddy-local-time.md](contracts/buddy-local-time.md), [quickstart.md](quickstart.md)

**Tests**: These are included because constitution Principle II requires them.

**Paths**: `BE` = `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/`, `BT` = `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/`, `FE` = `ui-personal-routine-manager/src/`.

---

## Phase 1: Setup

None.

## Phase 2: Foundational

- [X] T001 [P] Create `BE/funcs/TimeOfDay.java`: enum `MORNING`, `MIDDAY`, `EVENING`, each with its `label` ("morning", "midday", "evening") and the window style from the contract. `of(LocalTime)`: morning if 05:00 ≤ t < 12:00, midday if 12:00 ≤ t < 17:00, evening otherwise. `parse(String)` → `Optional<LocalTime>` for strict `HH:mm` (HH 00–23, mm 00–59); anything else is empty
- [X] T002 [P] Create `BE/funcs/ChatKind.java`: `DAY_TO_DAY` and `DEEP`, with the length-rule text from the contract
- [X] T003 [P] Unit test `BT/unit/TimeOfDayTest.java`:
  - Boundaries: 04:59 → EVENING, 05:00 → MORNING, 11:59 → MORNING, 12:00 → MIDDAY, 16:59 → MIDDAY, 17:00 → EVENING, 23:59 → EVENING, 00:00 → EVENING.
  - `parse`: "08:05" ok; "8:05", "24:00", "12:60", "", null and "08:05:00" empty.

## Phase 3: User Story 1 – Buddy matches my time of day (P1) 🎯 MVP

**Independent Test**: quickstart A1–A4 (real Gemini). Automated: the rule and prompt tests, and a component test showing the user's local time reaches the AI layer.

- [X] T004 [P] [US1] Unit test `BT/unit/TimeOfDayPromptTest.java`:
  - Each window gives its label, the "HH:mm" time, its style and the "Keep the user's chosen tone recognisable" line.
  - With no time, there is no window text and only the length rule.
  - DAY_TO_DAY vs DEEP length rules.
- [X] T005 [US1] Create `BE/funcs/TimeOfDayPrompt.java`: `format(LocalTime localTimeOrNull, ChatKind kind)` returns the exact block in the contract (the window is derived with `TimeOfDay.of`)
- [X] T006 [US1] Create `BE/service/BuddyCall.java`: enum `DEFAULT_ROUTINE_CHAT(true, DEEP)`, `DAILY_CHAT(true, DAY_TO_DAY)`, `REFLECTION_CHAT(true, DEEP)`, `REFLECTION_FEEDBACK(false, DEEP)` with `inChat()` and `kind()`. Change `BE/service/BuddyContextService.java` to `promptBlock(UUID userId, BuddyCall call, LocalTime localTime)` = goals(call.inChat) + tone + `TimeOfDayPrompt.format(localTime, call.kind())`
- [X] T007 [US1] Add a nullable `LocalTime localTime` parameter (last) to:
  - `AiChatService.defaultRoutineChat/dailyRoutineChat`
  - `ReflectionAiService.chat/feedback`
  - `ReflectionFeedbackService.generate`
  Update `MockAiChatService`, `MockReflectionAiService` and both Gemini services. The Gemini services call `buddyContext.promptBlock(userId, BuddyCall.X, localTime)`.
- [X] T008 [US1] Add `String localTime` to `BE/dto/ChatRequest.java` and `DailyRoutineChatRequest.java`, and a component to `ReflectionChatRequest.java` (record). In `BE/api/AIController.java`, pass `TimeOfDay.parse(request.localTime()).orElse(null)` to the AI calls. In `BE/api/DailyReflectionController.java`, `feedback` gets `@RequestParam(required = false) String localTime`, parsed the same way and passed to `generate`
- [X] T009 [US1] Update the existing stubs and verifies for the new arity in `BT/component/ChatHistoryComponentTest.java`, `ChatCompactionComponentTest.java`, `ReflectionComponentTest.java` and `GoalProposalComponentTest.java`. Update `BT/component/BuddyContextComponentTest.java` to the new `promptBlock` signature, and add one case: `DAILY_CHAT` at 08:00 contains "morning" and the 3-sentence rule
- [X] T010 [US1] Component test `BT/component/LocalTimeComponentTest.java` (capture with the AI spies):
  - Daily chat with `"localTime":"08:05"` → `dailyRoutineChat` receives `LocalTime.of(8,5)`.
  - Reflection chat with `"21:10"` → `21:10`.
  - Default routine chat without a time → null.
  - Malformed `"25:99"` → 200 and null.
  - Feedback `?localTime=07:30` → `feedback` receives `07:30`.
- [X] T011 [P] [US1] Create `FE/lib/localTime.ts`: `currentLocalTime(date = new Date())` → `"HH:mm"`, zero-padded, 24-hour. Add the unit test `localTime.test.ts`: 08:05, 00:00 and 23:59
- [X] T012 [US1] Send `localTime: currentLocalTime()` in `FE/features/default-routine/api/defaultRoutineChat.ts`, `FE/features/onboarding/api/completeOnboarding.ts` (chat), `FE/features/daily/api/dailyRoutineTasks.ts` (`submitDailyRoutineChat`) and `FE/features/reflection/api/reflection.ts` (`submitReflectionChat` body; `requestReflectionFeedback` as `?localTime=` with `encodeURIComponent`)

## Phase 4: User Story 2 – Short in day-to-day chat, deeper when planning or reflecting (P2)

**Independent Test**: quickstart A5–A6. Automated: the length rules in `TimeOfDayPromptTest` and the `BuddyCall` mapping.

- [X] T013 [US2] Check in `BuddyContextComponentTest` that `DAILY_CHAT` gets the 3-sentence rule, and that `DEFAULT_ROUTINE_CHAT`, `REFLECTION_CHAT` and `REFLECTION_FEEDBACK` get the deep rule (one assertion per call)

## Phase 5: Polish

- [X] T014 [P] Add `TimeOfDayTest`, `TimeOfDayPromptTest` and `LocalTimeComponentTest` to `ms-personal-routine-manager/docs/test-flows.md`
- [X] T015 [P] Update `ms-personal-routine-manager/CLAUDE.md` (Buddy context gets the time-of-day block, `localTime` on AI calls, `BuddyCall`) and `ui-personal-routine-manager/CLAUDE.md` (Buddy calls send `localTime` via `lib/localTime.ts`)
- [X] T016 Gates: `./gradlew build -PtestDb=postgres`; `pnpm lint && pnpm build && pnpm test`; `pnpm test:e2e`
- [X] T017 Leave quickstart A1–A7 (real Gemini wording) for the user's manual check

**Results (2026-11-24)**: backend `./gradlew build -PtestDb=postgres` 219/219; frontend lint (no new warnings), build and 219 unit/component tests pass; Playwright 10/10. A live smoke test with AI on showed the Gemini services wire up and calls reach the provider, but the local `GEMINI_API_KEY` is rejected ("API key not valid"), so quickstart A1–A7 still need a valid key and a manual check.

## Dependencies

T001/T002 → T005 → T006 → T007 → T008 → T009/T010; T011 → T012; T013 after T006 and T009; Polish last.
