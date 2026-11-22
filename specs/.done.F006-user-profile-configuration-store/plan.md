# Implementation Plan: User Profile & Configuration Store

**Branch**: `F006-user-profile-configuration-store` | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F006-user-profile-configuration-store/spec.md`

## Summary

Save each user's UI settings on their account, so they survive reloads and follow the user to other devices. The settings are theme (Light / Dark / System) and one board zoom shared by all boards. Also add a Profile page, opened from the sidebar user block, with account info, a fixed "Free plan", Preferences and Sign out.

- **Backend**: a key/value `user_setting` table, driven by a code registry of known keys with their defaults and validation, so future settings need no DDL. Three endpoints, all guarded by `CurrentUserGuard`:
  - `GET` / `PATCH /api/v1/users/{userId}/settings`
  - `GET /api/v1/users/{userId}/profile`
- **Frontend**:
  - A settings store loaded on sign-in. It drives the existing theme store, which gains a third value, `system`, and a new shared `useBoardZoom()`.
  - `ThemeToggle` becomes a 3-way `ThemeControl`.
  - New `/profile` page.
  - A one-time copy of a pre-F006 device theme.
  - A save-failure notice.
- **Testing**: adds React component tests (Testing Library + jsdom) and headless Playwright E2E for reload and second-device persistence.

## Technical Context

**Language/Version**: Backend Java 25 / Spring Boot 4.1. Frontend TypeScript ~6.0, React 19.2.

**Primary Dependencies**:
- Existing: Spring Web/Security/Data JPA, Lombok, React Router 7, Vite 8.
- New dev-only frontend dependencies: `@testing-library/react`, `@testing-library/user-event`, `jsdom`, `@playwright/test`. Pin exact current-stable versions at install time.

**Storage**: PostgreSQL 17 (prod/local), H2 (fast/test). New table `user_setting`, with hand-applied DDL `db/F006-user-settings.sql`. Device: `localStorage` keys `milos.theme` (existing cache) and `milos.theme.migrated` (new).

**Testing**:
- JUnit 5 + MockMvc (`UserSettingsIntegrationTest`).
- Vitest, for logic (`*.test.ts`, node) and components (`*.test.tsx`, jsdom per file).
- Playwright headless Chromium (`pnpm test:e2e`).

**Target Platform**: Modern desktop and mobile browsers. Backend on EC2 behind Nginx.

**Project Type**: Web application (separate backend + frontend repos in one workspace).

**Performance Goals**:
- Settings arrive within ~1 s of sign-in on a normal connection.
- Theme and zoom changes apply on screen within one frame, without waiting for the network.

**Constraints**:
- No visible theme flash on reload (SC-003). The existing boot script in `index.html` stays unchanged.
- Prod runs `ddl-auto: validate`, so the DDL must be applied before deploy.
- Only semantic style tokens (`noRawColors.test.ts`).
- The app stays usable when the settings service is down (SC-005).

**Scale/Scope**:
- Two settings keys, about one row per key per user.
- One new page, one control replaced, one board change.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the **unfilled template**, so there are no ratified principles and no gates to fail. Instead the plan follows the binding repo rules in `CLAUDE.md` and `codingrules.md`:

| Rule | Plan complies |
|---|---|
| Feature-based folders (`features/<name>/{api,components,pages,types,hooks,utils}`) | ✅ `features/settings/`, `features/profile/` |
| API calls through `src/lib/api.ts` | ✅ |
| Semantic tokens only; contrast in both themes | ✅ No new raw colors. `MonitorIcon` uses `currentColor` |
| New code is `.tsx` / `.ts`; `import type` | ✅ (`EditingBoard.jsx` is only edited, not converted) |
| Backend: constructor injection, `@Transactional` writes, UUID ids, DDL script under `db/` | ✅ |
| Don't hand-edit `milos.github.io/` | ✅ |

Post-design re-check: still passes, and no violations need justifying.

## Project Structure

### Documentation (this feature)

```text
specs/F006-user-profile-configuration-store/
├── F006-user-profile-configuration-store.md   # ticket
├── spec.md
├── plan.md              # this file
├── research.md          # R1–R9 decisions
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── settings-api.md
│   └── ui-profile-settings.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks (not created here)
```

### Source Code

```text
ms-personal-routine-manager/
├── db/F006-user-settings.sql                       # NEW: CREATE TABLE IF NOT EXISTS user_setting
└── src/
    ├── main/java/com/tom/payment/routinemanager/
    │   ├── api/UserSettingsController.java          # NEW: GET/PATCH settings, GET profile
    │   ├── dto/UserSettingsView.java, UserProfileView.java   # NEW
    │   ├── model/UserSetting.java (+ UserSettingId)  # NEW
    │   ├── repository/UserSettingRepository.java     # NEW
    │   └── service/UserSettingsService.java, UserSettingsRegistry.java   # NEW
    └── test/java/com/tom/payment/routinemanager/UserSettingsIntegrationTest.java   # NEW

