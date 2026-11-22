# Quickstart: validate F006 (Profile & account settings)

## Prerequisites

1. Backend: `cd ms-personal-routine-manager && SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun` (H2, auth open), or the `local` profile with `docker compose up -d database` and `db/F006-user-settings.sql` applied.
2. Frontend: `cd ui-personal-routine-manager && pnpm install && pnpm dev`.
3. One-time install of the E2E browser: `pnpm exec playwright install chromium`.

## Automated checks

| Command | Proves |
|---|---|
| `./gradlew test --tests "*UserSettingsIntegrationTest"` | GET defaults, PATCH per key, 400 rules, unknown stored keys ignored, profile body, 404 unknown user ([contracts/settings-api.md](contracts/settings-api.md)) |
| `pnpm test` | settings schema (zoom clamping and rounding, theme mapping), one-time migration decision, theme preference with `system`, plus React component tests: ThemeControl, ProfilePage, sidebar user link, SettingsSaveNotice |
| `pnpm test:e2e` (headless, both servers running) | the scenarios below, marked **E2E** |
| `pnpm lint && pnpm build` | types, lint, `noRawColors` / contrast tests still pass |

## Scenarios

1. **E2E: Theme kept on reload (US1-1)**. Register a new user and finish onboarding. Pick **Dark** in the sidebar theme control, then reload. Expected: the page is dark on the first paint (no light flash), and the control shows Dark.
2. **E2E: Shared zoom kept (US1-2, US1-3)**. On Today, press zoom in twice (→ 150%) and reload. Today shows 150%. Open Default routine: it also shows 150%.
3. **E2E: Second device (US1-4)**. In a new browser context (empty storage), sign in as the same user. Expected: Dark theme and 150% zoom.
4. **System (US1-5, US1-6)**. Pick **System**, then switch the OS appearance. Expected: the app follows the OS live, and after a reload it is still on System. A brand-new user starts on System and 100%.
5. **E2E: Profile (US2)**. Click the avatar and name at the bottom of the sidebar. Expected: `#/profile` shows the name, email, "Free plan", Preferences and Sign out. Change the theme to Light and the zoom to 125% there, and confirm the sidebar control and the boards match without a reload. Press Sign out and you land on `/auth`.
6. **Phone (US2-4)**. At 390 px width, open the burger and tap the user block. The overlay closes and Profile opens.
7. **Save failure (FR-013)**. Stop the backend while signed in and change the theme. Expected: the theme changes, and the notice "Couldn't save your setting — it's applied for now." appears and hides after about 5 s. Restart the backend, change it again, then reload: the new value is kept.
8. **Load failure**. With the backend stopped, reload. The app uses this device's last theme and 100% zoom, shows no notice, and stays usable as far as the rest of the offline app allows.
9. **One-time device copy (FR-014)**. In a fresh browser, set `localStorage["milos.theme"]="dark"` and remove `milos.theme.migrated`. Sign in as user A, who has never chosen a theme: A's account becomes Dark. Sign out. The sign-in screen stays dark. Sign in as new user B: B gets **System**, not Dark.
10. **Visual check**. Look at the Profile page in light and dark at desktop and phone widths. Cards, the segmented control and the zoom stepper should match the shell's style.

## Validation results (2026-11-21, /speckit-implement)

| Check | Result |
|---|---|
| `./gradlew test --tests "*UserSettings*"` | ✅ 12/12 (integration 10, registry 2), incl. 403 for another user |
| `./gradlew test` (full) | ⚠️ 54/56 — the 2 failures are in `apptest/OnboardingRoutineTest` (calls `POST /api/users` and `/api/routine-manager/default-routine/...`, which no controller serves). Not related to F006. |
| `pnpm test` | ✅ 144/144 (18 files) |
| `pnpm lint`, `pnpm build` | ✅ (lint: only warnings that existed before F006) |
| `pnpm test:e2e` | ✅ 2/2 — scenarios 1, 2, 3, 5 |
| Scenarios 4, 7, 8, 9 | ✅ run as throwaway headless Playwright scripts (OS scheme emulation, PATCH/GET aborted, localStorage seeded) |
| Scenario 10 (visual) | ✅ screenshots at 1280 px and 390 px, light and dark, incl. collapsed rail. Fixed: the sidebar theme control overflowed by a few px |
| Scenario 6 (phone overlay) | ✅ by component test only (`Sidebar.test.tsx`: tapping the user block in the overlay calls close). Not tapped in a real browser yet |

**Found while testing (existing bug, not F006)**: signing in twice as the same user within one second returns 500. The refresh-token JWT has only `sub`/`iat`/`exp`, so both logins produce the same token and hit the unique index on `refresh_tokens.token_val`. The E2E specs avoid it because registration takes several seconds.
