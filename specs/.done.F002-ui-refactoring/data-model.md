# Data Model: F002 UI Refactoring

**Feature**: [spec.md](./spec.md) · **Research**: [research.md](./research.md)

No backend or database changes. Everything below is client-side state or derived values. Existing server entities (`DefaultRoutine`, `RoutineTask`, `DailyRoutine`, `DailyTask`) are reused unchanged.

## 1. NavEntry (static config)

One item in the sidebar. Defined once in `src/components/layout/navEntries.ts`.

| Field | Type | Rules |
|-------|------|-------|
| `id` | `'today' \| 'default-routine' \| 'analytics'` | Unique |
| `label` | string | "Today", "Default routine", "Analytics" (FR-002) |
| `path` | string | `/today`, `/default-routine`, `/analytics` ([contracts/routes.md](./contracts/routes.md)) |
| `icon` | icon component | `CalendarIcon`, `RepeatIcon`, `BarChartIcon` |
| `badge` | string? | `"Soon"` on Analytics only |

Order is fixed as listed. Active state is derived from the current route, not stored.

## 2. SidebarPreference (device storage)

| Field | Storage | Values | Default |
|-------|---------|--------|---------|
| collapsed (wide screens) | `localStorage["milos.sidebar.collapsed"]` | `"true"` / `"false"` | expanded (`false`) |

- Read with `readSidebarCollapsed(storage): boolean`. Missing, unreadable or any other value → `false`. Storage access that throws → `false` (private browsing edge case).
- Written with `writeSidebarCollapsed(storage, value)`; write failures are ignored.
- Not tied to the user account; shared by all users on that browser.

## 3. SidebarState (runtime, `useSidebar`)

| Field | Type | Source |
|-------|------|--------|
| `isMobile` | boolean | `matchMedia('(max-width: 760px)')` |
| `isCollapsed` | boolean | SidebarPreference; only applies when `!isMobile` |
| `isMobileOpen` | boolean | starts `false`; never stored |

Transitions:

| Event | Wide screen | Narrow screen |
|-------|-------------|---------------|
| Toggle button | `isCollapsed = !isCollapsed`, persist | — |
| Burger button | — | `isMobileOpen = true` |
| Nav entry chosen | no change | `isMobileOpen = false` |
| Backdrop click / Escape | — | `isMobileOpen = false` |
| Resize wide → narrow | — | `isMobileOpen = false` |
| Resize narrow → wide | re-read preference | — |

## 4. RoutineType for a date (derived)

`routineTypeForDate(date): 'DAILY' | 'WEEKEND'`. Saturday and Sunday → `WEEKEND`, otherwise `DAILY` (same rule as the server's `DefaultRoutineService`).

Label: `DAILY` → "Weekday routine", `WEEKEND` → "Weekend routine". Shown in the sidebar user block (for today) and in the Daily header breadcrumb (for the selected date).

## 5. NowAndNext (derived, Daily board footer)

`nowAndNext(tasks, minutesOfDay) → { now: { name, minutesLeft } | null, next: { name, startTime } | null }`

- `now`: the task with `start ≤ minutes < end`. If several overlap, the one that started last. `minutesLeft = end − minutes`.
- `next`: the task with the smallest `start > minutes`.
- Tasks with no valid start time are ignored. An end time of `00:00` means end of day (matches `EditingBoard`).
- Display: "Now  {name} · {n} min left" (or "· {h}h {m}m left" from 60 min), and "Next: {name} at {HH:MM}". Either side hidden when `null`. Shown only while the live clock is on.

## 6. Task tint (derived)

Daily tasks have no colour; default-routine tasks may have one.

- Default-routine task with `color` → that colour as accent; background is a tinted mix of it.
- Otherwise → tint slot `index % 8` → tokens `--color-task-{1..8}-accent` / `--color-task-{1..8}-bg` ([contracts/style-tokens.md](./contracts/style-tokens.md)).
- States: **completed** → faded text, success check; **current** (live clock) → `--color-task-current` outline.

## 7. Style tokens

Named values for colour, type, spacing, radius, shadow, z-index and layout. Catalogue and rules in [contracts/style-tokens.md](./contracts/style-tokens.md).
