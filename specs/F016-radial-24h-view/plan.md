# Implementation Plan: Radial 24H View

**Branch**: `feat/F016-radial-24h-view` | **Date**: 2026-11-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F016-radial-24h-view/spec.md`

## Summary

Add a "Timeline | Circle" view switch to Today (incl. Reflection) and Default routine. The Circle view is one new SVG component, `RadialDayChart`, used everywhere: tasks are slices of a 24h clock face, and every name and time sits outside the circle with a leader line. Clicking a slice or its label calls the same handler the vertical board calls on click. Buddy chat gets a hide button and collapses to a narrow rail, like the sidebar. Both choices are saved per device in `localStorage`. Frontend only: no backend or API change.

## Technical Context

**Language/Version**: TypeScript 5 (strict), React 19

**Primary Dependencies**: Vite 8, React Router 7. No new dependencies: the chart is hand-written SVG (research R1).

**Storage**: `localStorage` for two per-device UI preferences ([data-model.md](data-model.md)). No server data.

**Testing**: Vitest unit tests for the pure layout and preference code; one Playwright journey (`e2e/radial-view.spec.ts`); manual visual check with [quickstart.md](quickstart.md).

**Target Platform**: Modern desktop and mobile browsers, 320px wide and up.

**Project Type**: Web SPA (`ui-personal-routine-manager/`)

**Performance Goals**: Layout recomputes only when tasks or container width change. Up to about 50 tasks, sort + one relaxation pass, well within INP 200ms.

**Constraints**: WCAG 2.2 AA, design tokens only (`noRawColors` test), no horizontal scroll at 320px, text never scaled below `--font-size-sm`.

**Scale/Scope**: 2 pages (Today with Reflection, Default routine), 1 new component, ~9 changed files.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Result |
|---|---|
| I. Contract-first API | Pass. No endpoint change. |
| II. Testing | Pass. Unit tests for `radialGeometry`, `radialLabels`, `radialFormat`, `devicePreference` with edge cases. One new Playwright journey. No snapshot tests. |
| III. Data changes | Pass. No schema change. |
| IV. Security | Pass. `localStorage` holds only two UI flags, no tokens or personal data. |
| V. AI agency | Pass. Buddy is unchanged; hiding the chat keeps it mounted. |
| VI. Frontend | Pass. New code is `.tsx`/`.ts` in `features/radial-view/`. Tokens only. Labels are real `<button>`s (keyboard, visible focus, ≥ 24px). Works at 320px. `useEffect` is used only for `ResizeObserver`. The `.jsx` files get small edits only, so they stay `.jsx`. |
| VII–VIII | N/A |
| IX. Simplicity | Pass. No chart library. One generic device-preference helper serves both new flags. |

**Post-design re-check**: still passes; no Complexity Tracking entries.

## Project Structure

### Documentation (this feature)

```text
specs/F016-radial-24h-view/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/ui-radial.md
└── tasks.md             # /speckit-tasks
```

### Source Code (`ui-personal-routine-manager/`)

```text
src/
├── lib/devicePreference.ts            # NEW read/write a per-device string flag (+ .test.ts)
├── hooks/
│   ├── useDevicePreference.ts         # NEW [value, setValue] backed by devicePreference
│   └── useElementWidth.ts             # NEW ResizeObserver width of a container
├── components/
│   ├── icons/Icons.tsx                # + PanelRightIcon
│   └── layout/ChatPanelRail.tsx       # NEW "Show Buddy chat" rail
├── features/
│   ├── radial-view/                   # NEW feature
│   │   ├── components/RadialDayChart.tsx   # the SVG chart + labels
│   │   ├── components/RadialBoard.tsx      # EditingBoard drop-in: toolbar + chart
│   │   ├── components/BoardViewSwitch.tsx
│   │   └── utils/
│   │       ├── radialGeometry.ts      # angles, slice paths, overlap lanes (+ .test.ts)
│   │       ├── radialLabels.ts        # labels around the ring (+ .test.ts)
│   │       └── radialFormat.ts        # duration text (+ .test.ts)
│   ├── onboarding/components/
│   │   ├── BoardToolbar.jsx           # + boardTools prop (hide zoom + Gap clear)
│   │   ├── BuddyChat.jsx              # + onHide prop (hide button in header)
│   │   └── DefaultRoutineEditor.tsx   # + view prop
│   ├── reflection/components/CompareBoards.jsx   # + view prop
│   ├── daily/pages/DailyRoutinePage.jsx          # switch, radial branch, chat panel
│   └── default-routine/pages/DefaultRoutinePage.tsx  # switch, chat panel
├── App.css                            # .rv-* styles, [data-chat='hidden'] grid rules
e2e/radial-view.spec.ts                # NEW journey
CLAUDE.md                              # document radial view + chat panel
```

**Structure Decision**: The chart is new, shared behaviour, so it gets its own feature folder, `features/radial-view/`. Pages import it the way they import `EditingBoard`. The device preference helper and the two hooks are app-wide, so they go in `lib/` and `hooks/`. Onboarding passes no `view`, so it stays vertical.

## Design Notes

- **Where the switch sits**: in `PageHeader` actions on both pages (Default routine: next to Weekday/Weekend). It works the same whatever the board shows.
- **Swapping boards**: `RadialBoard` takes `EditingBoard`'s prop names, so each page only picks the component (`view === 'radial' ? RadialBoard : EditingBoard`).
- **Toolbar in Circle view**: Today and Compare still render `BoardToolbar` with `boardTools={false}`. This hides zoom and Gap clear, which only act on the timeline. Clock, Reset day, Clean up, Reflection toggle and + Add task stay. The Default routine editor does the same, so "Copy Weekday to Weekend" stays available.
- **Click handling**: `RadialDayChart` gets `onTaskClick = handlers.onRequestEditTask`. On a narrow screen in Reflection this is already the popup handler, so FR-005 comes for free. With no handler (plan shown view-only before a reflection exists), labels render as plain text.
- **Chat panel**: page root `data-chat="shown|hidden"`. Hidden on wide screens means the grid column shrinks to `--sidebar-rail-width`, the `BuddyChat` aside gets `display:none` but stays mounted (keeps thread and unsent text), and `ChatPanelRail` shows the "Show Buddy chat" button. At ≤ 760px the attribute is ignored and the existing board/chat swap applies.

## Complexity Tracking

None.
