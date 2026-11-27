# Implementation Plan: Task overlay

**Branch**: `feat/F017-task-overlay` (root, `ms-`, `ui-`; based on `feat/T002-timeline-drag-ux`) | **Date**: 2026-11-27 | **Spec**: [spec.md](spec.md)

## Summary

Add a boolean `overlay` (default false) to default-routine and daily tasks, copied with the task and kept when an update leaves it out. The Edit task dialog gets an Overlay switch. On the timeline, dragging a task with `overlay === false` swaps with tasks it covers by half (T002 swap math), never pushes, stops at a neighbour's edge otherwise, and (Normal mode) cannot be resized into the next task. Overlay-on tasks keep T002 behaviour.

## Technical Context

**Language/Version**: Java 25 / Spring Boot 4.1 (backend); TypeScript 5, React 19 (frontend)

**Primary Dependencies**: Spring Data JPA, Lombok; Vite 8, Vitest, Playwright

**Storage**: PostgreSQL, schema via `ddl-auto: update` until phase 1 (no Flyway yet)

**Testing**: backend component tests (`DailyRoutineComponentTest`, `DefaultRoutineComponentTest`); UI Vitest unit tests (`dragPreview.test.ts`), e2e `today-board`

**Target Platform**: Web (desktop + phone browsers)

**Project Type**: Web app (backend API + SPA)

**Performance Goals**: Drag preview stays smooth (pure function per pointer move, a few dozen tasks)

**Constraints**: Backward compatible API (field optional on input)

**Scale/Scope**: 2 entities, 4 service paths, 1 dialog, 1 drag util, board render

## Constitution Check

| Principle | Status |
|---|---|
| I. Contract-first | Pass: contract in `contracts/task-overlay.md`. Field is optional on input, so the deployed UI keeps working. Deviation: task endpoints still serialise entities (existing gap in the Sync Impact Report); only a field is added, see Complexity Tracking. |
| II. Testing | Pass: unit tests for the drag rules, component tests for default/copy/keep, e2e for the toggle and a swap. |
| III. Data changes | Pass: additive column with DB default false; `ddl-auto` until phase 1 (agreed). |
| IV. Security | Pass: no new endpoint, same ownership checks. |
| V. AI agency | Pass: AI tools unchanged; new tasks default off, updates keep the value. |
| VI. Frontend | Pass: native checkbox with `role="switch"`, label + description, keyboard and 24px target; drag has the dialog as non-drag alternative. |
| IX. Simplicity | Pass: no new modules; extends `dragPreview.ts`. |

## Project Structure

### Documentation (this feature)

```text
specs/F017-task-overlay/
├── spec.md, plan.md, research.md, data-model.md, quickstart.md
├── contracts/task-overlay.md
└── tasks.md
```

### Source Code

```text
ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/
├── model/DailyTask.java, model/RoutineTaskTemplate.java      # + overlay
└── service/DailyRoutineService.java, DefaultRoutineService.java  # copy + keep-on-null
ms-personal-routine-manager/src/test/java/.../component/
└── DailyRoutineComponentTest.java, DefaultRoutineComponentTest.java

ui-personal-routine-manager/src/features/
├── board/types/board.ts                     # BoardTask.overlay
├── board/components/TaskEditModal.tsx (+ .module.css)  # Overlay switch, showOverlay prop
├── board/utils/dragPreview.ts (+ test)      # Overlay-off rules
├── board/components/EditingBoard.tsx        # pass overlay, dragged-task display at pointer
├── daily/…, default-routine/…               # types + pass overlay through
└── daily/pages/DailyRoutinePage.tsx         # showOverlay={target !== 'reality'}
ui-personal-routine-manager/e2e/today-board.spec.ts
```

**Structure Decision**: existing backend + SPA; no new folders.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Task endpoints keep returning JPA entities (Principle I) | Only one field is added | Moving daily/default task endpoints to DTOs is a separate refactor across both apps; out of scope (YAGNI) |
