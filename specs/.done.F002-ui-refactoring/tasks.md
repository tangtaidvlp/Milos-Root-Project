---

description: "Task list for F002 UI Refactoring – Sidebar Navigation and Visual Refresh"
---

# Tasks: UI Refactoring – Sidebar Navigation and Visual Refresh

**Input**: Design documents from `specs/F002-ui-refactoring/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Visual reference**: [resources/Sidebar-Design.png](./resources/Sidebar-Design.png)

**Tests**: The spec does not ask for TDD. The plan does include unit tests for pure logic: Vitest, `*.test.ts` next to the code, Node environment and no DOM, per `ui-personal-routine-manager/CLAUDE.md`. Those tests are listed in the tasks that create the logic. UI behaviour is checked by hand with [quickstart.md](./quickstart.md).

**Organization**: Tasks are grouped by user story so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story from spec.md (US1–US4)

## Path Conventions

All paths are relative to the workspace root. Frontend code is under `ui-personal-routine-manager/src/`, shortened below to `ui/src/` **only in this note**. Every task spells out the full path `ui-personal-routine-manager/src/...`. Commands run in `ui-personal-routine-manager/` with `pnpm`.

Conventions to follow in every task (from `ui-personal-routine-manager/CLAUDE.md` and `codingrules.md`):
- New files are `.ts` / `.tsx`; use `import type` for type-only imports (`verbatimModuleSyntax`).
- All HTTP goes through `src/lib/api.ts`. This feature adds **no** new API calls.
- Use semantic tokens from [contracts/style-tokens.md](./contracts/style-tokens.md) in all new CSS. Never use raw hex or rgba outside `src/styles/tokens.css`.
- Keep the walkthrough `data-tour` attributes: `schedule-switch`, `routine-board`, `add-task`, `routine-buddy`, `finish`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the folders and the design-token files that everything else styles against.

- [X] T001 Create folders `ui-personal-routine-manager/src/styles/`, `ui-personal-routine-manager/src/components/layout/`, `ui-personal-routine-manager/src/features/default-routine/pages/`, `ui-personal-routine-manager/src/features/analytics/pages/`, `ui-personal-routine-manager/src/features/daily/utils/`, `ui-personal-routine-manager/src/features/onboarding/hooks/`
- [X] T002 Create `ui-personal-routine-manager/src/styles/tokens.css` with a `:root` block holding the two tiers from [contracts/style-tokens.md](./contracts/style-tokens.md). (1) **Primitives**: every raw colour value lives here, seeded from the contract (`--color-blue-600: #1F6FDB`, `--color-slate-200: #E6EBF2`, `--color-red-500: #E04848`, `--color-green-500: #34C38F`, `--color-purple-500: #7C5CE6`, …). Add 8 task-tint accent/bg primitive pairs (green, peach, blue, grey, slate, orange, pink, purple), sampled by eye from `specs/F002-ui-refactoring/resources/Sidebar-Design.png`. (2) **Semantic tokens**: every group in the contract table (surfaces, borders, text, accent, status, board incl. `--color-task-{1..8}-accent`/`-bg`, `--color-now-line`, `--color-task-current`, chat, `--focus-ring`, type scale with `--font-family: 'Poppins', system-ui, sans-serif`, `--space-1..8` on a 4px scale, `--radius-sm|md|lg|pill`, `--shadow-sm|md|lg`, `--sidebar-width: 232px`, `--sidebar-rail-width: 56px`, `--chat-panel-width: 360px`, `--header-height`, `--z-sidebar|backdrop|modal|tour`). Semantic tokens may only reference primitives via `var(...)`
- [X] T003 Create `ui-personal-routine-manager/src/styles/base.css` with: box-sizing reset (move it from `src/index.css`), `html, body` font/colour/background from semantic tokens, a global `:focus-visible { outline: none; box-shadow: var(--focus-ring); }`, and shared component classes `.btn`, `.btn-primary`, `.btn-ghost`, `.btn-danger-text`, `.icon-btn`, `.card`, `.pill`, `.pill-success`, `.segmented`/`.segmented-btn` (active state), all styled only with semantic tokens and matching the design's buttons ("+ Add task" = primary, "Today" = outlined, "Clean up" = danger text, zoom −/+ = icon buttons)
- [X] T004 Update `ui-personal-routine-manager/src/index.css` so it starts with `@import './styles/tokens.css';` and `@import './styles/base.css';`. Turn every existing custom property (`--font`, `--white`, `--bg`, `--text`, `--text-dark`, `--blue-light`, `--blue-mid`, `--blue-primary`, `--blue-dark`, `--coral`, `--yellow`, `--yellow-dark`, `--gray-100|200|400`, `--shadow-*`, `--radius-*`) into an alias of the closest semantic token (e.g. `--blue-primary: var(--color-accent);`) and put a `/* legacy alias – remove when unused (T044) */` comment above them. Remove the rules now covered by `base.css`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared pure logic, icons and the token checks that several stories depend on.

**⚠️ CRITICAL**: Finish this phase before starting any user story.

