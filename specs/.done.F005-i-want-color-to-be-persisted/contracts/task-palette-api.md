# Contract: Task palette API (new)

## `GET /api/v1/task-palette`

Returns the configured task palette in round-robin order. Same auth as other `/api/**` endpoints (JWT on `sit`/`prod`, open on `local`/`fast`). Static per deployment; clients may cache for the session.

**200 OK**

```json
{
  "colors": [
    {
      "id": "green",
      "label": "Green",
      "light": { "accent": "#10A36B", "bg": "#E3F5EE" },
      "dark":  { "accent": "#34C98E", "bg": "#1B3836" }
    },
    { "id": "orange", "label": "Orange", "light": { "accent": "#E07B39", "bg": "#FDF0E5" }, "dark": { "accent": "#F0954F", "bg": "#392F2C" } }
  ]
}
```

| Field | Type | Notes |
|-------|------|-------|
| `colors` | array, ≥ 1 | Order = round-robin order. |
| `colors[].id` | string | Stable id; the value stored in a task's `color`. |
| `colors[].label` | string | Display / accessible name. |
| `colors[].light.accent`, `.light.bg`, `.dark.accent`, `.dark.bg` | `#RRGGBB` | Upper-case hex. |

Errors: 401 when auth is enabled and the token is missing/expired (same as other endpoints). No other error cases.

Controller: `api/TaskPaletteController`. Source: `TaskPaletteProperties` (`app.task-palette.colors`).
