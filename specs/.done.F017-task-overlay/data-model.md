# Data model: Task overlay

| Entity (table) | New field | Type | Rules |
|---|---|---|---|
| `DailyTask` (`daily_task`) | `overlay` | boolean, not null, DB default `false` | null on create → false; null on update → unchanged; copied from the default-routine task when a day is created or reset |
| `RoutineTaskTemplate` (`routine_task_template`) | `overlay` | same | same; copied by "Copy Weekday to Weekend" |

Not changed: `ReflectionTask` (Reality), overlap cap of 3 (still checked on every save).

Existing rows get `false` from the column default; no data migration.