- [X] T005 [P] Create `ui-personal-routine-manager/src/features/onboarding/utils/routineTypeForDate.ts` exporting `routineTypeForDate(date: Date): RoutineType` (import type `RoutineType` from `../api/defaultRoutine.ts`): Saturday or Sunday → `'WEEKEND'`, otherwise `'DAILY'`. This mirrors `DefaultRoutineService` line 118 in `ms-personal-routine-manager`; say so in a comment. Also export `routineTypeLabel(type: RoutineType): string` with `DAILY` → "Weekday routine" and `WEEKEND` → "Weekend routine". Add `routineTypeForDate.test.ts` next to it covering Mon–Sun and both labels
- [X] T006 [P] Create `ui-personal-routine-manager/src/styles/contrast.ts` exporting `parseHex(hex: string): [r,g,b]`, `relativeLuminance(rgb)` and `contrastRatio(hexA, hexB): number` (WCAG 2.x formula), plus `readTokens(cssText: string): Record<string,string>` that parses `--name: value;` pairs from `tokens.css` and resolves `var(--x)` chains to the final hex. Add `contrast.test.ts`: unit-test the maths (black/white = 21, same colour = 1), then read `src/styles/tokens.css` with `node:fs`. Assert ≥ 4.5 for each pair in the "Contrast pairs" list of [contracts/style-tokens.md](./contracts/style-tokens.md) (including `--color-text-primary` on each `--color-task-{1..8}-bg`), and ≥ 3 for `--color-text-muted` on `--color-bg-surface`. Adjust token values in `tokens.css` until it passes
- [X] T007 [P] Create `ui-personal-routine-manager/src/styles/noRawColors.test.ts`. Recursively read every `.css`, `.ts`, `.tsx`, `.jsx` file under `src/` with `node:fs`, skipping `src/styles/tokens.css` and `*.test.ts`. Fail if a line matches `/#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(/`, and print `file:line` for each hit. Support an allowlist constant naming `src/features/auth/pages/AuthPage.tsx` lines inside the Google, Facebook and Apple logo components only. Add a temporary `KNOWN_VIOLATION_FILES` set holding `src/App.css`, `src/features/onboarding/components/EditingBoard.jsx` and `src/features/auth/pages/AuthPage.tsx`, skipped with a `// TODO(T044): empty this set` comment, so the suite is green until the migration tasks empty it
- [X] T008 [P] Add `MenuIcon` (burger, three lines), `PanelLeftIcon` (sidebar collapse/expand) and `XIcon` (close) to `ui-personal-routine-manager/src/components/icons/Icons.tsx`, following the existing 24×24 `currentColor` pattern there, and export them from `ui-personal-routine-manager/src/components/icons/index.ts`

**Checkpoint**: `pnpm test` is green with tokens in place. User stories can now start.

---

## Phase 3: User Story 1 – Navigate between areas from a sidebar (Priority: P1) 🎯 MVP

**Goal**: Onboarded users get a persistent sidebar (Today, Default routine, Analytics "Soon", Replay tour, user block) with its own address per page, collapsible on wide screens with the choice remembered.

**Independent Test**: [quickstart.md](./quickstart.md) §2, §3 and §7. Sign in as an onboarded user and land on `/#/today` with the sidebar showing. Click each entry and check the address and highlight follow. Use Back/Forward and reload. Hide the sidebar, reload, and check it stays hidden. A user who isn't onboarded sees no sidebar.

### Implementation for User Story 1

