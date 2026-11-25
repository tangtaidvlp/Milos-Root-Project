# UI Contract: Radial 24H View

No HTTP changes. This is the component and DOM contract that pages, tests and e2e rely on.

## `RadialDayChart` (`features/radial-view/components/RadialDayChart.tsx`)

```ts
type RadialDayChartProps<T extends RadialTask> = {
  tasks: T[]
  label: string                     // accessible name, e.g. "Plan"; shown in the centre without a live clock
  onTaskClick?: (task: T) => void   // absent = view-only: rows are plain text, arcs not clickable
  showCompletion?: boolean          // default false; true on Today's plan (Done badges)
  currentTime?: number              // live clock minutes; absent = no hand, elapsed arc, centre time or Now badge
  width: number; height: number     // measured board body (RadialBoard)
}
```

- Root: `<figure aria-label={label} data-board-view="radial">`, class `is-ring` (labels around the clock with leader lines) or `is-stacked` (clock radius would be < 100px: labels listed under the clock, no lines). The SVG is `aria-hidden`; tasks are announced through the labels.
- Labels: `<ul>` in start order. Each label is a `<button>` (when `onTaskClick` is passed), accessible name `"{name}, {HH:mm} to {HH:mm}, {duration}"` plus `", now"` or `", done"`. Min target 24×24px, visible focus.
- Clicking an arc or a label calls `onTaskClick(task)` once.
- Empty `tasks`: clock only, no list.

## `RadialBoard` (`features/radial-view/components/RadialBoard.tsx`)

Drop-in for `EditingBoard`: takes the same prop names, so a page picks `const Board = view === 'radial' ? RadialBoard : EditingBoard` and keeps its JSX.

- Uses: `routine` (`routine?.tasks`), `label` (default "24-hour circle"), `onRequestEditTask` → `onTaskClick`, `showCompletion` (default `true`, as on `EditingBoard`), `liveClock` (default `true`), `showToolbar` (default `true`), `clock`, `toolbarActions`, `toolbarMenuActions`, `onResetDay`, `resetDisabled`.
- Ignores drag/scroll props (`onPersistTaskChange`, `onRequestCreateTask`, `onToggleComplete`, `onRequestDeleteTask`, `gapClearMode`, `scrollContainerRef`, `onPersistError`).
- Toolbar: `BoardToolbar` with `boardTools={false}`, its own `useBoardClock` when no shared `clock` is passed.

## `BoardViewSwitch` (`features/radial-view/components/BoardViewSwitch.tsx`)

```ts
type BoardViewSwitchProps = { value: 'vertical' | 'radial'; onChange: (view: 'vertical' | 'radial') => void }
```

- `role="group"`, `aria-label="Board view"`, two buttons **Timeline** and **Circle** with `aria-pressed`. Uses `.ui-segmented`.
- Placed in `PageHeader` `actions` on Today and Default routine.

## Changed components

| Component | Change |
|---|---|
| `BoardToolbar.jsx` | `boardTools?: boolean` (default `true`). `false` hides zoom and Gap clear, inline and in "More". |
| `CompareBoards.jsx` | `view?: 'vertical' \| 'radial'`. Radial: `RadialBoard` instead of `EditingBoard` in each column (`label` "Plan" / "Reality"); the shared toolbar uses `boardTools={false}`. |
| `DefaultRoutineEditor.tsx` | `view?: 'vertical' \| 'radial'` (default `vertical`; onboarding never passes it). Radial: `RadialBoard` (`liveClock={false}`, same props), so "Copy Weekday to Weekend" stays in its toolbar. Subtitle says "click a task to edit" instead of "drag to move". |
| `BuddyChat.jsx` | `onHide?: () => void` and `panelId?: string`. With `onHide`: an icon button **"Hide Buddy chat"** (`aria-expanded="true"`, `aria-controls={panelId}`) in the header. |
| `DailyRoutinePage.jsx`, `DefaultRoutinePage.tsx` | Own `boardView` and `chatPanel` via `useDevicePreference`; render the switch; root gets `data-board-view` and `data-chat`. |

## `ChatPanelRail` (`components/layout/ChatPanelRail.tsx`)

```ts
type ChatPanelRailProps = { panelId: string; onShow: () => void }
```

- Rendered only while the chat is hidden. One icon button **"Show Buddy chat"** (`aria-expanded="false"`, `aria-controls={panelId}`).
- Focus: after the user hides the chat, focus moves to "Show Buddy chat"; after the user shows it, focus moves to "Hide Buddy chat". Never on page load.

## Page DOM attributes (CSS hooks)

| Attribute | Values | Effect |
|---|---|---|
| `data-board-view` | `vertical` \| `radial` | which board renders |
| `data-chat` | `shown` \| `hidden` | > 760px: hidden → chat column becomes `--sidebar-rail-width`, `.ob-buddy-card` `display:none`. ≤ 760px: no effect (board/chat swap) |
