# Contract: task save endpoints (behaviour change)

Request and response shapes are **unchanged**. Two behaviours change.

| Endpoint | Used by |
|---|---|
| `POST /api/routine-manager/daily-routine/{routineId}/tasks` | task dialog (create), Buddy |
| `PUT /api/routine-manager/daily-routine/tasks` | board drag, task dialog (edit), done toggle, Buddy |
| `POST /api/v1/default-routine/{routineId}/tasks` | task dialog (create), Buddy |
| `PUT /api/v1/default-routine/tasks` | board drag, task dialog (edit), Buddy |

## 1. No automatic push

Before: saving a task moved every overlapping task of the same routine to start at the saved task's end (chained, on a 24h cycle).

Now: each task is stored with exactly the `startTime` and `durationMinutes` sent, and no other task changes.

## 2. Overlap cap: 409

After applying **every** task in the request, if a new task, or a task whose `startTime` or `durationMinutes` changed, shares any minute with 3 or more other tasks of its routine (24h cycle), the request is refused:

```http
HTTP/1.1 409 Conflict
Content-Type: application/json

{ "status": 409, "error": "Conflict", "message": "A time slot can hold at most 3 tasks.", "timestamp": "2026-11-27T09:00:00Z" }
```

Nothing from the request is stored (one transaction). The cap is checked on the end result, so a Push mode batch that is valid as a whole is accepted even if it would break the cap halfway through.

Unchanged errors: 400 for a duration outside 1–1440 or an invalid colour.

## Buddy tools

`DailyRoutineAiTools` / `DefaultRoutineAiTools` add/update call the same services. On a 409, the tool returns `Failed to … tasks: 409 CONFLICT "A time slot can hold at most 3 tasks."`, nothing is stored, and Buddy tells the user.

## Compatibility

The currently deployed UI keeps working: its drags now overlap instead of pushing, and a 409 shows its existing save error. The backend runs only locally (pre-production), and both sides ship in this feature.
