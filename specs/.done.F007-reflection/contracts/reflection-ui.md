# UI contract: reflection layout (enhancement 2026-11-22)

The backend API is unchanged (see `reflection-api.md` and `reflection-chat-api.md`). This file pins down the component interfaces and the accessible names that tests rely on.

## Accessible names and roles (used by e2e)

| Element | Role / name | State |
|---|---|---|
| Reflection toggle | `button` named "Reflection" | `aria-pressed="true|false"`, `disabled` on future days |
| Future-day hint | text "You can reflect once the day has happened." | visible when the toggle is on and a future date is shown |
| Summary strip | `region` named "Plan vs reality" | shown when Reflection is on and the reflection exists |
| Side-by-side boards | `region` named "Plan" and `region` named "Reality" | only at ≥ 1280px with Reflection on |
| Per-column add | `button` named "Add to plan" / "Add to reality" | side-by-side only |
| Buddy's note | inside the Buddy chat (`complementary`); button "Get Buddy's note" / "Refresh note" | reflection mode |
| Task status pop-up | `dialog` named after the task; contains a status chip, "Edit" and "Close" | < 1280px, reflection mode, task clicked |
| Page marker | `.dr-page[data-reflection="on|off"]`, `[data-layout="single|compare"]` | — |

## Components

- `ReflectionToggle({ on, disabled, onToggle })`
- `ReflectionSummaryStrip({ view })`
- `ReflectionNote({ view, onRequestFeedback })`
- `ReflectionTaskPopup({ item, onEdit, onClose })`. `item` is a `ComparisonItem`, or null when the pop-up is closed.
- `CompareBoards({ planRoutine, reflectionRoutine, planHandlers, realityHandlers, toolbarActions, planActions })`
- `EditingBoard` gains these optional props:
  - `showToolbar = true`
  - `clock?: { currentTime, isLive, setIsLive, setCurrentTime }`
  - `gapClearMode?: boolean`
  - `scrollContainerRef?: (el) => void`
- `BoardToolbar({ clock?, zoom, gapClearMode, onToggleGapClear, onResetDay, actions })`
- `BuddyChat` gains `topSlot?: ReactNode` and `compactHeader?: boolean`.
- Hooks:
  - `useMediaQuery(query): boolean`
  - `useBoardClock({ enabled }): clock`
  - `useSyncedScroll(): (el) => void`
