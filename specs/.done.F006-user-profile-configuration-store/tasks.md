---

description: "Task list for F006 – User profile & configuration store"
---

# Tasks: User Profile & Configuration Store

**Input**: Design documents from `specs/F006-user-profile-configuration-store/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/settings-api.md](contracts/settings-api.md), [contracts/ui-profile-settings.md](contracts/ui-profile-settings.md), [quickstart.md](quickstart.md)

**Tests**: The ticket asks for them ("How we know it works: Perform React Test"). Each story therefore has backend integration tests, Vitest logic and React component tests, and headless Playwright E2E (research R9). Write the tests first and watch them fail before implementing.

**Organization**: Tasks are grouped by user story, so each story can be implemented and tested on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 / US2 / US3 from spec.md

## Path Conventions

- Backend repo: `ms-personal-routine-manager/`. The Java main package is `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/`, and tests are in `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/`.
- Frontend repo: `ui-personal-routine-manager/`.
- All paths below are relative to the workspace root `/Users/tommtang2106/Projects/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Set up the test tooling and the empty feature folders.

- [X] T001 Add frontend dev dependencies with `pnpm add -D @testing-library/react @testing-library/user-event @testing-library/jest-dom jsdom @playwright/test` in `ui-personal-routine-manager/package.json`. Pin the exact resolved versions (no `^`) to match the repo's lockfile style. Run `pnpm exec playwright install chromium` once locally.
- [X] T002 Add the script `"test:e2e": "playwright test"` to `ui-personal-routine-manager/package.json`. Keep `"test": "vitest run --passWithNoTests"` so it picks up both `*.test.ts` and `*.test.tsx` under `src/`. If needed, add a `test.include: ['src/**/*.test.{ts,tsx}']` / `exclude: ['e2e/**']` block to `ui-personal-routine-manager/vite.config.ts`, so Vitest never runs the Playwright specs.
- [X] T003 [P] Update `ui-personal-routine-manager/tsconfig.test.json` to include `src/**/*.test.tsx`, `e2e/**/*.ts` and `playwright.config.ts`, and add `@testing-library/jest-dom` types. Check that `ui-personal-routine-manager/tsconfig.app.json` still excludes `*.test.tsx` and `e2e/`.
- [X] T004 [P] Create `ui-personal-routine-manager/playwright.config.ts`:
  - `testDir: 'e2e'`, Chromium only, `headless: true`.
  - `baseURL: 'http://localhost:5173/milos.github.io/'` (Vite `base`; the app uses HashRouter, so pages are `#/today` etc.).
  - `workers: 1`, `retries: 0`, `trace: 'retain-on-failure'`.
  - No `webServer` block: the backend (`SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun`) and `pnpm dev` are started by hand, as in quickstart.md.
  - Add `test-results/` and `playwright-report/` to `ui-personal-routine-manager/.gitignore`.
- [X] T005 [P] Create `ui-personal-routine-manager/e2e/helpers.ts` with:
  - `registerAndOnboard(page)`: register a unique user (`e2e-<timestamp>@example.com`) through the `#/auth` sign-up form, then finish onboarding by pressing "Ready to roll".
  - `signIn(page, email, password)`
  - `signOut(page)`

  Read `ui-personal-routine-manager/src/features/auth/` and the onboarding page to get the real field labels and button text.
- [X] T006 [P] Create the empty feature folders `ui-personal-routine-manager/src/features/settings/{api,types,utils,hooks,components}/` and `ui-personal-routine-manager/src/features/profile/{api,types,pages}/` (create each folder together with its first file, in later tasks).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The settings table, the registry and the frontend settings schema. US1, US2 (Preferences section) and US3 all depend on these.

**⚠️ CRITICAL**: Finish this phase before starting any user story.

- [X] T007 Create `ms-personal-routine-manager/db/F006-user-settings.sql`. Copy the header style of `db/F005-task-color.sql`: "Apply to prod BEFORE deploying F006 (prod uses ddl-auto: validate). Idempotent." It runs:
  ```sql
  CREATE TABLE IF NOT EXISTS user_setting (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    setting_key VARCHAR(64) NOT NULL,
    setting_value VARCHAR(255) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (user_id, setting_key));
  ```
- [X] T008 [P] Create the JPA entity `UserSetting` in `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/model/UserSetting.java`, with id class `UserSettingId` (`userId` UUID, `settingKey` String; `Serializable`, equals/hashCode) in `.../model/UserSettingId.java`.
  - `@Table(name = "user_setting")` and `@IdClass(UserSettingId.class)`.
  - Columns: `user_id`, `setting_key` (length 64), `setting_value` (length 255, `nullable = false`), `updated_at` (`OffsetDateTime`, `nullable = false`).
  - Store `userId` as a plain UUID column, not a `@ManyToOne`, so the `User` JSON isn't affected. Use Lombok `@Getter @Setter @NoArgsConstructor`.
