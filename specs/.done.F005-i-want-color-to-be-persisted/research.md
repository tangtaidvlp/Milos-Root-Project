# Research: F005 – Persistent Task Colors, Non-Intrusive Live Mode & Light/Dark Mode

All Technical Context unknowns are resolved below. Each item: Decision / Rationale / Alternatives considered.

## Findings from the current code

| # | Finding | Where |
|---|---------|-------|
| F1 | A card with no `color` gets one of 8 tints by **list index** (`index % 8`), so colors shift whenever the task list changes. This is the root cause of the ticket. | `ui…/features/onboarding/components/EditingBoard.jsx` `taskTintStyle` |
| F2 | `RoutineTaskTemplate.color` exists (`varchar(255)`) but `updateDefaultTasks` never copies it. A color picked in the edit dialog is **silently dropped** on save. Only create stores it. | `ms…/service/DefaultRoutineService.java` |
| F3 | `DailyTask` has no color field. `createDailyRoutineFromDefault` doesn't copy color. | `ms…/model/DailyTask.java`, `DailyRoutineService.java` |
| F4 | Buddy's add/update tools have no color input. The add tool's description says "split into 2 tasks having same color", but there's no way to do that. | `ms…/service/aitools/*AiTools.java` |
| F5 | The legacy `AiRoutineFunctions` beans also create tasks through `addDefaultTasks` / `addDailyTasks`. | `ms…/config/AiRoutineFunctions.java` |
| F6 | The live auto-scroll is `useEffect(..., [liveClock, currentTime, boardHeightPx])`, so it re-runs on every 60 s tick and every zoom. | `EditingBoard.jsx` |
| F7 | No CSS outside `tokens.css` references a tier-1 primitive (0 hits). Every color goes through tier-2 semantic tokens, and `noRawColors.test.ts` enforces this. So redefining tier-2 tokens for dark mode reaches the whole app. | `src/styles/` |
| F8 | Prod uses `ddl-auto: validate` without Flyway. New columns need a DDL script applied before deploy (precedent: `db/F004-chat-history.sql`). | `ms…/CLAUDE.md` |
| F9 | Per-device preferences already follow a pattern: `components/layout/sidebarPreference.ts` (`localStorage`, never throws, unit-tested). | `ui…` |

## R1 – How a task's color is stored

- **Decision**: Keep a single `color` string column on both task tables. The value is either a **palette ID** (lowercase name such as `green`) or an **exact color** `#RRGGBB`. A leading `#` tells them apart.
- **Rationale**: `routine_task_template.color` already exists, so this is the smallest schema change. Buddy can use the palette ID as-is ("make Gym the blue one" → `blue`). Exact colors keep working.
- **Alternatives considered**: Two columns (`palette_id` + `custom_hex`) are clearer but mean a schema migration on the template table and more mapping code. A numeric palette index would break if the palette were reordered (FR-012 needs IDs that stay valid).

## R2 – Where the palette is defined and served

- **Decision**: Define the palette in backend config, `app.task-palette.colors` in `application.yml` (an ordered list: `id`, `label`, `light{accent,bg}`, `dark{accent,bg}`), bound with `@ConfigurationProperties` (`TaskPaletteProperties`, like `ChatHistoryProperties`). Serve it at `GET /api/v1/task-palette`. The order of the list is the round-robin order.
- **Rationale**: The user wants to "control the UI color palette" from the backend. Config lets them change colors or the order without changing code. Startup validation rejects duplicate IDs, malformed hex values or an empty list.
- **Alternatives considered**: A Java enum is type-safe but needs a code change and redeploy for any tweak. A DB table is overkill for 8 static rows.

## R3 – Round-robin assignment

