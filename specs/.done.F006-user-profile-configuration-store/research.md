# Research: User Profile & Configuration Store (F006)

All Technical Context unknowns are resolved below. Each entry: Decision / Rationale / Alternatives considered.

## R1. How settings are stored on the server

- **Decision**: New table `user_setting`, one row per (user, setting key): `user_id`, `setting_key`, `setting_value` (text), `updated_at`. A server-side **settings registry** lists the known keys with their default value and validation rule: `theme` (LIGHT | DARK | SYSTEM, default SYSTEM) and `boardZoom` (0.5–3.0 in 0.25 steps, default 1.0). A missing row means "use the default". A row whose key isn't in the registry is skipped when reading.
- **Rationale**: Prod runs `ddl-auto: validate` with hand-applied DDL scripts (`db/F00x-*.sql`), so a new column per preference would mean a DDL script and a deploy step for every future setting. With key/value rows, adding a preference is just a registry entry (FR-016). Saving one key at a time means two devices changing *different* settings never overwrite each other, and for the same setting the last write wins (spec Edge Cases). It works the same on PostgreSQL and the H2 `fast`/test profile.
- **Alternatives considered**:
  - Typed columns on `users` (`theme`, `board_zoom`): simplest to query, but every new preference needs a schema change (fails FR-016).
  - One JSON/JSONB document per user: flexible, but `jsonb` behaves differently on H2, and every write rewrites the whole document (a lost-update risk across devices unless it is merged on the server).

## R2. API shape

