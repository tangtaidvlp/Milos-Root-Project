# Implementation Plan: UI Refactoring – Sidebar Navigation and Visual Refresh

**Branch**: `F002-ui-refactoring` | **Date**: 2026-11-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/F002-ui-refactoring/spec.md`, design `resources/Sidebar-Design.png`

## Summary

Add an app shell with a left sidebar (Today, Default routine, Analytics "Soon", Replay tour, user block) to every signed-in, onboarded page. It is collapsible on wide screens, with the choice remembered per device, and opens from a burger as an overlay on narrow screens. Add a Default Routine page that reuses the onboarding editor without Buddy chat and without the finish step. Add an Analytics placeholder. Restyle the whole app from one central set of CSS design tokens, enforced by a unit test that rejects raw colour literals.

This is frontend only (`ui-personal-routine-manager/`), with no backend or API changes. Approach details are in [research.md](./research.md).

## Technical Context

**Language/Version**: TypeScript ~6.0 (strict, `verbatimModuleSyntax`), plus existing `.jsx` pages. New files are `.tsx`/`.ts`.

**Primary Dependencies**: React 19, React Router 7 (`HashRouter`, layout routes, `NavLink`, `useOutletContext`), Vite 8. No new dependencies.

**Storage**: Browser `localStorage` for one key (`milos.sidebar.collapsed`). The server stores data through existing default-routine and daily-routine endpoints.

**Testing**: Vitest unit tests for pure logic (`*.test.ts` next to code, Node env). UI is checked by hand with [quickstart.md](./quickstart.md).

**Target Platform**: Modern evergreen browsers, desktop and mobile web. Hosted on GitHub Pages / Nginx (EC2).

**Project Type**: Web application (SPA frontend of a frontend + backend workspace).

**Performance Goals**: Page switches feel instant (< 100 ms, no network wait for the shell itself); the sidebar toggle animates at 60 fps; no layout shift on load from reading the stored preference.

**Constraints**: Hash routing must stay (GitHub Pages). Keep all walkthrough `data-tour` targets. No regressions in Daily Routine behaviour (SC-006). No horizontal page scroll from 360 px up (SC-007). WCAG AA text contrast (FR-019).

**Scale/Scope**: 3 shell pages plus 2 restyled flows (auth, onboarding); ~2.4k lines of CSS migrated to tokens (~300 dead lines removed); ~12 new source files.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template (placeholders only), so it defines no ratified principles or gates. The plan instead follows the project's own written rules:

| Rule (source) | Status |
|---------------|--------|
| Feature-based folders: `app/`, `components/`, `features/<name>/{api,components,pages,types,hooks,utils}` (`codingrules.md`) | Pass: shell in `components/layout/`, new `features/default-routine/` and `features/analytics/`, shared hook/editor in `features/onboarding/` |
| All HTTP through `lib/api.ts` (`codingrules.md`) | Pass: no new API calls; existing modules reused |
| New code in `.ts`/`.tsx`; `import type` for types (`ui/CLAUDE.md`) | Pass |
| Tests for pure logic only, UI by quickstart (`ui/CLAUDE.md`) | Pass: 5 pure modules tested; UI by quickstart |
| `pnpm` only; oxlint rules-of-hooks (`ui/CLAUDE.md`) | Pass |
| Don't hand-edit `milos.github.io/` (root `CLAUDE.md`) | Pass: untouched |

**Post-design re-check**: still passes. No violations, so Complexity Tracking is empty.

*Suggestion*: run `/speckit-constitution` at some point so later features have real gates.

## Project Structure

### Documentation (this feature)

```text
specs/F002-ui-refactoring/
├── F002-ui-refactoring.md   # Feature ticket + Claude working notes
├── resources/Sidebar-Design.png
├── spec.md
├── plan.md                  # This file
├── research.md              # Phase 0
├── data-model.md            # Phase 1
├── quickstart.md            # Phase 1
├── contracts/
│   ├── routes.md
│   ├── ui-shell.md
│   └── style-tokens.md
├── checklists/requirements.md
└── tasks.md                 # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (`ui-personal-routine-manager/`)