ui-personal-routine-manager/
├── e2e/                                             # NEW: Playwright specs + helpers
│   └── settings-persistence.spec.ts
├── playwright.config.ts                             # NEW (headless chromium, baseURL dev server)
├── package.json                                     # + test:e2e script, dev deps
├── tsconfig.test.json                               # include *.test.tsx, e2e/
└── src/
    ├── app/App.tsx                                  # /profile route; load settings on sign-in/refresh; reset on sign-out; <SettingsSaveNotice/>
    ├── theme/themePreference.ts (+ .test.ts)        # 'system' value; cache encoding; shouldMigrateDeviceTheme()
    ├── theme/useTheme.ts                            # setThemePreference / applyThemeFromAccount / setThemeRemoteSync
    ├── components/ThemeControl.tsx (+ .test.tsx)    # NEW: replaces ThemeToggle.tsx (deleted)
    ├── components/icons/                            # + MonitorIcon
    ├── components/layout/Sidebar.tsx (+ .test.tsx)  # user block → NavLink /profile
    ├── features/settings/
    │   ├── api/userSettings.ts
    │   ├── types/settings.ts
    │   ├── utils/settingsSchema.ts (+ .test.ts)     # defaults, normalizeZoom, theme mapping, ZOOM_* constants
    │   ├── hooks/useUserSettings.ts                 # module store: load, save (debounced zoom), reset; useBoardZoom()
    │   └── components/SettingsSaveNotice.tsx (+ .test.tsx)
    ├── features/profile/
    │   ├── api/profile.ts
    │   ├── types/profile.ts
    │   └── pages/ProfilePage.tsx (+ .test.tsx)
    └── features/onboarding/components/EditingBoard.jsx   # zoom from useBoardZoom()
```

**Structure Decision**: Use the existing two-repo web-app layout. New frontend code goes in two new feature folders: `settings` (shared store, used by the theme and board code) and `profile` (the page). Backend code goes in the existing layered packages.

## Implementation notes (ordering hints for /speckit-tasks)

1. **Backend first**: DDL → entity/repo → registry + service → controller → integration test. The frontend can be built against the contract in parallel.
2. **Theme store refactor** (`system` value, `setThemePreference`, remote-sync hook), then swap `ThemeToggle` → `ThemeControl` in its three places: sidebar, `AuthPage` header, onboarding top bar.
3. **Settings store + App wiring**: load after the login and silent-refresh success paths in `App.tsx`. Apply the theme via `applyThemeFromAccount` and run the one-time migration (research R4). Reset on logout.
4. **Shared zoom** in `EditingBoard` (keep the scroll-anchor effect intact; it keys on `boardHeightPx`).
5. **Profile page + sidebar link + route**.
6. **Tests**: unit → component → E2E. Then update docs: the backend `CLAUDE.md` (endpoint table, F006 DDL note) and the frontend `CLAUDE.md` (route table, testing line, theme section: the per-device text is now "device cache + account"; the F005 comment in `themePreference.ts` saying "never on the server" must change).

### Risks

- **Two sign-in paths** (login and the silent `/auth/refresh` on mount) both have to trigger the settings load. Use one helper called from both.
- The onboarding page sits outside `AppShell`, so the notice and settings load must live at the App level, not in the shell.
- `apiRequest` path prefixing: follow the exact convention of `features/palette/api/taskPalette.ts`, so dev proxy and prod URLs both work.

## Complexity Tracking

No constitution violations to justify.
