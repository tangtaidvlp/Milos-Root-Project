# Implementation Plan: Personal Goals

**Branch**: `feat/F013-personal-goals` | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F013-personal-goals/spec.md` (epic [E001](../E001-personal-target/E001-personal-target.md), phase 1)

## Summary

Users keep up to 3 goals, each with optional "how Buddy should help" text, on a new Personal Target page.

- **Backend**: a new `personal_goal` table and a CRUD API under `/api/v1/users/{userId}/goals`. The 3-goal limit is enforced under a user-row lock.
- **Buddy context**: every Buddy call (default routine and onboarding, daily routine, reflection chat, reflection feedback) gets the goals as a JSON data block plus fixed rules in its system prompt.
- **Proposals**: in chats, Buddy can call a per-request `proposeGoal` tool that only *records* a proposal. The reply carries it as `goalProposal`, and the UI shows a Confirm/Dismiss card. Confirm calls the same goals API, so nothing is saved without the user ([research.md](research.md) R4–R5).

## Technical Context

**Language/Version**: Java 25 (backend), TypeScript strict + React 19 (frontend)

**Primary Dependencies**: Spring Boot 4.1 (Web MVC, Data JPA, Security), Spring AI 2.0 (Gemini); React Router 7, Vite 8. No new dependencies.

**Storage**: PostgreSQL 17, with a new table `personal_goal` (`ddl-auto` locally, `db/F013-personal-goals.sql` for prod); H2 in `fast` and in tests

**Testing**: JUnit 5 component and unit tests (H2; Testcontainers PostgreSQL in CI), mock AI only; Vitest + Testing Library; Playwright

**Target Platform**: EC2 Linux behind Nginx (API); GitHub Pages (SPA)

**Project Type**: Web application (backend + frontend)

**Performance Goals**: Normal API latency. The prompt grows by at most about 2 KB (3 goals of up to 650 characters plus rules).

**Constraints**: ≤ 3 goals per user; goal text 150 and help text 500 characters; Buddy never writes goals; no live LLM in tests; additive contract changes only

**Scale/Scope**: ≤ 3 rows per user; 1 new page, 1 new chat card, 4 new endpoints, 1 additive response field

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|---|---|---|
| I. Contract-first | [goals-api.md](contracts/goals-api.md) and [buddy-chat-goal-proposal.md](contracts/buddy-chat-goal-proposal.md) are written before code. Bodies are record DTOs and errors are `ApiError`. `goalProposal` is additive and nullable. Backend and UI ship in this feature | PASS |
| II. Testing | Component tests: goals CRUD and refusals; proposal tool and chat field. Unit tests: `GoalRules` and `PersonalGoalPrompt`. Mock AI only. UI: unit tests (`goalRules`, `buddyReply`), a component test (`GoalProposalCard`), and the e2e test `personal-target` | PASS |
| III. Data | Additive table plus an idempotent `db/F013-personal-goals.sql`. GET is read-only. Writes are `@Transactional` | PASS |
| IV. Security | `CurrentUserGuard` + lookups by (user, id) → 403/404. Server-side validation (see Complexity Tracking for the mechanism) | PASS |
| V. AI agency | The proposal tool can't write. The user is bound server-side and never taken from the model. Arguments are validated by `GoalRules`. Goal text is sent as JSON data. Confirmation happens in the UI. Only goals are added to the prompt. Chat content logs move to DEBUG in the touched handlers | PASS |
| VI. Frontend | New `.ts`/`.tsx` in `features/personal-target/`. HTTP goes through `lib/api.ts`. Labels, keyboard, `ConfirmDialog`, tokens only, works at 320px | PASS |
| VII. Supply chain | No new dependencies | PASS |
| VIII. Observability | No goal or chat text logged at INFO | PASS |
| IX. Simplicity | Proposals aren't persisted and there's no new layer. The unused `AiChatService.chat()` is removed | PASS (one deviation, see below) |

**Post-design re-check (after Phase 1)**: unchanged, all PASS.

**Pre-existing gaps not fixed here**: Buddy task tools take `userId` from the model, and the frontend never sends the bearer token. Both are listed in research R10 and should become separate bugs. F013 doesn't make either worse; the new tool binds the user server-side.

## Project Structure

### Documentation (this feature)

```text
specs/F013-personal-goals/
├── spec.md
├── plan.md                 # this file
├── research.md             # R1–R10
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── goals-api.md
│   ├── buddy-chat-goal-proposal.md
│   └── ui.md
├── checklists/requirements.md
└── tasks.md                # /speckit-tasks (not created here)
```

### Source Code

```text
ms-personal-routine-manager/
├── db/F013-personal-goals.sql                                  # new
├── docs/test-flows.md                                          # + new tests
└── src/main/java/com/tom/payment/routinemanager/
    ├── model/PersonalGoal.java                                 # new
    ├── repository/PersonalGoalRepository.java                  # new
    ├── repository/UserRepository.java                          # + locked lookup (R2)
    ├── funcs/GoalRules.java                                    # new, pure (R3)
    ├── funcs/PersonalGoalPrompt.java                           # new, pure (R4)
    ├── dto/GoalRequest.java, GoalView.java, GoalListView.java, GoalProposalView.java   # new records
    ├── dto/ChatResponse.java                                   # + goalProposal
    ├── service/PersonalGoalService.java                        # new: list/create/update/delete
    ├── service/BuddyReply.java                                 # new record (text, goalProposal)
    ├── service/aitools/GoalProposalTool.java                   # new, per request, never writes (R5)
    ├── service/AiChatService.java, GeminiAiChatService.java, MockAiChatService.java   # BuddyReply, goals block + tool, drop chat()
    ├── service/reflection/ReflectionAiService.java, GeminiReflectionAiService.java,
    │   MockReflectionAiService.java, ReflectionFeedbackService.java                   # BuddyReply, feedback(userId, view)
    ├── api/PersonalGoalController.java                         # new
    └── api/AIController.java                                   # map BuddyReply → ChatResponse; content logs → DEBUG
    src/test/java/com/tom/payment/routinemanager/
    ├── component/PersonalGoalComponentTest.java                # new: CRUD, 400/403/404/409 + ApiError shape
    ├── component/GoalProposalComponentTest.java                # new: tool rules; chat returns goalProposal, history stores text only
    ├── unit/GoalRulesTest.java, unit/PersonalGoalPromptTest.java   # new
    └── component/ChatHistoryComponentTest.java, ReflectionComponentTest.java   # update stubs for new signatures