- [X] T009 [P] Create `UserSettingRepository extends JpaRepository<UserSetting, UserSettingId>` with `List<UserSetting> findByUserId(UUID userId)` in `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/repository/UserSettingRepository.java`.
- [X] T010 [P] Create `UserSettingsRegistry` (`@Component`) in `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/UserSettingsRegistry.java`. It holds an ordered map of `SettingDefinition(key, defaultValue, parse(Object raw) → canonical String or throw IllegalArgumentException, toJson(String stored) → Object)`. Entries:
  - `theme`: "exactly LIGHT / DARK / SYSTEM (case-insensitive on input, stored upper-case)", default `SYSTEM`, JSON as a String.
  - `boardZoom`: "0.5 ≤ v ≤ 3.0 and v is a multiple of 0.25", default `1.0`. Accept JSON numbers only, store as a plain decimal string (e.g. `1.25`), JSON as a Double.
  - Add `isKnown(key)`, `keys()`, and `effectiveValue(key, storedOrNull)`, which returns the default when the stored value is missing **or fails re-validation**.
- [X] T011 [P] Create the DTOs in `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/dto/UserSettingsView.java`: a record `UserSettingsView(Map<String, Object> settings, List<String> customized)`.
- [X] T012 [P] Create the frontend settings types in `ui-personal-routine-manager/src/features/settings/types/settings.ts`: `ThemePreference = 'light' | 'dark' | 'system'`, `UserSettings = { theme: ThemePreference; boardZoom: number }`, `UserSettingsView = { settings: UserSettings; customized: string[] }`, and the API wire type `ApiTheme = 'LIGHT' | 'DARK' | 'SYSTEM'`.
- [X] T013 [P] Write failing tests first in `ui-personal-routine-manager/src/features/settings/utils/settingsSchema.test.ts`:
  - `normalizeZoom`: clamps to 0.5–3.0; rounds to the nearest 0.25 (1.1 → 1.0, 1.13 → 1.25); `NaN`/`null`/a string → 1.0.
  - `themeFromApi`/`themeToApi` round-trip, with unknown input → `'system'`.
  - `normalizeSettings` fills in missing keys with defaults and ignores unknown keys.
- [X] T014 Implement `ui-personal-routine-manager/src/features/settings/utils/settingsSchema.ts` so T013 passes. It exports `ZOOM_MIN = 0.5`, `ZOOM_MAX = 3.0`, `ZOOM_STEP = 0.25`, `DEFAULT_SETTINGS = { theme: 'system', boardZoom: 1 }`, `normalizeZoom`, `themeFromApi`, `themeToApi` and `normalizeSettings`.

**Checkpoint**: The table, entity, registry and frontend schema exist. Story work can start.

---

## Phase 3: User Story 1 – My display settings stay as I left them (Priority: P1) 🎯 MVP

**Goal**: Theme (Light/Dark/System) and one shared board zoom are saved to the account. They are applied on sign-in or reload on any device. Save failures don't block the user. A pre-F006 device theme is copied once.

**Independent Test**: quickstart scenarios 1–4 and 7–9. Sign in, choose Dark, zoom to 150% on Today, reload: both are kept, and Default routine is also at 150%. A fresh browser context signed in as the same user sees the same values.

### Tests for User Story 1 (write first; they must fail)

- [X] T015 [P] [US1] Create `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/UserSettingsIntegrationTest.java` (`@SpringBootTest`, MockMvc, `@Transactional`; follow the setup in `TaskColorIntegrationTest.java`). Cases:
  - (a) A new user: GET `/api/v1/users/{id}/settings` → `settings.theme == "SYSTEM"`, `settings.boardZoom == 1.0`, `customized == []`.
  - (b) PATCH `{"theme":"dark"}` → 200, theme `DARK`, `customized` contains `theme`. A later GET returns the same.
  - (c) PATCH `{"boardZoom":1.5}`, then PATCH `{"theme":"LIGHT"}` → `boardZoom` is still 1.5.
  - (d) Each of these returns 400 and writes nothing: `{}`, `{"theme":"BLUE"}`, `{"boardZoom":0.25}`, `{"boardZoom":3.25}`, `{"boardZoom":1.1}`, `{"boardZoom":"1.5"}`, and `{"theme":"DARK","boardZoom":9}`. After the last one, theme is unchanged.
  - (e) An unknown userId → 404 for GET and PATCH.
  - (f) **Own data only (FR-012)**: create users A and B. Signed in as A, request B's settings and expect **403** for GET and PATCH, with B's rows unchanged. Signed in as A, request A's settings: 200. To sign in, set an authenticated `SecurityContext` whose name is A's email (`@WithMockUser(username = "<A's email>")` or `SecurityContextHolder` set by hand in the test), because `CurrentUserGuard` compares `auth.getName()` with the user's email. This works even under profiles where auth is turned off. Clear the context afterwards.
