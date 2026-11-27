# Contract: Personal Target chat API (F013 iteration)

Buddy's goals chat on the Personal Target page. Same shapes as the other Buddy chats (F004 history, F013 `goalProposal`, F015 `localTime`).

## POST `/api/ai/chat/personal-target/{userId}`

- Body: `{ "message": string, "localTime"?: "HH:mm" }`. A missing or malformed `localTime` is ignored.
- 200 → `ChatResponse { reply: string, goalProposal: GoalProposal | null }`. Only `reply` is stored in history.
- 400 `message must not be blank`. 404 unknown user, 403 another user (`CurrentUserGuard`). 503 `Buddy is unavailable right now` when the AI fails (constitution V); nothing is stored.
- Buddy has no plan or routine tools here. It may call `proposeGoal` (never writes).

## GET `/api/ai/chat/personal-target/{userId}/messages?before=&limit=`

- 200 → `ChatHistoryPage { messages (oldest → newest), hasMore, nextBefore }`; empty when the user hasn't chatted yet.
- 404 / 403 as above.
