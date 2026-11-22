# Quickstart: Validate Onboarding Instruction

How to prove the feature works end to end. Each check maps to a spec requirement or acceptance scenario. Contracts: [default-routine-api.md](./contracts/default-routine-api.md), [walkthrough-ui.md](./contracts/walkthrough-ui.md).

## Prerequisites

```bash
# Backend (PostgreSQL profile; tests need the DB too)
cd ms-personal-routine-manager
docker compose up -d database
./gradlew bootRun

# Frontend
cd ui-personal-routine-manager
pnpm install
pnpm dev            # http://localhost:5173/milos.github.io/
```

## Automated checks

```bash
cd ui-personal-routine-manager
pnpm test           # Vitest: walkthroughReducer, placeCard, routineTypeForTab
pnpm lint && pnpm build

cd ms-personal-routine-manager
./gradlew test      # routines per type, weekend get-or-create, resolveTemplateFor
```

All of these must pass.

## API smoke test (backend running, `local` profile; auth disabled)

```bash
U=<a user id>
curl -s localhost:8080/api/v1/default-routine/users/$U | jq '.routineType'                 # "DAILY"
curl -s "localhost:8080/api/v1/default-routine/users/$U?type=WEEKEND" | jq '.id,.routineType' # id A, "WEEKEND"
curl -s "localhost:8080/api/v1/default-routine/users/$U?type=WEEKEND" | jq '.id'              # same id A
curl -s -o /dev/null -w '%{http_code}\n' "localhost:8080/api/v1/default-routine/users/$U?type=FOO" # 400
```

## Manual walkthrough (desktop ≥ 1200px, then phone width 390px)

Compare each screen against the matching mockup in [resources/](./resources/).

| # | Do | Expect | Spec |
|---|----|--------|------|
| 1 | Register a new account | Slide 1 opens over the setup screen. Its icon, label, title, dots and Skip match `D · Slide 1`. | FR-001, US1-1 |
| 2 | Next ×3 (also try →, ←, the dots, Esc) | Slides 2–4 match their mockups. Back is hidden on 1. Esc closes with no tour. | FR-003–005 |
| 3 | Reload, then on Slide 4 press **Show me around** | Tour steps 1–5 highlight the switch, board, +, Buddy and Ready to roll, matching `D · Tour 1–5`. Step 1 has no Back. Step 5 has Back and Got it only. | FR-006, FR-007 |
| 4 | Click the dimmed area during the tour | Nothing happens. | walkthrough-ui |
| 5 | Reload, press **Skip** on Slide 1 | Setup screen, no tour. | FR-008, US2-3 |
| 6 | Add a task on Weekday by hand. Switch to **Weekend** and ask Buddy "I sleep in until 9 on weekends" | Each tab shows its own tasks and its own chat thread. The weekday task is not on Weekend. | D2, R5 |
| 7 | Log out, log back in | Slides show again from Slide 1. Skip shows both routines still saved. | FR-009, FR-010, US3-1/2 |
| 8 | Stop the backend, then drag a task | An error banner appears. The board does not show the change as saved. | FR-011 |
| 9 | Restart the backend. Press **How it works** on the setup screen | Slides, then the tour. | FR-012, FR-013 |
| 10 | Press **Ready to roll**, then log out and back in | The dashboard opens and no slides appear. | FR-002, US3-3 |
| 11 | On the dashboard, press **How it works** | Slides only. Slide 4's button reads **Close**. Routines are unchanged. | FR-013, FR-014, US4 |
| 12 | Phone width: repeat 1–3 | Slides fit with 16px margins and swipe works. Tour cards are bottom/top sheets. Step 4 switches to the chat view and step 5 back to the board. | FR-015, R10 |
| 13 | On the dashboard, open a **Saturday** date for a user with weekend tasks, then for one without | The first copies the Weekend routine. The second copies the Weekday routine. | R3 |
