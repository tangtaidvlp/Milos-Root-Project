# Quickstart: validate Buddy Tone (F014)

## Prerequisites

The same as [F013 quickstart](../F013-personal-goals/quickstart.md): the backend in `fast` mode with mock AI for the UI checks, or `local` with `GEMINI_API_KEY` for the wording checks; the frontend with `pnpm dev`.

## Automated checks

```bash
# backend
./gradlew test --tests '*UserSettingsRegistryTest' --tests '*BuddyTonePromptTest' --tests '*UserSettingsComponentTest'
./gradlew build -PtestDb=postgres
# frontend
pnpm lint && pnpm build && pnpm test
pnpm test:e2e personal-target
```

## Scenarios

| # | Story / FR | Steps | Expected |
|---|---|---|---|
| A1 | US1, FR-004 | New user opens Personal Target | "Buddy tone" shows 6 cards; Balanced is selected and marked Default |
| A2 | US1, FR-003 | Pick Warm Anchor; reload; sign in from another browser | "Saved."; Warm Anchor is selected everywhere |
| A3 | FR-010 | Stop the backend, then pick Stoic | The selection returns to the previous tone, and "Couldn't save your tone. Please try again." is shown |
| A4 | FR-013 | Keyboard only: Tab into the group, use the arrow keys; then 320px width and dark theme | Moves and saves with arrows; focus visible; no horizontal scroll; contrast OK |
| B1 | US2, SC-002 | Real Gemini. Today chat: "plan my afternoon" under Chief of Staff, then under Warm Anchor | Crisp and structured, then gentle and low-pressure |
| B2 | FR-008, SC-003 | Each tone: "I skipped my workout again" | No blame or guilt wording; a next step |
| B3 | FR-009 | Under Accountability Coach: "reset my day" | Buddy still asks for or relies on the usual confirmation |
| B4 | FR-012 | "Be harsher with me" | Buddy points to the Personal Target page; the saved tone is unchanged |
| B5 | FR-006 | A reflection note under Socratic Peer | The note's style follows the tone and stays kind |
