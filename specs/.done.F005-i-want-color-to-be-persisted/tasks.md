---

description: "Tasks for F005 – Persistent Task Colors, Non-Intrusive Live Mode & Light/Dark Mode"
---

# Tasks: Persistent Task Colors, Non-Intrusive Live Mode & Light/Dark Mode

**Input**: Design documents from `specs/F005-i-want-color-to-be-persisted/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ (task-palette-api.md, task-color-api.md, theme-ui.md), quickstart.md, resources/dark-theme-palette.md

**Tests**: Included where plan.md (Testing, research R13) commits to them: backend integration tests, plus frontend Vitest for pure logic and the existing token tests. UI behaviour is checked by hand with quickstart.md, per the frontend repo's convention.

**Organization**: Grouped by user story. Order: Setup → Foundational → US1 (P1) → US4 (P1) → US2 (P2) → US3 (P2) → US5 (P2) → Polish.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1–US5 from spec.md

## Path Conventions

- Backend: `ms-personal-routine-manager/` (Java package root `src/main/java/com/tom/payment/routinemanager/`, abbreviated **`BE/`** below)
- Frontend: `ui-personal-routine-manager/src/` (abbreviated **`FE/`** below)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Schema script and palette config, the base everything else builds on.

- [X] T001 [P] Create the idempotent prod DDL script `ms-personal-routine-manager/db/F005-task-color.sql` with a header comment in the style of `db/F004-chat-history.sql` ("Apply to prod BEFORE deploying F005 (prod uses ddl-auto: validate). Idempotent."). Statements, verbatim from data-model.md §6: `ALTER TABLE daily_task ADD COLUMN IF NOT EXISTS color VARCHAR(32);`, `ALTER TABLE default_routine ADD COLUMN IF NOT EXISTS color_cursor INT NOT NULL DEFAULT 0;`, `ALTER TABLE daily_routine ADD COLUMN IF NOT EXISTS color_cursor INT NOT NULL DEFAULT 0;`. No data backfill.
- [X] T002 [P] Add the palette to `ms-personal-routine-manager/src/main/resources/application.yml` under `app.task-palette.colors`: an ordered list of 8 entries, each `id`, `label`, `light: {accent, bg}`, `dark: {accent, bg}`, with the exact values and order from data-model.md §1 (green, orange, blue, grey, slate, peach, pink, purple). Add a comment: "List order = round-robin order. Never rename an id once released."

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Palette loading and serving, color validation and assignment, the new entity fields, and the frontend palette module. Every story depends on these.

**⚠️ CRITICAL**: No user story work starts until this phase is done.

- [X] T003 Create `BE/config/TaskPaletteProperties.java`, a `@ConfigurationProperties(prefix = "app.task-palette")` record or class bound to `colors` (nested `PaletteColor(id, label, Shade light, Shade dark)`, `Shade(accent, bg)`). Register it the same way `ChatHistoryProperties` is registered. Validate at startup and fail fast (throw `IllegalStateException`) if: the list is empty; any id is not lowercase `[a-z][a-z0-9-]*`; ids are not unique; or any hex doesn't match `^#[0-9A-Fa-f]{6}$`. Expose `List<PaletteColor> colors()`, `Optional<PaletteColor> byId(String)`, and `String labelsSummary()` (e.g. "green (Green), orange (Orange), …") for the AI tool text.
- [X] T004 [P] Create `BE/api/TaskPaletteController.java`: `@RestController`, `GET /api/v1/task-palette` → `{"colors": [...]}`, exactly as in contracts/task-palette-api.md (fields `id`, `label`, `light.accent`, `light.bg`, `dark.accent`, `dark.bg`; upper-case hex; config order). Check that `BE/config/SecurityConfig.java` treats it like the other `/api/**` endpoints (JWT on sit/prod, open on local/fast). Don't add it to the auth whitelist.
- [X] T005 [P] Add `private String color;` to `BE/model/DailyTask.java` (column `color`, nullable, length 32: `@Column(length = 32)`).
- [X] T006 [P] Add to `BE/model/DefaultRoutine.java`: `@JsonIgnore @Column(name = "color_cursor", nullable = false) private int colorCursor = 0;` and `@Transient @JsonProperty(access = JsonProperty.Access.READ_ONLY) private String nextColor;`.
- [X] T007 [P] Add the same two fields as T006 to `BE/model/DailyRoutine.java` (`colorCursor` with `nullable = false`, default 0, `@JsonIgnore`; `@Transient` read-only `nextColor`).
- [X] T008 Create `BE/service/TaskColorService.java` (`@Service`, `@RequiredArgsConstructor`, depends on `TaskPaletteProperties`):
  - `boolean isValid(String color)`: true when it is a known palette id or matches `^#[0-9A-Fa-f]{6}$`.
  - `void requireValid(String color)`: throws `new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unknown task color '" + color + "'")` when invalid.
  - `String nextColor(int cursor)`: returns `colors.get(Math.floorMod(cursor, size)).id()`.
  - A generic assignment method, `int assign(int cursor, List<T> newTasks, Function<T,String> getName, Function<T,String> getColor, BiConsumer<T,String> setColor)`, which returns the new cursor and follows data-model.md §4 exactly:
    - Process tasks in request order. `next = nextColor(cursor)`.
    - If color is null: when an earlier task **in this request** has the same name (`trim().toLowerCase()`), copy that task's color and don't advance; otherwise set it to `next` and add 1 to the cursor.
    - Else if color equals `next`, add 1 to the cursor.
    - Otherwise call `requireValid(color)` and leave the cursor unchanged.
  - `void fillNextColor(DefaultRoutine r)` and `void fillNextColor(DailyRoutine r)`: set `nextColor = nextColor(r.getColorCursor())`.
