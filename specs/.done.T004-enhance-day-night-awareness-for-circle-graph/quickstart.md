# Quickstart: check T004

**Setup**: backend `SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun`; UI `pnpm dev`; sign in, open Today, switch the header to **Circle**.

| # | Check | Expected |
|---|---|---|
| 1 | Light theme, wide window | Matches `resources/day-clock-light.png`: navy top half with moon + "NIGHT", cream bottom half with sun + "DAY", split at 06 / 18 |
| 2 | Dark theme | Matches `resources/day-clock-dark.png`: dark rim tracks, 06 and 18 in pills |
| 3 | Centre disc | About 60% of the clock radius; date/time/task/"until" still readable |
| 4 | Minute marks | 3 small marks between each pair of hour marks |
| 5 | Hour numbers | Night hours bluish, day hours warm; 00/06/12/18 emphasised |
| 6 | Tasks | Arcs on the rim, click opens the task, drag moves it in 5-min steps, a task over 06:00 or 18:00 is one arc |
| 7 | Narrow window (≤ 400 px) | No overlap; icons/labels/minute marks hide when they don't fit |
| 8 | Default routine (no live clock) | Same day/night face, centre shows the label |

**Automated**: `pnpm lint && pnpm test && pnpm build`, then `pnpm test:e2e e2e/radial-view.spec.ts` (and the full suite).
