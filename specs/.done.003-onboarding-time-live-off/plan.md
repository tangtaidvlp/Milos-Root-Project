# Implementation Plan: Live Clock Off During Onboarding

**Branch**: `003-onboarding-time-live-off` | **Date**: 2026-11-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-onboarding-time-live-off/spec.md`

## Summary

Turn the routine board's live clock off on the setup (onboarding) screen and keep it on the dashboard. The shared `EditingBoard` gets an optional `liveClock` prop (default `true`). With `liveClock={false}` it renders no clock readout, Pause/Resume button, slider, now-line or "Now: …" line, runs no timer, marks no task as current, opens at 06:00 (and again on each Weekday/Weekend switch), and keeps the top time of day in place when zooming. `OnboardingPage` passes `liveClock={false}`; the dashboard is untouched. Frontend only.

## Technical Context

**Language/Version**: JavaScript (JSX) for the existing board and pages; TypeScript for the new helper

**Primary Dependencies**: React 19, Vite 8

**Storage**: N/A (no data changes)

**Testing**: Vitest (pure-logic unit test for the scroll helper); manual/headless browser check via [quickstart.md](./quickstart.md)

**Target Platform**: Modern desktop and mobile browsers

**Project Type**: Web application (frontend SPA only for this feature)

**Performance Goals**: No timer on the setup screen; no measurable change elsewhere

**Constraints**: Dashboard behaviour must not change (FR-006); feature 002's `data-tour` anchors must keep working

**Scale/Scope**: 1 component, 1 page, 1 new helper + test

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so it sets no gates. The repo rules applied instead (`ui-personal-routine-manager/CLAUDE.md`, `codingrules.md`):

| Rule | Status |
|------|--------|
| Feature-based folders; helpers in `features/<feature>/utils/` | ✅ helper goes in `features/onboarding/utils/` |
| New files in `.ts`/`.tsx` | ✅ `boardScroll.ts` |
| Tests cover pure logic, next to the code | ✅ `boardScroll.test.ts` |
| API calls through `lib/api.ts` | ✅ n/a, no API calls |
| Don't hand-edit `milos.github.io/` | ✅ untouched |

Post-design re-check: no change, still passing.

## Project Structure

### Documentation (this feature)

```text
specs/003-onboarding-time-live-off/
├── spec.md
├── plan.md              # this file
├── research.md          # R1–R5
├── data-model.md        # in-memory view settings only
├── quickstart.md        # validation scenarios
├── contracts/
│   └── editing-board.md # liveClock prop contract
├── checklists/
│   └── requirements.md
└── tasks.md             # next: /speckit-tasks
```

### Source Code

```text
ui-personal-routine-manager/src/
├── features/onboarding/
│   ├── components/EditingBoard.jsx    # liveClock prop, conditional clock UI/timer/highlight, 06:00 scroll, zoom anchoring
│   ├── pages/OnboardingPage.jsx       # pass liveClock={false}
│   └── utils/
│       ├── boardScroll.ts             # NEW: scrollTopForMinutes()
│       └── boardScroll.test.ts        # NEW
└── features/daily/pages/DailyRoutinePage.jsx   # unchanged (default liveClock)
```

`ui-personal-routine-manager/CLAUDE.md`: one line under "Feature behavior → onboarding" noting the board's live clock is off on the setup screen.

**Structure Decision**: frontend-only change inside the existing `onboarding` feature; the backend repo is not touched.

## Complexity Tracking

No violations.
