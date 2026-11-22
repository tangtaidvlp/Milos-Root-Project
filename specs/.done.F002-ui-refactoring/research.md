# Research: F002 UI Refactoring – Sidebar Navigation and Visual Refresh

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Date**: 2026-11-20

All paths below are relative to `ui-personal-routine-manager/` unless stated.

## Current state (findings)

- Routing lives in `src/app/App.tsx` under a `HashRouter` (`src/main.tsx`). Signed-in, onboarded users get one route, `/dashboard` → `DailyRoutinePage`. Guards are inline ternaries repeated per route.
- `DailyRoutinePage.jsx` owns its own header (logo "Routine Canvas", "How it works", "Sign Out"), a date bar (‹ date-input › and "Clean up"), the `EditingBoard`, `BuddyChat`, the FAB group, `TaskEditModal` and `IntroSlides` (walkthrough state via `useWalkthrough()`).
- `OnboardingPage.jsx` holds the default-routine editing logic inline: two routines (`weekday`/`weekend`), load/save error handling, task modal wiring, plus `BuddyChat` per tab, "Ready to roll" and the guided tour (`data-tour` targets).
- `EditingBoard.jsx` already has every board control in the design: clock readout, Pause/Resume, zoom −/+, Gap Clear, plus "Reset day", a time slider, a now-line and a "Now: …" status line. Task colour falls back to a hard-coded `basePalette` array of hex values.
- Styling: `src/index.css` defines 22 custom properties; `src/App.css` (2,433 lines) uses them only 123 times and repeats ~80 distinct raw hex/rgba values. Lines 557–862 (`.cc-*`, "Control Centre Dashboard") are not referenced by any component (dead code). `AuthPage.tsx` has an inline illustration SVG with raw hex fills, plus third-party brand logos (Google, Facebook, Apple).
- Icons for the design already exist in `src/components/icons/` (exported from the Milos Figma file): `CalendarIcon` (Today), `RepeatIcon` (Default routine), `BarChartIcon` (Analytics), `SparkIcon` (Replay tour / Buddy), `ChevronLeft/Right`, `Plus`, `Minus`, `Check`, `Send`.
- Backend rule for which default routine a date uses: `DefaultRoutineService` (line 118) treats Saturday and Sunday as `WEEKEND`, every other day as `DAILY`.
- Tests: Vitest, pure logic only (`*.test.ts` next to the code). UI is verified by hand with `quickstart.md` (repo `CLAUDE.md`).

## R1 – Routing and the app shell

- **Decision**: Add a layout route `AppShell` (sidebar + `<Outlet/>`) guarded by a single `RequireOnboarded` element. Child routes: `/today`, `/default-routine`, `/analytics`. Keep `/dashboard` as a redirect to `/today` so existing bookmarks work. `/`, `/auth`, `/onboarding` and `*` keep their logic but point onboarded users at `/today`. Stay on `HashRouter`.
- **Rationale**: One guard instead of three copies (FR-015); each page gets its own address and back/forward works (FR-004); the sidebar stays mounted across page changes so its state and the walkthrough survive navigation. `HashRouter` is required by GitHub Pages hosting.
- **Alternatives**: a sidebar rendered inside every page (duplicated, remounts on navigation); a single page with tab state (no addresses, fails FR-004); switching to `BrowserRouter` (breaks GitHub Pages deep links).

## R2 – Central style values (design tokens)

- **Decision**: A new `src/styles/tokens.css`, imported first from `src/index.css`, in two tiers:
  1. **Primitive palette** (`--color-blue-600`, `--color-slate-900`, …): the only place raw colour values appear.
  2. **Semantic tokens** (`--color-bg-app`, `--color-text-primary`, `--color-accent`, `--color-danger`, `--color-task-1-bg` …) plus spacing, radius, shadow, type scale, z-index and layout sizes (`--sidebar-width`).
  Components use semantic tokens only. The existing names in `index.css` (`--blue-primary`, `--text`, …) become aliases of semantic tokens during migration and are removed when no longer used. Full catalogue in [contracts/style-tokens.md](./contracts/style-tokens.md).