- **Decision**: Add `color_cursor INT NOT NULL DEFAULT 0` to `default_routine` and `daily_routine`. When a task is created in a routine:
  1. If the request has no color, it gets `palette[cursor % size]` and the cursor goes up by 1.
  2. If the request's color equals `palette[cursor % size]` (the dialog's pre-selected color was kept), the cursor goes up by 1.
  3. Any other explicit color (another palette ID, or an exact color) is stored as sent and the cursor doesn't move.
  - Rule 3 also covers a color Buddy sets by name: it is stored, and the sequence doesn't move unless it is the next color.
  - Within one create request, tasks with the **same trimmed, case-insensitive name** share the color assigned to the first of them, and the cursor moves once. This keeps both parts of a task Buddy splits across midnight the same color (FR-013).
  - Routines expose a read-only `nextColor` (`palette[cursor % size]`) so the create dialog can pre-select it (FR-004).
  - A daily routine cloned from a default routine copies each task's `color` and starts at the template's `color_cursor`, so tasks added later continue the sequence.
- **Rationale**: After deletes, "the most recently assigned color" can't be worked out from the remaining tasks; a stored cursor gives a reliable sequence. Rule 3 keeps a user's override from breaking the sequence.
- **Alternatives considered**: Advancing on every create, even with a custom color, is simpler but skips a color whenever the user overrides. Working out the next color from the highest-index color still present breaks after deletes. A cursor per user, not per routine, would make the Weekday and Weekend routines affect each other's colors.

## R4 – Updates never lose or reset color

- **Decision**: In `updateDefaultTasks` / `updateDailyTasks`, a non-null `color` is validated and stored; a null or absent `color` keeps the current value. Neither ever re-assigns a color.
- **Rationale**: Fixes F2. Drag, resize and complete send partial task objects; old clients may omit `color`.
- **Alternatives considered**: "Null clears the color" would let a drag that drops the field wipe the color.

## R5 – Validation

- **Decision**: A color must be a known palette ID or match `^#[0-9A-Fa-f]{6}$`. Anything else on the REST API → `400` (via `ResponseStatusException`, handled by `GlobalExceptionHandler`). For Buddy tools, an unknown name → no change, and the tool's reply lists the valid names (spec US2 scenario 4). Buddy tools accept palette IDs only, never hex (FR-017).
- **Rationale**: Keeps stored data clean and gives Buddy a reply it can relay to the user.

## R6 – Old data

- **Decision**: Add no migration, backfill or null-color handling (FR-009). The DDL only adds nullable `daily_task.color` and the two cursor columns. On the frontend, a card whose color doesn't resolve shows the stylesheet's default task tint (neutral border token): a plain CSS default, not a code path written for old data. The index-based tint (F1) is removed.
- **Rationale**: Matches the user's instruction exactly.

## R7 – Theme mechanism

- **Decision**:
  - `tokens.css` keeps the light values in `:root` and adds a `:root[data-theme="dark"] { … }` block that redefines **only tier-2 semantic tokens** (plus new dark primitives), using the values in `resources/dark-theme-palette.md`.
  - A small theme module (`src/theme/`) stores the preference `'light' | 'dark' | null` in `localStorage["milos.theme"]`, following the `sidebarPreference.ts` pattern. It works out the effective theme (preference, otherwise `matchMedia('(prefers-color-scheme: dark)')`), always writes `data-theme` on `<html>`, and listens for device changes while no preference is set.
  - An inline script in `index.html` sets `data-theme` before React mounts, so the page doesn't flash light first. It contains no color literals, so it doesn't conflict with `noRawColors`. `<meta name="color-scheme" content="light dark">` makes native controls (scrollbars, date inputs) match the theme.
- **Rationale**: Thanks to F7, a single CSS block re-themes the whole app (FR-018). Writing the resolved theme to `data-theme` lets task-card CSS pick the right palette version without re-rendering.
- **Alternatives considered**: Using only `@media (prefers-color-scheme)` can't honor a manual choice. A React context that passes theme values to components means re-renders and inline styles everywhere.

