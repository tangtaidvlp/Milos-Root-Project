# Quickstart: F010 UX optimise

## Automated

```bash
cd ui-personal-routine-manager
pnpm lint && pnpm test && pnpm build
# backend: SPRING_PROFILES_ACTIVE=fast SPRING_AI_ACTIVE=false ./gradlew bootRun ; then pnpm dev
pnpm test:e2e today-board reflection profile settings-persistence
```

## By hand

| # | Where | Do | Expect |
|---|-------|----|--------|
| 1 | Today | Look at the toolbar | No slider, no Pause/Resume, no "Paused". Clock + "Live" shown. |
| 2 | Today | Leave the tab for over a minute, come back | Clock shows the real time at once. |
| 3 | Any page | Look top right | No "Sign out". Profile → Sign out works. |
| 4 | Today, wide window | Toolbar | All tools inline, no "More". |
| 5 | Today, narrow the window step by step | Toolbar | Never wraps. "+ Add task", "Reflection" and "More" stay. Zoom, Gap clear, Reset day and Clean up are in "More". |
| 6 | "More" open | Escape / click outside / pick Gap clear / press zoom + | Closes (focus back on More) / closes / toggles and closes / zooms and stays open. |
| 7 | Today | "+ Add task": 1 h 30 min, pick a color | A 1.5 h block in that color. |
| 8 | Default routine | Edit a 95-min task | Shows 1 h 35 min. |
| 9 | Dialog | 0 h 0 min → Save | Error "between 1 minute and 24 hours". Nothing is saved. |
| 10 | Reflection, ≥ 1280px | Toolbar | No slider or Pause. Both now-lines live. |
| 11 | 320px width | Today | No horizontal scroll. |
