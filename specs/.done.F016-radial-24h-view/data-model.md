# Data Model: Radial 24H View

No server data changes. Two per-device preferences and one derived (never stored) layout.

## Device preferences (`localStorage`, via `src/lib/devicePreference.ts`)

| Key | Values | Default | Used by |
|---|---|---|---|
| `milos.boardView` | `vertical` \| `radial` | `vertical` | Today (incl. Reflection), Default routine |
| `milos.chatPanel` | `shown` \| `hidden` | `shown` | Today (incl. Reflection), Default routine; wide screens only |

Rules: missing, unknown or unreadable value → default. Write failures are ignored. Never throws.

## Radial input task

What `RadialDayChart` reads from a `RoutineTask`, `DailyTask` or reflection task:

| Field | Rule |
|---|---|
| `id` | key; tasks without an id (unsaved draft) are skipped |
| `name` | label text |
| `startTime` | `HH:mm`; unparseable → task skipped |
| `durationMinutes` | 1–1440; may run past midnight (F011). Never use `endTime − startTime` |
| `color` | palette id or `#RRGGBB`, through `resolveTaskColor` |
| `completed` | optional; shown only when `showCompletion` |

## Derived layout (pure, `radialGeometry.ts` + `radialLabels.ts`)

- **Arc**: `taskId`, `lane`, `startAngle`, `sweep` (deg, 0 = midnight, clockwise), `radius`, `strokeWidth`; a dot when too short for round caps.
- **Now/next**: `findNowAndNext(items, minutes)` → current task, minutes left, next task (24h cycle).
- **Label**: `taskId`, `side` (`left` \| `right`), `y`, inner-edge `x` on the ring, `leader` (arc edge → outside numbers → label).
- **Chart**: ring or stacked, `radius`, `size`, hour marks.

Input: tasks + board width and height + live minutes. Output depends only on the input (unit-tested).
