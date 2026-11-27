# Bugfix: Refresh token expires after 15 minutes instead of 7 days

**Bugfix Branch**: `bug-0003-fix-refresh-token-lifetime`
**Created**: 2026-11-26
**Status**: Fixed
**Affected project(s)**: ms-personal-routine-manager
**Input**: Bug report: AI-project-docs/bugs/bug-0003.MD

## 1. Report

**Expected**: refresh token (stored expiry) and cookie both last `jwt.refresh.expiration` (7 days).

**Actual**: stored expiry used the access lifetime (900 s), so `POST /api/v1/auth/refresh` returned 401 "Your session has expired" after 15 minutes.

**Environment**: component tests (H2, controllable clock).

**Severity**: Medium (users are signed out after 15 minutes).

## 2. Reproduction

Log in, advance the clock 16 minutes, `POST /api/v1/auth/refresh` with the cookie.

**Reproduced?**: Yes, every time (401 instead of 200), via the regression test below.

## 3. Investigation

| # | Hypothesis | How tested | Result |
|---|------------|------------|--------|
| H1 | `login` computes expiry from the wrong property | Read `AuthenticationService.login` | Confirmed: `plusSeconds(accessTokenExpiration)`; `refreshTokenExpiration` unused |
| H2 | Cookie Max-Age is also wrong | Read `AuthenticationController` | Ruled out: `REFRESH_TOKEN_MAX_AGE = 604800` |

## 4. Root Cause

**Location**: `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/AuthenticationService.java` (`login`)

**Cause**: wrong property used for the refresh token expiry (stored row and JWT `exp`).

**Introduced by**: unknown (noted by F008 T058).

**Blast radius**: only `login`; `refresh` checks the stored expiry.

## 5. Regression Test

**Test kind**: Backend component (user flow)

**Test**: `SignInComponentTest#refreshStillWorksAfterTheAccessTokenLifetimeButNotAfterSevenDays` (also `#refreshCookieLastsSevenDays`, guards the cookie, passed before the fix)

**Command**: `./gradlew test --tests '*SignInComponentTest'`

**Failed before fix**: Yes: `Status expected:<200> but was:<401>` after advancing 16 minutes.

## 6. Fix

**Change summary**: `login` uses `refreshTokenExpiration`; removed the NOTE comment.

**Files changed**:

- `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/AuthenticationService.java`
- `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/component/SignInComponentTest.java`: 2 new tests
- `ms-personal-routine-manager/CLAUDE.md`: removed bug-0003 from Open bugs
- `AI-project-docs/bugs/bug-0003.MD` renamed to `.done.bug-0003.MD`

**Alternatives rejected**: none; the controller cookie was already 7 days.

## 7. Verification

- [x] Regression test passes (`SignInComponentTest`, 14/14)
- [x] `./gradlew test`: 241 tests, 0 failures, 2 skipped
- [x] `./gradlew build`: successful
- [x] Original reproduction: 200 after 16 min, 401 after 7 days
- [x] API contract unchanged

**Follow-ups**: bug-0004 (logout does not revoke the stored token) remains open.
