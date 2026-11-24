# Contract: user's local time on Buddy calls (F015)

The time is optional and additive everywhere. When it is missing or malformed it is ignored (no 400), and Buddy gets no time-of-day adjustment (FR-007). Everything else in these endpoints is unchanged.

| Endpoint | Where | Example |
|---|---|---|
| `POST /api/ai/chat/default-routine/{userId}` | body `localTime` | `{ "defaultRoutine": {…}, "message": "…", "localTime": "08:05" }` |
| `POST /api/ai/chat/daily-routine/{userId}` | body `localTime` | `{ "dailyRoutine": {…}, "date": "2026-11-24", "message": "…", "localTime": "14:30" }` |
| `POST /api/ai/chat/daily-reflection/{userId}` | body `localTime` | `{ "date": "2026-11-24", "message": "…", "localTime": "21:10" }` |
| `POST /api/routine-manager/daily-reflection/{userId}/{date}/feedback` | query `localTime` | `…/feedback?localTime=21:10` |

Format: `HH:mm`, 24-hour, in the user's device time. The frontend's `currentLocalTime()` (in `src/lib/localTime.ts`) builds it from `new Date()`.

# Contract: "Right now" block in Buddy's prompt

`funcs/TimeOfDayPrompt.format(Optional<TimeOfDay>, ChatKind)` returns the block below. It is appended last by `BuddyContextService.promptBlock(userId, call, localTime)`, after the goals (F013) and the tone (F014):

```text

## Right now
It is <morning|midday|evening> for the user (their local time is HH:mm). <window style>
Keep the user's chosen tone recognisable: adjust only energy and pacing, never what you may do.
<length rule>
```

With no time, the first three lines after the heading are left out, and only the heading and the length rule remain.

- **Window styles**:
  - MORNING: "Be energetic, crisp and decisive. Focus on clarity and on protecting their first important block of the day."
  - MIDDAY: "Be objective and adaptable. Help them re-plan around disruptions without any guilt."
  - EVENING: "Be slower, reflective and validating. Help them close open items so they can switch off and rest."
- **Length rules**:
  - DAY_TO_DAY: "This is a quick day-to-day chat: keep your text to at most 3 sentences unless the user asks for more detail. A plan or task list they asked for doesn't count."
  - DEEP: "This is a planning or reflection conversation: a longer coaching reply is fine when it helps."