```text
src/
├── main.tsx                                   # unchanged (HashRouter)
├── index.css                                  # imports styles/tokens.css + base.css; legacy vars → aliases
├── App.css                                    # restyled with semantic tokens; .cc-* dead block removed
├── styles/                                    # NEW
│   ├── tokens.css                             # primitive + semantic tokens (contracts/style-tokens.md)
│   ├── base.css                               # reset, focus ring, .btn/.card/.pill/.segmented
│   ├── contrast.ts (+ .test.ts)               # WCAG ratio helper + token pair checks
│   └── noRawColors.test.ts                    # fails on raw colours outside tokens.css
├── app/
│   └── App.tsx                                # layout route + RequireOnboarded guard; /today, /default-routine, /analytics; /dashboard → /today
├── components/
│   ├── icons/                                 # existing; add MenuIcon, ChevronsLeftIcon (collapse)
│   └── layout/                                # NEW
│       ├── AppShell.tsx                       # sidebar + Outlet, owns walkthrough slides, outlet context
│       ├── AppShell.css
│       ├── Sidebar.tsx                        # brand, PLAN nav, Replay tour, user block, collapse control
│       ├── PageHeader.tsx                     # burger (mobile) + title slot + actions + Sign out
│       ├── navEntries.ts                      # NavEntry config (data-model §1)
│       ├── useSidebar.ts                      # data-model §3
│       └── sidebarPreference.ts (+ .test.ts)  # localStorage read/write with fallbacks
├── features/
│   ├── analytics/pages/AnalyticsPage.tsx      # NEW placeholder
│   ├── default-routine/pages/DefaultRoutinePage.tsx   # NEW: DefaultRoutineEditor without aside/finish
│   ├── daily/
│   │   ├── pages/DailyRoutinePage.jsx         # new header/toolbar layout; walkthrough + logo removed (now in shell)
│   │   └── utils/nowAndNext.ts (+ .test.ts)   # NEW (data-model §5)
│   ├── onboarding/
│   │   ├── hooks/useDefaultRoutines.ts        # NEW: extracted load/save/error logic
│   │   ├── components/DefaultRoutineEditor.tsx# NEW: switch + board + modal + error banner (contracts/ui-shell.md)
│   │   ├── components/EditingBoard.jsx        # + toolbarActions, Now/Next footer, tint tokens instead of basePalette
│   │   ├── pages/OnboardingPage.jsx           # composes DefaultRoutineEditor + Buddy + Ready + tour; "Milos" brand
│   │   └── utils/routineTypeForDate.ts (+ .test.ts)  # NEW (data-model §4)
│   ├── auth/pages/AuthPage.tsx                # illustration fills → tokens; brand logos allowlisted
│   └── walkthrough/                           # unchanged logic; restyled
```

**Structure Decision**: Single frontend project inside the existing workspace. The shell is global layout, so it goes in `src/components/layout/`. New pages go in their own feature folders. Default-routine editing stays owned by `features/onboarding/` (its API, types and tour live there) and is consumed by `features/default-routine/`.

## Implementation phases (for /speckit-tasks)

1. **Tokens foundation**: `tokens.css`, `base.css`, alias the legacy variables, contrast helper and test, `noRawColors` test (initially listing current violations as the migration to-do).
2. **Shell and routing (US1, P1)**: router layout route and guard, `AppShell`, `Sidebar`, `PageHeader`, `useSidebar` with preference, Analytics placeholder, Replay tour moved to the shell, `/dashboard` redirect.
3. **Default Routine page (US2)**: extract `useDefaultRoutines` and `DefaultRoutineEditor`, rewire `OnboardingPage` (tour must still work), add `DefaultRoutinePage`.
4. **Daily page restyle (US3)**: header, `toolbarActions`, task tints, `nowAndNext` footer, Today button.
5. **Narrow screens (US4)**: burger, overlay, focus handling, resize behaviour.
6. **App-wide token migration (US3)**: `App.css` sections (auth, onboarding, walkthrough, daily) to semantic tokens, delete `.cc-*`, make `noRawColors` green, "Milos" brand on onboarding and auth.
7. **Validation**: full [quickstart.md](./quickstart.md) run, plus `pnpm test`, `pnpm lint` and `pnpm build`.

## Risks

| Risk | Mitigation |
|------|------------|
| Extracting the editor breaks the onboarding guided tour | Keep the `data-tour` targets listed in contracts/ui-shell.md; quickstart §7 checks every tour step |
| CSS migration causes visual regressions on auth/onboarding | Migrate one section at a time; `noRawColors` shows what's left; side-by-side checks in quickstart §6/§8 |
| Design shows no "Reset day" or slider | Kept as secondary controls (FR-011 over pixel match); noted in research R7 |
| Weekend rule duplicated client-side | `routineTypeForDate` test names the server rule it mirrors |

## Complexity Tracking

No constitution violations to justify.
