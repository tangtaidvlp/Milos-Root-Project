# Contract: board props and behaviour (UI)

## `BoardProps` changes (`features/board/types/board.ts`)

| Prop | Change |
|---|---|
| `gapClearMode?: boolean` | Renamed to **`pushMode?: boolean`** (shared Push mode state; timeline only). |
| `onPersistTaskChange?: (tasks) => unknown` | Unchanged signature. The returned promise **must settle after the board's `routine` prop shows the saved data**, and reject on failure. All current pages already do this. |
| `onPersistError?` | The timeline no longer calls it: the timeline shows its own bottom message. The circle view still uses it. |

`BoardToolbar`: `gapClearMode` / `onToggleGapClear` → **`pushMode` / `onTogglePushMode`**.

## Visible behaviour (for tests)

- **Toolbar button**: "Push mode" (`aria-pressed`; text "✓ Push mode" when on). Turning it on shows a status notice at the bottom: "Push mode is on: moving or resizing a task pushes the other tasks."
- **Hold**: a press held 300 ms without moving more than 5 px arms the drag. The task gets the `is-dragging` highlight.
- **Blocked drop**: while the preview breaks the cap, the dragged task is marked `data-blocked="true"`. On drop, nothing is saved and an alert at the bottom says "A time slot can hold at most 3 tasks."
- **While saving**: the board has `aria-busy="true"` and shows a status "Saving…" (three dots). Tasks, track clicks and the toolbar don't respond.
- **Save failure**: the tasks return to their pre-drag positions. An alert at the bottom shows the server's 4xx message, or "Something went wrong. Your change wasn't saved."
- **Overlap**: overlapping blocks share the width (up to 3 side by side).
