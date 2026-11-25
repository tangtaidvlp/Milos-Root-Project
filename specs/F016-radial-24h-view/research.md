# Research: Radial 24H View

## R1. How to draw the chart

- **Decision**: hand-written SVG (`<path>` arcs, `<line>` ticks, `<polyline>` leader lines) inside a `position: relative` box. Labels are HTML elements placed absolutely over it.
- **Rationale**: a pie of at most ~50 slices is a few dozen lines of geometry. HTML labels give native text wrapping, focus rings and `<button>` semantics for free.
- **Alternatives**: a chart library (Recharts, d3-shape) adds a dependency for one chart, and its labels are SVG text, which can't wrap or be buttons. Canvas is not accessible and can't be clicked per slice without extra work.

## R2. Keeping text readable at every width

- **Decision**: lay out in real CSS pixels from the measured board size (`ResizeObserver`), not an SVG `viewBox`, so text never scales. Label column `clamp(170px, 22% of width, 200px)`; ring radius = what fits the width (two columns) and height; clock radius R from `ring = max(1.2R, R + 32)` (32px = ticks + hour numbers), capped at 240px. Below R = 100px the labels list under a full-width clock.
- **Rationale**: the spec says the clock shrinks before the text does.
- **Alternatives**: `viewBox` scaling (text gets too small).

## R3. Placing labels around the clock without overlap (`radialLabels.ts`)

- **Decision**: label ring layout:
  1. Mid-angle θ of each task; right half (0–180°) labels go right, the rest left. Ideal y = `cy − ring · cos θ`.
  2. A side with more labels than fit gives its labels within 30° of midnight/noon to the other side (short leaders only).
  3. Overlapping labels merge into clusters centred on their ideal heights; a column that fits stays inside the ring range, an overloaded one is centred on it and the chart grows evenly.
  4. x follows the ring: the box's inner edge sits at `cx ± √(ring² − d²)`, d = distance from `cy` to the box's nearest edge.
  5. Leader: arc edge at θ → just outside the hour numbers at θ → label's inner edge, in the task's pastel colour, under the numbers (which have a surface-colour halo).
  - Label: 40px slot, the piece-information style (bar, name + badge, time · duration).
- **Rationale**: pure and unit-tested; fixed slots guarantee no overlap.
- **Alternatives**: one list beside the clock (tried; user wants the curved connectors back); force simulation (overkill).

## R4. Overlapping tasks

- **Decision**: give each task a lane with an interval-colouring pass in start order (lane = the first lane that is free at its start, on the 24h cycle). With L lanes the track splits into L thinner rings, lane 0 outermost. Arcs use round caps, trimmed by the cap radius so an arc covers only its own time; one too short for that is a dot.
- **Rationale**: the backend shifts overlapping daily tasks (`TaskTimeFunctions.shiftOverlappingTasks`), so overlap is rare, but it can still happen (reflection, default routines). Lanes keep both visible as the spec requires.
- **Alternatives**: draw later tasks on top (hides the earlier ones); transparency (hard to read, contrast issues).

## R5. Edge shapes

- **Over midnight**: angles are modulo 360°, so one arc from start to end works (22:00 + 8h = one slice over the top). There is no "main/wrap" split as on the board.
- **Full day (1440 min)**: an SVG arc can't draw 360°, so draw a `<circle>` (or a ring for lanes > 0).
- **Done tasks** (Today, `showCompletion`): slice at reduced opacity. The label gets a check icon, muted text and "done" in its accessible name, like `.ob-board-task.is-done`.

## R6. Saving the two choices

- **Decision**: one helper, `src/lib/devicePreference.ts`: `readDevicePreference(key, allowed, fallback)` and `writeDevicePreference(key, value)`. Neither ever throws (blocked storage = fallback), the same contract as `sidebarPreference.ts`. A `useDevicePreference` hook reads the value once on mount. Keys: `milos.boardView`, `milos.chatPanel`.
- **Rationale**: the spec says per device, not synced (Assumptions). Only one page is on screen at a time, so reading on mount is enough; no cross-component store.
- **Alternatives**: account settings (`settingsSchema` + backend registry), rejected by the spec's per-device assumption; a module-level store (not needed).

## R7. Hiding the chat without losing it

- **Decision**: keep `BuddyChat` mounted and hide it with CSS under `[data-chat='hidden']`. The hide button is in the chat header (`onHide` prop, `aria-expanded="true"`, `aria-controls`). `ChatPanelRail` holds the show button. This mirrors the sidebar's "Hide sidebar" / rail "Show sidebar".
- **Rationale**: unmounting would drop the unsent text and reload history (FR-011).
- **Alternatives**: unmount and keep the draft in state (more code, and history reloads).
