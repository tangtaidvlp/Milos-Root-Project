# Implementation Plan: Onboarding Instruction

**Branch**: `002-onboarding-instruction` | **Date**: 2026-11-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/002-onboarding-instruction/spec.md`, plus [walkthrough-script.md](./walkthrough-script.md), the mockups in [resources/](./resources/), and the ticket [F001](./F001-onboarding-instruction.md).

## Summary

Users who haven't finished onboarding see 4 intro slides, then an optional 5-step guided tour of the setup screen. These show on every visit until onboarding is done, and a "How it works" button replays them at any time. The slides and tour are a custom, dependency-free React module (`features/walkthrough/`). It is driven by a pure reducer and positions its cards over `data-tour` anchors on the setup screen.

Because the instructions promise **separate Weekday and Weekend routines** (decision D2), this feature also makes the Weekday/Weekend switch real:
- **Backend**: becomes type-aware. It drops the single-routine `findByUser` lookup, which would crash once a user has two routines. It adds `?type=` to the get-routine endpoint with get-or-create for weekends, and picks the right template for weekend days.
- **Frontend**: loads, edits and chats on the routine of the active tab.

Save failures, which are swallowed today, become a visible error.

## Technical Context

**Language/Version**: TypeScript ~6.0 with React 19.2 (frontend). Java 25 with Spring Boot 4.1 (backend).

**Primary Dependencies**:
- **Frontend**: React Router 7, Vite 8, react-markdown. **No new runtime dependency.** New dev dependency: Vitest.
- **Backend**: Spring Data JPA, Spring AI (Gemini). No new dependencies.

**Storage**: PostgreSQL through Hibernate (`ddl-auto: update` locally, `validate` in prod). No schema change, because the `routine_type` column and the `WEEKEND` value already exist.

**Testing**:
- **Frontend**: Vitest unit tests for the pure logic (reducer, card placement, tab mapping), plus the manual [quickstart.md](./quickstart.md) pass.
- **Backend**: JUnit `@SpringBootTest` on the `local` profile, which needs PostgreSQL.

**Target Platform**: modern desktop and mobile browsers. The SPA is served from GitHub Pages, S3 or the EC2 Nginx.

**Project Type**: web application with a separate frontend and backend.

**Performance Goals**:
- Slides and tour open in < 100 ms after the setup screen renders.
- Tour card re-positions within one animation frame on resize or scroll.

**Constraints**:
- Must match the desktop mockups.
- Phones ≤ 760px follow research R10.
- Keyboard usable (FR-015).
- No persistence of the "seen" state.
- Existing API callers must keep working.

**Scale/Scope**:
- 9 instruction screens, 1 changed endpoint, 1 new client module.
- About 7 backend call sites change.
- 2 pages change (`OnboardingPage`, `DailyRoutinePage`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so there are no ratified principles to gate on. In their place, these project rules apply:

| Source | Rule | Status |
|--------|------|--------|
| `ui-personal-routine-manager/codingrules.md` | Feature-based structure (`features/<name>/{api,components,pages,types,hooks,utils}`) | ✅ New `features/walkthrough/`. Routine API goes in `features/onboarding/api/`. |
| `codingrules.md` | Always use `lib/api.ts` | ✅ `fetchDefaultRoutine` uses `apiRequest` |
| UI `CLAUDE.md` | New files in `.tsx`/`.ts`. `import type` for types. pnpm only. | ✅ |
| UI `CLAUDE.md` | Shared components stay in `onboarding/components/` | ✅ Not moved. They only gain a `data-tour` pass-through. |
| Workspace `CLAUDE.md` | Keep request and response shapes aligned between UI and API | ✅ [contracts/default-routine-api.md](./contracts/default-routine-api.md) |
| Workspace `CLAUDE.md` | Don't hand-edit `milos.github.io/` | ✅ Not touched |

**Post-design re-check (after Phase 1)**: still passing. One deliberate trade-off is recorded under Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/002-onboarding-instruction/
├── F001-onboarding-instruction.md   # ticket (user + Claude working notes)
├── spec.md
├── walkthrough-script.md            # exact copy + navigation
├── resources/                       # desktop mockups (4 slides, 5 tour steps)
├── plan.md                          # this file
├── research.md                      # R1–R13 decisions
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── default-routine-api.md
│   └── walkthrough-ui.md
├── checklists/requirements.md
└── tasks.md                         # next: /speckit-tasks
```

### Source Code