- [X] T016 [P] [US1] Update `ui-personal-routine-manager/src/theme/themePreference.test.ts` for the 3-way preference:
  - `readThemePreference`: `light`/`dark` → same; absent/garbage → `'system'`.
  - `writeThemePreference('system')` removes `milos.theme`.
  - `resolveTheme('system', true) === 'dark'`.
  - New `shouldMigrateDeviceTheme(cache, migratedFlag, customized)`: true only when the cache is `light`/`dark`, the flag is absent and `customized` lacks `theme`. False in every other combination.
- [X] T017 [P] [US1] Create `ui-personal-routine-manager/src/features/settings/hooks/useUserSettings.test.ts`. Mock `fetchUserSettings`/`saveUserSettings` with `vi.mock`, use fake timers, jsdom env. Cases:
  - `loadUserSettings(userId)` applies the account theme with no save call, and sets zoom.
  - A load failure → status `error`, zoom 1.0, no notice.
  - Three `setBoardZoom` calls within 500 ms → exactly one PATCH with the final value.
  - A failed PATCH → the save-failure notice is triggered and the local value is kept.
  - `resetUserSettings()` → zoom 1.0, no user.
  - The migration runs once: when `shouldMigrateDeviceTheme` is true it PATCHes the theme, then sets `milos.theme.migrated`. A second load doesn't PATCH.
  - **Migration ordering (I1)**: with `localStorage["milos.theme"] = "dark"`, no migrated flag, and GET returning `{ theme: 'SYSTEM', customized: [] }`, the result is a PATCH `{ theme: 'DARK' }`, the applied theme is dark and the flag is set. This fails if the cache is read after the account theme is applied.
  - **Change during load (U1)**: start `loadUserSettings` with a GET that is still pending. Call `setThemePreference('dark')` and `setBoardZoom(2)`, then resolve the GET with `{ theme: 'LIGHT', boardZoom: 1 }`. The theme stays dark and the zoom stays 2. Both are PATCHed. The GET values don't overwrite them.
  - **Pending save sent on sign-out (U2)**: call `setBoardZoom(1.5)`, then `resetUserSettings()` within 500 ms. Exactly one PATCH `{ boardZoom: 1.5 }` is sent immediately. A `pagehide` event with a pending zoom also sends it at once (`keepalive: true`).
- [X] T018 [P] [US1] Create `ui-personal-routine-manager/src/components/ThemeControl.test.tsx` (`// @vitest-environment jsdom`, Testing Library):
  - It renders a `radiogroup` named "Theme" with three radios: Light, Dark, System.
  - The radio matching the current preference has `aria-checked="true"`.
  - Clicking Dark sets `document.documentElement.dataset.theme === 'dark'` and marks Dark checked.
  - ArrowRight from Dark selects System.
  - Two mounted controls stay in sync.
- [X] T019 [P] [US1] Create the E2E spec `ui-personal-routine-manager/e2e/settings-persistence.spec.ts` (quickstart 1–3):
  - (1) `registerAndOnboard`, pick Dark in the sidebar theme control, `page.reload()`, and expect `html[data-theme="dark"]` with the Dark radio checked.
  - (2) On `#/today`, click "Zoom in" twice and expect "150%". Reload and expect "150%". Go to `#/default-routine` and expect "150%".
  - (3) `browser.newContext()`, then `signIn` as the same user, and expect dark plus 150% on Today.

### Implementation for User Story 1

- [X] T020 [US1] Create `UserSettingsService` in `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/UserSettingsService.java` (constructor injection). It provides:
  - `getSettings(User)`: build `UserSettingsView` from `findByUserId`. Each registry key gets `registry.effectiveValue`. `customized` = stored keys that are known **and** valid. Rows with unknown keys are skipped.
  - `@Transactional updateSettings(User, Map<String,Object> patch)`: an empty map → `ResponseStatusException(400)`. Validate **all** entries first (an unknown key or a parse failure → 400 naming the key), then upsert each with `updated_at = OffsetDateTime.now()`. Return `getSettings`.
