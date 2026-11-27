# Data Model: Timeline drag UX improvements

No stored data changes: no new table, column or migration. Tasks keep `startTime` + `durationMinutes` (F011).

## Rules

- **Overlap cap**: at any minute of the day (on a 24h cycle; overnight tasks wrap), at most **3** tasks of one routine (daily plan or default routine) may run. Only new, moved or resized tasks are checked (research R4).
- **No automatic push**: a saved task keeps exactly the start and duration that were sent. Other tasks move only when the client sends them (Push mode).
- **One request, one change**: all tasks in a save request are applied, then checked, then stored, or none are.

## UI state (EditingBoard, in memory)

| State | Shape | Lifetime |
|---|---|---|
| press | `{ taskId, mode: 'move' \| 'resize', pointerId, startX, startY, timer }` (ref) | pointerdown → arm, cancel or tap |
| dragState | existing fields (`liveStartMinutes`, `liveDurationMinutes`, …), set when armed | arm → drop or cancel |
| preview | `Map<taskId, {start, duration}>`, derived in render from `dragState` + `pushMode` | during a drag |
| pending | `Map<taskId, {start, duration}>` | drop → save settles |
| notice | `{ message, tone: 'error' }` | until dismissed or timed out |
