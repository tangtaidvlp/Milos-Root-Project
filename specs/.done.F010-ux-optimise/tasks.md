---
description: "Tasks for F010 UX optimise (Today board)"
---

# Tasks: UX optimise (Today board)

**Input**: `specs/F010-ux-optimise/` (spec.md, plan.md, research.md, quickstart.md)

**Tests**: Unit test for the new duration util, plus a new Today-board e2e journey and updates to existing e2e (research R7, constitution II).

All paths are relative to `ui-personal-routine-manager/`. There are no setup or foundational phases: each story touches its own files, apart from `BoardToolbar.jsx` (US1 then US3, in that order).

## Phase 1: User Story 1 - Always-live board, no time slider (P1) 🎯 MVP

**Goal**: No slider, no Pause/Resume, no "Paused". The clock always follows real time.

**Independent Test**: On Today, there's no `slider` role and no Pause/Resume button. The clock readout changes with real time.

- [X] T001 [US1] In `src/features/onboarding/hooks/useBoardClock.ts`, reduce `BoardClock` to `{ currentTime: number }` and drop `isLive`, `setIsLive` and `setCurrentTime`. Tick every 60s while `enabled`. Also call `setCurrentTime(getCurrentMinutes())` on `document` `visibilitychange` when `document.visibilityState === 'visible'`, and remove the listener in cleanup. Update the doc comments (no Pause/slider).
- [X] T002 [US1] In `src/features/onboarding/components/BoardToolbar.jsx`, remove `handleSliderChange`, the `.ob-board-slider-wrap` block, the Pause/Resume button and the "Paused" pill. Show `<span className="ui-pill ui-pill-success">Live</span>` whenever `clock` is set. Update the doc comment.
- [X] T003 [P] [US1] In `src/features/onboarding/components/EditingBoard.jsx`, update the comments that mention Pause, Resume or the slider (lines ~66, ~75, ~167) so they describe the always-live clock. No logic change.
- [X] T004 [P] [US1] In `src/App.css`, delete the `.ob-board-slider-wrap` and `.ob-board-slider` rules, plus any `.rf-compare-toolbar .ob-board-slider-wrap` selector that references them.

**Checkpoint**: The Today and compare toolbars show no slider or Pause.

## Phase 2: User Story 2 - No Sign out in page headers (P1)

**Goal**: No page header shows "Sign out". Profile keeps it.

**Independent Test**: Today, Default routine, Analytics and Profile headers have no Sign out. Profile → Sign out goes to `/auth`.

- [X] T005 [P] [US2] In `src/components/layout/PageHeader.tsx`, remove the Sign out button and `onLogout` from the `useShellContext()` destructure. Update the `actions` prop comment and the component doc comment.
- [X] T006 [P] [US2] In `e2e/helpers.ts`, change `signOut` to click `page.getByRole('link', { name: 'Open profile' }).first()`, wait for `/#\/profile/`, then click `page.getByRole('button', { name: 'Sign out' })` and expect `/#\/auth/`.

**Checkpoint**: Sign out is only on Profile.

## Phase 3: User Story 3 - Board tools fold into "More" (P2)

**Goal**: A narrow toolbar shows "+ Add task", "Reflection" and "More". Zoom, Gap clear, Reset day and Clean up sit in the "More" list.

**Independent Test**: Narrow the window. "More" appears, each tool works from it, and Escape closes it with focus back on "More".

- [X] T007 [US3] Create `src/features/onboarding/components/ToolbarMoreMenu.tsx`: `({ children }: { children: ReactNode })`.
  - Local `open` state and `useId()` for the panel id.
  - Wrapper `<div className="ob-board-more">` (position: relative).
  - `<button type="button" className="ui-btn ui-btn-ghost" aria-haspopup="true" aria-expanded={open} aria-controls={id}>More</button>`.
  - When open: `<div id={id} className="ob-board-more-panel">{children}</div>`.
  - Close on Escape (keydown on the wrapper, then focus the More button), on `pointerdown` outside the wrapper (document listener in a `useEffect`, only while open), and on a click inside the panel whose target `closest('button')` is not inside `[data-keep-open]`.
- [X] T008 [US3] In `src/features/onboarding/components/BoardToolbar.jsx` (after T002), add the prop `menuActions = null`.
  - Build a `secondaryTools(inMenu)` fragment: the zoom group (wrapped in `<div data-keep-open>` when `inMenu`), Gap clear, Reset day, then `menuActions`.
  - Inside `.ob-board-toolbar-controls`, render `<div className="ob-board-tools-inline">{secondaryTools(false)}</div>`, then `<ToolbarMoreMenu>{secondaryTools(true)}</ToolbarMoreMenu>`, then the divider and `actions`.
  - Add `menuActions` to the JSDoc.
- [X] T009 [US3] In `src/features/onboarding/components/EditingBoard.jsx`, add a `toolbarMenuActions` prop (JSDoc too) and pass it to `<BoardToolbar menuActions={toolbarMenuActions}>`.
- [X] T010 [US3] In `src/features/daily/pages/DailyRoutinePage.jsx`, in the single-board `EditingBoard`, move `cleanUpButton` out of `toolbarActions` into `toolbarMenuActions={inReflection ? null : cleanUpButton}`. `toolbarActions` keeps `reflectionToggle` and "+ Add task". Leave `CompareBoards` unchanged.
- [X] T011 [US3] In `src/App.css`:
  - `.ob-board-toolbar`: add `container-type: inline-size` and change `flex-wrap` to `nowrap`. `.ob-board-toolbar-controls`: `flex-wrap: nowrap`.
  - `.ob-board-tools-inline { display: flex; align-items: center; gap: var(--space-2) }`.
  - `.ob-board-more { display: none; position: relative }`.
  - `.ob-board-more-panel`: absolute, `top: calc(100% + var(--space-1))`, `right: 0`, `z-index` above the board, `display: flex`, `flex-direction: column`, `align-items: stretch`, `gap: var(--space-1)`, `padding: var(--space-2)`, `background: var(--color-bg-surface)`, `border: 1px solid var(--color-border)`, `border-radius: var(--radius-md)`, `box-shadow: var(--shadow-md)`, `min-width: 180px`. Use only existing tokens (check names in `src/styles/tokens.css`).
  - `@container (max-width: 900px) { .ob-board-tools-inline { display: none } .ob-board-more { display: block } }`.
  - Tune 900px by hand so the widest Today toolbar never wraps.

