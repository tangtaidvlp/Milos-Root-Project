# Implementation Plan: Persistent Task Colors, Non-Intrusive Live Mode & Light/Dark Mode

**Branch**: `F005-i-want-color-to-be-persisted` | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F005-i-want-color-to-be-persisted/spec.md`

## Summary

Three changes, across both projects:

1. **Stored, backend-chosen task colors.**
   - The backend owns an 8-color, theme-aware palette (config) and serves it at `GET /api/v1/task-palette`.
   - Every new task gets a stored `color`, either a palette ID or a user-chosen `#RRGGBB`.
   - IDs are assigned round-robin with a per-routine `color_cursor`. Tasks with the same name in one request share a color, which covers Buddy's split across midnight.
   - Updates keep the color unless a new one is sent. This also fixes the existing bug where default-task updates dropped `color`.
   - Daily tasks gain `color` and copy it from their template.
   - Buddy can set a palette color by name.
   - The frontend drops the index-based tint and renders the stored color. The create dialog pre-selects the routine's `nextColor` from palette swatches.
2. **Live mode scrolls once.** The `EditingBoard` auto-scroll becomes a run-once-per-mount effect. Zoom keeps the time at the top of the view in place in live mode too.
3. **Light/dark mode.**
   - A `:root[data-theme="dark"]` block redefines the semantic tokens; values come from `resources/dark-theme-palette.md`.
   - A small theme module keeps a per-device preference in `localStorage` and follows the device setting until the user chooses.
   - An inline boot script prevents a flash of the light theme.
   - A toggle sits in the sidebar, on the sign-in page and in the onboarding header.

Old data (tasks with no stored color) gets no migration and no special-case code.

## Technical Context

**Language/Version**: Backend Java 25 / Spring Boot 4.1 (Gradle). Frontend TypeScript 5 + JSX, React 19, Vite 8.

**Primary Dependencies**: Spring Web, Spring Data JPA, Spring AI (`@Tool`, Gemini), Lombok. React Router 7, plain CSS tokens.

**Storage**: PostgreSQL 17 (prod `ddl-auto: validate`, so a DDL script is needed: `db/F005-task-color.sql`), H2 for the `fast` profile. Browser `localStorage` for the theme preference.

**Testing**: Backend JUnit + Spring Boot integration tests (`./gradlew test`). Frontend Vitest for pure logic (`pnpm test`), plus the existing `contrast.test.ts` / `noRawColors.test.ts`. UI checked by hand with `quickstart.md`.

**Target Platform**: Backend on Linux EC2 (Docker). SPA in modern evergreen browsers (needs `color-mix()`, already used), desktop and phone.

**Project Type**: Web application (separate backend + frontend projects).

**Performance Goals**: Theme switch under 1 s with no reload (SC-007); palette fetched once per session (8 entries, under 2 KB).

**Constraints**:
- No raw color literals outside `tokens.css`.
- WCAG AA token pairs must pass in both themes.
- All requests go through `lib/api.ts`.
- No old-data backfill or fallback logic.
- Palette IDs never change once released.

**Scale/Scope**:
- Backend: about 12 files touched or added (2 entities + 2 routine entities, 2 services, a new `TaskColorService`, palette properties + controller, 2 AI tool classes, legacy AI functions, DDL, tests).
- Frontend: about 15 files touched or added (palette feature, theme module, toggle, tokens, board, dialog, types, hook, `index.html`, tests).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so it has no ratified principles to gate on. The project's written conventions (root and subproject `CLAUDE.md`, `codingrules.md`) serve as the gates instead:

| Gate | Pre-design | Post-design |
|------|-----------|-------------|
| Feature-based frontend structure; API calls only through `lib/api.ts` | ✅ New code goes in `features/palette/`, `src/theme/`, `components/ThemeToggle.tsx`. The palette fetch uses `apiRequest`. | ✅ |
| No raw colors outside `tokens.css` (`noRawColors.test.ts`) | ✅ Dark values live in `tokens.css`. Palette hex values arrive as runtime data. The boot script has no color literals. | ✅ |
| Token contrast is tested (`contrast.test.ts`) | ⚠️ The test checks `--color-task-N-bg`, which this feature removes. | ✅ The test is updated to check the same AA pairs for **both** themes; task-card pairs are checked against the palette values in backend config (unit test on the backend side + values recorded in `data-model.md`). |
| Prod schema changes ship as an idempotent DDL script applied before deploy | ✅ `db/F005-task-color.sql` | ✅ |
| Backend conventions: Lombok, constructor injection, `@Transactional` writes, UUID keys, `@ConfigurationProperties` | ✅ | ✅ |
| Request/response shapes match between the two projects | ✅ `contracts/task-color-api.md` gives the TS types next to the JSON | ✅ |
| Old data left alone (user instruction) | ✅ No backfill or fallback code; only additive nullable columns | ✅ |

