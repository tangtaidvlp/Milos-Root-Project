# Quickstart: Validate Persisted Buddy Chat History

**Feature**: F004 | Contract: [contracts/chat-history-api.md](./contracts/chat-history-api.md) | Data: [data-model.md](./data-model.md)

## Baseline (verified 2026-11-21, before implementation)

This was run against a separate backend: `SPRING_PROFILES_ACTIVE=fast`, `--server.port=8099 --spring.ai.active=false`.

| Check | Result |
|-------|--------|
| Register user → default routine (DAILY) returned | OK (`id` present, `tasks: []`) |
| POST `/api/ai/chat/default-routine/{userId}` | `200`, mock reply |
| POST `/api/ai/chat/daily-routine/{userId}` (`dailyRoutine: null`) | `200`, mock reply |
| GET `/api/ai/chat/daily-routine/{userId}/2026-11-21/messages` | `404` (no history endpoint yet) |
| POST chat with a non-existent userId | `200`. No user validation. Plan adds a `404` |
| `User` table name | `users` (matches the prod DDL in data-model) |

## Prerequisites

- To avoid clashing with a dev server on `:8080`, run the backend on a spare port in mock mode:
  ```bash
  cd ms-personal-routine-manager
  SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun --args='--server.port=8099 --spring.ai.active=false --app.chat.compaction-threshold=4'
  ```
  A threshold of 4 makes compaction happen after 2 exchanges.
- Frontend: `cd ui-personal-routine-manager && pnpm dev`. Point the `/api` proxy at the port you used.

## A. API checks (curl)

```bash
B=localhost:8099
UID_=$(curl -s -X POST $B/api/v1/auth/register -H 'Content-Type: application/json' \
  -d '{"email":"f004@example.test","password":"Passw0rd!x","username":"f004"}' | python3 -c 'import json,sys;print(json.load(sys.stdin)["userId"])')
DR=$(curl -s "$B/api/v1/default-routine/users/$UID_?type=DAILY")
RID=$(echo "$DR" | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
```

| # | Step | Expected |
|---|------|----------|
| A1 | GET `$B/api/ai/chat/default-routine/$UID_/$RID/messages` before any chat | `200 {"messages":[],"hasMore":false,"nextBefore":null}` |
| A2 | POST 3 messages to `/default-routine/$UID_` with `{"defaultRoutine":$DR,"message":"m1..m3"}` | Each `200 {reply}` |
| A3 | GET history again | 6 messages, `seq` 1–6, alternating `user`/`assistant`, oldest first |
| A4 | POST 2 messages to `/daily-routine/$UID_` with `date: 2026-11-21`; GET `/daily-routine/$UID_/2026-11-21/messages` | Only those 4 messages (no mixing with A3) |
| A5 | GET `/daily-routine/$UID_/2026-11-22/messages` | Empty page |
| A6 | Send 12 more default-routine messages (30 total), then GET with no `before` | 20 messages (`seq` 11–30), `hasMore:true`, `nextBefore:11` |
| A7 | GET `?before=11` | `seq` 1–10, `hasMore:false`. A6+A7 together have no gaps or duplicates |
| A8 | POST with a blank `message` | `400`; history count unchanged |
| A9 | GET/POST with a random UUID as userId | `404` |
| A10 | GET with another user's `defaultRoutineId` | `404` |
| A11 | Stop and restart the backend on a Postgres profile (`local`, port override), then GET history | Same messages as before the restart (H2 `fast` loses data on restart, so use `local` for this check) |

## B. Compaction (threshold 4)

| # | Step | Expected |
|---|------|----------|
| B1 | After A2, check the logs | A `Compacted conversation <id> through seq 4` style log line appears asynchronously |
| B2 | Check the DB: `select summarized_through_seq, summary_text is not null from chat_conversation` | Cursor > 0, summary present |
| B3 | GET history | All original messages are still returned; the summary is not in the response (FR-011) |
| B4 | Make the summariser fail (e.g. point `spring.ai.google.genai.api-key` at an invalid key with `spring.ai.active=true`), then send messages | Chat replies still save when AI replies succeed. The compaction failure is logged, the cursor doesn't move, and it is retried on the next exchange |
| B5 | Real-AI memory (optional, `spring.ai.active=true`, `local`): say "I prefer workouts in the morning", send > threshold messages, restart, ask "when do I like to work out?" | The reply mentions morning (SC-005) |