**Checkpoint**: Quickstart steps 4–6 pass.

## Phase 4: User Story 4 - Task dialog: color and hours + minutes (P2)

**Goal**: Duration as hours + minutes everywhere, and a color picker on Today.

**Independent Test**: On Today, add a 1 h 30 colored task and see the block. A 95-min task opens as 1 h 35.

- [X] T012 [P] [US4] Create `src/features/onboarding/utils/duration.ts`:
  - `splitDuration(total: number): { hours: number; minutes: number }`: floor division. Negative or NaN input gives `{0, 0}`.
  - `joinDuration(hours: number, minutes: number): number`: `hours * 60 + minutes`. NaN parts count as 0.
- [X] T013 [P] [US4] Create `src/features/onboarding/utils/duration.test.ts` (Vitest, Node): split 0, 30, 60, 95, 1440, negative and NaN. Join (1,30)=90, (0,90)=90, (24,0)=1440, NaN parts. A round trip keeps the value.
- [X] T014 [US4] In `src/features/onboarding/components/TaskEditModal.tsx`:
  - Replace the `durationMinutes` state with `hours` and `minutes` state, initialised from `splitDuration(draftTask?.durationMinutes ?? 30)` in the open effect.
  - Replace the "Duration (min)" field with `<fieldset className="ob-modal-field ob-modal-duration"><legend>Duration</legend>`, containing two labelled `type="number"` inputs: "Hours" (min 0, max 24, step 1) and "Minutes" (min 0, max 59, step 1).
  - On submit, `durationMinutes = joinDuration(hours, minutes)`. If it's not 1–1440, show the error `Duration must be between 1 minute and 24 hours.`
- [X] T015 [US4] In `src/App.css`, style `.ob-modal-duration`: no fieldset border or padding, a legend styled like the other field labels, and the two inputs in a row with `gap: var(--space-2)`. Tokens only.
- [X] T016 [US4] In `src/features/daily/pages/DailyRoutinePage.jsx`, remove `showColor={false}` from `TaskEditModal`.
- [X] T017 [US4] In `e2e/reflection.spec.ts`, change `addTask` to fill `dialog.getByLabel('Hours')` with `String(Math.floor(minutes / 60))` and `dialog.getByLabel('Minutes')` with `String(minutes % 60)`, replacing the single `input[type="number"]`.

**Checkpoint**: Quickstart steps 7–9 pass.

## Phase 5: Polish & Verify

- [X] T018 Create `e2e/today-board.spec.ts` (use `registerAndOnboard` from `e2e/helpers.ts`, viewport 1400×900):
  - On Today, expect `getByRole('slider')` count 0, no button named /Pause clock|Resume live/, and no "Sign out" button in `page.locator('.page-header')`.
  - Add a task "Deep work" 09:00, 1 h 30, with the first palette swatch. Expect a `.ob-board-task` containing "Deep work" and "1h 30m" (match `showTaskDuration`'s format in `EditingBoard.jsx`).
  - Set the viewport to 800×900. Expect "+ Add task", "Reflection" and "More" visible, and "Gap clear" hidden. Click More, click Gap clear, expect the panel to close. Reopen and expect Gap clear `aria-pressed="true"`. Press Escape, expect the panel hidden and More focused.
- [X] T019 Run `pnpm lint && pnpm test && pnpm build` in `ui-personal-routine-manager/` and fix failures (e.g. tests or types using `clock.isLive` or `setIsLive`, found with a grep for `isLive|setIsLive|Timeline current time|Duration \(min\)`).
- [X] T020 Run `pnpm test:e2e today-board reflection profile settings-persistence` (backend `SPRING_PROFILES_ACTIVE=fast SPRING_AI_ACTIVE=false ./gradlew bootRun` plus `pnpm dev`). If the servers can't start, report it.
- [X] T021 Update `ui-personal-routine-manager/CLAUDE.md`:
  - "Board live clock": no Pause/slider, always live.
  - Reflection "Board API": no slider; `toolbarMenuActions`/`menuActions` and the "More" menu.
  - "E2E": add `today-board`.
  - `TaskEditModal`: hours + minutes, color shown on Today.
  - Header: no Sign out (Profile only).
- [ ] T022 Hand the manual checks in `specs/F010-ux-optimise/quickstart.md` to the user (threshold tuning, steps 1–11).

## Dependencies

- US1 (T001–T004) → US3 (T007–T011), because both edit `BoardToolbar.jsx`. T008 needs T002 and T007.
- US2 (T005–T006) and US4 (T012–T017) are independent of the other stories.
- T018–T022 run after all stories.

## Parallel Examples

- US1: T003 and T004 alongside T001.
- US2: T005 and T006 together, and with any US1 task.
- US4: T012 and T013 together, then T014 → T015. T016 and T017 can run any time.

## Implementation Strategy

MVP = US1 + US2 (both P1: removals only). Then US4 (dialog), then US3 (the More menu, with tuning by hand). One delivery, verified with quickstart.md.
