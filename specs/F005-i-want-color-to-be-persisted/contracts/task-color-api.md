# Contract: Task colour on existing routine/task endpoints (changed)

Paths and methods are unchanged; only payload fields and behaviour change. Color value format and assignment rules: [data-model.md](../data-model.md) §2 and §4.

## Routine reads gain `nextColor`

`GET /api/v1/default-routine/users/{userId}?type=…`, `POST /api/v1/default-routine/users/{userId}`, `PUT /api/v1/default-routine/{id}`, `GET|POST /api/routine-manager/daily-routine/{userId}?date=…`

```json
{
  "id": "…",
  "name": "Weekday Routine",
  "routineType": "DAILY",
  "nextColor": "blue",
  "tasks": [
    { "id": "…", "name": "Gym", "startTime": "07:00", "endTime": "08:00", "durationMinutes": 60, "description": null, "color": "green" }
  ]
}
```

- `nextColor` (string, read-only): the palette id the next auto-assigned task will get. Ignored if sent.
- `color_cursor` is never serialised.

## Daily tasks gain `color`

All daily task payloads (`GET` routine, `POST /daily-routine/{routineId}/tasks`, `PUT /daily-routine/tasks` responses) include `"color": "<palette id | #RRGGBB | null>"`.

## Create — `POST /api/v1/default-routine/{routineId}/tasks`, `POST /api/routine-manager/daily-routine/{routineId}/tasks`

Request `color` is optional:

| Request `color` | Stored | Cursor |
|-----------------|--------|--------|
| absent / `null` | next round-robin id (or the id given to an earlier same-named task in this request) | +1 (not for the same-name reuse) |
| equals `nextColor` | that id | +1 |
| other palette id or `#RRGGBB` | as sent | unchanged |
| anything else | — | **400** `{"message": "Unknown task color '<value>'"}`, nothing saved |

Response: created tasks, each with its stored `color`.

## Update — `PUT /api/v1/default-routine/tasks`, `PUT /api/routine-manager/daily-routine/tasks`

| Request `color` | Effect |
|-----------------|--------|
| absent / `null` | colour unchanged |
| valid palette id or `#RRGGBB` | stored |
| invalid | **400**, nothing saved |

(Previously the default-routine update ignored `color` entirely.)

## Full replace — `POST /api/v1/default-routine/users/{userId}`, `PUT /api/v1/default-routine/{id}`

Tasks are recreated; each task runs through the create rules above, cursor continuing from the routine's current value.

## Buddy tools (Spring AI `@Tool`)

| Tool | Change |
|------|--------|
| `addDefaultRoutineTasks`, `addDailyTasks` | `TaskInput` / `DailyTaskInput` gain optional `color` (palette id). Description lists the palette ids/labels and says: omit colour unless the user asks; when splitting a task across midnight, give both parts the **same name** (they then share a colour). |
| `updateDefaultRoutineTasks`, `updateDailyTasks` | Update inputs gain optional `color` (palette id). |
| All four | A `#hex` or unknown name → that task is not changed/added with that colour; the tool returns `"Unknown colour '<x>'. Available colours: Green, Orange, …"`. |

Tool descriptions get the palette list from `TaskPaletteProperties` at call time (or a static summary built at startup) so a config change is reflected.

## Frontend types

```ts
// onboarding/types/routine.ts
type RoutineTask = { …; color?: string | null }          // palette id or #RRGGBB
type DefaultRoutine = { …; nextColor?: string }
// daily/types/dailyRoutine.ts
type DailyTask = { …; color?: string | null }
type DailyRoutine = { …; nextColor?: string }
// palette/types/palette.ts
type PaletteEntry = { id: string; label: string; light: { accent: string; bg: string }; dark: { accent: string; bg: string } }
type TaskPalette = { colors: PaletteEntry[] }
```