- [X] T009 [P] [US1] Create `ui-personal-routine-manager/src/components/layout/sidebarPreference.ts` exporting `SIDEBAR_COLLAPSED_KEY = 'milos.sidebar.collapsed'`, `readSidebarCollapsed(storage: Pick<Storage,'getItem'> | null | undefined): boolean` and `writeSidebarCollapsed(storage, value: boolean): void`. Rules from [data-model.md §2](./data-model.md): values `"true"` / `"false"`; "Missing, unreadable or any other value → `false`. Storage access that throws → `false`"; "write failures are ignored" (wrap in try/catch). Add `sidebarPreference.test.ts` covering `"true"`, `"false"`, missing, garbage, a throwing `getItem`, a throwing `setItem`, and `null` storage
- [X] T010 [P] [US1] Create `ui-personal-routine-manager/src/components/layout/navEntries.ts` exporting type `NavEntry = { id: 'today' | 'default-routine' | 'analytics'; label: string; path: string; icon: ComponentType<IconProps>; badge?: string }` and `NAV_ENTRIES` in this fixed order: `{ id:'today', label:'Today', path:'/today', icon: CalendarIcon }`, `{ id:'default-routine', label:'Default routine', path:'/default-routine', icon: RepeatIcon }`, `{ id:'analytics', label:'Analytics', path:'/analytics', icon: BarChartIcon, badge:'Soon' }` (icons from `src/components/icons/index.ts`)
- [X] T011 [US1] Create `ui-personal-routine-manager/src/components/layout/useSidebar.ts` returning `{ isMobile, isCollapsed, isMobileOpen, toggleCollapsed, openMobile, closeMobile }` per [data-model.md §3](./data-model.md). Set `isMobile` from `window.matchMedia('(max-width: 760px)')` and subscribe to `change`. Read `isCollapsed` initially with `readSidebarCollapsed(safeLocalStorage())`, where `safeLocalStorage` returns `null` if touching `window.localStorage` throws; `toggleCollapsed` flips it and calls `writeSidebarCollapsed`. `isMobileOpen` starts `false` and is never stored. When the media query changes wide→narrow set `isMobileOpen=false`; on narrow→wide re-read the stored preference. Close the mobile overlay on route change (`useLocation().pathname` effect). Depends on T009
- [X] T012 [US1] Create `ui-personal-routine-manager/src/components/layout/Sidebar.tsx` per [contracts/ui-shell.md](./contracts/ui-shell.md) "Sidebar". Props: `{ user: AuthUser; isCollapsed: boolean; isMobile: boolean; isMobileOpen: boolean; onToggleCollapsed(): void; onCloseMobile(): void; onReplayTour(): void }`. Render `<aside id="app-sidebar">` containing, top to bottom: the brand ("M" square mark plus "Milos"); a "PLAN" section label; `<nav aria-label="Main">` listing `NAV_ENTRIES` as React Router `NavLink`s (icon, label, optional `.pill` badge; active class from `NavLink`, which also sets `aria-current="page"`; `onClick` calls `onCloseMobile` when `isMobile`); a spacer; a "Replay tour" button with `SparkIcon` calling `onReplayTour`; a user block with an avatar circle showing the first letter of `user.name || user.email`, the name with CSS ellipsis, and `routineTypeLabel(routineTypeForDate(new Date()))` (T005); and on wide screens a collapse button (`PanelLeftIcon`, `aria-label="Hide sidebar"`). When `isCollapsed && !isMobile`, render only a slim rail with a "Show sidebar" button (`aria-label="Show sidebar"`, `aria-expanded="false"`, `aria-controls="app-sidebar"`)
- [X] T013 [P] [US1] Create `ui-personal-routine-manager/src/components/layout/PageHeader.tsx`. Props: `{ children?: ReactNode; actions?: ReactNode; onLogout(): void; showMenuButton: boolean; onOpenMenu(): void; menuButtonRef?: Ref<HTMLButtonElement> }`. Render `<header className="page-header">` with: on the left a burger `.icon-btn` (`MenuIcon`, `aria-label="Open menu"`, `aria-controls="app-sidebar"`), shown only when `showMenuButton`, followed by `children` (the page's title area); on the right `actions` followed by a "Sign out" `.btn-ghost` that calls `onLogout` (FR-010)
- [X] T014 [US1] Create `ui-personal-routine-manager/src/components/layout/AppShell.tsx`, a layout route component. It reads `user` from `AuthContext` and takes `onLogout` as a prop, and owns `useSidebar()` (T011) and `useWalkthrough()` (from `src/features/walkthrough/hooks/useWalkthrough.ts`). Render `<div className="app-shell" data-sidebar={isMobile ? (isMobileOpen ? 'open' : 'closed') : (isCollapsed ? 'collapsed' : 'expanded')}>` containing `<Sidebar … onReplayTour={() => walkthrough.open('app')} />`, `<main className="app-shell-main"><Outlet context={...} /></main>` and `<IntroSlides state={walkthrough.state} dispatch={walkthrough.dispatch} />`. Export `type ShellOutletContext = { user: AuthUser; onLogout: () => void; openSidebar: () => void; isMobile: boolean }` exactly as in [contracts/ui-shell.md](./contracts/ui-shell.md), plus a `useShellContext()` helper wrapping `useOutletContext<ShellOutletContext>()`
- [X] T015 [P] [US1] Create `ui-personal-routine-manager/src/components/layout/AppShell.css` and import it from `AppShell.tsx`. Wide screens: CSS grid `var(--sidebar-width) 1fr`, switching to `var(--sidebar-rail-width) 1fr` when `[data-sidebar="collapsed"]`, with a width transition that respects `prefers-reduced-motion`. The sidebar has white surface, a right border of `--color-border`, full height and sticky position. Nav item styles match the design: icon + label, `--radius-md`, hover on `--color-bg-subtle`, active state with `--color-accent-soft` background and `--color-accent` text. Section label "PLAN" is uppercase `--font-size-xs` in `--color-text-muted`. The user block sits at the bottom. `.page-header` is laid out per the design (title block left, actions and Sign out right). Use semantic tokens only
- [X] T016 [P] [US1] Create `ui-personal-routine-manager/src/features/analytics/pages/AnalyticsPage.tsx`. Use `useShellContext()` and render `<PageHeader showMenuButton={isMobile} onOpenMenu={openSidebar} onLogout={onLogout}><h1>Analytics</h1></PageHeader>`, then one centred `.card` with `BarChartIcon`, the heading "Analytics is coming soon" and the line "Soon you'll see how your days compare to your routine." Make no data requests (FR-014)
- [X] T017 [US1] Refactor routing in `ui-personal-routine-manager/src/app/App.tsx` per [contracts/routes.md](./contracts/routes.md):
  - Add a `RequireOnboarded` element that redirects to `/auth` when signed out and to `/onboarding` when not onboarded, using `<Navigate replace>`, and otherwise renders `<AppShell onLogout={handleLogout} />`.
  - Under it add child routes `today` → `DailyRoutinePage`, `default-routine` → a temporary `<div>` placeholder that T026 replaces, and `analytics` → `AnalyticsPage`.
  - Change `authenticatedTarget` to `'/today'`. Make `/onboarding` redirect onboarded users to `/today`. Add `/dashboard` → `<Navigate to="/today" replace />` when onboarded (otherwise apply the same guard).
  - Remove the old inline `/dashboard` route.
  - Keep `HashRouter` in `src/main.tsx` unchanged.
- [X] T018 [US1] Update `ui-personal-routine-manager/src/features/daily/pages/DailyRoutinePage.jsx` to live inside the shell:
  - Remove `LogoMark`, the "Routine Canvas" brand, `HowItWorksButton`, `useWalkthrough` and `IntroSlides` (the shell owns them now).
  - Read `user`, `onLogout`, `openSidebar` and `isMobile` from `useShellContext()` instead of props.
  - Replace the old `dr-topbar` with `<PageHeader showMenuButton={isMobile} onOpenMenu={openSidebar} onLogout={onLogout}>…</PageHeader>`, temporarily wrapping the existing date bar. US3 restyles it.
  - Leave all other behaviour unchanged.
- [X] T019 [US1] Update `ui-personal-routine-manager/CLAUDE.md`: route table (`/today`, `/default-routine`, `/analytics`, `/dashboard` redirect, single `RequireOnboarded` guard), new `src/components/layout/` shell, `src/styles/tokens.css` rule ("no raw colours outside tokens.css; enforced by `noRawColors.test.ts`"), and walkthrough replay now in the sidebar

**Checkpoint**: US1 works on its own. Run quickstart §2, §3 and §7 (Replay tour). Default routine shows a placeholder until US2 is done.

---

## Phase 4: User Story 2 – Edit the default routine after onboarding (Priority: P2)

**Goal**: An onboarded user can view and edit their Weekday and Weekend default routines from the sidebar, using the onboarding editor without Buddy chat and without "Ready to roll".

**Independent Test**: [quickstart.md](./quickstart.md) §5, plus §7's onboarding tour check (the extraction must not break it).

### Implementation for User Story 2

- [X] T020 [US2] Create `ui-personal-routine-manager/src/features/onboarding/hooks/useDefaultRoutines.ts` by moving the default-routine state and logic out of `OnboardingPage.jsx` without changing behaviour:
  - State: `scheduleMode` (`'weekday' | 'weekend'`, type `ScheduleTab` from `../utils/routineTypeForTab.ts`), `routines` (`{ weekday, weekend }`), `routineError` and `taskModalState`.
  - Logic: `refreshRoutine(tab, { keepError })`, `handleSaveError`, `handleDeleteTask`, open/close modal helpers, the initial load of both tabs, `submitTask(mode, task)`, which calls `createDefaultTasks(activeRoutine.id, [task])` or `updateDefaultTasks([task])`, and `persistTaskChange(tasks)`, which calls `updateDefaultTasks` then `refreshRoutine`.
  - Keep the exact messages: `LOAD_ERROR = "Couldn't load your routine."` and `SAVE_ERROR = "Couldn't save that change."`, with the rule "On failure the last loaded routine stays on screen; it is never replaced by an empty one" and the rule that a save error is never overwritten by a load error.
  - Signature: `useDefaultRoutines(userId: string)`.
- [X] T021 [US2] Create `ui-personal-routine-manager/src/features/onboarding/components/DefaultRoutineEditor.tsx` per [contracts/ui-shell.md](./contracts/ui-shell.md) "DefaultRoutineEditor":
  - Props: `{ userId: string; headerActions?: ReactNode; renderAside?: (ctx: { scheduleMode; routines; refreshRoutine }) => ReactNode; mobileView?: 'board' | 'chat'; onMobileViewChange?: (v) => void; renderTitleArea?: (switcher: ReactNode) => ReactNode }`.
  - Uses `useDefaultRoutines`.
  - Renders: the Weekday/Weekend `.segmented` switch (`role="tablist"`, `aria-label="Schedule type"`, `data-tour="schedule-switch"`); the error banner (`role="alert"`) with Retry, which reloads both tabs; a board card `data-tour="routine-board"` with the title "Weekday Routine"/"Weekend Routine" and the existing `BOARD_SUBTITLE` text; `EditingBoard` with `liveClock={false}`; and `TaskEditModal` wired to the hook.
  - Add task: a "+ Add task" `.btn-primary` on wide screens, plus the existing `FabButton` with `tourId="add-task"`, disabled while `!activeRoutine?.id`, using `nextDefaultDraftTask` moved from the page.
  - Then renders `renderAside?.(…)`.
- [X] T022 [US2] Rewire `ui-personal-routine-manager/src/features/onboarding/pages/OnboardingPage.jsx` to compose `<DefaultRoutineEditor>`:
  - Pass `headerActions` = `HowItWorksButton` plus the "Ready to roll" button (`data-tour="finish"`, `isCompleting` label unchanged).
  - Pass `renderAside` = one `BuddyChat` per tab, with the inactive one hidden, `tourId="routine-buddy"` on the active one, and `onAfterSend` refreshing that tab and setting `mobileView` to `'board'`, all as today.
  - Pass `mobileView` and `onMobileViewChange`.
  - Keep `completeError`, the chat FAB, "View schedule", the "Planning for …" footer, `IntroSlides` and `GuidedTour`.
  - Delete the logic moved in T020/T021.
  - Replace "R / Routine Canvas" with the "M / Milos" brand.
  - Verify every `data-tour` value still exists exactly once in the rendered page.
- [X] T023 [P] [US2] Create `ui-personal-routine-manager/src/features/default-routine/pages/DefaultRoutinePage.tsx`:
  - Use `useShellContext()`.
  - Render `<DefaultRoutineEditor userId={user.id} renderTitleArea={(switcher) => <PageHeader showMenuButton={isMobile} onOpenMenu={openSidebar} onLogout={onLogout}><h1>Default routine</h1>{switcher}</PageHeader>} />`.
  - Pass no `renderAside` and no finish action (FR-013).
  - If `user?.id` is missing, render nothing until it arrives.
- [X] T024 [P] [US2] Style the Default Routine page and editor in `ui-personal-routine-manager/src/App.css` (new section `/* ── Default routine editor (F002) ── */`). The board card fills the main column when there is no aside; the header row holds the title and the Weekday/Weekend switch. Use semantic tokens only
- [X] T025 [US2] Empty-state check in `ui-personal-routine-manager/src/features/onboarding/components/DefaultRoutineEditor.tsx`: when the active routine loads with zero tasks, show the board with a short hint, "No tasks yet – add one with + Add task", and no error (spec edge case)
- [X] T026 [US2] Replace the temporary `default-routine` placeholder route in `ui-personal-routine-manager/src/app/App.tsx` with `DefaultRoutinePage`

**Checkpoint**: Quickstart §5 passes. Onboarding with a new account still shows slides plus the guided tour, and every tour step points at the right element (§7).

---

## Phase 5: User Story 3 – Refreshed, consistent look across the app (Priority: P2)

**Goal**: The Daily Routine page matches `resources/Sidebar-Design.png`, and every screen (auth, onboarding, walkthrough, daily) uses the shared tokens with no raw colours left.

**Independent Test**: [quickstart.md](./quickstart.md) §6, §8 and §9. Compare the Daily page with the design at 1440×900, change `--color-accent` once and see it update everywhere, and check that `noRawColors` passes with an empty known-violations set.

### Implementation for User Story 3

- [X] T027 [P] [US3] Create `ui-personal-routine-manager/src/features/daily/utils/nowAndNext.ts` per [data-model.md §5](./data-model.md):
  - Export `nowAndNext(tasks: { name: string; startTime?: string; endTime?: string }[], minutesOfDay: number): { now: { name: string; minutesLeft: number } | null; next: { name: string; startTime: string } | null }`.
  - `now` is the task with `start ≤ minutes < end`, choosing the one that started last when tasks overlap.
  - `next` is the task with the smallest `start > minutes`.
  - "Tasks with no valid start time are ignored. An end time of `00:00` means end of day."
  - Also export `formatMinutesLeft(n)`: under 60 gives `"18 min left"`, otherwise `"1h 5m left"`.
  - Add `nowAndNext.test.ts` covering: no tasks, before the first task, inside a task, overlapping tasks, the gap between tasks, after the last task, an end time of `00:00`, an invalid start time, and both `formatMinutesLeft` branches.
- [X] T028 [US3] Extend `ui-personal-routine-manager/src/features/onboarding/components/EditingBoard.jsx` per [contracts/ui-shell.md](./contracts/ui-shell.md) "EditingBoard additions":
  - (a) New prop `toolbarActions` rendered at the right end of `.ob-board-toolbar`.
  - (b) New prop `showFooter` (default = `liveClock`) that renders a footer with "Now" (muted label), `{name} · {formatMinutesLeft}` on the left and "Next: {name} at {HH:MM}" on the right, using `nowAndNext(tasks, currentTime)` from T027. Hide either side when it is `null`. Remove the old `ob-board-status` "Now: …" line.
  - (c) Toolbar order as in the design: clock readout + a "Live" `.pill-success` (shown while live), zoom − / "100%" / +, "Pause clock"/"Resume live", "Gap clear" (rename the label from "Gap Clear"; active state still marked), then "Reset day" and the time slider restyled as secondary controls (kept for FR-011), then `toolbarActions`.
  - (d) Delete the `basePalette` hex array. Give each task card CSS variables `--task-accent: task.color ?? var(--color-task-{(index % 8) + 1}-accent)` and `--task-bg: color-mix(in srgb, var(--task-accent) 12%, var(--color-bg-surface))` when `task.color` is set, else `var(--color-task-{n}-bg)`. Cards use `background: var(--task-bg)` with a 4px left bar in `var(--task-accent)`.
  - (e) Add classes: `is-completed` (faded text, success check) and `is-current` (outline `--color-task-current`).
  - (f) The now-line uses `--color-now-line`, with a time pill showing `HH:MM` on the hour gutter.
  - Keep every existing prop and behaviour.
- [X] T029 [US3] Restyle the Daily header in `ui-personal-routine-manager/src/features/daily/pages/DailyRoutinePage.jsx` inside `PageHeader` children, per the design:
  - A breadcrumb: "Today" (or the weekday name when another date is selected) · `routineTypeLabel(routineTypeForDate(parseDateInputValue(selectedDate)))`.
  - Under it: a ‹ `.icon-btn` (`ChevronLeftIcon`, `aria-label="Previous day"`), the date heading `Thursday, 19 Nov 2026` (format with `toLocaleDateString('en-GB', { weekday:'long', day:'numeric', month:'short', year:'numeric' })`) that wraps a visually hidden `<input type="date">` so clicking it opens the native picker, a › `.icon-btn` (`aria-label="Next day"`), and a "Today" `.btn` that sets the date to today, disabled when the selected date is today.
  - Remove the old `.dr-date-bar`.
- [X] T030 [US3] In `ui-personal-routine-manager/src/features/daily/pages/DailyRoutinePage.jsx`, pass `toolbarActions` to `EditingBoard`:
  - "Clean up" as a `.btn-danger-text` with the existing `handleCleanUp`, disabled when there are no tasks.
  - "+ Add task" as a `.btn-primary` calling `openCreateTaskModal(nextDefaultDraftTask())`.
  - Keep `FabButton` but show it only on narrow screens (CSS).
  - Keep the `BuddyChat` props as they are, but change its subtitle to `Here to help with ${short date}` (e.g. "Thu, 19 Nov").
- [X] T031 [US3] Rewrite the `/* ── Daily Routine Management ── */` section of `ui-personal-routine-manager/src/App.css` (from `.dr-page` to the end of its media queries) for the new layout:
  - Three columns on wide screens: the shell sidebar, the main column (header + board card with toolbar, scroll area and footer), and the Buddy panel at `var(--chat-panel-width)` with a left border.
  - Keep the existing `data-mobile-view` board/chat swap at ≤ 760px.
  - Use semantic tokens only.
- [X] T032 [US3] Migrate the board styles (`.ob-board-*`, `.ob-timeline-board`) in `ui-personal-routine-manager/src/App.css` to tokens and the new card look (T028): hour gutter text `--color-text-muted`, hour lines `--color-border`, task card radius `--radius-md`, `.is-completed`, `.is-current`, now-line + pill, footer bar. Remove `EditingBoard.jsx` from `KNOWN_VIOLATION_FILES` in `noRawColors.test.ts` once it has no literals
- [X] T033 [P] [US3] Restyle `ui-personal-routine-manager/src/features/onboarding/components/BuddyChat.jsx` styles (`.ob-buddy-*`, `.ob-message*`, `.ob-send-btn`, `.ob-typing*` in `ui-personal-routine-manager/src/App.css`) to match the design's "Routine Buddy" panel: spark avatar circle on `--color-accent-soft`, bot bubbles on `--color-chat-bot-bg` with a border, user bubbles `--color-chat-user-bg`/`--color-chat-user-text`, rounded input `--radius-pill`, round send button `--color-accent`. Tokens only
- [X] T034 [US3] Migrate the remaining `ui-personal-routine-manager/src/App.css` sections to semantic tokens, one section at a time: "Page layout", "Logo", "Decorative background", "Auth card", "Hero panel", "Forms panel", "Input fields", "Buttons", "Links & footer", "Social login", "Spinner & loading button", "Alert styling", "Onboarding" (`.ob-*`), "Walkthrough: intro slides", "Walkthrough: guided tour", "Onboarding: board subtitle + routine load/save error" and "Walkthrough: 'How it works' top-bar link". Replace every hex/rgba with the closest semantic token, and add a semantic token in `tokens.css` if none fits. Restyle buttons, inputs and cards to the shared `.btn`/`.card` look so the auth and onboarding screens match the shell (FR-018)
- [X] T035 [US3] Delete the unused "Control Centre Dashboard" block (`.cc-*`, from the `/* ── Control Centre Dashboard ── */` comment through the end of its `@media (max-width: 900px)` block) from `ui-personal-routine-manager/src/App.css`. First confirm with `grep -rn "cc-" ui-personal-routine-manager/src` that no component uses those classes
- [X] T036 [US3] Replace the raw fills and strokes in the illustration SVG of `ui-personal-routine-manager/src/features/auth/pages/AuthPage.tsx` with `var(--…)` semantic tokens (add `--color-illustration-*` tokens to `tokens.css` if needed). Keep the Google, Facebook and Apple brand logo colours as they are, and narrow the `noRawColors` allowlist to exactly those logo components. Replace any "Routine Canvas" branding on the auth screen with "Milos"
- [X] T037 [US3] Remove `src/App.css` and `src/features/auth/pages/AuthPage.tsx` from `KNOWN_VIOLATION_FILES` in `ui-personal-routine-manager/src/styles/noRawColors.test.ts`, delete the now-empty set and its TODO, and fix any remaining hits until `pnpm test` is green

**Checkpoint**: Quickstart §6 (side-by-side with the design plus the regression list), §8 and §9 pass, and `noRawColors` is green with no exceptions beyond the brand logos.

---

## Phase 6: User Story 4 – Sidebar on small screens (Priority: P3)

**Goal**: At ≤ 760px the sidebar starts hidden and opens from a burger as an overlay. Picking an entry, tapping the backdrop or pressing Escape closes it, and focus returns to the burger.

**Independent Test**: [quickstart.md](./quickstart.md) §4 at 375px and while resizing.

### Implementation for User Story 4

- [X] T038 [US4] In `ui-personal-routine-manager/src/components/layout/AppShell.tsx`, when `isMobile && isMobileOpen`, render a backdrop `<div className="app-shell-backdrop" onClick={closeMobile} />` and set `inert` on `.app-shell-main`. Add a `keydown` listener for Escape that calls `closeMobile`, active only while open. Keep a ref to the burger button: pass `menuButtonRef` through the outlet context (add `menuButtonRef: RefObject<HTMLButtonElement | null>` to `ShellOutletContext` and update [contracts/ui-shell.md](./contracts/ui-shell.md) to match) and return focus to it on close
- [X] T039 [US4] In `ui-personal-routine-manager/src/components/layout/Sidebar.tsx`, when `isMobile`: hide the collapse/rail controls; add a close `.icon-btn` (`XIcon`, `aria-label="Close menu"`) next to the brand; when it opens, move focus to the first nav link; and give the burger `aria-expanded={isMobileOpen}`. Pass this through `PageHeader` from each page: update `PageHeader.tsx` to accept `menuExpanded: boolean` and update its three call sites (`DailyRoutinePage.jsx`, `DefaultRoutinePage.tsx`, `AnalyticsPage.tsx`) and the `ShellOutletContext` (`isMobileOpen`)
- [X] T040 [US4] Add the narrow-screen rules to `ui-personal-routine-manager/src/components/layout/AppShell.css` under `@media (max-width: 760px)`:
  - The grid collapses to one column.
  - The sidebar is `position: fixed`, full height, `width: min(84vw, var(--sidebar-width))`, `transform: translateX(-100%)`, becoming `translateX(0)` when `[data-sidebar="open"]`, with a transition that respects `prefers-reduced-motion`, at `z-index: var(--z-sidebar)`.
  - The backdrop uses `--color-bg-overlay` at `z-index: var(--z-backdrop)`.
  - The page header keeps the burger visible.
- [X] T041 [US4] Check there's no horizontal page scroll from 360px to 1920px on Today, Default routine and Analytics (SC-007). Fix overflow in `ui-personal-routine-manager/src/App.css` / `AppShell.css`: long user names use ellipsis, and toolbar buttons wrap or scroll inside the board card, never the page

**Checkpoint**: All four user stories work on their own.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T042 [P] Tab through the sidebar, page header, board toolbar and Buddy panel on all three shell pages and fix any missing visible focus or label in the touched files under `ui-personal-routine-manager/src/components/layout/` and `ui-personal-routine-manager/src/features/` (FR-019, quickstart §9)
- [X] T043 [P] Update `ui-personal-routine-manager/src/features/walkthrough/content/walkthroughContent.ts` and `specs/002-onboarding-instruction/walkthrough-script.md` if any slide text mentions "Routine Canvas", the old "How it works" location on the dashboard, or the old dashboard layout; point it at the sidebar's "Replay tour"
- [X] T044 Remove the legacy alias block from `ui-personal-routine-manager/src/index.css` (added in T004). First run `grep -rn "var(--\(font\|white\|bg\|text\|text-dark\|blue-light\|blue-mid\|blue-primary\|blue-dark\|coral\|yellow\|yellow-dark\|gray-100\|gray-200\|gray-400\|shadow-sm\|shadow-md\|shadow-lg\|radius-sm\|radius-md\|radius-lg\|radius-xl\))" ui-personal-routine-manager/src` and replace remaining uses with semantic tokens, then delete the aliases
- [X] T045 Run `pnpm test`, `pnpm lint` and `pnpm build` in `ui-personal-routine-manager/` and fix all failures
- [X] T046 Run the full [quickstart.md](./quickstart.md) (§1–§9) against the local backend and record pass/fail per section at the end of `specs/F002-ui-refactoring/quickstart.md` under a "Validation run – YYYY-MM-DD" heading
- [X] T047 Update the "Claude Working Notes" in `specs/F002-ui-refactoring/F002-ui-refactoring.md`: tick `/speckit-tasks` and implementation, and note any deviation from the design (e.g. "Reset day" and the slider kept as secondary controls)

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)** comes first. T002 must exist before T003 and T004.
- **Foundational (Phase 2)** depends on Setup and blocks every story.
- **US1 (Phase 3, P1)** depends on Foundational. It's the MVP and provides the shell, router and `PageHeader` the other stories render into.
- **US2 (Phase 4)** depends on US1 (T013 `PageHeader`, T014 `useShellContext`, T017 routes).
- **US3 (Phase 5)** depends on US1 (T018 puts the Daily page in the shell). It is independent of US2, except that T034 also restyles onboarding CSS touched by T022, so do T022 first if both run.
- **US4 (Phase 6)** depends on US1. It is independent of US2 and US3, but T039 edits the `PageHeader` call sites created in T016, T018 and T023.
- **Polish (Phase 7)** comes after the stories you plan to ship.