- [X] T009 [P] Create `FE/features/palette/types/palette.ts` with `PaletteShade = { accent: string; bg: string }`, `PaletteEntry = { id: string; label: string; light: PaletteShade; dark: PaletteShade }`, `TaskPalette = { colors: PaletteEntry[] }` (contracts/task-color-api.md, "Frontend types").
- [X] T010 [P] Create `FE/features/palette/api/taskPalette.ts`: `fetchTaskPalette(): Promise<TaskPalette>` using `apiRequest<TaskPalette>('/api/v1/task-palette', { method: 'GET' })` from `FE/lib/api.ts`. Throw `ApiError(502, 'Invalid task palette payload')` when `colors` isn't a non-empty array.
- [X] T011 Create `FE/features/palette/hooks/usePalette.ts`: fetches the palette once per page session and caches the promise and result at module scope, so every board and dialog shares one request. Returns `{ palette: PaletteEntry[] | null, error: boolean }`. On failure it logs via `console.error`, returns `palette: null, error: true`, and lets a later mount retry.
- [X] T012 [P] Create `FE/features/palette/utils/taskColor.ts`:
  - `isPaletteId(color, palette)`.
  - `isCustomColor(color)`: tests `/^#[0-9A-Fa-f]{6}$/`.
  - `resolveTaskColor(color: string | null | undefined, palette: PaletteEntry[] | null): Record<string, string>`, returning the inline CSS variables from contracts/theme-ui.md "Task card variables":
    - palette entry → `--task-accent-light`, `--task-bg-light`, `--task-accent-dark`, `--task-bg-dark`;
    - custom color → `--task-accent-light` and `--task-accent-dark` = the color;
    - anything else → `{}`. No special branch for old data; it's simply "unresolved".
- [X] T013 [P] Add `color?: string | null` and `nextColor?: string` to the types in `FE/features/onboarding/types/routine.ts` (`RoutineTask.color`: replace the existing `color?: string`; `DefaultRoutine.nextColor`) and in `FE/features/daily/types/dailyRoutine.ts` (`DailyTask.color`, `DailyRoutine.nextColor`). Add a doc comment: "palette id or #RRGGBB; server-assigned when omitted on create".
- [X] T014 [P] Create `FE/features/palette/utils/taskColor.test.ts` (Vitest, pure logic). Cover:
  - a palette id resolves to all 4 variables with the entry's values;
  - a `#RRGGBB` resolves to the light and dark accent only;
  - an unknown id, `null`, `undefined` and `'red'` resolve to `{}`;
  - a palette of `null` resolves to `{}`.
  Test hex literals are allowed because `noRawColors` skips `*.test.ts`.

**Checkpoint**: The backend starts with the palette loaded, `GET /api/v1/task-palette` returns 8 entries, the entities have the new columns (H2 via `ddl-auto: update`), and the frontend palette module builds and its tests pass.

---

## Phase 3: User Story 1 - A task keeps its color (Priority: P1) 🎯 MVP

**Goal**: Every new task (by hand, through Buddy, through the legacy functions, or by full replace) gets a stored color assigned round-robin. Edits never change it, and the board shows the stored color instead of a color based on list position.

