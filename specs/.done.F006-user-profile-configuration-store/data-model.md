# Data Model: User Profile & Configuration Store (F006)

## 1. `user_setting` (new table / JPA entity `UserSetting`)

| Column | Type | Rules |
|---|---|---|
| `user_id` | UUID, FK → `users.id`, `ON DELETE CASCADE` | part of PK |
| `setting_key` | VARCHAR(64) | part of PK; one of the registry keys when written |
| `setting_value` | VARCHAR(255) NOT NULL | canonical string form (see registry) |
| `updated_at` | TIMESTAMP WITH TIME ZONE NOT NULL | set on every upsert |

- Primary key `(user_id, setting_key)`: each user has at most one value per key.
- No row = default value. A brand-new user has **no rows** (FR-017). Nothing is created at registration.
- Rows with unknown keys are left in place but ignored on read (FR-016, US3-2).
- DDL: `ms-personal-routine-manager/db/F006-user-settings.sql` (idempotent `CREATE TABLE IF NOT EXISTS`). It must be applied to prod **before** the image deploys (prod `ddl-auto: validate`).
- JPA: `@IdClass` or `@EmbeddedId` (`userId`, `settingKey`). Repository: `findByUserId(UUID)` and upsert via `save`.

## 2. Settings registry (code, not a table)

`UserSettingsRegistry` (backend) / `settingsSchema.ts` (frontend mirror) define every known key:

| Key (API) | Stored as | Allowed values | Default | Notes |
|---|---|---|---|---|
| `theme` | `LIGHT` / `DARK` / `SYSTEM` | exactly these (case-insensitive on input, stored upper-case) | `SYSTEM` | SYSTEM = follow the OS (FR-008) |
| `boardZoom` | decimal string, e.g. `1.25` | 0.5 ≤ v ≤ 3.0 and v is a multiple of 0.25 | `1.0` | Shared by Today, Default routine, Onboarding boards (FR-010) |

Validation on write: an unknown key → 400; a value outside the allowed set or range → 400. The whole PATCH is rejected and nothing is written. On read, the server checks each stored value again, and an invalid one falls back to the default, so a corrupt row can't break loading.

**Adding a preference later**: add one registry entry on the backend and one in the frontend schema, with no DDL (FR-016).

## 3. Effective settings (API view, not stored)

```
UserSettingsView {
  settings:   { theme: "LIGHT"|"DARK"|"SYSTEM", boardZoom: number }   // defaults merged in
  customized: string[]                                               // keys the user saved, e.g. ["boardZoom"]
}
```

## 4. Profile (API view, not stored)

```
UserProfileView {
  id: UUID, username: string, email: string,
  plan: { code: "FREE", name: "Free plan" }   // constant in F006; nothing stored
}
```

## 5. Frontend state

| Store | Where | Contents | Lifetime |
|---|---|---|---|
| Theme store | `src/theme/useTheme.ts` (module-level) | `preference: 'light'|'dark'|'system'`, `theme: 'light'|'dark'` (resolved) | page lifetime |
| Device theme cache | `localStorage["milos.theme"]` | `light` / `dark`, absent = system | device; never cleared on sign-out |
| Migration flag | `localStorage["milos.theme.migrated"]` | `"1"` once the device has done its one-time copy decision | device |
| Settings store | `src/features/settings/hooks/useUserSettings.ts` (module-level) | `{ status: 'idle'|'loading'|'ready'|'error', boardZoom, customized, userId }` | set on sign-in / refresh, reset on sign-out |
| Save notice | `SettingsSaveNotice` state | visible flag | ~5 s per failure |

### State transitions: settings store

```
idle ──sign-in/refresh ok──▶ loading ──GET ok──▶ ready ──(theme from server applied, cache written,
  ▲                                     │                   one-time migration check)
  │                                     └─GET fails─▶ error (cache theme + current zoom; app usable; no notice; migrated flag not set)
  └──── sign-out (pending zoom save sent first, before /auth/logout; then zoom 1.0, userId cleared; theme cache kept) ◀── ready / error
```

- `ready`/`error` + user change → apply locally right away → PATCH (theme: immediately; zoom: debounced 500 ms) → on failure, show the notice and keep the local value.
- In `error`, changes still try to PATCH, so a recovered server saves them.
- In `loading`, remote save is already registered. A theme or zoom change made then is saved, and the GET result doesn't overwrite it (`touchedWhileLoading`).
- On sign-out or `pagehide`, a pending zoom save is sent at once (on `pagehide` with `keepalive: true`).
