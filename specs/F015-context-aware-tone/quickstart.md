# Quickstart: validate Context-Aware Tone (F015)

## Automated checks

```bash
# backend
./gradlew test --tests '*TimeOfDay*' --tests '*BuddyContextComponentTest' --tests '*LocalTimeComponentTest'
./gradlew build -PtestDb=postgres
# frontend
pnpm lint && pnpm build && pnpm test && pnpm test:e2e
```

## Scenarios (real Gemini; the backend `local` profile with `GEMINI_API_KEY`)

| # | Story / FR | Steps | Expected |
|---|---|---|---|
| A1 | US1, FR-002 | Set the Mac clock (or wait) to 08:00. Today chat: "what should I do now?" | Crisp and decisive; points to the first important block |
| A2 | US1, FR-003 | At 14:00: "my meeting overran, fix my afternoon" | Objective re-plan, no guilt |
| A3 | US1, FR-004 | At 21:00: "how did today go?" | Calm and reflective; helps close open items |
| A4 | FR-005 | Under High-Accountability Coach at 21:00 | Calmer but still direct and firm |
| A5 | US2, FR-008 | Today chat, a simple question | At most 3 sentences of text |
| A6 | FR-009 | Reflection chat: "why do I keep missing evening tasks?" | A fuller coaching reply is allowed |
| A7 | FR-007 | Send a chat with no `localTime` (curl) | It works; no time-of-day wording |