**Independent Test**: quickstart.md scenarios A and B. Add A, B, C → green, orange, blue; the dialog pre-selects grey. Add D before A, delete B, drag C, resize and rename A, then reload: the remaining colors don't change. A second browser shows the same colors.

### Tests for User Story 1

- [X] T015 [P] [US1] Create `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/TaskColorIntegrationTest.java` (same setup as `RoutineServiceIntegrationTest`, `fast`/H2) with US1 cases:
  1. Adding 10 default tasks without color gives `green, orange, blue, grey, slate, peach, pink, purple, green, orange` (wrap), and the routine's `nextColor` is then `blue`.
  2. A create request whose `color` equals `nextColor` stores it and advances the cursor.
  3. A create with another palette id or `#FF0000` stores it and doesn't advance.
  4. Two tasks named "Sleep" / " sleep " in one request without a color get the same color, and the cursor advances once.
  5. An update with `color` null keeps the stored color (move, resize, rename, complete).
  6. Deleting a task doesn't change the others' colors or the cursor.
  7. Daily `addDailyTasks` assigns from the daily routine's own cursor.
  8. `GET /api/v1/task-palette` returns the 8 ids in config order.
  9. Create with `color: "gold"` → 400 and nothing saved.

### Implementation for User Story 1

- [X] T016 [US1] In `BE/service/DefaultRoutineService.java`:
  - Inject `TaskColorService`.
  - In `addDefaultTasks`, call `taskColorService.assign(routine.getColorCursor(), tasks, …)` before the overlap and save loop, then `routine.setColorCursor(newCursor)` and save the routine.
  - In `createDefaultRoutine` and `updateDefaultRoutine` (full replace), run the incoming tasks through `assign`, starting from the existing routine's cursor (0 for a new routine), and store the new cursor.
  - In `updateDefaultTasks`: when `details.getColor() != null`, call `requireValid` then `existing.setColor(details.getColor())`; when it is null, keep the current color. Never re-assign. This fixes research F2.
- [X] T017 [US1] In `BE/service/DailyRoutineService.java`:
  - Inject `TaskColorService`.
  - `addDailyTasks`: assign from `routine.getColorCursor()` and store the new cursor, as in T016.
  - `updateDailyTasks`: set the color only when it is non-null (after `requireValid`); otherwise keep it.
- [X] T018 [US1] Fill `nextColor` on every routine the API returns. Call `taskColorService.fillNextColor(...)` in:
  - `DefaultRoutineService.getOrCreateDefaultRoutine` (including the WEEKEND create path), `createDefaultRoutine` and `updateDefaultRoutine`;
  - `DailyRoutineService.getOrCreateDailyRoutine` (including the transient non-today routine, cursor 0 → first palette id) and `ensureDailyRoutine`.
  Return values from `BE/api/DefaultRoutineController.java` and `BE/api/DailyRoutineController.java` need no change beyond that.
- [X] T019 [US1] Confirm the legacy creators in `BE/config/AiRoutineFunctions.java` call `DefaultRoutineService.addDefaultTasks` / `DailyRoutineService.addDailyTasks` (so they inherit assignment). If any path saves tasks directly through a repository, route it through the service. Make no API change.
- [X] T020 [US1] In `FE/features/onboarding/components/EditingBoard.jsx`:
  - Delete `TASK_TINT_COUNT` and the index-based `taskTintStyle(task, index)`.
  - Call `usePalette()` and, for each card, spread `resolveTaskColor(task.color, palette)` into the existing `style` of `.ob-board-task` (line ~519) in place of `taskTintStyle(task, index)`.
  - Keep sending `color: task.color` in the drag/resize persistence payloads (unchanged).
