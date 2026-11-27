# Quickstart: validate timeline drag UX

## Run

```bash
cd ms-personal-routine-manager && SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun
cd ui-personal-routine-manager && pnpm dev          # http://localhost:5173
```

Automated checks:

```bash
cd ms-personal-routine-manager && ./gradlew test
cd ui-personal-routine-manager && pnpm lint && pnpm test && pnpm build
pnpm test:e2e --grep "today board"                   # backend + pnpm dev running
```

## Manual checks (phone = DevTools touch emulation or a real phone, plus desktop)

| # | Do | Expect |
|---|---|---|
| 1 | On Today, swipe fast across tasks | The board scrolls; no task moves |
| 2 | Press and hold a task ~0.15s, then drag | The task highlights, then follows the finger or mouse |
| 3 | Tap or click a task | The task dialog opens |
| 4 | Drop a task at a new time | It stays there, no jump back; dots show briefly; the board is locked meanwhile |
| 5 | Stop the backend, drag and drop | The task returns to its old place; a bottom message says something went wrong |
| 6 | Drop task A over task B | Both show side by side; after reload they keep their times |
| 7 | Make 3 tasks overlap, drag a 4th onto them | The task shows blocked while dragging; on drop it goes back and a message says a slot holds at most 3 tasks |
| 8 | Add a 4th parallel task in the task dialog | The dialog shows "A time slot can hold at most 3 tasks." |
| 9 | Turn Push mode on | A notice says Push mode is on |
| 10 | Push mode: drag a task down 30 min, then another up 30 min | Later tasks slide down live; earlier tasks slide up live; the saved result matches the preview |
| 10b | Push mode: drag a task down past the middle of the next task | The two swap places with the gap kept; nothing else moves; the saved result matches |
| 11 | Push mode: make a task longer | Tasks after it slide down; making it shorter moves nothing |
| 12 | Repeat 2 and 4 on Default routine and in Reflection compare (≥ 1280px) | Same behaviour |
| 13 | OS "reduce motion" on, Push mode drag | Tasks jump to place without sliding |
