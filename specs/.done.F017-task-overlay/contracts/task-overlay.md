# Contract: task `overlay`

Additive, backward compatible. No new endpoints, status codes or errors.

## Endpoints

| Endpoint | Change |
|---|---|
| `POST /api/routine-manager/daily-routine/{routineId}/tasks` | each task MAY send `overlay` (boolean); absent → `false` |
| `PUT /api/routine-manager/daily-routine/tasks` | each task MAY send `overlay`; absent/null → unchanged |
| `POST /api/v1/default-routine/{routineId}/tasks` | as daily POST |
| `PUT /api/v1/default-routine/tasks` | as daily PUT |
| Every response with daily or default-routine tasks (routine GETs, ensure/reset, the POST/PUT above) | each task has `overlay` (boolean, always present) |

```json
{ "id": "…", "name": "Sleep", "startTime": "23:00", "durationMinutes": 480, "color": "sand", "overlay": true }
```

Errors: unchanged (400 invalid duration/colour, 404, 409 overlap cap).

## UI

- `BoardTask.overlay?: boolean`; `TaskFormValue.overlay?: boolean`.
- `TaskEditModal` prop `showOverlay?: boolean` (default `true`).
- Board drag rules: research R2.
