# Data Model: F011 Sleep task

No schema change and no `db/F011-*.sql` script.

## Task (RoutineTaskTemplate, DailyTask, ReflectionTask)

| Field | Type | Rule |
|-------|------|------|
| `startTime` | time of day (HH:mm) | required, 00:00–23:59 |
| `durationMinutes` | int | **1–1440** (now enforced server-side for routine and daily tasks; reflection already enforces it) |
| `endTime` | time of day, read-only | `startTime + durationMinutes`, wrapping past midnight |

**Derived (not stored)**:
- `endMinutes = startMinutes + durationMinutes`
- `overnight = endMinutes > 1440`. A task that ends exactly at 24:00 is **not** overnight (its `endTime` is `00:00`).
- Board ranges: `[start, min(endMinutes, 1440))`, plus `[0, endMinutes − 1440)` when overnight.

**Rules**:
- An overnight task is always one row.
- Overlap uses the ranges above (research R2).
- Existing split pieces are not changed (FR-009).
