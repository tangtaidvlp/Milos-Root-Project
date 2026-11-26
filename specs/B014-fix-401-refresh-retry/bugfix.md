# Bugfix: Requests fail with 401 after the access token expires

**Bugfix Branch**: `B014-fix-401-refresh-retry`
**Created**: 2026-11-26
**Status**: Fixed
**Affected project(s)**: ui-personal-routine-manager
**Input**: Bug report: AI-project-docs/bugs/B014.MD

## 1. Report

**Expected**: on a 401 (not from `/auth/*`) refresh the access token once and retry; parallel 401s share one refresh; if refresh fails, end the session and show sign-in.

**Actual**: after the 15-minute access token expires every call throws `ApiError(401)`; the app stays "signed in".

**Environment**: auth-on profiles (`sit`/`test`/`prod`).

**Severity**: High.

## 2. Reproduction

1. Sign in with auth on, wait past token expiry, use the app.

**Reproduced?**: Yes, by unit test (a 401 response is thrown, no refresh is attempted).

## 3. Investigation

| # | Hypothesis | How tested | Result |
|---|------------|------------|--------|
| H1 | Nothing renews the token after load | Read `api.ts`, `useAuthSession.ts` | Confirmed: `refresh()` only runs on mount; `apiRequest` throws on 401 |

## 4. Root Cause

**Location**: `ui-personal-routine-manager/src/lib/api.ts` (`apiRequest`), `src/features/auth/hooks/useAuthSession.ts`.

**Cause**: no 401 handling; silent refresh happens only on page load.

**Introduced by**: unknown (auth wiring, see B008).

**Blast radius**: every `apiRequest` caller.

## 5. Regression Test

**Test kind**: Frontend unit (logic) + hook test

**Test**: `src/lib/api.test.ts` ("401 refresh and retry (B014)", 5 cases); `src/features/auth/hooks/useAuthSession.test.ts` (handler registered, session cleared on refresh failure)

**Command**: `pnpm exec vitest run src/lib/api.test.ts src/features/auth`

**Failed before fix**: Yes: `TypeError: setUnauthorizedHandler is not a function` (6 new tests failed).

## 6. Fix

**Change summary**: `api.ts` gets `setUnauthorizedHandler`; on a non-`/auth/` 401 with a handler, one shared (single-flight) renewal runs, then the request is retried once with the new token (retry never re-renews). Handler null/throw: original `ApiError(401)` is thrown. `useAuthSession` registers a handler that calls `refresh()`; on failure it clears user, onboarding flag and token (no logout call) so routing shows sign-in. Removed the leftover `console.log` in `apiRequest`.

**Files changed**:

- `ui-personal-routine-manager/src/lib/api.ts`
- `ui-personal-routine-manager/src/features/auth/hooks/useAuthSession.ts`
- `ui-personal-routine-manager/src/lib/api.test.ts`, `src/features/auth/hooks/useAuthSession.test.ts`
- `ui-personal-routine-manager/CLAUDE.md`

**Alternatives rejected**: refresh timer (clock drift, tab sleep); importing auth code into `lib/` (breaks dependency rule).

## 7. Verification

- [x] Regression tests pass
- [x] `pnpm test`: 49 files, 323 tests pass
- [x] `pnpm lint`: 0 errors (pre-existing warnings only); `pnpm build` passes
- [x] e2e (`sit` backend :8083, Vite :5179, auth on): 15 passed
- [x] API contract unchanged
- [x] Live check with the bug-0003 fix (`sit`, `JWT_ACCESS_EXPIRATION=60`): signed in, waited 70 s, clicked "Next day" without reloading: two parallel 401s, one `POST /auth/refresh` 200, both retries 200, still signed in

**Follow-ups**: none. Ships with bug-0003 (refresh token lifetime), fixed alongside.
