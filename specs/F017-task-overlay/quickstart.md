# Quickstart: Task overlay

Run: backend `SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun`, UI `pnpm dev`. Automated: `./gradlew test`, `pnpm lint && pnpm test && pnpm build`, `pnpm test:e2e e2e/today-board.spec.ts`.

| # | Do | Expect |
|---|---|---|
| 1 | Add a task | Overlay switch is off |
| 2 | Turn Overlay on for Sleep, save, reload | Still on |
| 3 | Default routine Sleep has Overlay on; Reset day on Today | Today's Sleep has Overlay on |
| 4 | A 09:00–10:00, B 10:30–11:00 (both off). Drag A down until it covers half of B | B jumps to 09:00; A follows the pointer |
| 5 | Release | A 10:00–11:00, B 09:00–09:30; same after reload |
| 6 | Drag A over less than half of B and release | A ends at B's start; B does not move |
| 7 | Push mode on, repeat 4–5 | Same swap; nothing else moves |
| 8 | Overlay-on task dragged over another | Side by side |
| 9 | Normal mode: resize an Overlay-off task into the next task | Stops at the next task's start |
| 10 | Reflection Reality task dialog | No Overlay switch |
| 11 | Phone: hold 0.1s and drag (as 4–5) | Same as desktop |
| 12 | Drag or resize any task | Red start/end times and the duration show in the time column and follow the drag; gone on release |
