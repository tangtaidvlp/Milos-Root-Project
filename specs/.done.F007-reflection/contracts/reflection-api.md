# Contract: Daily Reflection API

Base: `/api/routine-manager/daily-reflection/{userId}/{date}` (`date` = `yyyy-MM-dd`).

All endpoints use `CurrentUserGuard`: **404** if the user is unknown, **403** if the JWT user ≠ `{userId}`.

## ReflectionView (response body of every endpoint)

```json
{
  "exists": true,
  "id": "uuid | null",
  "date": "2026-11-21",
  "tasks": [ { "id": "uuid", "plannedTaskId": "uuid|null", "name": "Gym", "description": null,
               "startTime": "07:30", "endTime": "08:30", "durationMinutes": 60, "color": "green" } ],
  "plannedTasks": [ { "id": "uuid", "name": "Gym", "startTime": "07:00", "durationMinutes": 60 } ],
  "comparison": { "plannedMinutes": 60, "actualMinutes": 60,
                  "counts": { "asPlanned": 0, "changed": 1, "skipped": 0, "unplanned": 0 },
                  "items": [ { "status": "CHANGED", "planned": {…}, "actual": {…} } ] },
  "feedback": { "text": "…", "generatedAt": "2026-11-21T20:00:00Z", "stale": false } ,
  "nextColor": "orange"
}
```

- `feedback` is `null` until a note has been requested.
- When `exists=false`, `id` is null, `tasks` is `[]`, `feedback` is null, and `plannedTasks` and `comparison` still describe the plan, with every planned task SKIPPED.

## GET `{base}`

Read only. It never creates a reflection or a plan. → 200 ReflectionView.

## POST `{base}`

Create-or-get (idempotent). It copies the plan once if the reflection is missing, and never creates a plan.

- 200 ReflectionView
- **400** if `date` is after today

## POST `{base}/tasks`

Body: `[ { "name", "description?", "startTime": "HH:mm", "durationMinutes", "color?" } ]`. Tasks added this way are unplanned (`plannedTaskId` is ignored on input).

- 200 ReflectionView
- **400** for validation errors (blank name, duration outside 1–1440, missing startTime, unknown color, future date)
- **404** if the reflection doesn't exist

## PUT `{base}/tasks`

Body: `[ { "id", "name", "description?", "startTime", "durationMinutes", "color?" } ]`. A null color keeps the current color.

- 200 ReflectionView
- 400 for validation errors
- **404** if any id is not in this reflection; nothing is written

## DELETE `{base}/tasks?taskIds=a,b`

- 200 ReflectionView
- **404** if any id is not in this reflection; nothing is deleted

## POST `{base}/feedback`

Asks Buddy for an encouraging note about the current comparison, stores it, and returns the view with `feedback`.

- 200 ReflectionView
- **404** if there is no reflection
- **503** `"Buddy is unavailable right now"` if the AI call fails; the earlier note is kept

Invariant for all endpoints: they never read-modify the `daily_routine` or `daily_task` tables beyond reading.