## R8 – How task cards pick light/dark palette colors

- **Decision**:
  - For a palette color, the board sets four CSS custom properties inline on the card: `--task-accent-light`, `--task-bg-light`, `--task-accent-dark`, `--task-bg-dark`, read from the fetched palette. The board CSS resolves `--task-accent` / `--task-bg` from the `-light` pair, and from the `-dark` pair under `[data-theme="dark"]`. Both fall back to neutral tokens.
  - For an exact color, accent = that color in both themes, and bg = `color-mix(in srgb, <color> 14%, var(--color-bg-surface))`. That is the existing formula, and it adapts because the surface color changes with the theme.
- **Rationale**: Switching theme then needs no React re-render (SC-007, under 1 s). Hex values come from API data at runtime, not source literals, so `noRawColors` is satisfied.

## R9 – Fetching the palette in the app

- **Decision**: Add `src/features/palette/` with an `api/taskPalette.ts` (`apiRequest('/api/v1/task-palette')`), a `usePalette()` hook that fetches once per session and caches in module scope, and pure helpers (`resolveTaskColor(color, palette)` → the four CSS variables or the custom-color mix, and `isPaletteId`). Pure helpers get unit tests.
- **Rationale**: Follows the coding rules (feature folder, `lib/api.ts`) and the "pure logic is unit-tested" convention.
- **Alternatives considered**: Hard-coding the palette in the frontend breaks FR-010.

## R10 – Color picker in the task dialog

- **Decision**: Replace the bare `<input type="color">` in `TaskEditModal` with a row of palette swatches, one button per entry in the current theme's accent with its `label` as accessible name. A "Custom" swatch keeps the native color input. On create, the selection starts at `routine.nextColor`. On edit, it starts at the task's stored value. The daily page keeps `showColor={false}` (spec assumption).
- **Rationale**: A native color input can't represent a palette ID. Without swatches, keeping the pre-selected color would turn it into a fixed hex value and lose theme-awareness (FR-011).

## R11 – Live mode scroll once per board mount

- **Decision**: In `EditingBoard`:
  - Replace the `[liveClock, currentTime, boardHeightPx]` effect with a run-once effect guarded by a `hasCenteredRef`. It scrolls to `getCurrentMinutes()` on the first layout where the container exists.
  - Extend the existing zoom anchor (`useLayoutEffect` that keeps the top time in place) to live mode too, by dropping its `liveClock ||` guard.
  - Tick, Resume, slider and save never scroll.
- **Rationale**: Meets FR-014 and FR-015 with the smallest change. The run-once effect is easy to verify by hand.
- **Alternatives considered**: Tracking "the user scrolled away" and pausing the auto-scroll (heuristic) was rejected because the user chose "first load only".

## R12 – Where the theme switch goes

- **Decision**: A switch button (sun/moon icon, `aria-pressed`, label "Dark mode") goes in the sidebar footer next to "Replay tour", visible in both the expanded sidebar and the icon-only rail. On phones it sits in the sidebar overlay. A compact icon-only version sits in the top-right corner of the sign-in page and the onboarding header, so it is reachable from every page (FR-019).
- **Rationale**: The sidebar is on every shell page. Auth and onboarding have no sidebar.

## R13 – Testing approach

- **Backend**: integration tests in `RoutineServiceIntegrationTest` style (Spring Boot + H2 `fast` profile):
  - round-robin with wrap
  - pre-selected color advances the cursor; a custom color doesn't
  - same-name batch shares a color
  - update with null keeps the color, update with a value changes it
  - invalid color → 400
  - daily clone copies color and cursor
  - the palette endpoint returns the configured order
  - Buddy tool by name; unknown name → message
- **Frontend** (Vitest, pure logic): `resolveTaskColor`, `themePreference` read/write/resolve, and `contrast.test.ts` extended so the same AA pairs are checked against the dark token values. Everything else follows `quickstart.md` by hand.