No violations, so Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/F005-i-want-color-to-be-persisted/
├── F005-i-want-color-to-be-persisted.md   # ticket + Claude working notes
├── spec.md
├── plan.md              # this file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── task-palette-api.md
│   ├── task-color-api.md
│   └── theme-ui.md
├── resources/
│   └── dark-theme-palette.md
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks; not created here)
```

### Source Code

```text
ms-personal-routine-manager/
├── db/F005-task-color.sql                                   # NEW: ALTERs (daily_task.color, *_routine.color_cursor)
└── src/
    ├── main/java/com/tom/payment/routinemanager/
    │   ├── config/TaskPaletteProperties.java                # NEW: app.task-palette.colors + startup validation
    │   ├── api/TaskPaletteController.java                   # NEW: GET /api/v1/task-palette
    │   ├── service/TaskColorService.java                    # NEW: isValid, assign (round-robin + same-name), fillNextColor
    │   ├── model/DailyTask.java                             # + color
    │   ├── model/DefaultRoutine.java                        # + colorCursor (@JsonIgnore), + @Transient nextColor
    │   ├── model/DailyRoutine.java                          # + colorCursor, + @Transient nextColor
    │   ├── service/DefaultRoutineService.java               # assign on add/full-replace; update keeps/sets color; fill nextColor
    │   ├── service/DailyRoutineService.java                 # clone copies color + cursor; assign on add; update keeps/sets
    │   ├── service/aitools/DefaultRoutineAiTools.java       # color param (palette id), validation message, tool text
    │   ├── service/aitools/DailyRoutineAiTools.java         # same
    │   └── config/AiRoutineFunctions.java                   # legacy: goes through service, so assignment is inherited; no API change
    ├── main/resources/application.yml                       # app.task-palette.colors (8 entries)
    └── test/java/com/tom/payment/routinemanager/
        └── TaskColorIntegrationTest.java                    # NEW

ui-personal-routine-manager/
├── index.html                                               # inline theme boot script + color-scheme meta
└── src/
    ├── theme/
    │   ├── themePreference.ts (+ .test.ts)                  # NEW: read/write/resolve, THEME_KEY
    │   └── useTheme.ts                                      # NEW: applies data-theme, matchMedia listener, toggle
    ├── components/ThemeToggle.tsx                           # NEW
    ├── components/icons/Icons.tsx                           # + SunIcon, MoonIcon
    ├── components/layout/Sidebar.tsx                        # toggle in footer
    ├── features/auth/pages/AuthPage.tsx                     # compact toggle
    ├── features/onboarding/pages/OnboardingPage.jsx         # compact toggle in header
    ├── features/palette/
    │   ├── api/taskPalette.ts                               # NEW: fetchTaskPalette via apiRequest
    │   ├── hooks/usePalette.ts                              # NEW: fetch once, module cache
    │   ├── types/palette.ts                                 # NEW
    │   └── utils/taskColor.ts (+ .test.ts)                  # NEW: resolveTaskColor, isPaletteId
    ├── features/onboarding/components/EditingBoard.jsx      # drop taskTintStyle index tint; use resolveTaskColor; live scroll once; zoom anchor in live
    ├── features/onboarding/components/TaskEditModal.tsx     # palette swatches + Custom; initial = draft.color
    ├── features/onboarding/hooks/useDefaultRoutines.ts      # create draft gets color = activeRoutine.nextColor
    ├── features/onboarding/types/routine.ts                 # color?: string|null, nextColor
    ├── features/daily/types/dailyRoutine.ts                 # color?: string|null, nextColor
    ├── styles/tokens.css                                    # dark block, color-scheme, remove --color-task-N-*
    ├── styles/contrast.test.ts                              # check pairs for both themes
    └── App.css                                              # .ob-board-task light/dark variable resolution
```

**Structure Decision**: The existing two-project web app layout. Backend changes stay in the existing packages (`api`, `config`, `model`, `service`, `service/aitools`). Frontend: the palette is a new feature module (`features/palette/`) because the board, dialog and daily page all use it. The theme is app-wide, so it lives in `src/theme/` with a global `components/ThemeToggle.tsx`. Both follow `codingrules.md`.

## Implementation notes (order and risks)

1. **Backend first**: palette config + endpoint → `TaskColorService` → entity columns + DDL → service create/update/clone → AI tools → tests. The frontend can be built against `fast` once the palette endpoint and `nextColor` exist.
2. **Live-mode fix** is independent and small (US4, P1). It can ship first.
3. **Theme** is independent of colors except for the task-card CSS. Build the tokens and toggle, then switch the board to the palette variables.
4. **Risks**:
   - Old tasks with `color = null` show a neutral tint once the index fallback is gone. This is accepted (FR-009), and noted in the release note so it isn't reported as a bug.
   - Buddy may not keep split parts' names identical. The tool description instructs it to, and it can also pass the same palette ID explicitly.
   - `GET` default-routine for WEEKEND creates the routine. `nextColor` must be filled on that path too.
   - Deploy order: apply `db/F005-task-color.sql`, then the backend image, then the frontend. The old frontend keeps working against the new backend because all new fields are additive.

## Complexity Tracking

None. No gate violations.
