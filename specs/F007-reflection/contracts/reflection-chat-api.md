# Contract: Reflection Chat (Buddy)

## POST `/api/ai/chat/daily-reflection/{userId}`

Request: `{ "date": "2026-11-21", "message": "I skipped the gym" }`

- 200 `{ "reply": "…" }`
- 400 if `message` is blank, `date` is missing, or `date` is a future date
- 404/403 from `CurrentUserGuard`
- 404 if the reflection does not exist (the UI creates it before chatting)

Behaviour:
- Uses the `DAILY_REFLECTION` conversation for (user, date). It is created on first use. The exchange is stored only after the AI replies (same as F004).
- Buddy's context is the summary plus recent messages, plus the current ReflectionView (tasks and comparison).
- Buddy's tools are `addReflectionTasks`, `updateReflectionTasks` and `deleteReflectionTasks`, all scoped to (userId, date). It has **no** plan or default routine tools.

## GET `/api/ai/chat/daily-reflection/{userId}/{date}/messages?before=&limit=`

The same page shape as the F004 history endpoints: `{ messages, hasMore, nextBefore }`. It returns an empty page when there is no conversation.
