---
description: "Tasks for F016 Radial 24H View"
---

# Tasks: Radial 24H View

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/ui-radial.md](contracts/ui-radial.md), [quickstart.md](quickstart.md)

**Tests**: Required by the constitution (II) and the frontend `CLAUDE.md` "Testing strategy": Vitest unit tests for every pure function (with edge cases), one Playwright journey. No snapshot tests, no new component tests.

**All paths are relative to `ui-personal-routine-manager/`.** Read `ui-personal-routine-manager/CLAUDE.md` and `codingrules.md` first. Rules: TypeScript strict, `import type` for types, colours and sizes from `src/styles/tokens.css` only (no hex/rgb literals; `src/styles/noRawColors.test.ts`), `.jsx` files get small edits only (don't convert them).

## Workflow (owner decision)

- **Sonnet** implements each phase and its tests, then runs `pnpm lint && pnpm test && pnpm build`.
- **Opus** reviews each phase's diff against spec, plan, contract and constitution, and sends findings (critical/high/medium only).
- Sonnet fixes them, and the loop repeats until Opus approves. Code review and bug fixes run the same loop.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

- [X] T001 Create branch `feat/F016-radial-24h-view` from `main` in the `ui-personal-routine-manager/` repo (`git -C ui-personal-routine-manager checkout -b feat/F016-radial-24h-view`)

---

## Phase 2: Foundational (blocks all stories)

- [X] T002 [P] Create `src/lib/devicePreference.ts`: `readDevicePreference<T extends string>(key: string, allowed: readonly T[], fallback: T): T` and `writeDevicePreference(key: string, value: string): void`, using `window.localStorage` guarded like `src/components/layout/sidebarPreference.ts` (missing, unknown or unreadable value → `fallback`; write errors ignored; never throws; no `window` → fallback). Export the keys and values: `BOARD_VIEW_KEY = 'milos.boardView'`, `BOARD_VIEWS = ['vertical', 'radial'] as const`, type `BoardView`, default `'vertical'`; `CHAT_PANEL_KEY = 'milos.chatPanel'`, `CHAT_PANEL_STATES = ['shown', 'hidden'] as const`, type `ChatPanelState`, default `'shown'`.
- [X] T003 [P] Unit tests in `src/lib/devicePreference.test.ts`: valid value read; missing → fallback; unknown value → fallback; `getItem` throws → fallback; `setItem` throws → no throw; round trip. Use a fake storage object, as `src/components/layout/sidebarPreference.test.ts` does (pass the storage in, or stub `window.localStorage`).
- [X] T004 Create `src/hooks/useDevicePreference.ts`: `useDevicePreference<T extends string>(key, allowed, fallback): [T, (value: T) => void]`. Read once in the `useState` initializer; the setter updates state and calls `writeDevicePreference`. No effect needed.

**Checkpoint**: Opus reviews Phase 2.

---

## Phase 3: User Story 1 – See my day as a 24-hour circle (P1) 🎯 MVP

**Goal**: Today has a Timeline | Circle switch. Circle shows the day as a 24h clock face with labels outside, clicks open the task dialog, and the choice survives a reload.

**Independent Test**: quickstart rows 1–7.

### Pure logic + tests

- [X] T005 [P] [US1] Create `src/features/radial-view/utils/radialGeometry.ts` (pure, no React):
  - `MINUTES_PER_DAY = 1440`. `parseStartMinutes(startTime: string): number | null` accepts `H:mm`, `HH:mm`, `HH:mm:ss` (0–23 h, 0–59 m), else `null`.
  - `minutesToAngle(minutes)`: degrees, 0 = midnight at the top, clockwise, normalised to [0, 360).
  - `pointAt(cx, cy, r, angleDeg)`: `{ x: cx + r·sin θ, y: cy − r·cos θ }`.
  - `slicePath(cx, cy, innerR, outerR, startAngle, sweepDeg)`: SVG path `d`. Wedge when `innerR = 0`, ring segment otherwise. Large-arc flag when sweep > 180. A sweep ≥ 360 draws a full disc/ring (two half arcs), because one arc can't draw 360°. Crossing midnight needs no special case (angles are modular).
  - `assignLanes(items: { id: string; start: number; duration: number }[]): { lanes: Map<string, number>; laneCount: number }`: greedy in start order; lane = the lowest lane with no overlap. Overlap is on the 24h cycle: `[start, start + duration)` may run past 1440 and wrap, and touching ends don't overlap. Empty input → `laneCount` 1.
  - `laneBand(lane, laneCount, radius): { inner: number; outer: number }`: equal bands, lane 0 outermost; one lane → `{ inner: 0, outer: radius }`.
- [X] T006 [P] [US1] Unit tests in `src/features/radial-view/utils/radialGeometry.test.ts`: parse edge cases (`"7:05"`, `"07:05:00"`, `"24:00"`→null, `""`, `"ab"`); angles 0/360/720 min; `slicePath` for a small slice, a > 180° slice, a full day (1440), and 23:00 + 480 min; `assignLanes` with no overlap (1 lane), two overlapping (2 lanes), touching ends (1 lane), an overnight task overlapping an early-morning one; `laneBand` for 1 and 2 lanes.
- [X] T007 [P] [US1] Create `src/features/radial-view/utils/radialLabels.ts` (pure): `layoutLabels(items: { id: string; angle: number }[], opts: { cy: number; anchorRadius: number; slotHeight: number; gap: number; top: number; bottom: number }): { labels: { id: string; side: 'left' | 'right'; y: number }[]; height: number }`. Rules (research R3):
  - `side = angle in [0, 180) ? 'right' : 'left'`.
  - Ideal top `y = cy − anchorRadius·cos θ − slotHeight/2`.
  - Per side: sort by ideal y, then a forward pass `y[i] = max(ideal[i], y[i−1] + slotHeight + gap, top)`. If the last label's bottom passes `bottom`, a backward pass `y[i] = min(y[i], y[i+1] − slotHeight − gap)` without going above `top`.
  - `height = max(bottom, lowest label bottom)` (the chart grows instead of overlapping).
  - Output in input order.
- [X] T008 [P] [US1] Unit tests in `src/features/radial-view/utils/radialLabels.test.ts`: empty → no labels, `height = bottom`; side split at 0°, 90°, 180°, 270°; two labels at the same angle don't overlap (`y` difference ≥ `slotHeight + gap`); eight labels between 105° and 135° (8 × 15-minute tasks 07:00–09:00) never overlap and stay ≥ `top`; too many labels make `height > bottom`.

### Components

- [X] T009 [P] [US1] Create `src/hooks/useElementWidth.ts`: `useElementWidth<T extends HTMLElement>(): [RefCallback<T>, number]`. A `ResizeObserver` (in an effect or ref callback) reports `contentRect.width`, rounded. Without `ResizeObserver` (jsdom), fall back to `getBoundingClientRect().width` once. Clean up on unmount.
- [X] T010 [P] [US1] Add a `boardTools` prop (default `true`) to `src/features/onboarding/components/BoardToolbar.jsx`. When `false`, `secondaryTools` leaves out the zoom group and the Gap clear button, both inline and in the "More" menu. Reset day and `menuActions` stay. Update the JSDoc.
- [X] T011 [US1] Create `src/features/radial-view/components/RadialDayChart.tsx` per [contracts/ui-radial.md](contracts/ui-radial.md) and research R2–R5:
  - Props: `tasks`, `label`, `onTaskClick?`, `showCompletion?`.
  - Skip tasks without `id` or with an unparseable `startTime`; use `durationMinutes` (never `endTime`).
  - Width from `useElementWidth`. Starting constants (tune by eye): `column = clamp(88, 0.3·width, 180)`, `hourRing = 18`, `pad = 8`, `radius = clamp((width − 2·column − 2·hourRing − 2·pad)/2, 32, 220)`, `cx = width/2`, `cy = pad + hourRing + radius`, `slotHeight = 52`, `gap = 4`, `bottom = cy + radius + hourRing + pad`. Labels via `layoutLabels` with `anchorRadius = radius + hourRing`. Memoise the layout on tasks + width.
  - SVG (`aria-hidden`): background disc (`--color-bg-subtle` fill, `--color-border` stroke); one `<path>` per task from `slicePath` with `laneBand`; hour ticks every hour; hour numbers every hour when `radius ≥ 110`, else every 3 h (`--font-size-xs`, `--color-text-secondary`); leader `<polyline>` from the slice's outer edge at mid-angle → `pointAt(radius + hourRing + 4)` → the label's column edge at the label's vertical middle (`--color-border-strong` or the nearest existing border token).
  - Slice colour: `resolveTaskColor(task.color, palette)` from `features/palette` (with `usePalette()`), filled with the accent colour, choosing the light/dark variable the same way `.ob-board-task` does in `src/App.css`; unresolved → a neutral token. Thin stroke in the surface colour between slices.
  - Mid-angle for the label = `minutesToAngle(start + duration/2)`.
  - Labels: `<ul class="rv-labels">` in start-time order. Each `<li>` absolutely positioned (`top = y`, left column `left: 0` with right-aligned text, right column `right: 0`), width = `column`, height = `slotHeight`. Content: colour dot, name (`--font-size-sm`, at most 2 lines, `line-clamp`), time `HH:mm–HH:mm` (`--font-size-xs`).
  - With `onTaskClick`, the label is a `<button type="button">` with `aria-label="{name}, {HH:mm} to {HH:mm}"` (+ `", done"`), `title` = full name, min 24×24px, visible focus. Without it, a plain `<span>`.
  - The slice `<path>` gets `onClick={() => onTaskClick?.(task)}` and a pointer cursor only when clickable.
  - Done (`showCompletion && task.completed`): slice opacity ~0.5, `CheckIcon` in the label, muted text.
  - Root `<figure className="rv-chart" aria-label={label} data-board-view="radial">` with `height` = layout height. No horizontal overflow at 320px.
- [X] T012 [US1] Create `src/features/radial-view/components/RadialBoard.tsx`, a drop-in for `EditingBoard` per the contract:
  - Props `routine`, `label = '24-hour circle'`, `onRequestEditTask`, `showCompletion = true`, `liveClock = true`, `showToolbar = true`, `clock`, `toolbarActions`, `toolbarMenuActions`, `onResetDay`, `resetDisabled`. Accept and ignore the drag props (`onPersistTaskChange`, `onRequestCreateTask`, `onToggleComplete`, `onRequestDeleteTask`, `onPersistError`, `gapClearMode`, `scrollContainerRef`) so pages can spread the same handlers.
  - `const ownClock = useBoardClock(liveClock && !clock)` (as `EditingBoard` does).
  - Render `<section className="ob-timeline-board rv-board" aria-label={label}>`, with `BoardToolbar` (`boardTools={false}`, `clock={liveClock ? (clock ?? ownClock) : null}`, `gapClearMode={false}`, `onToggleGapClear={() => {}}`, `onResetDay`, `resetDisabled`, `actions={toolbarActions}`, `menuActions={toolbarMenuActions}`) when `showToolbar`, then a scrollable body (vertical only) holding `RadialDayChart` (`tasks={routine?.tasks ?? []}`, `onTaskClick={onRequestEditTask}`).
- [X] T013 [P] [US1] Create `src/features/radial-view/components/BoardViewSwitch.tsx`: `<div className="ui-segmented" role="group" aria-label="Board view">` with two `<button type="button">`s, **Timeline** (`vertical`) and **Circle** (`radial`), `aria-pressed`, class `ui-segmented-btn` + `active` like the Weekday/Weekend switch in `DefaultRoutineEditor.tsx`.
- [X] T014 [US1] Add `.rv-*` styles to `src/App.css` (new section `/* ── Radial view (F016) ── */`): `.rv-board` body scrolls vertically, never sideways (`overflow-x: hidden`, `min-width: 0`); `.rv-chart` is `position: relative; width: 100%`; label styles (2-line clamp, ellipsis, focus ring from existing tokens, done style); slice hover; tokens only.
- [X] T015 [US1] Wire Today in `src/features/daily/pages/DailyRoutinePage.jsx`:
  - `const [boardView, setBoardView] = useDevicePreference(BOARD_VIEW_KEY, BOARD_VIEWS, 'vertical')`.
  - Pass `<BoardViewSwitch value={boardView} onChange={setBoardView} />` as `PageHeader` `actions`; check that the header still fits at 320px.
  - Add `data-board-view={boardView}` to the root.
  - In the single-board branch, render `const Board = boardView === 'radial' ? RadialBoard : EditingBoard` with the same props as today, plus `label` ("Reality" when showing reality, else "Day plan"). Reflection single view gets this for free (its handlers already route reality taps to `ReflectionTaskPopup`; view-only plan = no `onRequestEditTask`).
- [X] T016 [US1] Playwright journey `e2e/radial-view.spec.ts`, test "Today circle view" (patterns and helpers from `e2e/today-board.spec.ts`, `e2e/helpers.ts`): `registerAndOnboard`, go to Today, add a task through "+ Add task", press **Circle** (`getByRole('button', { name: 'Circle' })`) → expect `aria-pressed=true` and a label button named `"{task name}, …"`. Click it → the task dialog opens; close it. Reload → **Circle** is still pressed and the label is visible. Press **Timeline** → the timeline board is back.

**Checkpoint**: Opus reviews US1, including screenshots at 320 / 768 / 1366px. Sonnet captures them with a throwaway Playwright script saved in the session scratchpad (not committed): a day with 8 × 15-minute tasks 07:00–09:00, an overnight 23:00 + 8h task and a done task, in light and dark. MVP done.

---

## Phase 4: User Story 2 – Radial view in Default Routine and Reflection (P2)

**Goal**: Same switch and chart on Default routine and in Reflection compare.

**Independent Test**: quickstart rows 8–10, 15.

- [X] T017 [P] [US2] `src/features/reflection/components/CompareBoards.jsx`: add a `view` prop (default `'vertical'`). In radial, use `RadialBoard` instead of `EditingBoard` in both columns (same props; `label` "Plan" / "Reality"; Reality keeps `showCompletion={false}`) and pass `boardTools={view !== 'radial'}` to the shared `BoardToolbar`.
- [X] T018 [US2] `src/features/daily/pages/DailyRoutinePage.jsx`: pass `view={boardView}` to `CompareBoards`.
- [X] T019 [P] [US2] `src/features/onboarding/components/DefaultRoutineEditor.tsx`: add `view?: BoardView` (default `'vertical'`). Pick `RadialBoard` or `EditingBoard` with the same props (`label = BOARD_TITLE[scheduleMode]`); in radial the subtitle ends with "click a task to edit" instead of "drag to move". `OnboardingPage` passes no `view`, so it stays the timeline.
- [X] T020 [US2] `src/features/default-routine/pages/DefaultRoutinePage.tsx`: `useDevicePreference(BOARD_VIEW_KEY, …)`. Render `BoardViewSwitch` next to the Weekday/Weekend switcher in `PageHeader` `actions` (wrap both in one flex container that wraps at narrow widths). Pass `view` to `DefaultRoutineEditor`; add `data-board-view` on the root through `className`/a wrapper if needed.
- [X] T021 [US2] Extend `e2e/radial-view.spec.ts` with "Default routine circle view": set Circle on Today, open Default routine → **Circle** is pressed. Add a Weekday task → its label shows; switch to Weekend → that label is gone. Click a label → the task dialog opens.

**Checkpoint**: Opus reviews US2, with Compare screenshots at 1366px wide.

---

## Phase 5: User Story 3 – Hide the Buddy chat (P2)

**Goal**: On wide screens Buddy chat collapses to a rail like the sidebar, keeps its state, and the choice is remembered.

**Independent Test**: quickstart rows 11–13.

- [X] T022 [P] [US3] Add `PanelRightIcon` to `src/components/icons/Icons.tsx` (mirror of `PanelLeftIcon`) and export it from `src/components/icons/index.ts`.
- [X] T023 [P] [US3] `src/features/onboarding/components/BuddyChat.jsx`: optional `panelId` (set as the `<aside>` `id`) and `onHide`. With `onHide`, an icon button in `.ob-buddy-head` (pushed right) `className="ui-icon-btn is-plain ob-buddy-hide"`, `aria-label="Hide Buddy chat"`, `aria-expanded="true"`, `aria-controls={panelId}`, `<PanelRightIcon />`. Optional `focusHideButton?: boolean`: when it turns true, focus the hide button (effect on that prop only). Update the JSDoc.
- [X] T024 [P] [US3] Create `src/components/layout/ChatPanelRail.tsx`: `{ panelId: string; onShow: () => void; autoFocus?: boolean }`. Renders `<div className="chat-rail">` with one `ui-icon-btn is-plain` button, `aria-label="Show Buddy chat"`, `aria-expanded="false"`, `aria-controls={panelId}`, `<PanelRightIcon />`; focuses it on mount when `autoFocus`.
- [X] T025 [US3] CSS in `src/App.css`, inside `@media (min-width: 761px)` only:
  - `.dr-page[data-chat='hidden']` and `.drt-page[data-chat='hidden']` get `grid-template-columns: minmax(0, 1fr) var(--sidebar-rail-width)`, and their `.ob-buddy-card` gets `display: none`.
  - `.chat-rail` sits in grid column 2, rows 1 / -1, with `border-left: 1px solid var(--color-border)`, padding like the sidebar rail (`src/components/layout/AppShell.css`).
  - At ≤ 760px: `.chat-rail` and `.ob-buddy-hide` get `display: none`.
- [X] T026 [US3] `src/features/daily/pages/DailyRoutinePage.jsx`:
  - `const [chatPanel, setChatPanel] = useDevicePreference(CHAT_PANEL_KEY, CHAT_PANEL_STATES, 'shown')`, plus a `useState` flag `chatToggled` (true after a user toggle in this mount).
  - Root `data-chat={chatPanel}`.
  - Both `BuddyChat`s get `panelId="buddy-chat"`, `onHide={() => { setChatToggled(true); setChatPanel('hidden') }}` and `focusHideButton={chatToggled && chatPanel === 'shown'}`.
  - When hidden, render `<ChatPanelRail panelId="buddy-chat" autoFocus={chatToggled} onShow={…'shown'} />`.
  - Keep `BuddyChat` mounted in both states (don't render it conditionally on `chatPanel`).
- [X] T027 [US3] `src/features/default-routine/pages/DefaultRoutinePage.tsx`: the same wiring. Each tab's `BuddyChat` gets `panelId={`buddy-chat-${tab}`}`; the rail's `panelId` is the active tab's. `data-chat` goes on the page root: `DefaultRoutineEditor` renders the root, so add an optional `rootProps`/`dataChat` prop or wrap, whichever is smaller. Render the rail through `renderAside` after the chats.
- [X] T028 [US3] Extend `e2e/radial-view.spec.ts` with "Hide Buddy chat" (desktop viewport 1366×768): on Today type text in the chat input without sending, press **Hide Buddy chat** → the chat input is hidden and **Show Buddy chat** is focused. Reload → still hidden. Press **Show Buddy chat** → the chat is visible (typed text kept before the reload is not required; check text kept in a second hide/show cycle without reload).

**Checkpoint**: Opus reviews US3.

---

## Phase 6: Polish

- [X] T029 [P] Update `ui-personal-routine-manager/CLAUDE.md`: add F016 to "Done"; a **radial view** bullet under Feature behavior (`features/radial-view/`, `RadialBoard` drop-in, `BoardViewSwitch`, `milos.boardView`, onboarding stays timeline); a **chat panel** line next to **sidebar** (`milos.chatPanel`, rail, stays mounted); `src/lib/devicePreference.ts`; the `boardTools` prop in the Board API line; `radial-view` in the E2E list.
- [X] T030 Run `pnpm lint && pnpm test && pnpm build`, then `pnpm test:e2e e2e/radial-view.spec.ts e2e/today-board.spec.ts e2e/reflection.spec.ts` (backend: `SPRING_PROFILES_ACTIVE=fast SPRING_AI_ACTIVE=false ./gradlew bootRun`). All green; report the outputs.
- [X] T031 Final Opus review: the whole diff against [quickstart.md](quickstart.md) rows 1–15 (screenshots for the visual rows), the constitution VI checklist, and no leftover dead code.

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 → US1 (Phase 3) → US2 (Phase 4). US2 needs `RadialBoard` and `BoardViewSwitch` from US1.
- US3 (Phase 5) depends only on Phase 2; it can run before or after US1/US2. It touches the same two page files, so run it after US2 to avoid conflicts.
- Polish after all stories.

### Parallel opportunities

- Phase 2: T002 + T003 together, then T004.
- US1: T005–T010 and T013 are independent files, so run them together; then T011 → T012 → T014 → T015 → T016.
- US2: T017 and T019 together; then T018, T020, T021.
- US3: T022, T023, T024 together; then T025 → T026 → T027 → T028.

## Implementation Strategy

1. **MVP**: Phases 1–3 (Today circle). Stop, run the review loop, validate quickstart rows 1–7.
2. Add US2, then review.
3. Add US3, then review.
4. Polish, then the final review. Don't commit or push until the owner asks.
