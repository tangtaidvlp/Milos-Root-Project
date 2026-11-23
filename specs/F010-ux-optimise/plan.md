# Implementation Plan: UX optimise (Today board)

**Branch**: `F010-ux-optimise` | **Date**: 2026-11-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F010-ux-optimise/spec.md`

## Summary

This is a frontend-only clean-up of the board:
- Remove the time slider and pausing (the clock is always live).
- Remove "Sign out" from page headers.
- Fold the secondary toolbar tools into a "More" disclosure when the toolbar is narrow (CSS container query).
- Give the task dialog hours + minutes everywhere, and the color picker on Today.

No backend or data change. Decisions are in [research.md](research.md).

## Technical Context

**Language/Version**: TypeScript 5 strict / JSX, React 19

**Primary Dependencies**: none new (CSS container queries, native buttons)

**Storage**: N/A (tasks already store `color` and `durationMinutes`)

**Testing**: Vitest unit (`duration.test.ts`), Playwright (new `today-board.spec.ts`, updated `reflection.spec.ts`, `helpers.ts`)

**Target Platform**: Modern evergreen browsers, 320px to desktop

**Project Type**: Web SPA (`ui-personal-routine-manager/`)

**Performance Goals**: No extra re-renders. The clock still ticks once a minute.

**Constraints**: WCAG 2.2 AA (keyboard, focus, 24px targets), tokens only, no horizontal scroll at 320px

**Scale/Scope**: About 8 source files, 1 new component, 1 new util, 3 e2e files

## Constitution Check

| Principle | Status |
|-----------|--------|
| I API contracts | N/A: no API change |
| II Testing | ✅ Unit for the new pure util. Core journey e2e for routine editing (missing so far). Existing e2e updated. No snapshot tests. |
| III Data | N/A |
| IV Security | ✅ Sign out still reachable (Profile). No auth change. |
| V AI | N/A |
| VI Frontend | ✅ New files are `.tsx`/`.ts`. Disclosure pattern with aria-expanded, Escape and focus return. Tokens only. 320px works. |
| VII Supply chain | ✅ No new dependencies |
| VIII Observability | N/A |
| IX Simplicity | ✅ Platform features (container query, native buttons). Dead clock state removed, not hidden. |

Post-design re-check: passes.

## Design

### Clock (US1): `features/onboarding/hooks/useBoardClock.ts`
- `BoardClock = { currentTime: number }`. Remove `isLive`, `setIsLive` and `setCurrentTime`.
- Tick every 60s while `enabled`. Also set the current time on `document` `visibilitychange` when the tab becomes visible.
- Update the comments in `EditingBoard.jsx` that mention Pause, Resume or the slider.

### Toolbar (US1 + US3): `features/onboarding/components/BoardToolbar.jsx`
- Remove `handleSliderChange`, the slider block, the Pause/Resume button and the "Paused" pill (keep the clock and "Live").
- New prop `menuActions` (ReactNode): page tools that may fold into "More" (Today: Clean up). `actions` stays always visible (Reflection, + Add task).
- The secondary group (zoom, Gap clear, Reset day, `menuActions`) is rendered twice:
  - inline: `.ob-board-tools-inline`
  - inside `<ToolbarMoreMenu>`: zoom buttons get `data-keep-open`
- CSS (`App.css`): `.ob-board-toolbar { container-type: inline-size; flex-wrap: nowrap }`. Default: inline shown, `.ob-board-more` hidden. `@container (max-width: ~900px)`: inline hidden, More shown. Remove the `.ob-board-slider*` rules.

### More menu (US3): new `features/onboarding/components/ToolbarMoreMenu.tsx`
- Props: `children`. Local `open` state. The "More" button has `aria-expanded`, `aria-controls` and `aria-haspopup="true"`. The panel is absolutely positioned under the button (right-aligned).
- Closes on Escape (focus back to the button), on `pointerdown` outside the wrapper, and on clicking a button inside the panel unless it is in `[data-keep-open]`.
- The panel stacks its buttons vertically. Targets ≥ 24px.

### Page wiring
- `daily/pages/DailyRoutinePage.jsx`: pass the Clean up button as `menuActions` (single layout, not in reflection). Keep Reflection and + Add task in `toolbarActions`. Remove `showColor={false}`.
- `EditingBoard.jsx`: forward a new `toolbarMenuActions` prop to `BoardToolbar` as `menuActions`.
- Compare view (`CompareBoards.jsx`): unchanged API. Clean up stays in the Plan header, so its toolbar's More holds zoom, Gap clear and Reset day.

### Sign out (US2): `components/layout/PageHeader.tsx`
- Remove the button and `onLogout` from the destructure. Update the doc comment.

### Task dialog (US4)
- New `features/onboarding/utils/duration.ts`: `splitDuration`, `joinDuration` (+ `duration.test.ts`).
- `TaskEditModal.tsx`: state `hours`/`minutes` from `splitDuration(draft.durationMinutes ?? 30)`. Two labelled number inputs ("Hours" 0–24, "Minutes" 0–59, step 1) in one `fieldset` with legend "Duration". On submit, `joinDuration`, validated 1–1440 with the message "Duration must be between 1 minute and 24 hours."

### Tests
- `e2e/helpers.ts` `signOut`: click the "Open profile" link, then "Sign out".
- `e2e/reflection.spec.ts` `addTask(…, minutes)`: fill "Hours" with `Math.floor(m/60)` and "Minutes" with `m%60` by label.
- New `e2e/today-board.spec.ts`: register and onboard, then on Today assert:
  - no `slider` role, no Pause/Resume button, no header Sign out
  - add a 1 h 30 task with a palette color, and see its card with "1h 30m"
  - set the viewport narrow, open "More", toggle Gap clear (`aria-pressed`), check Escape closes it and focus returns.

## Project Structure

### Documentation

```text
specs/F010-ux-optimise/
├── spec.md · plan.md · research.md · quickstart.md
└── checklists/requirements.md
```

No `data-model.md` or `contracts/`: no data or API change.

### Source Code (`ui-personal-routine-manager/`)

```text
src/components/layout/PageHeader.tsx                       # remove Sign out
src/features/onboarding/hooks/useBoardClock.ts             # always live
src/features/onboarding/components/BoardToolbar.jsx        # no slider/pause; inline + More
src/features/onboarding/components/ToolbarMoreMenu.tsx     # NEW
src/features/onboarding/components/EditingBoard.jsx        # forward toolbarMenuActions; comments
src/features/onboarding/components/TaskEditModal.tsx       # hours + minutes
src/features/onboarding/utils/duration.ts (+ .test.ts)     # NEW
src/features/daily/pages/DailyRoutinePage.jsx              # menuActions; color on
src/App.css                                                # container query, More, drop slider
e2e/helpers.ts · e2e/reflection.spec.ts · e2e/today-board.spec.ts (NEW)
```

**Structure Decision**: Existing feature folders. The shared board components stay in `onboarding/components/` (current pattern).

## Risks

- **Threshold value**: the ~900px toolbar width must be tuned against the real toolbar (longest case: Today single board, not in reflection). Too small means it wraps, too big means "More" shows needlessly. Check by hand (quickstart steps 4–5).
- **Other boards**: the Default routine and Onboarding toolbars also get "More" when narrow, since the component is shared. Their behaviour is the same. Checked: no walkthrough target (`data-tour`) is on a folded tool.
