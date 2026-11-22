# UI Contract: `EditingBoard` `liveClock` prop

File: `ui-personal-routine-manager/src/features/onboarding/components/EditingBoard.jsx`

## New prop

| Prop | Type | Default | Meaning |
|------|------|---------|---------|
| `liveClock` | `boolean` | `true` | `true`: today's live clock behaviour, unchanged. `false`: no clock UI, no timer, no current-task highlight; opens at 06:00. |

All other props are unchanged.

## Callers

| Page | Passes | Result |
|------|--------|--------|
| `features/onboarding/pages/OnboardingPage.jsx` | `liveClock={false}` | setup screen without the live clock |
| `features/daily/pages/DailyRoutinePage.jsx` | nothing | dashboard unchanged |

## Guarantees when `liveClock={false}`

- These are absent from the DOM: `.ob-board-time`, the Pause clock / Resume live button, `.ob-board-slider-wrap`, `.ob-board-now-line`, `.ob-board-status`.
- No `.ob-board-task` has the class `is-active`.
- No interval timer is running.
- After the routine loads, and after `routine.id` changes, `.ob-board-scroll` is scrolled so 06:00 is at the top, with 16 px (`SETUP_SCROLL_OFFSET_PX`) above it so the 06:00 label isn't cut off.
- Saving (same `routine.id`) does not change the scroll position.
- Zooming keeps the time of day at the top of the view in place.
- `data-tour="routine-board"` (feature 002's tour anchor) is unaffected.

## Helper

`features/onboarding/utils/boardScroll.ts`

```ts
scrollTopForMinutes(minutes: number, boardHeightPx: number, offsetPx?: number): number
// minutes / 1440 * boardHeightPx - offsetPx, never below 0
```
