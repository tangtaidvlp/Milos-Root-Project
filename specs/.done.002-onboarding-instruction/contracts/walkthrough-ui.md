# Contract: Walkthrough UI

**Frontend**: `ui-personal-routine-manager/src/features/walkthrough/`

This is the contract between the walkthrough module and the pages that host it (`OnboardingPage`, `DailyRoutinePage`). Text and layout come from [walkthrough-script.md](../walkthrough-script.md) and the mockups in [resources/](../resources/).

---

## Hook

```ts
function useWalkthrough(options: {
  autoOpen?: WalkthroughContext   // OnboardingPage passes 'onboarding'; DailyRoutinePage passes nothing
}): {
  state: WalkthroughState         // see data-model.md §3
  open: (ctx: WalkthroughContext) => void
  dispatch: (event: WalkthroughEvent) => void
}
```

`autoOpen` dispatches `OPEN(ctx)` once per mount. It never reads or writes storage.

---

## Components

```tsx
<IntroSlides
  state={state}            // renders only when state.phase === 'slides'
  dispatch={dispatch}
/>

<GuidedTour
  state={state}            // renders only when state.phase === 'tour'
  dispatch={dispatch}
  onMobileViewChange={(view: 'board' | 'chat') => void}  // OnboardingPage passes setMobileView
/>

<HowItWorksButton onClick={() => open(ctx)} />   // plain text button, top bar
```

**IntroSlides must**:
- render as `role="dialog"` with `aria-modal="true"`, labelled by the slide title
- move focus into the card when it opens, and trap Tab inside it
- **keys**: Esc → `SKIP`. ← → `BACK`. → → `NEXT` (or nothing on the last slide).
- **swipe**: horizontal swipe over 50px → `NEXT`/`BACK`
- **buttons**:
  - Back is hidden on slide 1.
  - Slide 4 shows *I'll explore myself* (`SKIP`) and **Show me around** (`START_TOUR`).
  - In the `app` context, Slide 4 hides *I'll explore myself* and the primary button reads **Close**.
- leave nothing behind when closed: focus returns to the element that had it before opening

**GuidedTour must**:
- find its target with `document.querySelector('[data-tour="<target>"]')`
- **if the target is missing** (for example, hidden on a phone): show the card centered with no spotlight, so it never crashes
- **re-measure the target on**: step change, `resize`, `scroll` (capture), and through a `ResizeObserver` on the target
- **block the page**: intercept clicks on the dimmed area so they do nothing; the target itself is not clickable during the tour
- **keys**: Esc → `END`. ← → `BACK`. → → `NEXT`.
- **step buttons**:
  - Step 1: End tour · Next (no Back).
  - Steps 2–4: End tour · Back · Next.
  - Step 5: Back · **Got it** (no End tour). Got it → `END`.
- **phones (≤760px)**:
  - Show the card as a bottom sheet (or a top sheet when the target is in the lower half).
  - Call `onMobileViewChange` with the step's `mobileView`. When the tour ends, restore the view from before it started.

---

## Target anchors (`data-tour`)

These must exist in the host page (setup screen). The tour visits them in this order:

| `data-tour` | Element | File |
|-------------|---------|------|
| `schedule-switch` | `.ob-segmented` (Weekday / Weekend) | `features/onboarding/pages/OnboardingPage.jsx` |
| `routine-board` | `.ob-canvas-card` (whole board card) | same |
| `add-task` | FAB `+` button | `features/onboarding/components/FabButton.tsx` (pass the attribute through) |
| `routine-buddy` | the visible `BuddyChat` panel | `features/onboarding/components/BuddyChat.jsx` (pass the attribute through) |
| `finish` | "Ready to roll" button | `features/onboarding/pages/OnboardingPage.jsx` |

Changing or removing one of these attributes breaks the tour. Search for `data-tour=` before refactoring these elements.

---

## Pure helpers (unit-tested)

```ts
walkthroughReducer(state: WalkthroughState, event: WalkthroughEvent): WalkthroughState

placeCard(input: {
  target: { top: number; left: number; width: number; height: number } | null
  card: { width: number; height: number }
  viewport: { width: number; height: number }
  side: 'top' | 'bottom' | 'left' | 'right'
  gap?: number              // default 12
}): { top: number; left: number; side: 'top' | 'bottom' | 'left' | 'right' | 'center'; arrowOffset: number }
// Flips to the opposite side when the preferred side doesn't fit, then tries the other axis,
// then 'center'. Always clamps the card inside the viewport with a 16px margin.

routineTypeForTab(tab: 'weekday' | 'weekend'): 'DAILY' | 'WEEKEND'
```