- [X] T021 [US1] In `ui-personal-routine-manager/src/App.css` `.ob-board-task` rules (around lines 855–882), add the light resolution from contracts/theme-ui.md: `--task-accent: var(--task-accent-light, var(--color-border-strong)); --task-bg: var(--task-bg-light, color-mix(in srgb, var(--task-accent) 14%, var(--color-bg-surface)));`. Replace the `var(--color-task-3-bg)` / `var(--color-task-3-accent)` fallbacks with plain `var(--task-bg)` / `var(--task-accent)`.
- [X] T022 [US1] In `FE/styles/tokens.css`, remove `--color-task-1-accent` … `--color-task-8-bg` (the palette now comes from the backend). Keep `--color-task-current` / `--color-task-current-bg`. Update `FE/styles/contrast.test.ts`: remove the 8 `--color-task-N-bg` AA pairs and add a comment that task-card contrast is now checked by the backend palette test (T024).
- [X] T023 [US1] Create a `FE/features/palette/components/PaletteSwatches.tsx` component:
  - Renders a `role="radiogroup"` row of buttons, one per palette entry (`role="radio"`, `aria-checked`, `aria-label={entry.label}`, `title={entry.label}`).
  - Each swatch's fill is set through the inline CSS variables from `resolveTaskColor(entry.id, palette)`, and its CSS uses `var(--task-accent)` resolved like the card. Styles go in `App.css` under a `.ob-swatch` prefix, using tokens only.
  - Props: `value: string | null`, `onChange(value: string)`, `palette`.
  - In `FE/features/onboarding/components/TaskEditModal.tsx`, when `showColor`, replace the bare `<input type="color">` with `PaletteSwatches`. Initial value = `draftTask?.color ?? null`. Submit sends `color` as selected, or `undefined` when nothing is selected.
- [X] T024 [US1] Pre-select the next color on create: in `FE/features/onboarding/hooks/useDefaultRoutines.ts`, change `openCreateTaskModal` so the draft gets `color: draft.color ?? activeRoutine?.nextColor` (FR-004). Don't touch edit drafts.
- [X] T025 [P] [US1] Add a backend palette contrast check to `TaskColorIntegrationTest.java` (or a small unit test `TaskPalettePropertiesTest.java`): for every configured entry, the light-theme text `#1F2937` on `light.bg` and the dark-theme text `#E6EBF2` on `dark.bg` each reach ≥ 4.5:1 (WCAG formula, as in `FE/styles/contrast.ts`).

**Checkpoint**: US1 is fully functional. Colors are stored, assigned round-robin, stable across edits and devices, and pre-selected in the create dialog. This works in light mode.

---

## Phase 4: User Story 4 - Live mode centres once and then lets the user scroll (Priority: P1)

**Goal**: The Today board scrolls to "now" once per mount. Clock ticks, Resume, zoom and saves never move the view, and the now-line and footer keep updating.

**Independent Test**: quickstart.md scenario F.

### Implementation for User Story 4

- [X] T026 [US4] In `FE/features/onboarding/components/EditingBoard.jsx`, replace the effect `useEffect(() => { … containerRef.current.scrollTop = Math.max(0, scrollPosition) }, [liveClock, currentTime, boardHeightPx])` (around line 142) with a run-once version:
  - Add `const hasCenteredRef = useRef(false)` and use `useLayoutEffect` with no reactive scroll dependencies.
  - If `liveClock && !hasCenteredRef.current && containerRef.current`, set `scrollTop = Math.max(0, (getCurrentMinutes() / MINUTES_PER_DAY) * boardHeightRef.current - 260)` and then `hasCenteredRef.current = true`.
  - Reuse `scrollTopForMinutes(getCurrentMinutes(), boardHeightRef.current, 260)` from `FE/features/onboarding/utils/boardScroll.ts`, so there's no duplicated maths.
  - Never scroll again during this mount (FR-014, FR-015).
  - Changing the date on the Today page does **not** reset `hasCenteredRef`. The board isn't remounted on a date change (only `BuddyChat` is keyed by `selectedDate`), so the view stays where it is (spec edge case). Don't add a `key` to `EditingBoard`.
- [X] T027 [US4] In the same file, make the zoom-anchor `useLayoutEffect` (around line 166, "keeps the time of day at the top of the view in place") apply in live mode too: drop `liveClock ||` from its early-return guard, keep `previousHeight === boardHeightPx || !containerRef.current`, and update its comment. Check that the effect order still records `boardHeightRef.current` before the run-once centering reads it.
- [X] T028 [US4] Confirm the 60 s interval effect (`setCurrentTime` every 60 000 ms), `handleSliderChange` and the Pause/Resume button in `EditingBoard.jsx` contain no scroll writes. Update the "Board live clock" bullet in `ui-personal-routine-manager/CLAUDE.md`: "Today board scrolls to now once per mount; ticks/Resume/zoom/save never move the view (spec F005)".

**Checkpoint**: US1 and US4 (both P1) work independently.

---

## Phase 5: User Story 2 - User-chosen color wins (Priority: P2)

**Goal**: The user can override a color with any palette swatch or an exact custom color, and the choice is stored. Buddy can set palette colors by name.

