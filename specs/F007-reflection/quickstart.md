# Quickstart: F007 Daily Reflection

## Prerequisites

```bash
cd ms-personal-routine-manager && SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun   # mock AI unless GEMINI_API_KEY + spring.ai.active=true
cd ui-personal-routine-manager && pnpm dev
```

For prod, apply `db/F007-daily-reflection.sql` **before** deploying the new backend image.

## Automated checks

```bash
cd ms-personal-routine-manager && ./gradlew test --tests "*Reflection*"
cd ui-personal-routine-manager && pnpm test && pnpm lint && pnpm build
```

## Manual scenarios

1. **Copy once (US1)**: Register and onboard with 3 weekday tasks, then open Today. Press the **Reflection** toggle in the board toolbar. The board shows the same 3 tasks, with a "Reality" badge and no completion checkboxes. The comparison shows 3 "As planned".
2. **Independence**: In Reality, shorten one task, delete one and add "Coffee with Sam". Turn **Reflection** off: the original 3 tasks are unchanged. Edit a planned task's time, then turn Reflection back on: the reflection is unchanged.
3. **Comparison (US2)**: The panel shows 1 as planned, 1 changed, 1 skipped and 1 unplanned, plus planned vs actual totals. Rename the changed task: it still shows as "changed".
4. **Feedback**: Click "Get Buddy's note". The note starts positively and has at most 2 suggestions. Edit a task: the note shows a "Refresh note" hint.
5. **Chat (US3)**: With Reflection on, type "I skipped the gym and read for 30 minutes". With the mock AI, the reply echoes the message. With Gemini, the reflection updates and the plan doesn't. Reload: the Reality chat shows its history, and the Plan chat does not contain it.
6. **Dates**: Go to tomorrow: the Reflection toggle is disabled with the hint "You can reflect once the day has happened", and the page shows the Plan. Go to a past day with no plan, then turn Reflection on: the reflection is empty and the Plan for that day is still empty (no plan was created).
7. **Phone width (≤ 760px)**: The toggle, panel and board fit with no horizontal scroll, and the chat button opens the Reality chat.
8. **Dark theme**: The panel, badge and status chips stay readable.

## Enhancement scenarios (2026-11-22)

9. **Toggle placement**: The date row holds only the date and the Today button. The "Reflection" toggle sits in the board toolbar, with no extra row and no tabs.
10. **Side by side (≥ 1280px)**: At 1400px wide, turn Reflection on. The Plan and Reality boards appear side by side under one toolbar.
    - Scroll or zoom one board: the other follows, and 08:00 lines up.
    - Pause the clock or drag the slider: both now-lines move.
    - "Add to plan" adds to the plan only, and the summary strip updates. "Add to reality" adds to the reflection only.
    - Gap clear affects plan drags only.
11. **Summary strip and note**: Above the boards there is one line with Planned → Reality, the difference and four chips, and "Task by task" starts collapsed. Buddy's note and its "Get Buddy's note" button sit at the top of the Buddy chat, whose header is compact.
12. **Narrow (< 1280px)**: At 900px, turn Reflection on. The single board shows Reality. Click a task: a pop-up shows its group and planned vs actual times. "Edit" opens the task editor. Turn Reflection off to see the Plan.
13. **Resize**: With Reflection on, resize from 1400px to 900px and back. The mode and the data are kept, and the layout switches.