- **Enforcement**: a Vitest test (`src/styles/noRawColors.test.ts`) reads `src/**/*.css|tsx|jsx|ts` with Node `fs` and fails on any hex/`rgb(a)`/`hsl(a)` literal outside `tokens.css`, with a small allowlist (third-party brand logos in `AuthPage.tsx`). This keeps SC-004 true after the feature ships, within the repo's "pure logic tests" rule (no DOM).
- **Rationale**: CSS custom properties are already in use, need no new dependency, work in inline `style` values from JS (`var(--color-task-3-accent)`), and allow dark mode later (out of scope now) by redefining the semantic tier only.
- **Alternatives**: CSS-in-JS or Tailwind (new dependency and rewrite of 2.4k lines, not justified); Sass variables (build-time only, can't be used from JS inline styles, needs a dependency); a TS constants file (CSS would still need its own copy).

## R3 – Token values from the design

- **Decision**: Seed values sampled from `resources/Sidebar-Design.png`; implementation re-samples exact pixels and adjusts. Key values: primary `#1F6FDB` family (active nav, "+ Add task", user chat bubble, send button; close to the current `--blue-primary #1a6fd4`), app background white with sidebar/board border `#E6EBF2`, page text `#1A202C`, muted text `#8A94A6`, danger `#E04848` ("Clean up", now-line, time pill), success `#34C38F` (Live pill, done checks), current-task outline `#7C5CE6`. Task tints: eight accent/background pairs (green, peach, blue, grey, slate, orange, pink, purple) as in the mock. Font stays Poppins.
- **Rationale**: Matches the mock while keeping today's brand blue nearly unchanged.
- **Contrast**: semantic text tokens must be ≥ 4.5:1 on their backgrounds (FR-019); checked with a pure function in the same token test (parse primitive hex values → WCAG ratio) for the listed text/background pairs.

## R4 – Sidebar behaviour and persistence

- **Decision**: `useSidebar()` hook in `src/components/layout/` returns `{ isMobile, isCollapsed, isMobileOpen, toggleCollapsed, openMobile, closeMobile }`.
  - Breakpoint: `matchMedia('(max-width: 760px)')`, the breakpoint `App.css` already uses for the mobile board/chat swap.
  - Wide-screen preference stored in `localStorage` key `milos.sidebar.collapsed` (`"true"`/`"false"`), read/written through `sidebarPreference.ts` with `try/catch`; default is expanded (FR-006, edge case "storage unavailable").
  - Mobile open state is never stored; it starts closed and closes on route change, backdrop click and Escape (FR-007).
  - Resizing wide→narrow closes any overlay; narrow→wide reapplies the stored preference (edge case).
- **Collapsed form**: on wide screens "hidden" collapses to a slim rail holding only the show control (the spec's "a control to show it again stays visible").
- **Rationale**: Pure read/parse functions are unit-testable; the hook is thin.
- **Alternatives**: storing in the user account (spec says device-only); CSS-only `:checked` hacks (poor a11y, no persistence).

## R5 – Accessibility of navigation

- **Decision**: Sidebar is `<nav aria-label="Main">` with `NavLink`s (React Router sets `aria-current="page"` on the active one, FR-003). Burger button has `aria-expanded` and `aria-controls`. Mobile overlay: backdrop, focus moves to the first link on open and back to the burger on close, Escape closes; background is `inert` while open. Collapse toggle has `aria-label` "Hide sidebar" / "Show sidebar". Visible focus ring via a `--focus-ring` token on all interactive elements (FR-019).
- **Rationale**: Covers the keyboard-only edge case without a dialog library.

## R6 – Default Routine page (reuse onboarding editor)

- **Decision**: Extract the default-routine logic from `OnboardingPage.jsx` into
  - `features/onboarding/hooks/useDefaultRoutines.ts`: both routines, active tab, refresh, save-error handling, create/update/delete (current behaviour, unchanged messages);
  - `features/onboarding/components/DefaultRoutineEditor.tsx`: Weekday/Weekend switch, error banner with Retry, board card with title/subtitle, `EditingBoard liveClock={false}`, `TaskEditModal`, add-task button. Accepts an optional `aside` slot (Buddy chats) and `headerActions` slot ("Ready to roll").
  `OnboardingPage` composes the editor with Buddy chats, "Ready to roll" and the guided tour (all `data-tour` attributes kept on the same elements). The new `features/default-routine/pages/DefaultRoutinePage.tsx` composes it with no aside and no finish action (FR-012, FR-013).
- **Rationale**: One implementation of default-routine editing; the onboarding behaviour and tour stay as they are.
- **Alternatives**: copy `OnboardingPage` (two copies to maintain); render `OnboardingPage` with flags (mixes onboarding-only concerns into the post-onboarding page).
- **Risk**: the guided tour finds targets by `data-tour`; the extraction must keep `schedule-switch`, `routine-board`, `add-task`, `routine-buddy`, `finish` on equivalent elements. Covered in quickstart.

## R7 – Daily Routine page in the new layout

- **Decision**: Keep all behaviour (FR-011); move and restyle:
  - Header: breadcrumb "Today · Weekday routine", ‹ date ›, "Today" button (new: jumps to today; hidden state = disabled when already today), "Sign out" on the right. The date stays clickable to open the native date picker (current `<input type="date">`, visually styled as the heading).
  - Board toolbar (inside `EditingBoard`): clock + "Live" pill, zoom −/100%/+, "Pause clock", "Gap clear", then page-supplied actions through a new `toolbarActions` prop ("Clean up", "+ Add task"). "Reset day" and the time slider remain available, restyled as secondary controls (not in the mock, kept to avoid regressions; noted as a deliberate deviation).
  - Task cards: tinted background + left accent bar from task tint tokens (`basePalette` replaced by token references, cycled by index as today); completed tasks faded with success check; current task outlined with `--color-task-current`.
  - Now-line in danger colour with a time pill on the hour gutter.
  - Footer: "Now  Design review · 18 min left" left, "Next: Emails & admin at 11:00" right, from a new pure util `nowAndNext(tasks, minutes)` (unit-tested). Replaces the "Now: …" line.
  - Routine Buddy on the right on wide screens; existing mobile board/chat swap kept.
  - The FAB stays on mobile only; wide screens use "+ Add task" in the toolbar.
- **Rationale**: Matches the mock while keeping regressions visible and testable (SC-006).

## R8 – Walkthrough "Replay tour" in the sidebar

- **Decision**: `AppShell` owns `useWalkthrough()` and renders `IntroSlides`; "Replay tour" calls `open('app')` (slides only, as today on the dashboard). `DailyRoutinePage` drops its own walkthrough and "How it works" button. `OnboardingPage` keeps its own (outside the shell).
- **Rationale**: Replay must work from every sidebar page (FR-009).

## R9 – Today's routine type label

- **Decision**: Pure util `routineTypeForDate(date: Date): RoutineType` (`features/onboarding/utils/`) with Saturday/Sunday → `WEEKEND`, otherwise `DAILY`, mirroring `DefaultRoutineService`. Label map: `DAILY` → "Weekday routine", `WEEKEND` → "Weekend routine". Used in the sidebar user block (today) and the daily header breadcrumb (selected date).
- **Rationale**: No API call needed; same rule as the server. If the server rule changes, the util test documents the dependency.

## R10 – Branding and the rest of the app

- **Decision**: Brand mark "M" + "Milos" replaces "R / Routine Canvas" in the shell and on the onboarding top bar. Auth and onboarding screens switch to semantic tokens and shared component classes (buttons, inputs, cards, segmented control) with no layout change beyond the new style (FR-018). The `AuthPage` illustration fills move to tokens; brand logos stay as-is (allowlisted).
- **Cleanup**: delete the unused `.cc-*` block (`App.css` 557–862) as part of the token migration.

## R11 – CSS organisation

- **Decision**: Keep plain CSS. Add `src/styles/tokens.css` and `src/styles/base.css` (resets, focus ring, shared `.btn`, `.card`, `.pill`, `.segmented`), and `src/components/layout/AppShell.css` for the shell/sidebar. Restyle existing `.ob-*`, `.dr-*`, `.wt-*` rules in `App.css` in place to use tokens; no class renames except where markup changes (keeps diff reviewable and `data-tour` untouched).
- **Alternatives**: CSS Modules per component (larger rename, not needed for this feature).

## Open items

None. All Technical Context unknowns are resolved above.
