# Bugfix: Frontend never sends the access token

**Bugfix Branch**: `B008-fix-frontend-never-sends-the-access-token`
**Created**: 2026-11-26
**Status**: Fixed
**Affected project(s)**: ui-personal-routine-manager
**Input**: Bug report: AI-project-docs/bugs/B008.MD

## 1. Report

**Expected**: every API request after sign-in carries `Authorization: Bearer <accessToken>`; token set on login/refresh, cleared on logout.

**Actual**: no request carries the token. With auth on (`sit`/`test`/`prod`) every call after sign-in returns 401. With `local`/`fast` auth is off, so the bug is hidden.

**Environment**: backend profile `sit` on :8081, Vite on :5174, Chromium.

**Severity**: Critical (security / app unusable with auth on).

## 2. Reproduction

1. Backend `SPRING_PROFILES_ACTIVE=sit`, frontend with `VITE_API_BASE_URL=http://localhost:8081`.
2. Register and sign in (Playwright script logging requests).

**Reproduced?**: Yes, every time. `POST /auth/login` 200, then `GET /api/v1/users/<id>/settings` (auth=NONE) 401 and `GET /api/users/<id>/onboarding/complete` (auth=NONE) 401. Sign-in never leaves `#/auth`; the e2e journeys (today-board, 3 of 3 run) failed at sign-in. `curl` of a protected endpoint without token: 401.

## 3. Investigation

| # | Hypothesis | How tested | Result |
|---|------------|------------|--------|
| H1 | `apiRequest` never gets a token | Read `api.ts`; grep callers for `token:` | Confirmed: header added only if caller passes `token`; no caller does |
| H2 | Backend rejects a valid token | Re-ran after fix with the header | Ruled out: 200s with the header |

## 4. Root Cause

**Location**: `ui-personal-routine-manager/src/lib/api.ts` (`apiRequest`, `if (token)`); `src/app/App.tsx` kept `accessToken` in React state that nothing read.

**Cause**: the token had no path from login/refresh to `apiRequest`.

**Introduced by**: unknown (auth wiring never completed).

**Blast radius**: every `apiRequest` caller in the app.

## 5. Regression Test

**Test kind**: Frontend unit (logic)

**Test**: `ui-personal-routine-manager/src/lib/api.test.ts`

**Command**: `pnpm exec vitest run src/lib/api.test.ts`

**Failed before fix**: Yes: `TypeError: setAccessToken is not a function` (2 of 3 failed; the no-token case passed).

## 6. Fix

**Change summary**: `api.ts` holds the token in a module variable (memory only), exports `setAccessToken`, and `apiRequest` attaches the Bearer header; an explicit `token` option still wins. `App.tsx` calls `setAccessToken` on login, silent refresh, and `setAccessToken(null)` on logout; the redundant `accessToken` state and no-op `useEffect` were removed.

**Files changed**:

- `ui-personal-routine-manager/src/lib/api.ts`
- `ui-personal-routine-manager/src/app/App.tsx`
- `ui-personal-routine-manager/src/lib/api.test.ts` (new)

**Alternatives rejected**: passing `token` at every call site (many call sites, easy to miss); localStorage (XSS exposure).

## 7. Verification

- [x] Regression test passes (3/3)
- [x] `pnpm test`: 43 files, 270 tests pass
- [x] `pnpm lint`: 0 errors (3 pre-existing warnings); `pnpm build` passes
- [x] Original reproduction: after sign-in, requests carry the Bearer header and return 200; all 15 e2e tests pass against `sit` backend
- [x] API contract unchanged

**Follow-ups**:

- No 401 -> refresh -> retry; the access token lasts 15 min (bug-0003), so a session will fail after expiry.
- Deploy profile: switch to an auth-on profile (bug-0007).
- Some calls use `/api/users/...` and `/api/ai/...` (no `v1`); they worked on `sit`, not changed here.
- Silent refresh (`setAccessToken` on page reload) not exercised by e2e: the refresh cookie was not sent by the test browser (401 on `/auth/refresh`).
- Larger auth refactor planned separately.
