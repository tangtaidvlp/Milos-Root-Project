# Contract: Profile screen, theme control, shared zoom (F006 UI)

## Route

| Route | Page | Guard |
|---|---|---|
| `/profile` | `features/profile/pages/ProfilePage.tsx` | Shell child: `RequireOnboarded` → `AppShell` (same as `/today`) |

It isn't added to `NAV_ENTRIES`. Update the route table in `ui-personal-routine-manager/CLAUDE.md`.

## Sidebar user block (FR-001, FR-006)

- `.app-user` becomes `<NavLink to="/profile" aria-label="Open profile">` and keeps its avatar initial, name and sub-label.
- Active (`aria-current="page"`) style on `/profile`, using the same tokens as `.app-nav-link.active`.
- In the phone overlay, picking it closes the overlay, as the nav links do.
- Keyboard: reachable with Tab, opened with Enter.
- **Collapsed rail** (desktop, sidebar hidden): below the "Show sidebar" button, show the avatar initial as `<NavLink to="/profile" aria-label="Open profile">`, with the same active style. The rail has no theme control.
- **Display name**: `user.username || user.email || 'You'`. `AuthUser.name` is filled from `username` at sign-in, so the sidebar and Profile always match.

## ProfilePage layout

```
<PageHeader title="Profile" />           (existing header: burger on phones, Sign out at right)
┌ Account ────────────────────────┐
│ [A] Name        Tom             │
│     Email       tom@example.com │
└─────────────────────────────────┘
┌ Plan ───────────────────────────┐
│ Free plan                       │
└─────────────────────────────────┘
┌ Preferences ────────────────────┐
│ Theme       ( Light | Dark | System )   ← ThemeControl variant="full"
│ Board zoom  [ − ]  125%  [ + ]          ← useBoardZoom(); 50–300 %, 25 % steps
└─────────────────────────────────┘
[ Sign out ]                              ← onLogout from useShellContext() (FR-005)
```

- States:
  - **loading**: card placeholders with no layout shift.
  - **profile fetch failed**: the Account card shows the name and email already known from sign-in (`AuthContext`), plus a note "Couldn't load all profile details." The Plan card still shows "Free plan" (constant).
- Styling: `.ui-card`, `.ui-segmented`, `.ui-btn` and semantic tokens only (`noRawColors.test.ts`).

## ThemeControl (replaces `components/ThemeToggle.tsx`; FR-009)

- `role="radiogroup"`, `aria-label="Theme"`, three `role="radio"` buttons: Light (SunIcon), Dark (MoonIcon), System (new `MonitorIcon`). `aria-checked` marks the active **preference** (not the resolved theme).
- Arrow Left/Right moves between options and selects. Tab enters and leaves the group.
- Variants:
  - `sidebar`: in the sidebar footer, with labels.
  - `compact`: icons only, with `title` tooltips. Used in the auth header and onboarding top bar.
  - `full`: used in Profile Preferences.
- Selecting calls `setThemePreference(pref)`, which applies at once, writes the device cache and, when signed in, PATCHes `theme`. The control must update everywhere at once (one module store).

## Theme store API (`src/theme/useTheme.ts`)

| Export | Behaviour |
|---|---|
| `useTheme()` | `{ theme, preference, setPreference }` |
| `setThemePreference(pref)` | apply, write the cache, notify the remote-sync hook if one is registered |
| `applyThemeFromAccount(pref)` | apply + write the cache, **without** a remote save (used after GET settings) |
| `setThemeRemoteSync(fn \| null)` | registered by the settings store on sign-in, cleared on sign-out |

## Board zoom (FR-010, FR-011)

- `useBoardZoom()` → `{ zoom, setZoom, zoomIn, zoomOut, canZoomIn, canZoomOut }` from the settings store.
- `EditingBoard` uses it in place of its local `zoomLevel` state. It keeps `ZOOM_MIN/MAX/STEP` (move them to `features/settings/utils/settingsSchema.ts`).
- Changes apply at once. The PATCH is debounced by 500 ms, and only the last value is sent.

## SettingsSaveNotice (FR-013)

- Rendered once in `App.tsx`, outside the routes, so it covers shell pages and Onboarding.
- `role="status"`, text "Couldn't save your setting — it's applied for now.", auto-hides after ~5 s, with a dismiss button.
- Shown only for **save** failures, never for load failures.
