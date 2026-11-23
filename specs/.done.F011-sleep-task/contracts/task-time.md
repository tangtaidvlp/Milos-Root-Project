# Contract: overnight task times (F011)

No new endpoints. Request and response shapes are unchanged. This contract only changes meaning and validation on the existing task endpoints:

| Endpoint | Change |
|----------|--------|
| `POST /api/v1/default-routine/{routineId}/tasks` | accepts an overnight task (e.g. `startTime "22:00"`, `durationMinutes 480`); 400 if `durationMinutes` ∉ 1–1440 |
| `PUT /api/v1/default-routine/tasks` | same |
| `POST /api/routine-manager/daily-routine/{routineId}/tasks` | same |
| `PUT /api/routine-manager/daily-routine/tasks` | same |
| `GET` routine endpoints (default and daily) | `endTime` may be earlier than `startTime`, which means the next day (e.g. `"22:00"` → `"06:00"`) |

## Example

Request item:
```json
{ "name": "Sleep", "startTime": "22:00", "durationMinutes": 480 }
```
Response item (one task):
```json
{ "id": "…", "name": "Sleep", "startTime": "22:00", "durationMinutes": 480, "endTime": "06:00", "color": "indigo" }
```

## Errors (`ApiError`)

| Case | Status | message |
|------|--------|---------|
| `durationMinutes` < 1 or > 1440 | 400 | `durationMinutes must be between 1 and 1440` |

## Overlap side effect (unchanged rule, new reach)

Saving a task still moves any overlapping sibling to start at the saved task's end. This now also covers the after-midnight part. Example: with Sleep 22:00–06:00 saved, a 05:30 task moves to 06:00.

## AI tools (mirrored registry, Constitution I)

`addDefaultRoutineTasks` and `addDailyRoutineTasks` tool descriptions: replace "split it into 2 tasks" with "create ONE task with the full durationMinutes; never split".

## Compatibility

The deployed UI already sends `durationMinutes` ≤ 1440. The old UI shows an overnight task wrongly (negative height) until the new UI ships. Deploy the backend and UI together.
