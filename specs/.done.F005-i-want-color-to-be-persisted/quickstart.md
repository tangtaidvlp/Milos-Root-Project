# Quickstart: validate F005

Shapes and rules: [contracts/](contracts/) and [data-model.md](data-model.md). This guide only lists how to run the checks and what you should see.

## Prerequisites

```bash
# Backend (H2, no auth). Use the local profile + docker DB to test the prod DDL path.
cd ms-personal-routine-manager && SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun
# Frontend
cd ui-personal-routine-manager && pnpm dev
```

Sign up a fresh user and finish onboarding (old data is out of scope, so test with new tasks).

## Automated checks

```bash
cd ms-personal-routine-manager && ./gradlew test     # palette config, round-robin, update/keep, clone, 400s, Buddy tools
cd ui-personal-routine-manager && pnpm test          # resolveTaskColor, theme preference, contrast (light + dark), noRawColors
cd ui-personal-routine-manager && pnpm lint && pnpm build
```

## Manual scenarios

### A. Palette API (FR-010)
`curl localhost:8080/api/v1/task-palette` → 8 entries in order green, orange, blue, grey, slate, peach, pink, purple, each with `light`/`dark` accent + bg.

### B. Round-robin + stable colours (US1, FR-001–006)
1. Default Routine → Weekday. Add tasks A, B, C via "+ Add task", keeping the pre-selected swatch each time → green, orange, blue.
2. Open "+ Add task" again → **grey** is pre-selected.
3. Add D at 05:00 (before A), delete B, drag C to another time, resize A, rename A. Reload.
   - **Expect**: A green, C blue, D grey — unchanged after every step and after reload.
4. Open the app in a second browser → same colours.

### C. User override (US2, FR-007)
1. Edit C → pick the **Pink** swatch → Save → reload → C is pink.
2. Edit C → **Custom** → pick a red → Save → reload → C shows that red, also after switching theme.
3. Create a new task after step 1 keeping the pre-selected swatch → it is the next round-robin colour (override didn't move the cursor).

### D. Buddy (US2 scenarios 3–4, FR-002, FR-013, FR-017)
1. Ask Buddy: "add Reading at 21:00 for 30 minutes" → new task in the next round-robin colour.
2. "make Reading the purple one" → Reading turns purple.
3. "make Reading #ff0000" or "make it gold" → colour unchanged; Buddy lists the available colours.
4. "add Sleep from 23:00 to 07:00" → two parts (23:00–24:00, 00:00–07:00), **same colour**.

### E. Daily inherits colours (US3, FR-008)
1. With colours set on the Weekday routine, trigger a new day: `POST /api/support/cron/spawn-daily-task` (local/fast; delete today's routine first if it exists) or open Today for a date with no routine and add a task (ensure).
2. **Expect**: every daily task has the same colour as its template task.
3. Add a task only on Today → gets the template's next round-robin colour, stable after reload.
4. Change a template task's colour → existing daily task keeps its colour.

### F. Live mode (US4, FR-014–016)
1. Open Today → board is scrolled so the now-line is visible.
2. Scroll to evening, wait ≥ 2 minutes → **view doesn't move**; the now-line and Now/Next footer still update.
3. Pause clock → Resume live → view doesn't move.
4. Zoom in/out → the time at the top of the view stays in place; no jump to now.
5. Edit/save a task, or let Buddy change one → view doesn't move.
6. Navigate to Default Routine and back to Today → scrolls to now once.

### G. Light / dark mode (US5, FR-018–022)
1. Clear site data; set the OS to dark → app opens dark (incl. sign-in page). OS light → light.
2. Toggle "Dark mode" in the sidebar → whole app switches instantly, no reload. Check sign-in, onboarding, Today, Default Routine, Buddy chat, task dialog, confirm dialog, walkthrough slides: no light-only panels (SC-006).
3. Palette tasks show the dark variants; custom-colour tasks show their exact colour.
4. Reload → chosen theme kept, no light flash before it applies. Another browser → its own setting (FR-021).
5. With a chosen theme, change the OS setting → app doesn't change. Clear `localStorage["milos.theme"]` → follows the OS again.

### H. Prod schema
`psql "$DATABASE_URL" -f ms-personal-routine-manager/db/F005-task-color.sql` twice → no errors (idempotent); then start the app with `ddl-auto: validate` → starts cleanly.