### Story completion order

```text
Setup → Foundational → US1 (MVP) ─┬─→ US2
                                  ├─→ US3
                                  └─→ US4 → Polish
```

### Within each story

- Pure utils and their tests come before the components that use them (T009 → T011; T027 → T028; T020 → T021 → T022/T023).
- Component before route wiring (T014–T016 → T017; T023 → T026).
- Shared CSS file `ui-personal-routine-manager/src/App.css` is edited by T024, T031–T035: run those **one at a time** (not [P] with each other).

### Parallel opportunities

- Phase 2: T005, T006, T007, T008 all touch different files.
- US1: T009, T010, T013, T015, T016 can run together; then T011 → T012 → T014 → T017 → T018.
- US2: T023 and T024 run in parallel after T021.
- US3: T027 and T033 can start straight away, in parallel with T029/T030 (different files).
- After US1, US2, US3 and US4 can be staffed in parallel, keeping the `App.css` and `PageHeader` call-site notes above in mind.

## Parallel Example: User Story 1

```text
Task: "T009 [US1] sidebarPreference.ts + test in ui-personal-routine-manager/src/components/layout/"
Task: "T010 [US1] navEntries.ts in ui-personal-routine-manager/src/components/layout/"
Task: "T013 [US1] PageHeader.tsx in ui-personal-routine-manager/src/components/layout/"
Task: "T015 [US1] AppShell.css in ui-personal-routine-manager/src/components/layout/"
Task: "T016 [US1] AnalyticsPage.tsx in ui-personal-routine-manager/src/features/analytics/pages/"
```