- [X] T021 [US1] Create `UserSettingsController` (`@RestController @RequestMapping("/api/v1/users/{userId}")`) in `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/api/UserSettingsController.java`:
  - `GET /settings` and `PATCH /settings` (body `Map<String,Object>`), both calling `currentUserGuard.requireUser(userId)` first.
  - Check that `GlobalExceptionHandler` turns `ResponseStatusException` into the right 400/404 status. T015 should now pass.
- [X] T022 [P] [US1] Create the API client `ui-personal-routine-manager/src/features/settings/api/userSettings.ts`:
  - `fetchUserSettings(userId)` → GET `/api/v1/users/${userId}/settings`, mapped with `themeFromApi` + `normalizeSettings`.
  - `saveUserSettings(userId, partial, { keepalive? })` → PATCH with `themeToApi` on `theme`. `keepalive` is passed through to `fetch` (`apiRequest` spreads its init options into `fetch`; check this), so a save sent while the page is unloading still goes out.
  - Both use `apiRequest` from `src/lib/api.ts` with the **same path convention as** `src/features/palette/api/taskPalette.ts` (check the URL this produces in dev before relying on it).
- [X] T023 [US1] Refactor `ui-personal-routine-manager/src/theme/themePreference.ts` so T016 passes:
  - `ThemePreference` becomes `'light' | 'dark' | 'system'` (re-export the type from `features/settings/types/settings.ts`, or define it here and import it there; one definition only).
  - `readThemePreference` returns `'system'` when the value is absent or invalid, and `writeThemePreference('system')` removes the key.
  - Add `MIGRATED_KEY = 'milos.theme.migrated'`, `readMigratedFlag`, `writeMigratedFlag` and `shouldMigrateDeviceTheme`.
  - Replace the header comment "kept per device and never on the server" with "device cache of the account theme (specs/F006 research R3)".
  - Leave `index.html`'s boot script unchanged; the encoding stays compatible.
- [X] T024 [US1] Refactor `ui-personal-routine-manager/src/theme/useTheme.ts`:
  - Snapshot becomes `{ theme, preference }` with the 3-way preference. Follow the OS live only while `preference === 'system'`.
  - Exports: `setThemePreference(pref)` (apply + cache + call the registered remote-sync fn), `applyThemeFromAccount(pref)` (apply + cache, no remote call) and `setThemeRemoteSync(fn | null)`.
  - `useTheme()` returns `{ theme, preference, setPreference }`.
  - Remove `toggleTheme`.
- [X] T025 [US1] Create the settings store `ui-personal-routine-manager/src/features/settings/hooks/useUserSettings.ts`. It is a module-level store using `useSyncExternalStore`, like `useTheme.ts`. State: `{ status: 'idle'|'loading'|'ready'|'error', userId, boardZoom, customized }`. Exports:
  - `loadUserSettings(userId)`, in this exact order:
    1. Set `userId` and status `loading`. **Register remote sync right away** with `setThemeRemoteSync(theme => save({ theme }))`, so changes made during loading are saved (U1). Keep a `touchedWhileLoading` set: any `setThemePreference` or `setBoardZoom` call while status is `loading` adds its key. Theme changes go through the theme store, so the settings store only sees them through this callback. Make the remote-save callback itself do `if (status === 'loading') touchedWhileLoading.add('theme')` before saving (U6).
    2. **Before anything is applied**, take a snapshot: `deviceTheme = readThemePreference(storage)` and `migrated = readMigratedFlag(storage)`. Applying the account theme overwrites the cache (I1).
    3. GET. If the user signed out or changed in the meantime, ignore the result.
    4. On success, for each key **not** in `touchedWhileLoading`: theme → `applyThemeFromAccount(settings.theme)`, zoom → set. Store `customized`.
    5. If `!touchedWhileLoading.has('theme') && shouldMigrateDeviceTheme(deviceTheme, migrated, customized)`, call `setThemePreference(deviceTheme)`, which applies and saves it.
    6. Call `writeMigratedFlag` in every success case. Status `ready`, then clear `touchedWhileLoading`.
    7. On GET failure: status `error`, keep the cache theme and whatever zoom is current (1.0 unless the user changed it), keep remote sync registered, **no notice**, and don't set the migrated flag, so the copy is retried next time.
  - `resetUserSettings()`: first **flush** any pending debounced zoom save immediately (U2). Then clear the user, zoom 1.0, `setThemeRemoteSync(null)`; keep the theme cache.
  - A `pagehide` listener (added once) flushes a pending zoom save immediately, sending the PATCH with `keepalive: true`. Add a `keepalive` option to `saveUserSettings` in T022 that is passed through to `apiRequest`/`fetch`.
  - `setBoardZoom(z)`: `normalizeZoom`, apply at once, and save after a 500 ms debounce (send only the last value).
  - Save failure → `notifySettingsSaveFailed()` (from T027).
  - `useUserSettings()` and `useBoardZoom()` → `{ zoom, setZoom, zoomIn, zoomOut, canZoomIn, canZoomOut }` using `ZOOM_*` from `settingsSchema.ts`.

  T017 should now pass.
