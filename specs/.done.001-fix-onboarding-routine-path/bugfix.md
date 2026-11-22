
# Bugfix: Onboarding AI chat fails with NPE — default routine id is null

**Bugfix Branch**: `001-fix-onboarding-routine-path`
**Created**: 2026-11-19
**Status**: Fixed
**Affected project(s)**: ui-personal-routine-manager (root cause); ms-personal-routine-manager (symptom site)
**Input**: Bug report: "When login & create new account, at the OnboardingPage, when I ask AI then we will get the defaultRoutineId issue is null"

## 1. Report

**Expected behavior**: A newly registered user who logs in lands on the Onboarding page, sees their (empty) default routine, and can chat with Routine Buddy, which can read and edit that routine.

**Actual behavior**: Sending any chat message (e.g. "hey") returns HTTP 500. Backend log:

```
java.lang.NullPointerException: Cannot invoke "java.util.UUID.toString()" because the return value of
"com.tom.payment.routinemanager.model.DefaultRoutine.getId()" is null
    at ...GeminiAiChatService.lambda$defaultRoutineChat$0(GeminiAiChatService.java:84)
    at ...AIController.chatWithAi(AIController.java:36)
```

**Environment**: Local dev — frontend `pnpm dev` with `.env.development` (`VITE_API_BASE_URL=http://localhost:8080`), backend on `localhost:8080`. Endpoint: `POST /api/ai/chat/default-routine/{userId}`.

**Severity**: High — the core onboarding flow (AI chat, plus manual add/edit/delete of tasks) is broken for every new user.

## 2. Reproduction

**Steps**:

1. Register a new account, then log in → routed to `/onboarding`.
2. Type "hey" in Routine Buddy and send.
3. Backend logs the NPE above; the UI receives 500.

**Reproduced?**: Yes, every time.

**Smallest reproduction** (against the running backend, new user `55d3d070-…`):

```
GET  http://localhost:8080/api/v1/default-routine/users/{id}  -> 200 {"id":"aea0163c-…","name":"Default Routine",...}   (correct path)
GET  http://localhost:8080/default-routine/users/{id}         -> 404 "No static resource default-routine/users/…"  (path the UI actually calls)
POST http://localhost:8080/api/ai/chat/default-routine/{id}  body {"defaultRoutine":{"tasks":[]},"message":"Onboarding: [hey]"} -> 500 (NPE)
```

## 3. Investigation

| # | Hypothesis | How it was tested | Result |
|---|------------|-------------------|--------|
| H1 | New users are created without a default routine | Read `AuthenticationService.register` → `UserService.createUserAndDefaultRoutine`; registered a test user and called `GET /api/v1/default-routine/users/{id}` | Ruled out: routine exists, response includes `id` |
| H2 | `id` is dropped by Jackson (annotation on `DefaultRoutine`) | Same GET returns `id` in JSON; no `@JsonIgnore`/write-only on `id` | Ruled out |
| H3 | Onboarding page uses a different user id for fetch vs chat | `authContext.user` and the `user` prop are the same `App` state | Ruled out |
| H4 | The UI's routine fetch hits the wrong URL, fails, and falls back to `{ tasks: [] }` (no `id`), which is then sent as `defaultRoutine` in the chat body | `apiRequest` prefixes `VITE_API_BASE_URL` (`http://localhost:8080` in dev, a bare host in prod) — no `/api/v1`. `fetchDefaultRoutine` passes `/default-routine/users/{id}` → 404 (curl). The `catch` in `refreshDefaultRoutine` sets `{ tasks: [] }`. Posting that body reproduces the exact NPE | **Confirmed** |

## 4. Root Cause

**Location**: `ui-personal-routine-manager/src/features/onboarding/pages/OnboardingPage.jsx:36` (and `src/features/onboarding/api/defaultRoutineTasks.ts:5,12,19`)

