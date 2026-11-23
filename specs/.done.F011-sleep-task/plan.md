# Implementation Plan: Sleep task (overnight tasks)

**Branch**: `feat/F011-sleep-task` | **Date**: 2026-11-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F011-sleep-task/spec.md`

## Summary

Allow one task to cross midnight. Storage already supports it (`startTime + durationMinutes`). The fix is in the code that reads it:
- **Backend**: overlap check on a 24h cycle, a server-side 1–1440 duration check, and Buddy tool text that stops asking for a split.
- **Frontend**: the board draws an overnight task as two linked parts (bottom and top), drag/resize no longer stops at 24:00, Now/Next handles the wrap, and the edit form shows "Ends … (next day)".

No schema change, no new endpoint.

## Technical Context

**Language/Version**: Java 25 (Spring Boot 4.1); TypeScript/React 19

**Primary Dependencies**: existing only (Spring Web/JPA/AI; React, Vite)

**Storage**: PostgreSQL. No schema change.

**Testing**: JUnit unit and component tests; Vitest unit; Playwright e2e

**Target Platform**: EC2 backend and GitHub Pages SPA

**Project Type**: web app (backend + frontend)

**Performance Goals / Constraints / Scale**: n/a (a single user's day has under 50 tasks)

## Constitution Check

| Principle | Status |
|-----------|--------|
| I Contract-first | ✅ [contracts/task-time.md](contracts/task-time.md); AI tool text updated in the same feature; no shape change. Entities used as request bodies are a pre-existing gap and are not widened here. |
| II Testing | ✅ unit (`TaskTimeFunctionsTest`, `taskSegments`, `nowAndNext`), component (default and daily add, 400 `ApiError` body), e2e (`today-board`) |
| III Data | ✅ no schema change, no backfill (FR-009) |
| IV Security | ✅ adds the missing server-side duration check; ownership unchanged |
| V AI | ✅ tools keep calling the same services and validation |
| VI Frontend | ✅ new logic in a `.ts` util with tests; a non-drag path exists (edit form); `EditingBoard.jsx` gets a targeted change, not a rewrite, so no TSX conversion |
| IX Simplicity | ✅ no new libraries or layers |

Re-check after design: passes, no violations.

## Project Structure

### Documentation

```text
specs/F011-sleep-task/
├── spec.md · plan.md · research.md · data-model.md · quickstart.md
├── contracts/task-time.md
└── tasks.md   (/speckit-tasks)
```

### Source code touched

```text
ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/
├── funcs/TaskTimeFunctions.java          # overlap on 24h cycle (R2)
├── service/DefaultRoutineService.java    # duration 1–1440 → 400 (R3)
├── service/DailyRoutineService.java      # duration 1–1440 → 400 (R3)
└── service/aitools/{Default,Daily}RoutineAiTools.java  # "never split" (R4)
ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/
├── unit/TaskTimeFunctionsTest.java
└── component/{DefaultRoutine,DailyRoutine}ComponentTest.java

ui-personal-routine-manager/src/features/
├── onboarding/utils/taskSegments.ts (+ .test.ts)   # new (R5)
├── onboarding/components/EditingBoard.jsx           # segments, no 24:00 clamp (R5)
├── onboarding/components/TaskEditModal.tsx          # "Ends … (next day)" (R7)
└── daily/utils/nowAndNext.ts (+ .test.ts)           # wrap (R6)
ui-personal-routine-manager/e2e/today-board.spec.ts  # overnight journey
```

**Structure Decision**: existing backend and frontend layout. No new modules.

## Execution

Two sub-agents run in parallel: **backend** (`ms-personal-routine-manager/` only) and **frontend** (`ui-personal-routine-manager/` only). They share no files. [contracts/task-time.md](contracts/task-time.md) is the fixed interface between them. The e2e test runs last, against both.

## Risks

- **Push cascade wrapping:** tasks pushed by the overlap rule can now wrap past midnight instead of producing a wrong time. This is acceptable and covered by a unit test.
- **Release order:** the old UI draws overnight tasks wrongly. Ship backend and UI together (see contract, "Compatibility").
