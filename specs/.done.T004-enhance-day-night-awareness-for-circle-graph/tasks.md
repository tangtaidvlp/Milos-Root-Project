# Tasks: Day & night awareness for the circle graph

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md). Paths are under `ui-personal-routine-manager/`.

## Phase 1: Foundational (blocks all stories)

- [x] T001 Add the clock tokens from research R5 (`--color-clock-night-band`, `-day-band`, `-night-ink`, `-sun`, `-day-ink`, `-night-track`, `-day-track`, `-night-tone`, `-day-tone`, plus a pill background for 06/18 in dark mode) to `src/styles/tokens.css`, light in `:root`, dark overrides in `:root[data-theme="dark"]`
- [x] T002 Add the clock pairs to `src/styles/contrast.test.ts`: night-ink and day-ink ≥ 4.5 on their band; sun ≥ 3 on day band; night-tone and day-tone ≥ 3 on `--color-bg-surface`; both themes
- [x] T003 [P] Add `annulusPath(cx, cy, inner, outer, startAngle, sweepDeg)` (filled ring segment, closed path) to `src/features/radial-view/utils/radialGeometry.ts` with tests in `radialGeometry.test.ts` (start/end points on both radii, 180° sweep, sweep 0 → empty string)

## Phase 2: User Story 1 – Day and night halves (P1)

**Independent test**: quickstart rows 1, 2, 6, 8.

- [x] T004 [P] [US1] Create `src/features/radial-view/components/DayNightIcons.tsx` with `SunIcon` and `MoonIcon` (paths from `resources/icon-sun.svg` / `icon-moon.svg`, `stroke="currentColor"`, no metadata, `aria-hidden`), usable inside the chart's SVG
- [x] T005 [US1] In `src/features/radial-view/components/RadialDayChart.tsx` draw the band as two `annulusPath` halves (night 270°→90°, day 90°→270°) between the disc and the track's inner edge, under the arcs
- [x] T006 [US1] In `RadialDayChart.tsx` split the rim track into a night arc and a day arc (two 180° `arcPath` strokes, night/day track tokens), replacing the single `.rv-track` circle
- [x] T007 [US1] In `RadialDayChart.tsx` place the moon + "NIGHT" at the top of the band and the sun + "DAY" at the bottom, centred in the band; icon + label from a 36 px band, icon only from 22 px (research R4)
- [x] T008 [US1] Create `src/features/radial-view/components/RadialDayChart.module.css` with the rules for the new band, track halves, icons and labels (tokens only; label: small caps-style uppercase, semibold, letter-spacing as in the sketch)

## Phase 3: User Story 2 – Smaller centre disc (P2)

**Independent test**: quickstart row 3.

- [x] T009 [US2] In `RadialDayChart.tsx` set `discRadius = 0.62 × radius` (research R1) and start the now hand at the disc edge; centre text keeps fitting (sizes already scale from `discRadius`)

## Phase 4: User Story 3 – Minute marks and tinted hours (P3)

**Independent test**: quickstart rows 4, 5, 7.

- [x] T010 [US3] In `RadialDayChart.tsx` add minor ticks every 15 minutes (not on the hour), only when `radius >= 90`; style them shorter/lighter in `RadialDayChart.module.css`
- [x] T011 [US3] Tint hour ticks and numbers by half (19–23, 01–05 night tone; 07–11, 13–17 day tone; 00/06/12/18 stay neutral `is-major`) and, in dark mode, draw 06 and 18 in a pill (`RadialDayChart.tsx` + module CSS)

## Phase 5: Polish

- [x] T012 Run `pnpm lint && pnpm test && pnpm build` and the e2e suite (`radial-view`, then all); fix anything red without changing test behaviour
- [x] T013 Screenshot the circle in light and dark (wide and 375 px) and compare with `resources/day-clock-*.png` (quickstart rows 1–8)
- [x] T014 Update the radial view paragraph in `ui-personal-routine-manager/CLAUDE.md` (one line: day/night face, T004)

## Dependencies

T001 → T002, T005–T011. T003 → T005. T004 → T007. US1 → US2 → US3 (same file, sequential). Polish last.

## Strategy

MVP = Phase 1 + US1. One developer, one file mostly, so the stories run in order.