- [X] T026 [P] [US1] Add `MonitorIcon` (stroke `currentColor`, same props as `SunIcon`) to `ui-personal-routine-manager/src/components/icons/Icons.tsx` and export it from `ui-personal-routine-manager/src/components/icons/index.ts`.
- [X] T027 [P] [US1] Create `ui-personal-routine-manager/src/features/settings/components/SettingsSaveNotice.tsx`:
  - Exports `notifySettingsSaveFailed()`: a module-level emitter, so the store doesn't import React.
  - The component: `role="status"`, text "Couldn't save your setting — it's applied for now.", auto-hides after 5 s, dismiss button labelled "Dismiss".
  - Styles go in `ui-personal-routine-manager/src/components/layout/AppShell.css` (or `src/styles/base.css` as `.ui-notice`), using semantic tokens only.

  Add `ui-personal-routine-manager/src/features/settings/components/SettingsSaveNotice.test.tsx` (jsdom): the notice appears after `notifySettingsSaveFailed()`, hides after 5 s with fake timers, and hides on Dismiss.
- [X] T028 [US1] Create `ui-personal-routine-manager/src/components/ThemeControl.tsx`, replacing `ThemeToggle.tsx`:
  - `role="radiogroup"`, `aria-label="Theme"`, three `role="radio"` buttons (Light/SunIcon, Dark/MoonIcon, System/MonitorIcon) with `aria-checked` on the active **preference**.
  - Roving tabindex. ArrowLeft/ArrowRight move and select.
  - `variant: 'sidebar' | 'compact' | 'full'`. `compact` hides labels but keeps `title` and an accessible name.
  - Uses `.ui-segmented` classes from `src/styles/base.css`; add variant CSS with semantic tokens only.

  T018 should now pass.
