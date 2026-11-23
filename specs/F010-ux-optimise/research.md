# Research: F010 UX optimise

## R1. Always-live clock

**Decision**: Reduce `BoardClock` to `{ currentTime }`. Remove `isLive`, `setIsLive`, `setCurrentTime`, the Pause/Resume button, the slider and the "Paused" pill. The clock ticks every minute and also refreshes on `visibilitychange` (tab shown again), so the time is right at once after sleep (spec edge case).

**Rationale**: Pausing and the slider were the only writers of `isLive` and `setCurrentTime`. Removing them makes the "stale time" state impossible (SC-001). The "Live" badge stays (spec Assumptions).

**Alternatives**: Keep the API and hide the controls. Rejected: it leaves dead state behind (constitution IX: remove what's replaced).

## R2. "More" menu when the toolbar is narrow

**Decision**: Use a CSS **container query** on the toolbar (`container-type: inline-size`). Above a toolbar width of about 900px (tuned by measuring the full toolbar), the secondary tools show inline and "More" is hidden. Below it, the inline group is hidden (`display: none`) and "More" shows. The secondary tools are rendered in both places, and only one place is visible at a time, so the accessibility tree has no duplicates.

**Rationale**: Measuring with a ResizeObserver would need extra JS. A container query reacts to the toolbar's own width (the spec says "can't fit", not a screen breakpoint), works the same in the Plan | Reality compare toolbar, and resizing while open can't leave a tool lost or doubled (the panel hides with "More").

**Alternatives**:
- ResizeObserver with a `scrollWidth` check: exact, but more code and re-render loops. Rejected.
- Media query on the window width: wrong when the sidebar or chat take space. Rejected.

## R3. Menu widget

**Decision**: A small `ToolbarMoreMenu` (`.tsx`), using the **disclosure** pattern: a "More" button with `aria-expanded` and `aria-controls`, and a panel of ordinary buttons. It closes on Escape (focus returns to "More"), a pointer down outside, or clicking an item. Zoom items carry `data-keep-open` so they can be pressed repeatedly.

**Rationale**: Disclosure plus native buttons gives Tab order, labels and disabled states for free. A full ARIA `menu` would need roving focus, which is more code for no user gain here.

**Alternatives**: The `popover` attribute. Rejected: placing it next to the button needs CSS anchor positioning, which isn't safe across all target browsers.

## R4. Duration as hours + minutes

**Decision**: Pure helpers `splitDuration(total) → { hours, minutes }` and `joinDuration(hours, minutes) → total` in `features/onboarding/utils/duration.ts`, with unit tests. The dialog shows two number fields: Hours (0–24, step 1) and Minutes (0–59, step 1). Validation stays on the total (1–1440): "Duration must be between 1 minute and 24 hours."

**Rationale**: Step 1 removes today's hidden step-5 browser block (a 92-minute AI task couldn't be saved). The API still takes `durationMinutes`, so no backend change.

## R5. Color on Today

**Decision**: Drop `showColor={false}` in `DailyRoutinePage`. The palette, Custom color and "no color → server picks the next one" behaviour already exist (F005), and the daily create/update payloads already carry `color`.

## R6. Sign out

**Decision**: Remove the button from `PageHeader` (every shell page). Profile keeps its own Sign out. The e2e `signOut` helper switches to opening Profile (sidebar "Open profile" link), then Sign out.

## R7. Tests (constitution II)

- Unit: `duration.test.ts` (0, 30, 60, 95, 1440, minutes > 59, negative/NaN).
- E2E: new `e2e/today-board.spec.ts` (routine editing had no e2e): no slider, Pause or header Sign out. Add a 1 h 30 colored task. At narrow width, "More" opens, Gap clear toggles, and Escape closes it.
- Update `e2e/reflection.spec.ts` `addTask` (two number fields now) and `e2e/helpers.ts` `signOut`.
- No new component test: the menu is covered by e2e, because jsdom can't evaluate container queries.
