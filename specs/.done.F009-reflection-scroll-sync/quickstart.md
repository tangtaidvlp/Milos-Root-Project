# Quickstart: F009 Smooth scroll sync

## Automated

```bash
cd ui-personal-routine-manager
pnpm lint && pnpm test          # includes useSyncedScroll.test.ts (new "late echo" case)
pnpm test:e2e reflection        # backend: SPRING_PROFILES_ACTIVE=fast SPRING_AI_ACTIVE=false ./gradlew bootRun; plus pnpm dev
```

## By hand (SC-001, SC-002)

Browser window ≥ 1280px wide → Today → turn **Reflection** on (Plan | Reality side by side).

| # | Do | Expect |
|---|----|--------|
| 1 | Fast trackpad flicks on Plan, up and down, several times | Reality follows in step. Plan coasts naturally and never jumps back or stutters. |
| 2 | Same on Reality | Plan follows the same way. |
| 3 | Flick Plan, then immediately scroll Reality while Plan is still coasting | Reality takes over with no snap-back. |
| 4 | Mouse wheel, scrollbar drag, keyboard (click a board, then arrows / Page Down) | Both move together. |
| 5 | Stop scrolling | Both boards show the same top time. |
| 6 | Change zoom, then the date | The boards stay aligned. |

Do it in Chrome, plus Safari if it's available (trackpad coasting differs).
