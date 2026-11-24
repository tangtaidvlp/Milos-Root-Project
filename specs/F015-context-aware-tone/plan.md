# Implementation Plan: Context-Aware Tone

**Branch**: `feat/E001-personal-target` (epic branch; F015 = phase 3) | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F015-context-aware-tone/spec.md` (epic [E001](../E001-personal-target/E001-personal-target.md))

## Summary

Buddy adjusts the chosen tone to the user's local time of day, and keeps day-to-day replies short.

- **Local time**: the frontend sends `localTime` ("HH:mm", device time) with each Buddy call: in the chat request bodies, and as a query parameter on reflection feedback. A missing or bad value is ignored.
- **Rules**: the pure rules `TimeOfDay` (windows) and `TimeOfDayPrompt` (window style, "keep the tone recognisable", and a length rule per kind of chat) build a "Right now" block.
- **Wiring**: `BuddyContextService` appends the block after goals and tone. A `BuddyCall` enum tells it which call is being made ([research.md](research.md)).

## Technical Context

**Language/Version**: Java 25; TypeScript strict + React 19

**Primary Dependencies**: unchanged; no new dependencies

**Storage**: none (nothing stored)

**Testing**: JUnit unit tests (windows, prompt) and component tests (local time reaches the AI layer; bad values are ignored); Vitest unit test for `currentLocalTime`; the existing e2e suite as a regression check

**Target Platform / Project Type**: Web application (EC2 API + GitHub Pages SPA)

**Performance Goals**: The prompt grows by about 0.4 KB.

**Constraints**: Always on, with fixed windows; no LLM in tests; additive contract changes only

**Scale/Scope**: 3 small enums/rules, 1 formatter, 4 request contracts gain an optional field, 4 frontend API calls

## Constitution Check

| Principle | Check | Result |
|---|---|---|
| I. Contract-first | [buddy-local-time.md](contracts/buddy-local-time.md): optional field and parameter, backward compatible; backend and UI ship together | PASS |
| II. Testing | Unit tests per rule (windows and boundaries, prompt), component tests per flow (the time is passed through; malformed is ignored), frontend unit test | PASS |
| III. Data | No schema change | PASS |
| IV. Security | Input is validated (strict `HH:mm`); bad input is ignored and never echoed into the prompt | PASS |
| V. AI agency | Only the time is added to the prompt; "never what you may do" is restated | PASS |
| VI–IX | No UI change; no new dependencies; nothing logged; it extends the single context service | PASS |

**Post-design re-check**: unchanged, all PASS.

## Project Structure

### Documentation

```text
specs/F015-context-aware-tone/
├── spec.md, plan.md, research.md, data-model.md, quickstart.md
├── contracts/buddy-local-time.md
└── tasks.md
```

### Source Code

```text
ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/
├── funcs/TimeOfDay.java, funcs/ChatKind.java, funcs/TimeOfDayPrompt.java   # new pure rules
├── service/BuddyCall.java                                                  # new enum
├── service/BuddyContextService.java                                        # promptBlock(userId, call, localTime)
├── dto/ChatRequest.java, DailyRoutineChatRequest.java, ReflectionChatRequest.java   # + localTime
├── api/AIController.java, api/DailyReflectionController.java               # parse localTime, pass it on
├── service/AiChatService.java, GeminiAiChatService.java, MockAiChatService.java     # + LocalTime param
└── service/reflection/ReflectionAiService.java, GeminiReflectionAiService.java,
    MockReflectionAiService.java, ReflectionFeedbackService.java                     # + LocalTime param
ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/
├── unit/TimeOfDayTest.java, unit/TimeOfDayPromptTest.java                  # new
├── component/LocalTimeComponentTest.java                                   # new
└── component/BuddyContextComponentTest.java, ChatHistoryComponentTest.java,
    ChatCompactionComponentTest.java, ReflectionComponentTest.java,
    GoalProposalComponentTest.java                                          # new signatures
ui-personal-routine-manager/src/
├── lib/localTime.ts (+ .test.ts)                                           # currentLocalTime()
└── features/{default-routine,onboarding,daily,reflection}/api/*            # send localTime
```

**Structure Decision**: It follows the F013/F014 layout. `localTime.ts` sits in `src/lib/` because four features use it.

## Complexity Tracking

No violations.