- [X] T029 [US1] Swap `ThemeToggle` for `ThemeControl` everywhere: `ui-personal-routine-manager/src/components/layout/Sidebar.tsx` (`variant="sidebar"`), the auth header in `ui-personal-routine-manager/src/features/auth/` (`variant="compact"`), and the onboarding top bar in `ui-personal-routine-manager/src/features/onboarding/` (`variant="compact"`; find it with `grep -rn ThemeToggle ui-personal-routine-manager/src`). Then delete `ui-personal-routine-manager/src/components/ThemeToggle.tsx` and fix sidebar CSS (`.app-theme-toggle*` in `AppShell.css`) for the new control.
- [X] T030 [US1] Wire the settings into `ui-personal-routine-manager/src/app/App.tsx`:
  - Add one helper, `startUserSession(userId)`, that calls `loadUserSettings(userId)` (don't await it before routing). Call it from **both** the login success path and the silent `/auth/refresh` success path on mount (plan risk 1).
  - In the logout handler, call `await resetUserSettings()` **first**: before the `/auth/logout` request and before clearing the auth state (U5). The session is still valid then, so the pending zoom save is accepted in sit/prod. `resetUserSettings()` returns a Promise that settles once the save finishes; a failed save doesn't block logout. Then call `/auth/logout` and clear the auth state as today.
  - Display name (T1, spec FR-003): wherever `setUser` fills `name` (login, refresh, register), set `name = username || email`. Drop the `decoded.name` fallback: the username claim, or `data.user.username`, is the only source (A4). `AuthUser` keeps its current shape (`name` now always holds the display name).
  - Render `<SettingsSaveNotice />` once, outside `<Routes>`, so it covers the shell pages **and** `/onboarding`.
- [X] T031 [US1] Update `ui-personal-routine-manager/src/features/onboarding/components/EditingBoard.jsx`:
  - Remove the local `const [zoomLevel, setZoomLevel] = useState(1.0)` and the local `ZOOM_MIN/ZOOM_MAX/ZOOM_STEP`.
  - Use `const { zoom: zoomLevel, zoomIn, zoomOut, canZoomIn, canZoomOut } = useBoardZoom()` from `../../settings/hooks/useUserSettings.ts`.
  - Wire the Zoom out/in buttons and `disabled` states to these.
  - Keep `boardHeightPx` and the scroll-anchor `useLayoutEffect` unchanged, and the `ob-board-zoom-label` showing `Math.round(zoomLevel * 100)%`.
  - Check that Today, Default routine and Onboarding all show the shared value.
- [X] T032 [US1] Run `pnpm test` and `./gradlew test --tests "*UserSettingsIntegrationTest"` until both are green. Then start the backend (`SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun`) and `pnpm dev`, and run `pnpm test:e2e e2e/settings-persistence.spec.ts` until it is green.

**Checkpoint**: US1 is done and can ship as the MVP (account-saved theme and zoom), with no Profile page yet.

---

## Phase 4: User Story 2 – Open my profile from the sidebar (Priority: P2)

**Goal**: The sidebar user block opens `#/profile`, which shows name, email, "Free plan", Preferences (theme + zoom, live-synced) and Sign out.

**Independent Test**: quickstart scenarios 5–6. Click the user block, and the Profile page shows the correct details. Changing the theme or zoom there updates the sidebar control and boards with no reload. Sign out lands on `#/auth`.

**Depends on**: US1 (`ThemeControl`, `useBoardZoom`) for the Preferences section only.

### Tests for User Story 2 (write first; they must fail)

- [X] T033 [P] [US2] Add profile cases to `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/UserSettingsIntegrationTest.java`:
  - GET `/api/v1/users/{id}/profile` → 200 with `username`, `email`, `plan.code == "FREE"` and `plan.name == "Free plan"`, and **no** `passwordHash` or `defaultRoutines` fields.
  - An unknown id → 404.
  - Signed in as user A (same `SecurityContext` setup as T015(f)), requesting B's `/profile` → 403.
- [X] T034 [P] [US2] Create `ui-personal-routine-manager/src/features/profile/pages/ProfilePage.test.tsx` (jsdom). Render inside a `MemoryRouter` with a stub shell context (`onLogout` as `vi.fn`) and mock `fetchUserProfile`. Cases:
  - It shows the name, email and "Free plan".
  - It has a "Theme" radiogroup and the zoom stepper showing "100%".
  - Clicking Sign out calls `onLogout`.
  - When the profile fetch fails, it still shows the name and email from `AuthContext`, the note "Couldn't load all profile details." and "Free plan".
- [X] T035 [P] [US2] Create `ui-personal-routine-manager/src/components/layout/Sidebar.test.tsx` (jsdom, `MemoryRouter`):
  - The user block is a link named "Open profile" with `href` ending in `/profile`.
  - On `/profile` it has `aria-current="page"`.
  - With `isMobile` + `isMobileOpen`, clicking it calls `onCloseMobile`.
  - With `isCollapsed` (desktop rail), a link named "Open profile" still exists, shows the avatar initial and goes to `/profile` (U3, FR-001, SC-004).
  - The display name shown is `username`, falling back to email (T1).
- [X] T036 [P] [US2] Create the E2E spec `ui-personal-routine-manager/e2e/profile.spec.ts` (quickstart 5):
  - `registerAndOnboard`, click "Open profile", and expect the URL hash `#/profile`, the email shown and "Free plan".
  - Choose Light and press Zoom in once (→ 125%). Expect `html[data-theme="light"]`, the sidebar Light radio checked, and `#/today` showing "125%".
  - Go back to Profile, click Sign out, and expect the URL hash `#/auth`.

### Implementation for User Story 2

- [X] T037 [P] [US2] Create the DTO record `UserProfileView(UUID id, String username, String email, Plan plan)` with a nested `record Plan(String code, String name)` and the constant `Plan.FREE = new Plan("FREE", "Free plan")` in `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/dto/UserProfileView.java`.
- [X] T038 [US2] Add `GET /profile` to `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/api/UserSettingsController.java`. It calls `currentUserGuard.requireUser(userId)` and returns `new UserProfileView(user.getId(), user.getUsername(), user.getEmail(), Plan.FREE)`. T033 should now pass.
- [X] T039 [P] [US2] Create the profile types `ui-personal-routine-manager/src/features/profile/types/profile.ts` (`UserProfile = { id: string; username: string; email: string; plan: { code: string; name: string } }`) and the client `ui-personal-routine-manager/src/features/profile/api/profile.ts`. The client's `fetchUserProfile(userId)` sends GET `/api/v1/users/${userId}/profile` via `apiRequest`, using the same path convention as T022.
- [X] T040 [US2] Create `ui-personal-routine-manager/src/features/profile/pages/ProfilePage.tsx` (layout per `contracts/ui-profile-settings.md`):
  - `<PageHeader title="Profile" />`.
  - Account card: avatar initial, Name (`profile.username || profile.email`, falling back to the `AuthContext` value; spec FR-003), Email.
  - Plan card: `plan.name`, falling back to "Free plan".
  - Preferences card: "Theme" `<ThemeControl variant="full" />`, and "Board zoom" with − / value% / + from `useBoardZoom()`, its buttons labelled "Zoom out"/"Zoom in".
  - A Sign out button calling `onLogout` from `useShellContext()`.
  - Loading placeholders that don't shift the layout, and the failure note.
  - Use `.ui-card`/`.ui-btn` and semantic tokens. Page CSS goes in `ui-personal-routine-manager/src/App.css` with a `.pf-` prefix.

  T034 should now pass.
- [X] T041 [US2] Add the route `<Route path="/profile" element={<ProfilePage />} />` as a shell child next to `/today`, `/default-routine` and `/analytics` in `ui-personal-routine-manager/src/app/App.tsx`. Don't add it to `NAV_ENTRIES`.
- [X] T042 [US2] In `ui-personal-routine-manager/src/components/layout/Sidebar.tsx`, turn the `.app-user` `<div>` into `<NavLink to="/profile" className="app-user" aria-label="Open profile" onClick={isMobile ? onCloseMobile : undefined}>`, keeping the avatar, name and sub-label. Add focus-visible and `.active` styles in `ui-personal-routine-manager/src/components/layout/AppShell.css` with the same tokens as `.app-nav-link.active`.
  - In the collapsed-rail branch (`isCollapsed && !isMobile`), add below the "Show sidebar" button a `<NavLink to="/profile" className="app-rail-user" aria-label="Open profile">` holding the `.app-user-avatar` initial, with the same active style.
  - Keep `displayName = user?.name || user?.email || 'You'`. After T030, `name` always holds `username || email`, so `AuthUser` stays unchanged (T1, A4).

  T035 should now pass.
- [X] T043 [US2] Run `pnpm test`, `./gradlew test --tests "*UserSettingsIntegrationTest"` and `pnpm test:e2e e2e/profile.spec.ts` until all are green. Then check phone width (390 px) by hand, per quickstart scenario 6.

**Checkpoint**: US1 + US2 both work. The Profile page is live and its Preferences stay in sync with the rest of the app.

---

## Phase 5: User Story 3 – Settings store ready for new preferences (Priority: P3)

**Goal**: Prove that adding a preference needs only a registry entry on each side. Unknown stored keys and invalid stored values never break loading.

**Independent Test**: quickstart, automated checks row 1. Integration tests with a corrupt row and an unknown-key row still load correctly. The frontend `normalizeSettings` ignores unknown keys and defaults missing ones.

### Tests for User Story 3 (write first; they must fail)

- [X] T044 [P] [US3] Add to `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/UserSettingsIntegrationTest.java`:
  - (a) Insert a row `("fontSize","14")` directly through `UserSettingRepository`. GET → 200, `settings` has no `fontSize`, and `customized` doesn't list it.
  - (b) Insert a row `("boardZoom","banana")`. GET → `boardZoom == 1.0`, and `customized` doesn't list `boardZoom`.
  - (c) Then a valid PATCH `{"boardZoom":2.0}` overwrites the corrupt row → 2.0.
  - (d) A unit test of `UserSettingsRegistry` with a test-only `SettingDefinition` added (construct the registry with an extra definition) shows it appears in `getSettings` with its default and doesn't change `theme`/`boardZoom`.
- [X] T045 [P] [US3] Extend `ui-personal-routine-manager/src/features/settings/utils/settingsSchema.test.ts`:
  - `normalizeSettings({ theme: 'DARK', boardZoom: 1.5, fontSize: 14 })` → no `fontSize`.
  - `normalizeSettings({})` → `DEFAULT_SETTINGS`.
  - `normalizeSettings({ boardZoom: 'banana' })` → zoom 1.0.

### Implementation for User Story 3

- [X] T046 [US3] If T044(d) needs it, change `UserSettingsRegistry` in `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/UserSettingsRegistry.java` to build from a `List<SettingDefinition>`, with a package-visible constructor for tests and the default bean using the two built-in definitions. Add Javadoc on "How to add a preference": add a definition here plus an entry in `ui-personal-routine-manager/src/features/settings/utils/settingsSchema.ts`, with no DDL.
- [X] T047 [US3] Make sure `normalizeSettings` and the `DEFAULT_SETTINGS` shape in `ui-personal-routine-manager/src/features/settings/utils/settingsSchema.ts` are driven by one per-key definitions table (`{ default, normalize }`), so adding a key means one entry. T045 should now pass.

**Checkpoint**: All three stories work independently.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T048 [P] Update `ui-personal-routine-manager/CLAUDE.md`:
  - Commands: add `pnpm test:e2e` with its prerequisites. Replace "Tests cover pure logic only (no DOM setup)" with the three-layer testing description (research R9).
  - Route table: add `/profile`.
  - Styling/theme section: account-saved theme (`light`/`dark`/`system`), the device cache plus `milos.theme.migrated`, `ThemeControl` replacing `ThemeToggle`.
  - Shared board zoom via `useBoardZoom()` (spec F006).
- [X] T049 [P] Update `ms-personal-routine-manager/CLAUDE.md`:
  - Endpoint table row: `/api/v1/users/{userId}/settings|profile` → `UserSettingsController`.
  - Domain model bullet for `UserSetting` + registry (add a preference = a registry entry, no DDL).
  - Schema note: `db/F006-user-settings.sql` must be applied before deploy.
- [X] T050 [P] Update the workspace `CLAUDE.md` "API contract" paragraph if needed. Run `pnpm lint` and `pnpm build` in `ui-personal-routine-manager/`, and make sure `src/styles/noRawColors.test.ts` and `src/styles/contrast.test.ts` still pass.
- [X] T051 Run `./gradlew test` (full suite) in `ms-personal-routine-manager/` and `pnpm test && pnpm test:e2e` in `ui-personal-routine-manager/`. Then walk through the manual scenarios 4, 6, 7, 8, 9 and 10 in `specs/F006-user-profile-configuration-store/quickstart.md` and note the results in that file.
- [X] T052 Update the `## Claude Working Notes` status in `specs/F006-user-profile-configuration-store/F006-user-profile-configuration-store.md` to "Implemented". Note the deploy step: "apply `db/F006-user-settings.sql` to prod before the backend image".

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: depends on Setup. Blocks all stories.
- **US1 (Phase 3)**: depends on Foundational. This is the MVP.
- **US2 (Phase 4)**:
  - The backend (T033, T037, T038) and the profile client (T039) depend only on Foundational.
  - The Preferences section in `ProfilePage` (T040) needs `ThemeControl` (T028) and `useBoardZoom` (T025) from US1.
- **US3 (Phase 5)**: depends on Foundational and on T020 (service). It is independent of US2.
- **Polish (Phase 6)**: after the stories you want to ship.

### Within US1

T015–T019 (tests) → T020 → T021 (backend). In parallel: T022 → T023 → T024 → T025 (needs T027's `notifySettingsSaveFailed`) → T028 (needs T026) → T029, T030, T031 → T032.

### Parallel Opportunities

- Setup: T003, T004, T005 and T006 together after T001/T002.
- Foundational: T008, T009, T010, T011 (backend) alongside T012 and T013 (frontend). Then T014.
- US1 tests: T015, T016, T017, T018 and T019 all together (different files).
- US1 implementation: backend T020–T021 alongside frontend T022, T026 and T027.
- US2: T033, T034, T035, T036, T037 and T039 together. The backend T038 can run as soon as T037 is done, even before US1 is finished.
- US3: T044 and T045 together.
- Polish: T048, T049 and T050 together.

### Parallel example: User Story 1

```text
# Tests at once:
T015 UserSettingsIntegrationTest.java     T016 themePreference.test.ts
T017 useUserSettings.test.ts              T018 ThemeControl.test.tsx
T019 e2e/settings-persistence.spec.ts
# Then backend and frontend side by side:
T020→T021 (Java service + controller)   ||   T022, T026, T027 (TS client, icon, notice)
```

## Implementation Strategy

### MVP first (US1 only)

1. Phase 1 → Phase 2 → Phase 3.
2. **Stop and validate**: quickstart 1–4 and 7–9. Settings now survive reloads and follow the user to other devices, which fixes the ticket's core problem.
3. Deploy: apply `db/F006-user-settings.sql` to prod **first**, then the backend image, then the frontend.

### Incremental delivery

1. MVP (US1) → deploy.
2. Add US2 (Profile page) → test → deploy.
3. Add US3 (extensibility hardening) → test → deploy.
4. Polish (docs, full regression).

## Notes

- `[P]` = different files with no dependency on an incomplete task.
- Write the tests in each story first and confirm they fail.
- Never use a raw colour outside `tokens.css` (`noRawColors.test.ts` fails on one).
- Don't edit `milos.github.io/`. Don't change `index.html`'s theme boot script (research R3).
- Commit after each task or logical group, and only when the user asks.