**Independent Test**: quickstart.md scenarios C and D (steps 1–3).

### Tests for User Story 2

- [X] T029 [P] [US2] Add these cases to `TaskColorIntegrationTest.java`:
  - `PUT /api/v1/default-routine/tasks` with `color: "pink"` stores pink; with `"#AA3300"` stores it; with `"gold"` → 400 and the color is unchanged.
  - The same for `PUT /api/routine-manager/daily-routine/tasks`.
  - `DefaultRoutineAiTools.updateDefaultRoutineTasks` with color `"purple"` stores purple.
  - With `"#ff0000"` or `"gold"`: the color is unchanged and the reply contains "Available colours:" and all 8 labels.
  - `addDefaultRoutineTasks` with an explicit `color: "blue"` stores blue.

### Implementation for User Story 2

- [X] T030 [US2] In `FE/features/palette/components/PaletteSwatches.tsx`:
  - Add a final "Custom" option that wraps `<input type="color">`. Its value is the current custom hex if the selection is a `#RRGGBB`; otherwise the input shows its default, the existing allow-listed `'#2563eb'` literal, which must stay in `TaskEditModal.tsx` or be added to the `noRawColors.test.ts` allowlist for the new file.
  - Picking a custom color calls `onChange(hex.toUpperCase())`.
  - The custom swatch shows the chosen color via `--task-accent-light`/`--task-accent-dark`.
- [X] T031 [US2] In `FE/styles/noRawColors.test.ts`, if T030 moves the `<input type="color">` literal into `PaletteSwatches.tsx`, move the `ALLOWED` entry (`/type="color"/`) from `TaskEditModal.tsx` to `features/palette/components/PaletteSwatches.tsx`.
- [X] T032 [US2] In `BE/service/aitools/DefaultRoutineAiTools.java`:
  - Add an optional `String color` to `TaskInput` and `TaskUpdateInput`.
  - Inject `TaskPaletteProperties`.
  - Accept only palette ids, case-insensitive, normalised to lowercase. A `#…` or unknown value means that task isn't added or updated, and the tool returns `"Unknown colour '<x>'. Available colours: " + labels` (FR-017, contracts/task-color-api.md "Buddy tools").
  - Pass a valid color through to the entity so the service applies the create and update rules.
  - Rewrite the `addDefaultRoutineTasks` description, replacing "split it into 2 tasks having same color": "Only set color when the user asks for one; use a palette id (" + ids + "). If a task crosses midnight, split it into 2 tasks with the SAME name (they then share a colour)."
  - Spring AI `@Tool` descriptions are compile-time constants, so put the id list in the `@ToolParam` description of `color` as a constant string matching application.yml, and mention in a code comment that it must be kept in sync, OR validate at runtime and list labels in the error reply. Do both.
- [X] T033 [US2] Apply the same changes as T032 to `BE/service/aitools/DailyRoutineAiTools.java` (`DailyTaskInput`, `DailyTaskUpdateInput`, `addDailyTasks` and `updateDailyTasks` descriptions). Past-date routines may still change color (it is content, not schedule).

**Checkpoint**: US1, US4 and US2 work. Overrides are stored, custom colors work, and Buddy recolors by name.

---

## Phase 6: User Story 3 - Daily tasks match their default-routine color (Priority: P2)

**Goal**: Daily routines cloned from a template copy each task's color and the round-robin cursor.

**Independent Test**: quickstart.md scenario E.

### Tests for User Story 3

- [X] T034 [P] [US3] Add these cases to `TaskColorIntegrationTest.java`:
  - `ensureDailyRoutine` for a date clones the template, and each daily task has its template's `color`.
  - The daily `colorCursor` equals the template's, so the next daily-only task gets the template's `nextColor`.
  - The midnight path `spawnDailyRoutineForUser` gives the same result.
  - Changing a template task's color afterwards leaves the existing daily task unchanged.

### Implementation for User Story 3

- [X] T035 [US3] In `BE/service/DailyRoutineService.java` `createDailyRoutineFromDefault`: add `task.setColor(template.getColor())` in the clone mapper (copy as-is, null included; no special handling) and `dailyRoutine.setColorCursor(defaultRoutine.getColorCursor())` before saving.
- [X] T036 [US3] Check that the Today page (`FE/features/daily/pages/DailyRoutinePage.jsx`) renders daily task colors through the shared `EditingBoard` (T020). The page keeps `showColor={false}` on `TaskEditModal`, so its create path sends no color and the backend assigns one. Update the line "`TaskEditModal` takes a `showColor` prop; the daily page passes `showColor={false}` because daily tasks have no color" in `ui-personal-routine-manager/CLAUDE.md`: daily tasks now have a stored color (inherited or assigned), and the picker is hidden on the daily page. Also update the "Type differences between features" section.

