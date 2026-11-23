# Data Model: F012

No schema change. No `db/*.sql` script.

| Entity | Change by this feature |
|---|---|
| `DailyRoutine` (one per user+date) | Reset: all `DailyTask` rows are replaced by copies of the resolved template's tasks; `colorCursor` = the template's. |
| `DailyTask` | Copies: `name, description, startTime, durationMinutes, color` from the template; `completed=false`; new ids. |
| `DefaultRoutine` WEEKEND | Copy: all `RoutineTaskTemplate` rows are replaced by copies of the DAILY ones; `colorCursor` = DAILY's. |
| `DefaultRoutine` DAILY, `DailyReflection`, chat conversations | Unchanged. |

Rules:
- Reset is refused for `date < today` (server clock).
- Both operations are all-or-nothing (one transaction).
- An empty source gives an empty target (an empty Weekday copied → empty Weekend). For a weekend day the template follows R1.