## Parallel Example: User Story 3

```text
Task: "T027 [US3] nowAndNext.ts + test in ui-personal-routine-manager/src/features/daily/utils/"
Task: "T033 [US3] BuddyChat styles in ui-personal-routine-manager/src/App.css"   # only if no other App.css task is running
Task: "T029 [US3] Daily header in ui-personal-routine-manager/src/features/daily/pages/DailyRoutinePage.jsx"
```

---

## Implementation Strategy

### MVP first (User Story 1)

1. Phase 1 and Phase 2 (tokens, checks, utils, icons).
2. Phase 3 (US1): sidebar, routes, Analytics placeholder, Replay tour.
3. **Stop and validate** with quickstart §2, §3 and §7, then demo. The app already has proper navigation even before the full restyle.

### Incremental delivery

1. + US2: the Default Routine page becomes real (quickstart §5).
2. + US3: the Daily page matches the design, the whole app moves to tokens, and `noRawColors` goes green (quickstart §6, §8, §9).
3. + US4: phone overlay (quickstart §4).
4. Polish: remove legacy aliases, full quickstart run, update notes.

### Notes

- The shared `App.css` is the main merge-conflict risk. Keep `App.css` tasks sequential.
- Commit after each task or logical group.

---

## Implementation notes (2026-11-21)