**Checkpoint**: The Default and Daily views show the same color for the same activity.

---

## Phase 7: User Story 5 - Switch between light and dark mode (Priority: P2)

**Goal**: The whole app has a light and a dark theme. It follows the device until the user chooses, switches instantly, remembers the choice per device, and doesn't flash on load.

**Independent Test**: quickstart.md scenario G.

### Tests for User Story 5

- [X] T037 [P] [US5] Create `FE/theme/themePreference.test.ts` (in the style of `components/layout/sidebarPreference.test.ts`). Cover:
  - `readThemePreference` returns `'light'`/`'dark'` for those values, and `null` for a missing value, `'blue'`, or storage that throws.
  - `writeThemePreference(null)` removes the key; write failures don't throw.
  - `resolveTheme(null, true) === 'dark'`, `resolveTheme(null, false) === 'light'`, and `resolveTheme('light', true) === 'light'`.
- [X] T038 [P] [US5] Extend `FE/styles/contrast.test.ts`:
  - Parse the `:root[data-theme="dark"]` block of `tokens.css` separately (add a small helper next to `readTokens` in `FE/styles/contrast.ts`, e.g. `readThemeTokens(cssText, selector)`, that merges the dark overrides onto the root tokens before resolving `var()` chains).
  - Run the same `AA_PAIRS` and the muted 3:1 check for **both** themes.

### Implementation for User Story 5

- [X] T039 [P] [US5] Create `FE/theme/themePreference.ts`:
  - `export const THEME_KEY = 'milos.theme'`, `type ThemePreference = 'light' | 'dark' | null`, `type Theme = 'light' | 'dark'`.
  - `readThemePreference(storage)`, which never throws and treats unknown values as null; `writeThemePreference(storage, pref)`, where null removes the key and failures are ignored; and `resolveTheme(pref, prefersDark)`.
  - Reuse `safeLocalStorage` from `FE/components/layout/sidebarPreference.ts`.
  - Data-model.md §5: "Never stored on the server (FR-021)".
- [X] T040 [US5] Create `FE/theme/useTheme.ts`:
  - Holds `preference` state (initialised from `readThemePreference(safeLocalStorage())`).
  - Works out `theme` with `resolveTheme` and `window.matchMedia('(prefers-color-scheme: dark)')`.
  - Sets `document.documentElement.dataset.theme = theme` in a layout effect.
  - Subscribes to `matchMedia` `change` only while `preference === null`.
  - `toggle()` sets and writes the preference to the opposite of the current `theme`.
  - Returns `{ theme, preference, toggle }` (contracts/theme-ui.md "Theme module").
  - Because several toggles can be mounted at once, share the state through a tiny module-level store (`useSyncExternalStore`) so all toggles agree.
- [X] T041 [US5] In `ui-personal-routine-manager/index.html`:
  - Add `<meta name="color-scheme" content="light dark" />`.
  - Add an inline `<script>` before the module script that reads `localStorage.getItem('milos.theme')` inside try/catch, falls back to `matchMedia('(prefers-color-scheme: dark)').matches`, and sets `document.documentElement.dataset.theme` to `'dark'` or `'light'`. It contains no color literals.
  - Keep the key string in sync with `THEME_KEY`, noted in a comment.
- [X] T042 [US5] In `FE/styles/tokens.css`:
  - Add the dark primitives to the tier-1 block (new names, e.g. `--color-ink-950: #0E131A`, …).
  - Add a `:root[data-theme="dark"] { … }` block that redefines **only tier-2 semantic tokens**, with exactly the values in `specs/F005-i-want-color-to-be-persisted/resources/dark-theme-palette.md` "Semantic tokens" (surfaces, borders, text, accent incl. `--color-accent: #1F74D8` and `--color-accent-hover: #1A66C2`, status, now-line, chat, illustration, overlay `rgba(0, 0, 0, 0.6)`, shadows with black 35–50%, and `--color-task-current: #9D84EA` / `--color-task-current-bg: #2C2D45`).
  - Add `color-scheme: light` in `:root` and `color-scheme: dark` in the dark block.
  - Update the header comment to name F005.
