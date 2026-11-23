# Implementation Plan: Reset day to default routine

**Branch**: `F012-make-reset-day-reset-to-default-routine` | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F012-make-reset-day-reset-to-default-routine/spec.md`

## Summary

Reset day (Today) asks the user to confirm, then replaces the day's plan with a fresh copy of its default routine in one server transaction. A new "Copy Weekday to Weekend" button on the Onboarding/Default routine pages replaces the Weekend routine with a copy of the Weekday one, also after a confirm. Reset day is removed from the setup boards. Two new `204` endpoints; no schema change.

## Technical Context

**Language/Version**: Java 25 (backend), TypeScript/React 19 (frontend)

**Primary Dependencies**: Spring Boot 4.1 (Web MVC, Data JPA); Vite 8

**Storage**: PostgreSQL; no schema change

**Testing**: JUnit component tests (`BaseComponentTest`); Vitest; Playwright `today-board.spec.ts`

**Target Platform**: EC2 backend; GitHub Pages SPA

**Project Type**: Web app (backend + frontend)

**Performance Goals**: None beyond the existing ones (a day has tens of tasks)

**Constraints**: All-or-nothing writes; past days refused server-side

**Scale/Scope**: 2 endpoints, ~6 frontend files

## Constitution Check

| Principle | Status |
|---|---|
| I Contract-first, DTOs, ApiError | ✅ [contracts/reset-and-copy-api.md](contracts/reset-and-copy-api.md). `204` (no entity serialised); errors via `ResponseStatusException` → `ApiError`. Additive. |
| II Testing | ✅ Component tests per flow plus refusals (past date 400, other user 403) checking the full `ApiError`. No new pure rule (reuses `RoutineTemplateRules`, `DayRules`, which are already unit-tested). One e2e journey added. |
| III Data | ✅ No schema change; `@Transactional` service writes. |
| IV Security | ✅ `CurrentUserGuard.requireUser`; lookups scoped by user. Fixes the known ownership gap for these two new paths only. |
| V AI | ✅ Bulk action is UI-confirmed; no Buddy tool added. |
| VI Frontend | ✅ Reuses `ConfirmDialog` (keyboard, `alertdialog`); new API functions in feature `api/` via `lib/api.ts`. `.jsx` files are only lightly touched, so they aren't converted. |
| IX Simplicity | ✅ Removes the old local-tick reset (`handleResetSchedule`, `resetSignal`). |

Post-design re-check: no violations.

## Project Structure

### Documentation

```text
specs/F012-make-reset-day-reset-to-default-routine/
├── plan.md  research.md  data-model.md  quickstart.md
└── contracts/reset-and-copy-api.md
```

### Source Code

```text
ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/
├── api/DailyRoutineController.java        # + POST /daily-routine/{userId}/{date}/reset
├── api/DefaultRoutineController.java      # + POST /users/{userId}/copy-weekday-to-weekend
├── service/DailyRoutineService.java       # + resetToDefault(user, date); extract copyTemplateTasks()
└── service/DefaultRoutineService.java     # + copyWeekdayToWeekend(user)
ms-personal-routine-manager/src/test/java/.../component/
├── DailyRoutineComponentTest.java         # reset: weekday, weekend, missing day, past 400, other user 403, reflection kept
└── DefaultRoutineComponentTest.java       # copy: replaces Weekend, Weekday unchanged, 403

ui-personal-routine-manager/src/features/
├── daily/api/dailyRoutineTasks.ts         # + resetDailyRoutine(userId, date)
├── daily/pages/DailyRoutinePage.jsx       # confirm dialog + handler; pass onResetDay/resetDisabled
├── onboarding/api/defaultRoutine.ts       # + copyWeekdayToWeekend(userId)
├── onboarding/components/BoardToolbar.jsx # render Reset day only with onResetDay; resetDisabled
├── onboarding/components/EditingBoard.jsx # pass-through props; remove resetSignal/handleResetSchedule
├── onboarding/components/DefaultRoutineEditor.tsx  # Copy button + ConfirmDialog + reload Weekend
├── onboarding/hooks/useDefaultRoutines.ts # expose reload of one tab, if not already there
└── reflection/components/CompareBoards.jsx # onResetDay from page instead of resetSignal
ui-personal-routine-manager/e2e/today-board.spec.ts  # reset journey
```

**Structure Decision**: Existing backend layers (controller → service) and frontend feature folders. No new modules.

## Complexity Tracking

None.