- **Decision**: Add a new `UserSettingsController` under `/api/v1/users/{userId}`:
  - `GET  /api/v1/users/{userId}/settings` returns the effective settings (defaults merged in) plus `customized`, the keys the user has actually saved.
  - `PATCH /api/v1/users/{userId}/settings` takes a partial map, validates **every** key before writing any, upserts the changed keys, and returns the same body as GET.
  - `GET  /api/v1/users/{userId}/profile` returns `{ id, username, email, plan }`, with `plan` fixed at FREE.

  All three use `CurrentUserGuard.requireUser(userId)` (404 for an unknown user, 403 when the JWT user isn't `{userId}`; FR-012). Full detail: [contracts/settings-api.md](contracts/settings-api.md).
- **Rationale**: This matches the existing per-user path style and the guard used by the F004 chat history endpoints. `customized` is what the one-time device-theme copy needs (FR-014: copy only when the account has no theme). PATCH with a partial body saves only the key that changed. Returning the plan from the server means real plans later need no frontend change.
- **Alternatives considered**: `PUT` with the full document (risks overwriting another device's change to a different key). Adding the settings to the login/refresh response (couples auth to settings; a settings failure would then break sign-in). Hard-coding "Free plan" in the frontend (works, but needs a UI change once plans exist).

## R3. Theme states and the device cache

- **Decision**: The frontend `ThemePreference` becomes `'light' | 'dark' | 'system'`. `localStorage["milos.theme"]` stays as the **device cache** of the last-applied preference: `light`/`dark` are written as today, and `system` removes the key, so the boot script in `index.html` and older builds still read it correctly with no change. The account value replaces the cache once it loads (FR-015). Signed-out screens read and write only the cache (spec Edge Cases).
- **Rationale**: Keeping the key and its encoding means the no-flash boot script keeps working as is (SC-003). A third stored value would need the boot script changed, and it gains nothing.
- **Alternatives considered**: Storing the string `system` in the cache (needs a boot-script change and risks bugs with old tabs). Waiting for the server before the first paint (slow, and it flashes when offline).

## R4. One-time copy of the pre-F006 device theme (FR-014)

- **Decision**: Add a device flag `localStorage["milos.theme.migrated"]`. After the first **successful** settings load while signed in on a device with no flag, the app copies the device theme to the account, but only when the cache holds `light`/`dark` and `theme` is **not** in `customized`. It then sets the flag **in every case** (copied or not). Later sign-ins on that device never copy. The decision is a pure function, `shouldMigrateDeviceTheme(cache, flag, customized)`, with its own tests. **Order matters**: read the device cache and the flag **before** applying the account theme, because applying writes the cache.
- **Rationale**: This meets the "at most once per device, first account after release" answer from clarification Q3, so later users of a shared device never inherit the theme. A failed settings load doesn't set the flag, so the copy is retried next time.
- **Alternatives considered**: Copying on every sign-in when the account has no theme (leaks between users of a shared device, which Q3 rejected). Clearing the cache on sign-out (rejected in Q3: the sign-in screen keeps the last theme).

## R5. Shared board zoom in the frontend

- **Decision**: A module-level settings store (`features/settings/hooks/useUserSettings.ts`, `useSyncExternalStore`, the same pattern as `theme/useTheme.ts`) holds `boardZoom`. `EditingBoard` replaces its local `useState(1.0)` with `useBoardZoom()`, which returns the shared value and a setter. Pressing zoom applies right away. The save is **debounced (~500 ms)** so a burst of clicks saves only the final value (spec Edge Cases). `normalizeZoom()` clamps to 0.5–3.0, rounds to the nearest 0.25, and treats bad input as 1.0. Zoom is **not** cached on the device: it starts at 100% until the account value arrives (normally within the first second, before a user zooms).
- **Rationale**: One store gives every board one shared value (clarification answer Q3 in the ticket), and a change on the Profile screen shows on the boards without a reload (FR-005a). The anchor-preserving scroll effect already reacts to `boardHeightPx`, so it keeps working.
- **Alternatives considered**: React context at the App level (re-renders the whole tree on each zoom step; the module store matches the existing theme store). Also caching zoom in localStorage (it would hold the previous user's zoom on a shared device; skipped for simplicity).

## R6. Save-failure notice

- **Decision**: A small `SettingsSaveNotice` (`role="status"`, auto-hides after ~5 s) is rendered once at the App level, so it covers the shell pages *and* the Onboarding page. Its text: "Couldn't save your setting — it's applied for now." The settings store keeps the value in memory either way. A failed load shows **no** notice: it falls back to the cache and defaults quietly (FR-013).
- **Rationale**: This shows the notice without blocking (FR-013), and nothing like it exists in the app yet. App level is the only place shared by both theme locations.

## R7. Theme control UI (3-way)

- **Decision**: Replace `ThemeToggle` with `ThemeControl`, a `ui-segmented` radio group with three options: Light (sun), Dark (moon), System (new `MonitorIcon`). It is labelled "Theme", each option has `aria-checked`, and arrow keys move between options. Variants: `sidebar` (shows labels, sits in the sidebar footer row), `compact` (icons only: auth header and onboarding top bar), and `full` (Profile Preferences). It sets the preference through `setThemePreference(pref)` from `theme/useTheme.ts`.
- **Rationale**: Clarification Q1 asks for three ways everywhere, and a radio group is the accessible pattern for "pick one of three".

## R8. Profile page and sidebar entry

- **Decision**: New route `/profile` as a shell child (`RequireOnboarded` → `AppShell`) → `features/profile/pages/ProfilePage.tsx`. The sidebar `.app-user` block becomes a `NavLink to="/profile"` labelled "Open profile", with the active style and the same close-overlay-on-pick behaviour as nav links (FR-006). The page has an Account card (name, email), a Plan card ("Free plan"), Preferences (`ThemeControl variant="full"` + a zoom stepper from `useBoardZoom()`), and Sign out (`onLogout` from `useShellContext()`). It is **not** added to `NAV_ENTRIES`, since the user block is the entry point.

## R9. Testing approach (answers the ticket's testing questions)

- **Decision**: Three layers.
  1. **Backend**: `UserSettingsIntegrationTest` (Spring Boot + MockMvc on H2, the same pattern as `TaskColorIntegrationTest` and `ChatHistoryIntegrationTest`).
  2. **Frontend logic + React components**: Vitest. Pure `*.test.ts` stays as it is. **New: React component tests** `*.test.tsx` with `@testing-library/react`, `@testing-library/user-event` and `jsdom`, which a file opts into with `// @vitest-environment jsdom`, so existing node tests aren't affected. Covers `ThemeControl`, `ProfilePage`, the sidebar user link and `SettingsSaveNotice`.
  3. **Headless browser E2E**: Playwright (`@playwright/test`, Chromium headless) in `ui-personal-routine-manager/e2e/`, run with `pnpm test:e2e` against `pnpm dev` + backend on the `fast` profile. It covers reload persistence, a second device (a new browser context) and Profile sign-out. It runs locally (and is optional in CI later). Manual visual checks are in [quickstart.md](quickstart.md).
- **Rationale**: The ticket asks for React tests. jsdom component tests are fast and run with `pnpm test`, but they can't prove "reload keeps it" against a real server. Headless Playwright can, and it repeats exactly every time (preferred over a person clicking through a browser). Claude can run both headlessly.
- **Alternatives considered**: Cypress (heavier, and Playwright's multiple browser contexts model "a second device" more simply). Manual-only checks (the current approach, which isn't repeatable). Vitest browser mode (newer, and it needs Playwright anyway).
- **Impact on docs**: `ui-personal-routine-manager/CLAUDE.md` currently says "Tests cover pure logic only (no DOM setup)". The implementation must update that line and the Commands table (`pnpm test:e2e`).
