# Contract: Reset day and Copy Weekday → Weekend

Both endpoints are new, have no request body, and return `204 No Content` on success. Errors use `ApiError` (`status`, `error`, `message`, `timestamp`). Both are user-scoped via `CurrentUserGuard`.

## POST `/api/routine-manager/daily-routine/{userId}/{date}/reset`

Replaces every task of the user's day `date` (ISO `YYYY-MM-DD`) with a fresh copy of its default routine (research R1). Creates the day if it doesn't exist yet. The day's reflection is not changed.

| Status | When | `message` |
|---|---|---|
| 204 | Reset done | — |
| 400 | `date` is before today (server clock) | `Past days can't be reset` |
| 400 | `date` is malformed | (standard) |
| 401 | No/invalid token (auth profiles) | (standard) |
| 403 | `userId` isn't the caller | `Access denied` |
| 404 | User or Weekday default routine missing | `User not found` / `Default routine not found for user` |

After 204 the client reloads the day: `GET /api/routine-manager/daily-routine/{userId}?date=…`.

## POST `/api/v1/default-routine/users/{userId}/copy-weekday-to-weekend`

Replaces every task of the user's Weekend default routine with a copy of the Weekday (`DAILY`) routine's tasks. Creates the Weekend routine if missing. The Weekday routine is unchanged.

| Status | When | `message` |
|---|---|---|
| 204 | Copy done | — |
| 401 | No/invalid token (auth profiles) | (standard) |
| 403 | `userId` isn't the caller | `Access denied` |
| 404 | User or Weekday routine missing | `User not found` / `Default routine not found` |

After 204 the client reloads: `GET /api/v1/default-routine/users/{userId}?type=WEEKEND`.

## Backward compatibility
Additive only; the deployed frontend is unaffected.
