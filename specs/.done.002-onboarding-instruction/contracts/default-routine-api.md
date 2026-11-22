# Contract: Default Routine API (change)

**Backend**: `ms-personal-routine-manager` · `DefaultRoutineController` (`/api/v1/default-routine`)
**Client**: `ui-personal-routine-manager` · `features/onboarding/api/`

Only one endpoint changes. Everything else stays the same, and is listed here so client and server stay aligned.

---

## Changed: get a user's default routine by type

```http
GET /api/v1/default-routine/users/{userId}?type=DAILY|WEEKEND
```

| Param | In | Required | Values | Default |
|-------|----|----------|--------|---------|
| `userId` | path | yes | UUID | — |
| `type` | query | no | `DAILY`, `WEEKEND` (case-sensitive) | `DAILY` |

**Behaviour**

- **`type=DAILY`, or no `type`**: returns the weekday routine. Same as today.
- **`type=WEEKEND`**: returns the weekend routine. **If the user has none, it creates an empty one and returns it.** This is idempotent: repeated calls return the same `id`. This is the only write a GET performs (research R2).

**200 response** (unchanged shape):

```json
{
  "id": "aea0163c-…",
  "name": "Weekend Routine",
  "routineType": "WEEKEND",
  "tasks": [
    { "id": "…", "name": "Long run", "startTime": "08:00", "durationMinutes": 60, "endTime": "09:00", "description": null, "color": "#…" }
  ]
}
```

**Errors**

| Status | When |
|--------|------|
| `400` | `type` is not `DAILY` or `WEEKEND` |
| `404` | user not found |

**Back-compat**: existing callers that send no `type` keep working. Some callers parse `routineType` as a UI type: the UI type is `'DAILY' | 'WEEKEND'`, which already matches.

---

## Changed (internal): registration

`POST /api/v1/auth/register` keeps its request and response unchanged. Server side, it now creates **two** empty default routines: "Weekday Routine" (`DAILY`) and "Weekend Routine" (`WEEKEND`).

---

## Changed (internal): which routine a new day copies

There is no API change for this. `GET /api/routine-manager/...` daily endpoints and the midnight job copy a day from:
- **Saturday or Sunday**: `WEEKEND` if it has ≥ 1 task, otherwise `DAILY`.
- **Any other day**: `DAILY`.

See [data-model.md](../data-model.md) §1.

---

## Unchanged (routine-id based, work for both types)

| Method | Path | Used by |
|--------|------|---------|
| `POST` | `/api/v1/default-routine/{routineId}/tasks` | add tasks (`createDefaultTasks`) |
| `PUT` | `/api/v1/default-routine/tasks` | edit or move tasks (`updateDefaultTasks`) |
| `DELETE` | `/api/v1/default-routine/tasks?taskIds=…` | delete tasks (`deleteDefaultTasks`) |
| `POST` | `/api/ai/chat/default-routine/{userId}` | Routine Buddy. The body's `defaultRoutine` must be the **active tab's** routine, including its `id`. |
| `GET`/`POST` | `/api/users/{userId}/onboarding/complete` | read and set onboarding status |

---

## Client function (new signature)

```ts
// features/onboarding/api/defaultRoutine.ts
export type RoutineType = 'DAILY' | 'WEEKEND'
export function fetchDefaultRoutine(userId: string, type: RoutineType): Promise<DefaultRoutine>
// → apiRequest(`/api/v1/default-routine/users/${userId}?type=${type}`, { method: 'GET' })
```

This replaces the local `fetchDefaultRoutine` inside `OnboardingPage.jsx`.
