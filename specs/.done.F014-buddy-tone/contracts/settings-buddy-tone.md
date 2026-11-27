# Contract: `buddyTone` account setting (F014)

This adds a key to the F006 settings API (`specs/.done.F006-user-profile-configuration-store/contracts/settings-api.md`). Paths, auth, owner checks (404/403/401) and the `ApiError` body are unchanged.

## GET `/api/v1/users/{userId}/settings`

`settings` gains `buddyTone`. It is `"BALANCED"` when nothing is stored or the stored value is invalid. `customized` lists `"buddyTone"` once the user has saved one.

```json
{ "settings": { "theme": "SYSTEM", "boardZoom": 1.0, "buddyTone": "BALANCED" }, "customized": [] }
```

## PATCH `/api/v1/users/{userId}/settings`

```json
{ "buddyTone": "warm_anchor" }
```

- 200 + the settings view, with `buddyTone` = `"WARM_ANCHOR"` (input is case-insensitive and trimmed; it is stored upper-case).
- 400 `buddyTone must be one of BALANCED, CHIEF_OF_STAFF, STOIC, SOCRATIC_PEER, WARM_ANCHOR, ACCOUNTABILITY_COACH` for an unknown value or a non-string. Nothing is written (the F006 rule: one bad key spoils the whole PATCH).

**Backward compatible**: older frontends ignore the extra key, because `normalizeSettings` keeps known keys only.
