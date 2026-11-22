# Data Model: F007 Daily Reflection

## daily_reflection (entity `DailyReflection`)

| Column | Type | Rules |
|--------|------|-------|
| id | UUID PK | generated |
| user_id | UUID NOT NULL FK → users(id) | owner |
| reflection_date | DATE NOT NULL | ≤ today when created; UNIQUE (user_id, reflection_date) |
| color_cursor | INTEGER NOT NULL DEFAULT 0 | F005 round-robin; starts at the plan's cursor |
| feedback_text | TEXT NULL | latest Buddy note |
| feedback_at | TIMESTAMPTZ NULL | when the note was written |
| content_updated_at | TIMESTAMPTZ NOT NULL | touched on create and on every task add, update or delete |
| created_at | TIMESTAMPTZ NOT NULL | |

Relationships: one-to-many `tasks` (`ReflectionTask`, cascade all, orphan removal).

Derived (not stored): `nextColor` and `feedbackStale` (`feedback_at < content_updated_at`).

## reflection_task (entity `ReflectionTask`)

| Column | Type | Rules |
|--------|------|-------|
| id | UUID PK | generated |
| daily_reflection_id | UUID NOT NULL FK → daily_reflection(id) | |
| planned_task_id | UUID NULL | the `daily_task.id` it was copied from; plain column, no FK; null = unplanned |
| name | VARCHAR(255) NOT NULL | not blank, trimmed |
| description | VARCHAR(255) NULL | |
| start_time | TIME NOT NULL | HH:mm |
| duration_minutes | INTEGER NOT NULL | 1–1440 |
| color | VARCHAR(32) NULL | palette id or #RRGGBB (F005) |

Derived: `endTime = startTime + durationMinutes` (read-only JSON).

## chat_conversation (existing, F004)

- New enum value `DAILY_REFLECTION`. It uses `routine_date`.
- New partial unique index `ux_chat_conv_reflection (user_id, routine_date) WHERE type = 'DAILY_REFLECTION'`.

## Comparison (computed, `ReflectionComparison`)

```
ReflectionComparison {
  plannedMinutes: int, actualMinutes: int,
  counts: { asPlanned, changed, skipped, unplanned },
  items: [ { status: AS_PLANNED|CHANGED|SKIPPED|UNPLANNED,
             planned:  { id, name, startTime, durationMinutes } | null,
             actual:   { id, name, startTime, durationMinutes } | null } ]
}
```

- Items are sorted by start time (planned time for skipped items, otherwise actual time).
- Grouping rules are in research R3.

## Lifecycle

```
(no reflection) --toggle on (date ≤ today)--> exists (copy of plan, once)
exists --add/update/delete task--> exists (content_updated_at = now)
exists --request feedback--> exists (feedback_text, feedback_at = now)
```

There is no delete-reflection flow in this feature.
