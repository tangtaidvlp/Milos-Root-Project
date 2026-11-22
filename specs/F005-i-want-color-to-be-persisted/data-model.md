# Data Model: F005

## 1. Task palette (config, not a DB table)

Defined in `ms-personal-routine-manager/src/main/resources/application.yml` under `app.task-palette.colors`, bound to `TaskPaletteProperties`. **List order = round-robin order.**

| Field | Type | Rules |
|-------|------|-------|
| `id` | string | Lowercase `[a-z][a-z0-9-]*`, unique, **never renamed once released** (FR-012). Used as the stored task color and by Buddy. |
| `label` | string | Human name shown in the swatch tooltip / accessible name and to Buddy (e.g. "Green"). |
| `light.accent` | `#RRGGBB` | Card stripe/border in light theme. |
| `light.bg` | `#RRGGBB` | Card background in light theme. |
| `dark.accent` | `#RRGGBB` | Card stripe/border in dark theme. |
| `dark.bg` | `#RRGGBB` | Card background in dark theme. |

Startup validation (fail fast): ≥ 1 entry, unique ids, every hex matches `^#[0-9A-Fa-f]{6}$`.

Initial values (from `resources/dark-theme-palette.md`):

| # | id | label | light.accent | light.bg | dark.accent | dark.bg |
|---|----|-------|--------------|----------|-------------|---------|
| 0 | `green` | Green | `#10A36B` | `#E3F5EE` | `#34C98E` | `#1B3836` |
| 1 | `orange` | Orange | `#E07B39` | `#FDF0E5` | `#F0954F` | `#392F2C` |
| 2 | `blue` | Blue | `#1A6FD4` | `#E8F1FC` | `#5B9DF0` | `#213145` |
| 3 | `grey` | Grey | `#AAB3BF` | `#F6F7F9` | `#9AA4B1` | `#2B323B` |
| 4 | `slate` | Slate | `#6F7E94` | `#EEF1F5` | `#8E9CB2` | `#29303C` |
| 5 | `peach` | Peach | `#EEB692` | `#FEF7F1` | `#E8B08A` | `#383435` |
| 6 | `pink` | Pink | `#D94A6A` | `#FCEAEE` | `#EE6F8C` | `#392935` |
| 7 | `purple` | Purple | `#7C5CD6` | `#F0ECFB` | `#9D84EA` | `#2C2D45` |

## 2. Task color value

Stored as a single string `color` on a task.

| Form | Example | Meaning |
|------|---------|---------|
| Palette id | `green` | Follows the theme (light/dark variant). Assigned by round-robin, picked from a swatch, or set by Buddy. |
| Exact colour | `#FF0000` | User-chosen in the dialog's Custom swatch. Same in both themes. REST only; Buddy can't set it. |
| `null` | — | Only on tasks created before F005 (old data, untouched — FR-009). |

Validation on write: palette id that exists in the current palette, or `^#[0-9A-Fa-f]{6}$`. Otherwise REST → 400; Buddy tool → no change + list of valid names.

## 3. Entity changes

### `RoutineTaskTemplate` (table `routine_task_template`)
- `color` — **existing** column, now always set on create (FR-001/002). Update copies it when non-null (fixes F2).

### `DailyTask` (table `daily_task`)
- **+ `color VARCHAR(32) NULL`** — set on create; copied from the template on clone (FR-008).

### `DefaultRoutine` (table `default_routine`)
- **+ `color_cursor INT NOT NULL DEFAULT 0`** — next round-robin position. `@JsonIgnore`.
- **+ `nextColor`** — `@Transient` field, read-only in JSON, = `palette[colorCursor % size].id`. Filled by the service (`TaskColorService.fillNextColor`) before the routine is returned; never persisted.

### `DailyRoutine` (table `daily_routine`)
- **+ `color_cursor INT NOT NULL DEFAULT 0`** — on clone from a template, initialised to the template's `color_cursor`.
- **+ `nextColor`** — as above. For a transient (unsaved) routine: `palette[0]`.

## 4. Assignment rules (state transitions of `color_cursor`)

For each task in a create request (`addDefaultTasks`, `addDailyTasks`, full-replace `createDefaultRoutine`/`updateDefaultRoutine`, Buddy add tools, legacy `AiRoutineFunctions`), processed in request order:

```
next = palette[cursor % size].id
if task.color == null:
    if an earlier task in this request has the same normalised name: task.color = that task's color   (no advance)
    else: task.color = next; cursor += 1
elif task.color == next: cursor += 1        # dialog's pre-selected colour kept
else: (explicit other colour) cursor unchanged
```

Normalised name = `trim().toLowerCase()`.

Clone (default → daily): `daily.task.color = template.color` (including `null` for old templates — no special handling), `daily.color_cursor = template.color_cursor`.

Updates (`updateDefaultTasks`, `updateDailyTasks`, Buddy update tools): `color != null` → validate and set; `color == null` → keep. Never re-assigned. Cursor never touched.

## 5. Theme preference (frontend only, per device)

| Key | Values | Meaning |
|-----|--------|---------|
| `localStorage["milos.theme"]` | `"light"`, `"dark"`, absent/other | Absent/unknown/unreadable ⇒ follow the device (`prefers-color-scheme`). Never stored on the server (FR-021). |

Effective theme is written to `<html data-theme="light|dark">` (always resolved, never absent after boot).

## 6. Prod DDL (`ms-personal-routine-manager/db/F005-task-color.sql`)

```sql
ALTER TABLE daily_task      ADD COLUMN IF NOT EXISTS color        VARCHAR(32);
ALTER TABLE default_routine ADD COLUMN IF NOT EXISTS color_cursor INT NOT NULL DEFAULT 0;
ALTER TABLE daily_routine   ADD COLUMN IF NOT EXISTS color_cursor INT NOT NULL DEFAULT 0;
```

Idempotent; apply before deploying the F005 backend image. No data backfill.
