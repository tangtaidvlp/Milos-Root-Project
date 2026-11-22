---
description: "Task list for 003 – Live Clock Off During Onboarding"
---

# Tasks: Live Clock Off During Onboarding

**Input**: Design documents from `specs/003-onboarding-time-live-off/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/editing-board.md](./contracts/editing-board.md), [quickstart.md](./quickstart.md)

**Tests**: One pure-logic unit test for the scroll helper (plan R5, repo convention: Vitest, `*.test.ts` next to the code). UI is checked with `quickstart.md`.

**Organization**: Tasks are grouped by user story. All paths are relative to `ui-personal-routine-manager/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Setup

- [X] T001 Record a baseline: run `pnpm test`, `pnpm build` and `pnpm lint` in `ui-personal-routine-manager/` and note the results (expected: 29/29 tests, build OK, 2 existing lint warnings) under "Baseline" at the end of this file

---

## Phase 2: Foundational (blocks US1)

- [X] T002 [P] Write `src/features/onboarding/utils/boardScroll.test.ts` for `scrollTopForMinutes(minutes, boardHeightPx, offsetPx = 0)`: 360 min on a 2400 px board → 600; 0 min → 0; offset larger than the position clamps to 0 (e.g. 60 min, 2400 px, offset 260 → 0); 1440 min on 4800 px → 4800; offset subtracts (720 min, 2400 px, offset 260 → 940)
- [X] T003 Create `src/features/onboarding/utils/boardScroll.ts` exporting `scrollTopForMinutes(minutes: number, boardHeightPx: number, offsetPx = 0): number` = `Math.max(0, (minutes / 1440) * boardHeightPx - offsetPx)`, and `minutesForScrollTop(scrollTop: number, boardHeightPx: number): number` = `scrollTop / boardHeightPx * 1440` (add 2 cases for it to T002's test file); also export `SETUP_SCROLL_ANCHOR_MINUTES = 360` (06:00). Run `pnpm test` until green

**Checkpoint**: helper tested; board work can start.

---

## Phase 3: User Story 1 – Set up routines without a live clock (Priority: P1) 🎯 MVP

**Goal**: on the setup screen the board shows no live clock, highlights no current task, never moves by itself, and opens at 06:00.

**Independent Test**: quickstart scenarios 1–9.

- [X] T004 [US1] In `src/features/onboarding/components/EditingBoard.jsx` add the prop `liveClock = true` to the component's destructured props (contract: `boolean`, default `true`)
- [X] T005 [US1] In `src/features/onboarding/components/EditingBoard.jsx` make the ticking `useEffect` (the 60 s `setInterval` on `isLive`) return early when `liveClock` is `false`, and add `liveClock` to its dependency array (FR-003)
- [X] T006 [US1] In `src/features/onboarding/components/EditingBoard.jsx` render only when `liveClock` is true: the `.ob-board-time` block, the "Pause clock / Resume live" button in `.ob-board-actions`, the `.ob-board-slider-wrap` block, the `.ob-board-now-line` element, and the `.ob-board-status` "Now: …" line (FR-001)
- [X] T007 [US1] In `src/features/onboarding/components/EditingBoard.jsx` compute `isActive` per task as `liveClock && currentTime >= taskStartTime && currentTime < taskEndTime`, and `activeTask` only when `liveClock` is true (FR-002)
- [X] T008 [US1] In `src/features/onboarding/components/EditingBoard.jsx` make the existing auto-scroll-to-now `useEffect` (`[currentTime, boardHeightPx]`) run only when `liveClock` is true; keep its `- 260` formula unchanged for the dashboard
- [X] T009 [US1] In `src/features/onboarding/components/EditingBoard.jsx` add a `useEffect` keyed on `[liveClock, routine?.id]` that, when `liveClock` is false and `routine?.id` is set, sets `containerRef.current.scrollTop = scrollTopForMinutes(SETUP_SCROLL_ANCHOR_MINUTES, boardHeightPx)` (FR-004; a save keeps the same id, so it does not re-scroll). Read `boardHeightPx` through a ref or exclude it from deps so zoom does not trigger this effect
- [X] T010 [US1] In `src/features/onboarding/components/EditingBoard.jsx` keep the top time of day in place on zoom when `liveClock` is false (research R4): keep a ref with the previous `boardHeightPx`; in a `useLayoutEffect` on `boardHeightPx`, compute `minutesForScrollTop(scrollTop, previousHeight)` and set `scrollTop = scrollTopForMinutes(thatMinute, boardHeightPx)`, then update the ref. Do nothing when `liveClock` is true
- [X] T011 [US1] In `src/features/onboarding/pages/OnboardingPage.jsx` pass `liveClock={false}` to `<EditingBoard>`
- [X] T012 [US1] Run `pnpm build` and `pnpm lint`; fix any new errors or warnings in the files above

**Checkpoint**: setup screen has no live clock and opens at 06:00.

---

## Phase 4: User Story 2 – The daily dashboard keeps its live clock (Priority: P1)

**Goal**: dashboard unchanged.

**Independent Test**: quickstart scenario 10.

- [X] T013 [US2] Confirm `src/features/daily/pages/DailyRoutinePage.jsx` does not pass `liveClock` (default `true`), and review the diff of `src/features/onboarding/components/EditingBoard.jsx` to check every `liveClock === true` path matches the old code exactly (FR-006)

---

## Phase 5: Polish & Cross-Cutting

- [X] T014 [P] Add one line under "Feature behavior → onboarding" in `ui-personal-routine-manager/CLAUDE.md`: the board's live clock is off on the setup screen (`EditingBoard liveClock={false}`), which opens at 06:00; the dashboard keeps it
- [X] T015 Run all quickstart scenarios 1–10 in `specs/003-onboarding-time-live-off/quickstart.md` (desktop 1440×900 and phone 390×844), by hand or with a headless Chrome script in the session scratchpad; record results under "Validation notes" at the end of this file
- [X] T016 Final run of `pnpm test`, `pnpm build`, `pnpm lint` and compare with the T001 baseline

---

## Dependencies & Execution Order

- T001 → T002/T003 → T004–T011 (same file, in order) → T012 → T013 → T014–T016
- US2 depends on US1 (it verifies the same component edit did not change the dashboard)
- No backend work

### Parallel Opportunities

- T002 (test) can be written alongside T001
- T014 (docs) can be done alongside T013 or T015

## Implementation Strategy

US1 is the MVP and the whole feature; US2 is its regression guard. Ship both together.

## Baseline

- `pnpm test`: 29/29 passed
- `pnpm build`: OK
- `pnpm lint`: 0 errors, 2 existing warnings (`EditingBoard.jsx` redundant `Boolean` call; `DailyRoutinePage.jsx` missing hook dependency)

## Validation notes

Headless Chrome (system Chrome via playwright-core, scratchpad script `liveclock-check.cjs`) against the dev app on :5173 and backend on :8080, fresh user with a 3 h weekday task covering the current time: **23/23 checks passed**, rows 1–10, desktop 1440×900 and phone 390×844. Row 5 waited 65 s (one clock tick), not 5 min.

Final run: `pnpm test` 36/36 (29 + 7 new in `boardScroll.test.ts`), `pnpm build` OK, `pnpm lint` the same 2 existing warnings.

Deviations:
- The board opens with 06:00 **16 px below the top** (`SETUP_SCROLL_OFFSET_PX`), not exactly at the top: the hour labels are centred on their line, so 06:00 at the very top showed only half its label. Matches the mockup.
- `boardScroll.ts` also exports `minutesForScrollTop` (used for zoom anchoring, R4), with 2 extra tests.
- The fresh-browser "Refresh token not found" console message (silent re-auth with no cookie) is expected and was ignored, as in feature 002.
