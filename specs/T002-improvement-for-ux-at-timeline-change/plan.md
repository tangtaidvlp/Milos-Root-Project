# Implementation Plan: Timeline drag UX improvements

**Branch**: `feat/T002-timeline-drag-ux` (root, `ms-`, `ui-`) | **Date**: 2026-11-27 | **Spec**: [spec.md](spec.md)

## Summary

Make dragging on the timeline feel natural: a 0.15s hold starts a drag (a swipe scrolls), the drop shows at once and saves in the background (revert + bottom message on failure), tasks may overlap up to 3 at once (side by side), and "Gap clear" becomes "Push mode", which pushes tasks both ways with a live preview.

The backend must stop its automatic overlap push and check the 3-task cap instead, otherwise it undoes overlaps and scrambles Push mode saves (spec Clarifications).

## Technical Context

**Language/Version**: TypeScript 5 / React 19 (UI); Java 25 / Spring Boot 4.1 (API)

**Primary Dependencies**: no new ones. Pointer Events and a non-passive `touchmove` listener for hold-to-drag (research R1)

**Storage**: PostgreSQL. No schema change

**Testing**: Vitest unit tests for the new pure board rules; Playwright for the drag journey; backend JUnit unit test for the cap rule plus component tests for the task save endpoints

**Target Platform**: modern browsers (desktop + phone touch); backend runs locally (pre-production)

**Project Type**: web app (SPA + REST API)

**Performance Goals**: the drag preview recalculates on every pointer move. With fewer than 100 tasks a day, the per-minute sweep (1440 slots) stays well under 1 ms

**Constraints**: WCAG 2.2 AA (a drag alternative already exists in the task dialog); reduced motion skips the slide animation; tokens only for colours

**Scale/Scope**: one shared board component (`EditingBoard`) used by Today, Default routine, Onboarding and Reflection compare; four backend task save endpoints plus Buddy's tools, which call the same services

## Constitution Check

| Principle | Status |
|---|---|
| I. Contract-first | Pass. [contracts/task-save-api.md](contracts/task-save-api.md) covers the new 409 and the no-push behaviour. The shapes are unchanged. UI and API land in this feature. |
| II. Testing | Pass. Cap rule: unit test. Save flows: component tests that check the full `ApiError` on 409. Pure UI rules: Vitest. Drag journey: Playwright. |
| III. Data | Pass. No schema change. The save stays `@Transactional`, so a refused batch stores nothing. |
| IV. Security | Pass. No new endpoint or input. The cap is enforced on the server, not only in the client. Ownership gap bug-0002 is unchanged and tracked. |
| V. AI agency | Pass. Buddy's tools go through the same services, so the cap applies, and the refusal text is returned to Buddy. |
| VI. Frontend | Pass. Strict TS, logic in `features/board/utils`, a drag alternative in the dialog, tokens only, reduced motion respected. |
| IX. Simplicity | Pass. No library. The old push code is deleted (`shiftOverlappingTasks`, `standardiseTasks`), not left alongside. |

Post-design re-check: still passes. No Complexity Tracking entries.

## Project Structure

### Documentation (this feature)

```text
specs/T002-improvement-for-ux-at-timeline-change/
├── spec.md, plan.md, research.md, data-model.md, quickstart.md
├── contracts/task-save-api.md      # backend contract change
├── contracts/board-ui.md           # BoardProps / board behaviour contract
└── tasks.md                        # /speckit-tasks
```

### Source Code

```text
ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/
├── funcs/TaskTimeFunctions.java            # remove push; add requireOverlapCap (R5)
├── service/DailyRoutineService.java        # add/update: no push, cap on end result
└── service/DefaultRoutineService.java      # same
ms-personal-routine-manager/src/test/java/.../
├── unit/TaskTimeFunctionsTest.java         # cap rule tests replace shift tests
└── component/{Daily,Default}RoutineComponentTest.java

ui-personal-routine-manager/src/features/board/
├── utils/dragPreview.ts (+ .test.ts)       # push rules + bounds (R3)
├── utils/overlapCap.ts (+ .test.ts)        # 3-task cap (R4)
├── utils/taskLanes.ts (+ .test.ts)         # side-by-side lanes (R6)
├── components/EditingBoard.tsx (+ .module.css)  # hold-to-drag, preview, pending save, notices
├── components/BoardToolbar.tsx             # "Push mode" + notice
├── components/BoardNotice.tsx              # bottom message (reuses .ui-notice)
└── types/board.ts                          # gapClearMode → pushMode
ui-personal-routine-manager/src/App.css     # .ob-board-task: touch-action, transitions, blocked state
ui-personal-routine-manager/src/features/{reflection/components/CompareBoards.jsx, radial-view/components/RadialBoard.tsx}  # prop rename
ui-personal-routine-manager/e2e/today-board.spec.ts
```

**Structure Decision**: the existing two subprojects. All UI logic stays in the `board` building-block feature, so every page gets it without page changes, apart from the prop rename.

## Design Notes

Details and alternatives are in [research.md](research.md).

- **Hold-to-drag (R1)**: task cards use `touch-action: pan-y`. A press starts a 150 ms timer. Moving more than 5 px first cancels it, so the swipe scrolls. When the timer fires, the board highlights the task, captures the pointer and blocks scrolling with a non-passive `touchmove` listener. A short tap still opens the dialog.
- **Instant drop (R2)**: on drop, the board keeps a `pending` map of positions and renders from it, marks itself busy (three dots, task layer and toolbar inert) and awaits `onPersistTaskChange`. On success it clears `pending`; the page has already reloaded the routine. On failure it clears `pending`, so the board shows the old layout, and shows a `BoardNotice`.
- **Push mode (R3)** and **cap (R4)**: pure functions compute the preview positions on every move. The dragged task is marked blocked when the preview breaks the cap, and a blocked drop saves nothing.
- **Lanes (R6)**: overlapping blocks get `left`/`width` from lane math. All position changes animate with a CSS transition on `top`/`height`/`left`/`width`, except the dragged task and when reduced motion is on.
- **Backend (R5)**: no auto-push. After all changes in one request are applied, each new, moved or resized task is checked against the cap: 409 `A time slot can hold at most 3 tasks.`, and the whole request rolls back.