Where the build differs from the task wording:

- **Shared class names**: `base.css` uses a `ui-` prefix (`.ui-btn`, `.ui-btn-primary`, `.ui-btn-ghost`, `.ui-btn-danger-text`, `.ui-icon-btn`, `.ui-card`, `.ui-pill`, `.ui-pill-success`, `.ui-segmented`) instead of `.btn`/`.card`/…, because the auth screen already uses `.btn`.
- **Contrast**: the mock's active-nav text (#1A6FD4 on #E8F1FC) is 4.3:1, below AA. Added `--color-accent-text` (darker blue) for accent text on the soft background; contract updated.
- **Allowlist**: besides the brand logos, `TaskEditModal.tsx`'s `<input type="color">` default stays a literal hex (the input only accepts `#rrggbb`).
- **Known-violations set** (T007) was emptied in T037 as planned; the legacy alias block (T004) was removed in T044.
- **PageHeader** reads the shell context itself (no `onLogout`/`showMenuButton` props); `ShellOutletContext` also carries `isMobileOpen` and `menuButtonRef`. `SIDEBAR_ID` and `useShellContext` live in `components/layout/shellContext.ts`.
- **US4 (T038–T040)** was built into `AppShell`/`Sidebar`/`AppShell.css` together with US1.
- **T026**: the Default routine route was wired to the real page directly (no temporary placeholder).
- **DefaultRoutineEditor** props are `className`, `renderHeader(switcher)`, `banner`, `renderAside`, `extraFabs`, `mobileView`, `children` (see contracts/ui-shell.md).
- **Guided tour**: `GuidedTour` now uses the first *visible* `[data-tour]` match, so `add-task` can sit on both the wide-screen "+ Add task" button and the phone FAB.
- **Test type-checking**: `tsconfig.test.json` (Node types) checks `*.test.ts`; `tsconfig.app.json` excludes them, so app code doesn't get Node types.
- **Reset day / slider** are kept as secondary controls (not in the mock) to avoid regressions (FR-011).

## Change request – 2026-11-21: Routine Buddy always visible

- [X] T048 [US2] Add `submitDefaultRoutineChat` in `ui-personal-routine-manager/src/features/default-routine/api/defaultRoutineChat.ts` (default-routine chat endpoint, no "Onboarding:" framing)
- [X] T049 [US2] Show one `BuddyChat` per Weekday/Weekend tab on `ui-personal-routine-manager/src/features/default-routine/pages/DefaultRoutinePage.tsx`, with the phone chat button and "View schedule"
- [X] T050 [US3] Lay out `.drt-page` like Today (board left, chat full height right) and move the board ⇄ chat swap from ≤ 1200px to ≤ 760px for `.ob-page`, `.drt-page` and `.dr-page` in `ui-personal-routine-manager/src/App.css`; `--chat-panel-width: clamp(280px, 28vw, 360px)` in `src/styles/tokens.css`
- [X] T051 Update spec FR-013/FR-013a, contracts/ui-shell.md, quickstart.md, CLAUDE.md

