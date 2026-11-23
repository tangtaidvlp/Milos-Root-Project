# Contract: Chat History API

**Feature**: F004 | Base path: `/api/ai/chat` (existing `AIController`)

All endpoints run through `CurrentUserGuard` (research R5):

- **sit/prod**: if the JWT principal is not `{userId}`, the response is `403`.
- **All profiles**: if `{userId}` doesn't exist, the response is `404`.

Errors use the existing `ApiError` body from `GlobalExceptionHandler`.

## Shared shapes

```jsonc
// ChatMessageDto
{
  "seq": 41,                         // number, unique and increasing within the conversation
  "role": "user" | "assistant",
  "content": "Move my run to 6:30",  // full text, markdown allowed for assistant
  "createdAt": "2026-11-21T08:15:02Z"
}

// ChatHistoryPage
{
  "messages": [ChatMessageDto, ...], // oldest → newest, at most `limit`
  "hasMore": true,                   // older messages exist before messages[0]
  "nextBefore": 22                   // = messages[0].seq when hasMore, else null
}
```

The conversation summary is **never** returned.

## GET `/default-routine/{userId}/{defaultRoutineId}/messages`

Returns the history page for the user's conversation about one default routine. Onboarding chats are included, because they use the same conversation.

| Query | Type | Default | Notes |
|-------|------|---------|-------|
| `before` | long | absent | Return messages with `seq < before`. Absent = newest page |
| `limit` | int | `app.chat.history-page-size` (20) | Clamped to 1..history-page-size |

- `200` + `ChatHistoryPage`. If the conversation doesn't exist yet, the response is `{"messages":[],"hasMore":false,"nextBefore":null}`. No row is created on read.
- `404` if the default routine does not belong to `{userId}`.
- `403` or `404` per the guard rules above.

## GET `/daily-routine/{userId}/{date}/messages`

`{date}` is ISO `yyyy-MM-dd`. The rest is the same as above. An invalid date returns `400`.

## POST `/default-routine/{userId}` (existing, behaviour change)

The request and response shapes are unchanged: `{ defaultRoutine, message }` → `{ reply }`.

New behaviour:

1. The guard runs. The server requires `defaultRoutine.id` to belong to `{userId}`, otherwise `404`.
2. Buddy's context = stored summary + unsummarised messages for (user, routine).
3. On success, the user message and the reply are saved as two messages, then compaction may be triggered asynchronously.
4. On an AI error, nothing is saved. The existing error status is returned.
5. A blank `message` returns `400`, and nothing is saved.

## POST `/daily-routine/{userId}` (existing, behaviour change)

The request and response are unchanged: `{ dailyRoutine, date, message }` → `{ reply }`. The rules are the same as above, but the conversation is keyed by (user, `date`). A missing `date` returns `400`.

## Frontend API (`ui-personal-routine-manager`)

- `features/default-routine/api/defaultRoutineChat.ts` gets `fetchDefaultRoutineChatHistory(userId, routineId, before?) : Promise<ChatHistoryPage>`.
- `features/daily/api/dailyRoutineTasks.ts` (or a new `dailyRoutineChat.ts`) gets `fetchDailyRoutineChatHistory(userId, date, before?)`.
- `BuddyChat` gets a new optional prop, `loadHistory?: (before?: number) => Promise<ChatHistoryPage>`. Without it, BuddyChat behaves as it does today.
