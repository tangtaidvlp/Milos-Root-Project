# Quickstart: validate F011 Sleep task

## Run

```bash
cd ms-personal-routine-manager && SPRING_PROFILES_ACTIVE=fast SPRING_AI_ACTIVE=false ./gradlew bootRun
cd ui-personal-routine-manager && pnpm dev
```

## Automated checks

| Check | Command | Proves |
|-------|---------|--------|
| Backend unit (`TaskTimeFunctionsTest`) | `./gradlew test --tests '*TaskTimeFunctionsTest'` | overlap on a 24h cycle; wrapped part pushes a 05:30 task to 06:00 |
| Backend component (`DefaultRoutineComponentTest`, `DailyRoutineComponentTest`) | `./gradlew test` | 22:00 + 480 is saved as one task with `endTime 06:00`; duration 1441 → 400 `ApiError`; a daily routine created from the default copies it once |
| Frontend unit (`taskSegments.test.ts`, `nowAndNext.test.ts`) | `pnpm test` | 1 vs 2 segments, ends exactly at 24:00 = 1 segment; Now at 02:00 is Sleep |
| E2E (`today-board.spec.ts`) | `pnpm test:e2e` | create Sleep 22:00 for 8h via the form → two linked parts, one task after reload |

## Manual (Default routine and Today)

1. Stretch a 22:00 task down past the bottom of the board to 06:00. **Expect**: the bottom part shows 22:00–24:00 and the top part 00:00–06:00, both labeled `22:00 – 06:00 · 8h`.
2. Reload. **Expect**: the same, one task.
3. Click the top part. **Expect**: the edit form opens for the whole task, showing "Ends 06:00 (next day)".
4. Delete from the bottom part. **Expect**: both parts disappear.
5. Stretch a task to end exactly at 24:00. **Expect**: no top part.
6. Ask Buddy: "add sleep from 10pm to 6am". **Expect**: one task.