ui-personal-routine-manager/
├── e2e/personal-target.spec.ts                                 # new journey: add/edit/delete, limit, reload
└── src/
    ├── app/App.tsx                                             # + /personal-target route
    ├── App.css                                                 # + .pt-* styles
    ├── components/icons/                                       # + TargetIcon
    ├── components/layout/navEntries.ts                         # + Personal Target entry
    ├── features/personal-target/
    │   ├── api/goals.ts
    │   ├── types/goal.ts                                       # Goal, GoalProposal, BuddyReply
    │   ├── utils/goalRules.ts (+ .test.ts)                     # mirror of GoalRules
    │   ├── utils/buddyReply.ts (+ .test.ts)                    # parse {reply, goalProposal}
    │   ├── components/GoalForm.tsx, GoalProposalCard.tsx (+ GoalProposalCard.test.tsx)
    │   └── pages/PersonalTargetPage.tsx
    ├── features/onboarding/components/BuddyChat.jsx            # onSend may return BuddyReply; render card
    ├── features/onboarding/api/completeOnboarding.ts           # return BuddyReply
    ├── features/default-routine/api/defaultRoutineChat.ts      # return BuddyReply
    ├── features/daily/api/dailyRoutineTasks.ts                 # return BuddyReply
    ├── features/daily/pages/DailyRoutinePage.jsx               # reflection onSend wrapper returns BuddyReply
    └── features/reflection/api/reflection.ts                   # return BuddyReply
```

**Structure Decision**: The existing two-project layout is kept. Backend code follows the package conventions in its `CLAUDE.md`. The frontend adds one feature folder per `codingrules.md`. Both `CLAUDE.md` files get the new endpoints, table and page as part of the tasks.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Input is validated by a shared rule (`GoalRules` → 400 `ApiError`), not by Bean Validation annotations (Principle IV wording) | The REST API and Buddy's tool need the same trim and length rule. Bean Validation errors pass through `handleExceptionInternal` with `ex.getMessage()`, which leaks class and field internals (Principle I) | Bean Validation alone doesn't cover the tool and gives no user-facing message. Overriding the shared handler for this one feature widens the change. This matches the F006 settings precedent |
