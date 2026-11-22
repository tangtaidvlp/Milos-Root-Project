# Contract: Settings & Profile API (F006)

Base: `/api/v1/users/{userId}`. Controller: `UserSettingsController` (backend `api` package).
Guard: `CurrentUserGuard.requireUser(userId)` on every call. An unknown user gets **404**, and in sit/prod (JWT) a caller who isn't `{userId}` gets **403** (FR-012). The local/fast profiles only check that the user exists.

## GET `/settings`

The user's effective settings: the stored values, with defaults filled in for keys they haven't saved.

**200**
```json
{
  "settings": { "theme": "SYSTEM", "boardZoom": 1.0 },
  "customized": []
}
```
- `settings` always contains **every** registry key.
- `customized` lists the keys that have a stored row. Order isn't defined.
- Stored rows with unknown keys or invalid values are ignored. They don't cause an error and aren't listed in `customized`.

## PATCH `/settings`

Saves one or more settings. Keys left out of the body are unchanged.

**Request**
```json
{ "theme": "DARK" }
```
```json
{ "boardZoom": 1.5 }
```

**200**: the same body as GET, after the update.

**400** (nothing is written), for any of:
- an empty body `{}`
- an unknown key, e.g. `{ "fontSize": 14 }`
- `theme` that isn't LIGHT/DARK/SYSTEM (case-insensitive)
- `boardZoom` that isn't a number, is outside 0.5–3.0, or isn't a multiple of 0.25

Error body: the existing `GlobalExceptionHandler` shape, with a message naming the bad key.

Writes upsert per key and set `updated_at`. If two devices write the same key, the last one wins.

## GET `/profile`

**200**
```json
{
  "id": "6f1c…",
  "username": "Tom",
  "email": "tom@example.com",
  "plan": { "code": "FREE", "name": "Free plan" }
}
```
- `plan` is a constant in F006 (spec FR-004). The shape leaves room for real plans later.
- The password hash and routines are **never** included.
- **Display name** (spec FR-003): the UI shows `username`, falling back to `email` when `username` is empty. The sidebar user block uses the same rule.

## Frontend client (`ui-personal-routine-manager/src/features/settings/api/userSettings.ts`, `features/profile/api/profile.ts`)

| Function | Call |
|---|---|
| `fetchUserSettings(userId)` | GET `/settings` → `UserSettingsView`, values passed through `normalizeSettings()` |
| `saveUserSettings(userId, partial, { keepalive? })` | PATCH `/settings` → `UserSettingsView`; `keepalive` is used when a pending save is sent while the page unloads |
| `fetchUserProfile(userId)` | GET `/profile` → `UserProfile` |

Use `apiRequest` from `src/lib/api.ts`, following the same path convention as `features/palette/api/taskPalette.ts`.

Map the theme between the API and the frontend like this: `LIGHT` ⇄ `'light'`, `DARK` ⇄ `'dark'`, `SYSTEM` ⇄ `'system'`.
