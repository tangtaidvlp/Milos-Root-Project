# Quickstart: Radial 24H View

## Run

```bash
cd ms-personal-routine-manager && SPRING_PROFILES_ACTIVE=fast SPRING_AI_ACTIVE=false ./gradlew bootRun
cd ui-personal-routine-manager && pnpm dev
```

Checks: `pnpm lint && pnpm test && pnpm test:e2e e2e/radial-view.spec.ts`

## Manual checks

| # | Do | Expect | Spec |
|---|---|---|---|
| 1 | Today → **Circle** | 24h circle, midnight at top, clockwise; every task a slice in its colour; name + time outside, joined by a line | US1-1/2, FR-003/004 |
| 2 | Add 8 tasks of 15 min in a row (07:00–09:00) | All 8 labels readable, none overlap; chart grows taller if needed | SC-002 |
| 3 | Task 23:00 + 8h | One slice over the top, one label | Edge case |
| 4 | Click a slice, then Tab to a label and press Enter | Task edit dialog opens both times; save → circle updates without reload | FR-005, FR-009 |
| 5 | Mark a task done (Buddy or timeline), back to Circle | Slice faded, label shows check | Edge case |
| 6 | Reload | Circle still selected; Default routine also opens in Circle | FR-002 |
| 7 | Widths 320 / 768 / 1366 (devtools) | Circle shrinks, text size unchanged, no sideways scroll | FR-004, SC-001 |
| 8 | Reflection on, ≥ 1280px | Plan and Reality circles side by side; clicks edit the right board | US2-2, FR-008 |
| 9 | Reflection, < 1280px | One Reality circle; tap opens the reflection popup | US2-3/4 |
| 10 | Default routine → Weekday/Weekend | Circle follows the tab; "Copy Weekday to Weekend" still in toolbar | US2-1 |
| 11 | Type a message without sending → **Hide Buddy chat** → **Show Buddy chat** | Board grows; chat returns with thread and typed text | US3, FR-011 |
| 12 | Hide chat, reload, open Default routine | Still hidden | US3-3 |
| 13 | ≤ 760px | No hide button; board/chat swap works as before | Edge case |
| 14 | Dark theme, keyboard only | Text readable, focus visible on switch, labels, hide/show | FR-012 |
| 15 | Onboarding setup screen | Unchanged: timeline only, no switch | Plan structure decision |
