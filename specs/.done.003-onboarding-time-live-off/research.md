# Research: Live Clock Off During Onboarding

All decisions below come from reading the current code. There were no open technical unknowns.

## Current state

`ui-personal-routine-manager/src/features/onboarding/components/EditingBoard.jsx` is shared by the setup screen (`OnboardingPage.jsx`) and the dashboard (`DailyRoutinePage.jsx`). Its live clock is made of:

| Piece | Code |
|-------|------|
| Clock state | `currentTime`, `isLive` (`useState`) |
| Ticking | `useEffect` on `isLive` with a 60 s `setInterval` |
| Auto-scroll to now | `useEffect` on `[currentTime, boardHeightPx]`: `scrollTop = currentTime/1440 * height - 260` |
| Toolbar readout | `.ob-board-time` (time + "Live"/"Manual") |
| Pause/Resume button | first button in `.ob-board-actions` |
| Slider | `.ob-board-slider-wrap` (range input) |
| Now-line | `.ob-board-now-line` |
| Current-task highlight | `isActive` → `is-active` class on each task |
| Status line | `activeTask` → `.ob-board-status` "Now: …" |

`OnboardingPage` renders **one** `EditingBoard` and swaps `routine={activeRoutine}` when the Weekday/Weekend tab changes, so the board is not remounted on a tab switch.

## R1: How to switch the clock off

- **Decision**: add an optional prop `liveClock` (boolean, default `true`) to `EditingBoard`. `OnboardingPage` passes `liveClock={false}`. The dashboard passes nothing and keeps today's behaviour.
- **Rationale**: one small, explicit switch; the dashboard needs no change (FR-006); follows the existing optional-prop pattern (`onToggleComplete`, `onPersistError`).
- **Alternatives considered**:
  - Hide with CSS on the setup screen: the timer still runs, the board still jumps to now and tasks still get `is-active`. Fails FR-002/FR-003.
  - A separate setup-only board component: duplicates ~500 lines of drag/zoom logic.

## R2: What "off" does inside the board

- **Decision**: when `liveClock` is `false`:
  - the ticking effect does nothing (no interval);
  - the toolbar readout, the Pause/Resume button, the slider, the now-line and the "Now: …" status line are not rendered;
  - no task gets `is-active`;
  - the auto-scroll-to-now effect does not run (R3 replaces it).
  Zoom, Gap clear, Reset day, drag/resize, click-to-create and the hover tooltip are untouched (FR-005).
- **Rationale**: not rendering is simpler and safer than rendering hidden; nothing time-based runs.
- **Toolbar layout**: with the readout gone, the zoom group becomes the first item in `.ob-board-toolbar` (`justify-content: space-between`), which matches the mockup (zoom and Gap clear on the right side of the header). No CSS change expected; check in the quickstart.

## R3: Opening at 06:00

- **Decision**: when the clock is off, scroll the board so 06:00 is at the top of the view:
  - once the routine first loads, and
  - whenever the routine changes identity (`routine?.id`), i.e. on a Weekday/Weekend switch.
  A refresh after a save keeps the same id, so the user's scroll position is not reset by saving.
- **Helper**: a pure function `scrollTopForMinutes(minutes, boardHeightPx, offsetPx = 0)` in `features/onboarding/utils/boardScroll.ts` (clamped at 0), unit tested. The dashboard's existing "now − 260 px" formula is left as it is.
- **Alternatives considered**: `key={scheduleMode}` on the board remounts it on tab switch, but it also resets zoom and any drag state. Keying the scroll effect on the routine id is narrower.

## R4: Zoom while the clock is off

- **Decision**: today, zoom re-centres on the current time (the auto-scroll effect depends on `boardHeightPx`). With the clock off, zoom keeps the time that is at the top of the view where it is: before the height changes, read the top minute from `scrollTop`; after, scroll back to it with the same helper.
- **Rationale**: without this, zooming would either jump to 06:00 or keep a pixel offset that now points to a different time. Neither matches FR-003 ("does not move by itself").
- **Alternative considered**: leave scroll untouched on zoom. The view drifts to another time of day, which feels like the board moving by itself.

## R5: Testing

- **Decision**: unit-test `scrollTopForMinutes` with Vitest (pure logic, the repo's test convention). Check the UI by hand with `quickstart.md`, optionally with the headless Chrome script used for feature 002.
- **Rationale**: the repo has no DOM test setup (`CLAUDE.md`: "Tests cover pure logic only").