```text
ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/
├── repository/DefaultRoutineRepository.java      # + findByUserAndRoutineType; − findByUser
├── service/DefaultRoutineService.java            # type-aware get / get-or-create weekend / create; + resolveTemplateFor(user, date)
├── service/UserService.java                      # register creates DAILY + WEEKEND
├── service/DailyRoutineService.java              # createDailyRoutineFromDefault & spawn use resolveTemplateFor
├── service/cronjobs/DailyTaskSpawningJob.java    # delegates weekday/weekend choice to resolveTemplateFor
├── config/AiRoutineFunctions.java                # findByUser → findByUserAndRoutineType(DAILY)
└── api/DefaultRoutineController.java             # GET /users/{userId}?type=…
ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/
├── RoutineServiceIntegrationTest.java            # migrate findByUser; + per-type + resolveTemplateFor tests
└── apptest/OnboardingRoutineTest.java            # + register creates both; weekend get-or-create idempotent

ui-personal-routine-manager/
├── package.json                                  # + vitest (dev), "test": "vitest run"
└── src/features/
    ├── walkthrough/                              # NEW
    │   ├── content/walkthroughContent.ts         # slide + step copy (mirrors walkthrough-script.md)
    │   ├── types/walkthrough.ts
    │   ├── utils/walkthroughReducer.ts (+ .test.ts)
    │   ├── utils/placeCard.ts (+ .test.ts)
    │   ├── hooks/useWalkthrough.ts
    │   ├── components/IntroSlides.tsx
    │   ├── components/GuidedTour.tsx
    │   ├── components/HowItWorksButton.tsx
    │   └── components/icons.tsx                  # calendar, repeat, chart, sparkles
    ├── onboarding/
    │   ├── api/defaultRoutine.ts                 # NEW fetchDefaultRoutine(userId, type)
    │   ├── utils/routineTypeForTab.ts (+ .test.ts)
    │   ├── pages/OnboardingPage.jsx              # two routines by tab, walkthrough host, data-tour anchors,
    │   │                                         # save-error banner, new subtitle/greeting, How it works
    │   └── components/{FabButton.tsx,BuddyChat.jsx,EditingBoard.jsx}  # data-tour pass-through; onPersistError
    └── daily/pages/DailyRoutinePage.jsx          # How it works (app context, slides only)
└── src/App.css                                   # .wt-* styles for slides, spotlight, tour card, sheets
```

**Structure Decision**: this is the existing two-repo web app. All new UI code sits in a new feature module, `features/walkthrough/`, because two pages use it. Routine-type logic stays in `features/onboarding/`. Backend changes stay in the existing service and repository layers. No new modules.

## Implementation phases (input for `/speckit-tasks`)

Phases are in dependency order. Phases B and C can run in parallel once A is merged.

1. **A. Backend: type-aware routines** (blocking; R1–R4)
   1. Replace `findByUser` with `findByUserAndRoutineType` at all 7 main and 4 test call sites. Tests must stay green **before** any weekend routine is created.
   2. Add `resolveTemplateFor(user, date)`, and route daily creation, spawn and the cron job through it. Write the tests first: a weekday date gives DAILY, a weekend date with tasks gives WEEKEND, an empty weekend gives DAILY.
   3. Registration creates both routines. `GET …/users/{id}?type=` with get-or-create for WEEKEND, a 400 on a bad type, and DAILY as the default.
2. **B. Frontend: two routines on the setup screen** (D2, R5, R9, R13)
   1. `fetchDefaultRoutine(userId, type)` and `routineTypeForTab`.
   2. `OnboardingPage` keeps `{weekday, weekend}`, and the board, FAB, modal and chat use the active tab's routine. Render one `BuddyChat` per tab and hide the inactive one.
   3. Error banner for load and save failures. `EditingBoard.onPersistError`.
   4. New board subtitle and Buddy greeting.
3. **C. Frontend: walkthrough module** (FR-001 to FR-008, FR-012 to FR-015)
   1. Vitest setup. Write the tests for `walkthroughReducer` and `placeCard` first, then implement them.
   2. Content file, icons, `IntroSlides` (keys, swipe, focus trap), `GuidedTour` (spotlight, placement, re-measure, mobile sheets, view switching).
   3. CSS in `App.css` (`.wt-*`), matched to the mockups.
4. **D. Wire-up**
   1. `data-tour` anchors on the setup screen.
   2. `OnboardingPage` auto-opens on mount and gets **How it works**.
   3. `DailyRoutinePage` gets **How it works** (app context).
5. **E. Validate**: run `pnpm test`, `pnpm lint`, `pnpm build`, `./gradlew test`, the API smoke test and the full manual pass in [quickstart.md](./quickstart.md). Update the ticket's working notes.

## Risks

| Risk | Mitigation |
|------|------------|
| A missed `findByUser` caller crashes once a weekend routine exists | Phase A.1 removes the method entirely, so any missed caller fails to compile. |
| Existing users suddenly get empty weekends | `resolveTemplateFor` falls back to DAILY when WEEKEND has no tasks (R3). |
| Tour targets move or re-render (drag, zoom, chat growth) | Re-measure on resize, scroll and `ResizeObserver`. Missing target → centered card. |
| GET that writes (weekend get-or-create) surprises a future maintainer | Documented in the contract, in research R2, and in a code comment. Idempotent. |
| `prod` uses `ddl-auto: validate` | No schema change. Only rows are added. |

## Complexity Tracking

| Choice | Why needed | Simpler alternative rejected because |
|--------|------------|--------------------------------------|
| `GET ?type=WEEKEND` creates the routine if missing | Existing users have no weekend routine, and there is no migration tool | A backfill needs manual production access, and 404 + POST adds a round trip and a race (R2) |
| Weekend scope pulled into an instructions feature | The instructions say "two routines", and D2 put the fix in scope | Rewording the instructions was rejected by the user (D2) |
| New dev dependency (Vitest) | The navigation rules (FR-005/007/008/013) need automated checks, and the frontend has no test runner | Manual-only testing leaves the reducer rules unguarded |