## C. AI error is not stored

Run with `spring.ai.active=true` and an invalid `GEMINI_API_KEY`, then POST a chat.

**Expected**: an error status, and the history count is unchanged (FR-008).

## D. Ownership (sit profile, JWT on)

1. Register users U1 and U2, and log in as U1 to get a token.
2. GET U2's history with U1's token. **Expected**: `403`.
3. GET U1's own history with U1's token. **Expected**: `200`.

## E. UI checks (browser)

| # | Step | Expected |
|---|------|----------|
| E1 | Default Routine page → Weekday tab → send 2 messages → reload | Greeting at the top, then the 2 exchanges, scrolled to the bottom |
| E2 | Switch to the Weekend tab | Only weekend messages (or just the greeting) |
| E3 | Onboarding: chat on the Weekday tab, finish onboarding, open Default Routine → Weekday | The onboarding messages are there |
| E4 | Daily page: chat on today → switch to yesterday → back to today | Yesterday shows its own history; today's history comes back |
| E5 | Conversation with 30+ messages: open it, scroll to the top | 20 shown first. Scrolling up loads older ones above without the view jumping; it stops at the first message |
| E6 | Stop the backend, reload the page | Greeting plus the "Couldn't load earlier messages" notice. After restarting the backend, sending works |
| E7 | Phone width (≤ 760px): open chat via the FAB | History is shown the same way |

## Automated tests

```bash
cd ms-personal-routine-manager && ./gradlew test --tests "*ChatHistory*"
cd ui-personal-routine-manager && pnpm test && pnpm build
```

## Results (2026-11-21, after implementation)

**Setup:**
- The backend JAR ran on `:8099` with a throwaway H2 **file** DB in the session scratchpad, so data survives a restart and the local Postgres was not touched.
- `app.chat.compaction-threshold=4`.
- AI was the mock unless stated otherwise.

| # | Result |
|---|--------|
| A1 | ✅ `{"messages":[],"hasMore":false,"nextBefore":null}` |
| A2–A3 | ✅ 3×200, then 6 messages, seq 1–6, alternating user/assistant |
| A4–A5 | ✅ The day conversation has its own 4 messages; the next day is empty |
| A6 | ✅ 20 messages, seq 11–30, `hasMore:true`, `nextBefore:11` |
| A7 | ✅ seq 1–10, `hasMore:false` |
| A8 | ✅ Blank message → 400, last seq still 30 |
| A9 | ✅ Unknown user → GET 404, POST 404 |
| A10 | ✅ Another user's routine → 404. Bad date → 400 |
| A11 | ✅ After a restart on the same DB: 20 newest (seq … 30) and the day conversation intact |
| B1–B3 | ✅ Log shows `Compacted conversation … through seq 20/24/28`. The history response contains no `summary` |
| B4 | ✅ Covered by `ChatCompactionIntegrationTest.summariserFailureKeepsChatWorkingAndRetries`: logs WARN, cursor unchanged, retried after the next exchange |
| B5 | ⏸ Not run (needs a real Gemini key and spends tokens) |
| C | ✅ `spring.ai.active=true` with an invalid key: POST → 500, message count 4 → 4 (nothing stored) |
| D | ✅ `sit` (JWT): own history 200, other user's history 403, POST as other user 403, no token 401, own POST 200 |
| E1–E7 | ⏸ Not run here (no browser in this session). Frontend unit tests, type-check and build pass |

**Automated tests:**
- Backend: `ChatHistoryIntegrationTest` 10/10, `ChatCompactionIntegrationTest` 2/2, `RoutineServiceIntegrationTest` 10/10.
- `OnboardingRoutineTest` has 2 failures, which also fail on the untouched `HEAD` (they call a `POST /api/users` endpoint that doesn't exist). They were already failing before F004.
- Frontend: `pnpm test` 86/86; `pnpm build` OK; `pnpm lint` shows only 2 warnings that were already in the code.
