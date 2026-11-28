# Implementation Plan: Day & night awareness for the circle graph

**Branch**: `feat/T004-day-night-circle` | **Date**: 2026-11-28 | **Spec**: [spec.md](spec.md)

## Summary

Redraw the clock face of `RadialDayChart` (UI only): a night half (top, 18:00 → 06:00) and a day half (bottom) with their own band fill, rim track colour, icon and label; a smaller centre disc (≈ 0.6 × clock radius); a mark every 15 minutes; hour marks/numbers tinted by half. Tasks, hand, labels and drag logic stay as they are. See [research.md](research.md).

## Technical Context

**Language/Version**: TypeScript 5, React 19 (`ui-personal-routine-manager`)

**Primary Dependencies**: none new. Hand-written SVG, as today.

**Storage**: N/A (no data, no API change, no backend change)

**Testing**: Vitest (unit tests for the new pure geometry), `contrast.test.ts` and `noRawColors.test.ts` (new tokens), Playwright `e2e/radial-view.spec.ts` (must stay green), visual check against the sketches with [quickstart.md](quickstart.md)

**Target Platform**: modern browsers, 320 px and up, light and dark theme

**Project Type**: web SPA (frontend only)

**Performance Goals**: no visible change; at most ~100 extra static SVG lines (minute marks), computed in the existing `useMemo` layout

**Constraints**: colours only from `tokens.css` (light in `:root`, dark overrides); WCAG 2.2 AA; decoration `aria-hidden`; existing e2e selectors (`.rv-centre`, `.rv-arc`) unchanged

**Scale/Scope**: 1 component, 1 geometry util, tokens, 1 new CSS module, 1 small icon component

## Constitution Check

| Gate | Status |
|---|---|
| II Testing: unit-test new pure logic; keep e2e journeys green | Pass: half-annulus path + minute marks get unit tests; `radial-view` e2e re-run |
| VI Accessibility: AA contrast in both themes, decoration hidden from screen readers, 320 px | Pass: new token pairs added to `contrast.test.ts`; SVG stays `aria-hidden`; small clocks hide extras |
| Styling: tokens only, CSS Module for new rules | Pass: new `--color-clock-*` tokens; new rules in `RadialDayChart.module.css`; existing `rv-*` classes that e2e selects stay in `App.css` |
| Security | N/A: static SVG icons inlined as path data (metadata stripped), no external assets, no user input |

No violations. Post-design re-check: same result.

## Project Structure

### Documentation

```text
specs/T004-enhance-day-night-awareness-for-circle-graph/
├── spec.md, plan.md, research.md, quickstart.md, tasks.md
└── resources/   # sketches + icons (design source of truth)
```

### Source Code (`ui-personal-routine-manager/`)

```text
src/styles/tokens.css                                   # + --color-clock-* tokens (light + dark)
src/styles/contrast.test.ts                             # + clock pairs
src/features/radial-view/utils/radialGeometry.ts        # + annulusPath(), quarterMarks helper
src/features/radial-view/utils/radialGeometry.test.ts   # + tests
src/features/radial-view/components/DayNightIcons.tsx   # new: SunIcon, MoonIcon (inline SVG paths)
src/features/radial-view/components/RadialDayChart.tsx  # face: bands, split track, disc ratio, marks, icons/labels
src/features/radial-view/components/RadialDayChart.module.css  # new: rules for the new face elements
src/App.css                                             # .rv-track / .rv-tick / .rv-hour tweaks only where needed
```

**Structure Decision**: everything stays in `features/radial-view/`; no new feature or shared code.