**Cause**: The onboarding default-routine calls use paths relative to an assumed `/api/v1` base (`/default-routine/...`). Every other call in the app passes the full path (`/api/v1/auth/login`, `/api/ai/...`, `/api/routine-manager/...`), and the configured `VITE_API_BASE_URL` (dev and prod) is just the host. So these requests go to `/default-routine/...` and 404. `refreshDefaultRoutine` swallows the error and substitutes `{ tasks: [] }`, which has no `id`; the chat then sends that object, and the backend dereferences `defaultRoutine.getId()` to build the conversation id → NPE.

**Introduced by**: unknown (inconsistent path convention vs. `API_BASE_URL` default of `/api/v1`).

**Blast radius**:
- `GET  /default-routine/users/{id}` — onboarding board never loads the routine.
- `POST /default-routine/{routineId}/tasks` — manual "add task" (FAB is also disabled since `currentDefaultRoutine.id` is missing).
- `PUT  /default-routine/tasks`, `DELETE /default-routine/tasks` — edit/drag/delete on the board.
- AI chat (this report).
- Production is affected the same way (`.env.production` base is also host-only).

No escalation needed: frontend-only path fix, no schema or API shape change.

## 5. Regression Test

**Test**: Manual (the frontend has no test framework configured; installing one was not requested). The fetch paths are plain strings in an API module, so a test framework (e.g. Vitest with a mocked `fetch`) would let these be covered.

Manual check:
1. `pnpm dev`, register a new user, log in → `/onboarding`.
2. DevTools Network: `GET http://localhost:8080/api/v1/default-routine/users/{id}` returns 200 with an `id`.
3. Send "hey" in Routine Buddy → 200 with a reply; no NPE in backend log.
4. Add a task via the + button, edit it, delete it → each request returns 2xx.

**Failed before fix**: Yes — step 2 is a 404 to `/default-routine/users/{id}`; step 3 yields 500 with the NPE (reproduced via curl in Section 2).

## 6. Fix

**Change summary**: Prefixed the four onboarding default-routine paths with `/api/v1`, matching the app-wide convention of passing full paths to `apiRequest`. The routine fetch now succeeds, so the chat body carries the real routine with its `id`.

**Files changed**:

- `ui-personal-routine-manager/src/features/onboarding/pages/OnboardingPage.jsx`: `GET /api/v1/default-routine/users/{id}`
- `ui-personal-routine-manager/src/features/onboarding/api/defaultRoutineTasks.ts`: `POST /api/v1/default-routine/{routineId}/tasks`, `PUT /api/v1/default-routine/tasks`, `DELETE /api/v1/default-routine/tasks`

**Alternatives rejected**:
- Null guard in `GeminiAiChatService` — hides the symptom; the board would still be empty and task CRUD still broken.
- Change `VITE_API_BASE_URL` to include `/api/v1` — breaks every other call that already passes `/api/...` (`/api/ai`, `/api/users`, `/api/routine-manager`).

## 7. Verification

- [x] Regression test passes — manual check replayed against the running backend with the exact URLs the UI now builds: GET routine 200 (with `id`), POST task 200, PUT task 200, DELETE task 204, chat "hey" 200 with an AI reply, no NPE.
- [x] Full test suite for the affected project passes — N/A: no frontend test framework; backend unchanged.
- [x] Lint/build passes — `pnpm build` OK; `pnpm lint` 0 errors, 3 pre-existing warnings in untouched lines.
- [x] Original reproduction steps no longer show the bug (curl replay above; browser re-check recommended).
- [x] API contract still aligned — no shape changes.

**Follow-ups**:
- Backend trusts a client-supplied `DefaultRoutine` in `ChatRequest`; a missing `id` should be a 400 (or the backend should load the routine by `userId`), not a 500 NPE.
- `API_BASE_URL` defaults to `/api/v1` in `src/lib/api.ts`, which contradicts every caller passing full paths; default should be `''`.
- `refreshDefaultRoutine` silently replaces a failed fetch with an id-less routine, hiding errors.
- Test user `dbgfix1795089941@example.test` (id `55d3d070-8428-4c34-bdf3-81508a2749d8`) was created in the local DB during reproduction.
