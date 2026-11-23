# Research: F011 Sleep task (overnight tasks)

## R1 – How an overnight task is stored

- **Decision**: No schema change. A task is already `startTime + durationMinutes`. It is overnight when `startMinutes + durationMinutes > 1440`. The server's computed `endTime` already wraps (`LocalTime.plusMinutes`), e.g. 22:00 + 480 → `06:00`.
- **Rationale**: The model already supports it. Only the code that reads it is wrong.
- **Alternatives**: an `overnight` flag or an `endDate` column. Rejected: redundant (derivable), and it needs a migration.

## R2 – Backend overlap rule on a 24h cycle

- **Decision**: In `TaskTimeFunctions`, compare tasks in minutes. Each task covers 1 or 2 ranges on the day: `[start, min(start+dur, 1440))` and, if overnight, `[0, start+dur-1440)`. Two tasks overlap if any range of one overlaps any range of the other. The push behavior is unchanged: an overlapping sibling moves to the new task's end (which may now be in the early morning).
- **Rationale**: Today `isOverlapping` uses `LocalTime` start/end. For 22:00–06:00, `end < start`, so overlaps are missed or wrong.
- **Alternatives**: forbid overlaps with the wrapped part (a new rule; spec says to keep the existing rule).

## R3 – Duration limit

- **Decision**: Services reject `durationMinutes` outside 1–1440 with 400 `ApiError` (default and daily task add/update, and the AI tools through the same services).
- **Rationale**: Over 24h, a task would overlap itself (spec edge case). The UI already limits it to 1440. The server does not check it today for these tasks (Constitution IV: server-side validation).
- **Alternatives**: move to request DTOs with Bean Validation. Deferred: those endpoints take entities directly (a known gap), and rewriting them is outside this feature.

## R4 – Buddy (AI tools)

- **Decision**: Replace the "If a task crosses midnight, split it into 2 tasks…" text in `DefaultRoutineAiTools` and `DailyRoutineAiTools` with: "A task may cross midnight: create ONE task with its startTime and full durationMinutes (e.g. sleep 22:00 + 480 ends 06:00). Never split it."
- **Rationale**: The tool text is the only reason Buddy splits today. The tools already call the same services.

## R5 – Board rendering (frontend)

- **Decision**: A new pure util `onboarding/utils/taskSegments.ts` turns `(startMinutes, durationMinutes)` into 1 or 2 board segments (`main`: start→min(end,1440); `wrap`: 0→end−1440). `EditingBoard` renders one block per segment with the same task handlers. Duration comes from `durationMinutes`, not `endTime − startTime` (which goes negative for overnight tasks).
  - Both parts show the full label `22:00 – 06:00 · 8h`. The done check and delete button sit on the `main` part only. The resize handle sits on the part that holds the end.
  - Move: start is limited to 0–1435, and the end may pass 24:00. Resize: duration limited to 5–1440. Gap-clear shifts use the same limits.
  - Highlight: the task is current if now is inside either part.
- **Rationale**: This is the smallest change to the existing board. Clicking either part opens the same task, so FR-004 is met for free.
- **Alternatives**: one rotated/continuous board. Rejected: the spec chose a 24h cycle wrapped on the same board.

## R6 – Now / Next

- **Decision**: In `nowAndNext.ts`, treat `end <= start` as overnight: it is current when `now >= start || now < end`, and `minutesLeft` counts across midnight. Today's `00:00` end rule becomes a special case of this.
- **Rationale**: This is a pure function with a unit test already in place.

## R7 – Edit form

- **Decision**: `TaskEditModal` shows a read-only hint "Ends HH:MM (next day)" when start + duration passes 24:00. No validation change: 1–1440 already passes.
