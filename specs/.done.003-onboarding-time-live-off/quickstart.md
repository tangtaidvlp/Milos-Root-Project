# Quickstart: Live Clock Off During Onboarding

## Prerequisites

- Backend: `cd ms-personal-routine-manager && ./gradlew bootRun` (PostgreSQL container `routine-manager-dbdo` on port 5469 running).
- Frontend: `cd ui-personal-routine-manager && pnpm dev`.
- A user who has **not** finished onboarding (register a new one). Add a task that covers the current time of day, e.g. a 3-hour task around now.

## Automated checks

```bash
cd ui-personal-routine-manager
pnpm test     # includes boardScroll.test.ts
pnpm build
pnpm lint
```

## Scenarios

| # | Steps | Expected | Spec |
|---|-------|----------|------|
| 1 | Open the setup screen (skip the slides). | No clock readout, no Live/Manual, no Pause clock / Resume live, no slider, no now-line, no "Now: …" line. | FR-001, SC-001 |
| 2 | Look at the task covering the current time. | Same style as the other tasks; no active highlight. | FR-002 |
| 3 | On load, check the board's top. | 06:00 is at the top, whatever the current time. | FR-004, SC-003 |
| 4 | Switch to Weekend, then back to Weekday. | Each switch shows 06:00 at the top. | FR-004 |
| 5 | Scroll to 14:00, wait 2+ minutes (5 for SC-002). | Board does not move or change. | FR-003, SC-002 |
| 6 | Scroll to 09:00, zoom in and out. | 09:00 stays at the top of the view. | R4 |
| 7 | Add, edit, drag, resize and delete a task; toggle Gap clear; Reset day. | All work as before; saving does not move the board. | FR-005, FR-007 |
| 8 | Phone width (390×844): repeat 1 and 3. | Same results. | Edge cases |
| 9 | Run "How it works" → tour step 2 (routine board). | Board shows no clock elements. | Edge cases |
| 10 | Finish onboarding, open the dashboard for today. | Clock, Live label, Pause/Resume, slider, now-line, current-task highlight and "Now: …" are all present; board scrolls to now; Pause/Resume and slider work. | FR-006, SC-004 |