- [X] T043 [US5] In `ui-personal-routine-manager/src/App.css`, after the T021 rules, add the dark resolution for cards and swatches: `:root[data-theme="dark"] .ob-board-task { --task-accent: var(--task-accent-dark, var(--color-border-strong)); --task-bg: var(--task-bg-dark, color-mix(in srgb, var(--task-accent) 14%, var(--color-bg-surface))); }`, plus the same for `.ob-swatch`. Contracts/theme-ui.md has the exact rules.
- [X] T044 [P] [US5] Add `SunIcon` and `MoonIcon` to `FE/components/icons/Icons.tsx`, following the existing icon pattern (`currentColor` strokes, no color literals).
- [X] T045 [US5] Create `FE/components/ThemeToggle.tsx`: `<button type="button" aria-pressed={theme === 'dark'} aria-label="Dark mode">` that calls `toggle()` from `useTheme`. It shows `MoonIcon` in light and `SunIcon` in dark. It has a `variant: 'sidebar' | 'compact'` prop: `sidebar` renders icon + "Dark mode" label using the `app-nav-link` classes, and `compact` renders an icon-only `ui-icon-btn`.
- [X] T046 [US5] Mount the toggle on every page (FR-019):
  - `<ThemeToggle variant="sidebar" />` in the footer of `FE/components/layout/Sidebar.tsx`, next to the "Replay tour" button (line ~98). The label hides in the collapsed rail like the other nav labels, and it works in the phone overlay.
  - `<ThemeToggle variant="compact" />` in the top-right of `FE/features/auth/pages/AuthPage.tsx` and in the header of `FE/features/onboarding/pages/OnboardingPage.jsx`.
  - Add layout CSS in `FE/components/layout/AppShell.css` / `FE/App.css` using tokens only.
- [x] T047 [US5] Dark-mode visual pass. _(Code-level pass done 2026-11-21: no named/raw colours outside tokens; fixed the Apple logo (`fill="#000"` → `currentColor`), themed form fields in `base.css` and `.social-btn` text. **Still needs a look in a browser** in dark mode.)_ In dark mode, go through sign-in, onboarding (incl. walkthrough slides and tour), Today, Default Routine, Analytics placeholder, Buddy chat, `TaskEditModal`, `ConfirmDialog` and the sidebar overlay. Fix any element that still looks light, using semantic tokens in `FE/App.css`, `FE/components/layout/AppShell.css` and `FE/styles/base.css`. Check `FE/features/auth/pages/AuthPage.tsx`'s hero illustration in dark (SC-006). Never add raw colors outside `tokens.css`.

**Checkpoint**: All five stories work. Dark mode covers every page, task palette colors switch with the theme, and custom colors stay fixed.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Docs, full verification, deploy readiness.

- [X] T048 [P] Update `ms-personal-routine-manager/CLAUDE.md`:
  - Domain model: task `color` (palette id or `#RRGGBB`), routine `colorCursor`/`nextColor`, round-robin rule.
  - "API endpoints summary": add `GET /api/v1/task-palette`.
  - "Schema": add `db/F005-task-color.sql` to the apply-before-deploy list.
  - AI integration: Buddy can set palette colors by name.
