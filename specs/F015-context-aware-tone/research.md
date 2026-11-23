# Research: Context-Aware Tone (F015)

## R1. Knowing the user's local time

- **Decision**: The frontend sends the user's local clock time as `localTime: "HH:mm"` with every Buddy call:
  - a new optional field in the three chat request bodies;
  - `?localTime=HH:mm` on `POST …/daily-reflection/{userId}/{date}/feedback`, which has no body.
  A missing or malformed value is ignored, and Buddy then gets no time-of-day adjustment (FR-007). The request is not refused: the time only shapes tone, so a bad value must never block a chat.
- **Rationale**: This is the simplest way to get the user's real local time (FR-006). There's no time-zone database and nothing new is stored. The server clock (`Clock.systemDefaultZone()`) is the EC2 zone, not the user's.
- **Alternatives**: An IANA time zone plus the server clock was rejected: it needs more parsing and gives the same result. A stored user time zone was rejected: it would need a profile setting the spec doesn't ask for (YAGNI).

## R2. Windows

- **Decision**: The pure rule `funcs/TimeOfDay.of(LocalTime)` returns `MORNING` [05:00, 12:00), `MIDDAY` [12:00, 17:00) and `EVENING` otherwise (17:00–04:59, including after midnight). `TimeOfDay.parse(String)` turns `"HH:mm"` into an optional `LocalTime`, accepting 00:00–23:59 only.

## R3. Kind of call → reply length

| Call | Kind | Length rule |
|---|---|---|
| Daily routine chat (Today) | DAY_TO_DAY | At most 3 sentences of text unless the user asks for detail; a requested plan or list doesn't count (FR-008) |
| Default routine chat (planning, includes onboarding) | DEEP | May give longer coaching (FR-009) |
| Reflection chat and reflection feedback | DEEP | Same; feedback keeps its own 60–120-word limit |

## R4. Prompt

- **Decision**: The pure formatter `funcs/TimeOfDayPrompt.format(Optional<TimeOfDay>, ChatKind)` builds a "Right now" block. It contains the window's style (FR-002 to FR-004), "keep the chosen tone recognisable; adjust energy and pacing only, never what you may do" (FR-005), and the length rule for the kind. With no time, only the length rule is added.
- **Wiring**: `BuddyContextService.promptBlock(userId, BuddyCall, LocalTime)` replaces `promptBlock(userId, inChat)`. The enum `BuddyCall` (`DEFAULT_ROUTINE_CHAT`, `DAILY_CHAT`, `REFLECTION_CHAT`, `REFLECTION_FEEDBACK`) gives both "in chat" (the proposal rule) and the kind. Its order is goals → tone → right now, so the time adjusts the chosen tone.
- **Rationale**: It extends the single context point added in F014, and each rule gets a unit test.

## R5. Passing the time through

`AiChatService.defaultRoutineChat/dailyRoutineChat`, `ReflectionAiService.chat/feedback` and `ReflectionFeedbackService.generate` gain a `LocalTime localTime` parameter (nullable). The mocks ignore it. Existing test verifies and stubs get one more matcher.

## R6. Out of scope

Off-track or streak-break detection waits for analytics metrics (clarification 2026-11-24). F014's no-guilt rule already covers a user saying they missed something.