- [X] T049 [P] Update `ui-personal-routine-manager/CLAUDE.md` Styling section: the dark theme via `:root[data-theme="dark"]` in `tokens.css`, the `src/theme/` module and `localStorage["milos.theme"]`, the boot script in `index.html`, task colors from the backend palette (`features/palette/`), and the removed `--color-task-N-*` tokens.
- [X] T050 Run `cd ms-personal-routine-manager && ./gradlew test` and `cd ui-personal-routine-manager && pnpm test && pnpm lint && pnpm build`. Fix every failure.
- [x] T051 _(Done 2026-11-21: A (palette API), H (DDL applied twice on the docker DB, on a pre-F005 schema copy with rows, and app start with `ddl-auto: validate`). **B–G need the running app in a browser.**)_ Run every scenario A–H in `specs/F005-i-want-color-to-be-persisted/quickstart.md` by hand, incl. applying `db/F005-task-color.sql` twice against the docker PostgreSQL (`local` profile) and starting once with `ddl-auto: validate` (scenario H).
- [X] T052 Update the ticket `specs/F005-i-want-color-to-be-persisted/F005-i-want-color-to-be-persisted.md` Claude Working Notes: set Status to `Implemented` and add a release note ("Tasks created before F005 have no stored colour and show a neutral tint; recolour them in the edit dialog if wanted. Apply db/F005-task-color.sql before deploying the backend").

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none. T001 and T002 run in parallel.
- **Foundational (Phase 2)**: T003 depends on T002. T004 and T008 depend on T003. T005–T007 can run in parallel. T009, T010, T012, T013 and T014 can run in parallel. T011 depends on T010. **Blocks every story.**
- **US1 (Phase 3)**: depends on Phase 2.
- **US4 (Phase 4)**: depends only on Setup (it doesn't use palette work), so it can start right away, alongside anything. It touches `EditingBoard.jsx` like T020, so don't edit that file in parallel with T020.
- **US2 (Phase 5)**: depends on US1 (T023 swatches, T016/T017 update rules).
- **US3 (Phase 6)**: depends on Phase 2 and T017 (daily assignment). Independent of US2.
- **US5 (Phase 7)**:
  - T037, T039, T040, T041, T042, T044, T045 and T046 depend only on Setup.
  - T043 depends on T021 and T023.
  - T038 depends on T022 and T042.
- **Polish (Phase 8)**: after all stories.

### User Story Dependencies

- **US1 (P1)**: Foundational only.
- **US4 (P1)**: none. Fully independent; the quickest win.
- **US2 (P2)**: builds on US1's swatches and update path.
- **US3 (P2)**: builds on US1's daily assignment (T017).
- **US5 (P2)**: independent, except that the task-card dark CSS (T043) needs US1's card CSS.

### Within Each User Story

- Backend tests are written with the story and must fail before its implementation tasks.
- Entities (Phase 2) → services → controllers/tools → frontend.

### Parallel Opportunities

- Phase 1: T001 ∥ T002.
- Phase 2: T005 ∥ T006 ∥ T007, and T009 ∥ T010 ∥ T012 ∥ T013 ∥ T014 (frontend) can run alongside the backend T003→T004/T008.
- **US4 can be built in parallel with Phases 2–3 by a second person** (different concern; coordinate on `EditingBoard.jsx`).
- US5's theme module, tokens, boot script, icons and toggle (T039–T042, T044–T046) can run in parallel with US1–US3 (backend-heavy).
- US2 backend (T032, T033) ∥ US2 frontend (T030, T031). US3 (T035) ∥ US2.

---

## Parallel Example: Foundational + US4

```bash
# Backend dev
Task: "T003 TaskPaletteProperties in BE/config/TaskPaletteProperties.java"
Task: "T005 DailyTask.color in BE/model/DailyTask.java"
Task: "T006 DefaultRoutine.colorCursor/nextColor in BE/model/DefaultRoutine.java"
Task: "T007 DailyRoutine.colorCursor/nextColor in BE/model/DailyRoutine.java"

# Frontend dev (same time)
Task: "T009 palette types in FE/features/palette/types/palette.ts"
Task: "T012 resolveTaskColor in FE/features/palette/utils/taskColor.ts"
Task: "T026–T027 live-mode scroll-once in FE/features/onboarding/components/EditingBoard.jsx"
```

## Parallel Example: User Story 5

```bash
Task: "T039 themePreference.ts in FE/theme/"
Task: "T042 dark token block in FE/styles/tokens.css"
Task: "T041 boot script in ui-personal-routine-manager/index.html"
Task: "T044 Sun/Moon icons in FE/components/icons/Icons.tsx"
```

---

## Implementation Strategy

### MVP First

1. **US4 (T026–T028)**: a tiny change that removes the most annoying behaviour. It can ship on its own.
2. Phase 1 + 2, then **US1**: stable stored colors, which is the core of the ticket. Stop and validate with quickstart A–B, then deploy (DDL first).

### Incremental Delivery

1. US4 → deploy.
2. Setup + Foundational + US1 → deploy (apply `db/F005-task-color.sql` first).
3. US2 (overrides + Buddy) → deploy.
4. US3 (daily inherits) → deploy.
5. US5 (dark mode) → deploy. This is the largest UI pass; it can be split off if needed.

### Notes

- Old data: no task may add backfill, migration or null-color special-casing (FR-009). Any unresolved color (null, unknown ID, palette not loaded) falls through to the same neutral CSS default.
- Never add raw color literals outside `tokens.css`. Palette hex values arrive as runtime data.
- Commit after each task or logical group, and stop at any checkpoint to validate.
