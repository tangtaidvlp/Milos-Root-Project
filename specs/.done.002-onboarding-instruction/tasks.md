---

description: "Task list for 002-onboarding-instruction"
---

# Tasks: Onboarding Instruction

**Input**: Design documents from `specs/002-onboarding-instruction/`: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md), [walkthrough-script.md](./walkthrough-script.md), mockups in [resources/](./resources/)

**Tests**: Included. The plan asks for test-first work on the walkthrough reducer, card placement and routine-type rules (research R8). Write each test task first and confirm it **fails** before writing the code.

**Organization**: tasks are grouped by user story (spec.md US1–US4), so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1–US4 from spec.md

## Path conventions (two repos in this workspace)

All paths are relative to the workspace root `/Users/tommtang2106/Projects/`.

- **Backend**: `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/…`, tests in `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/…`
- **Frontend**: `ui-personal-routine-manager/src/…`
- **Commands**:
  - Backend: run in `ms-personal-routine-manager/` with `docker compose up -d database` first, because tests use the `local` PostgreSQL profile.
  - Frontend: run in `ui-personal-routine-manager/`, with **pnpm only**.
- **Frontend rules** (`ui-personal-routine-manager/codingrules.md` and `CLAUDE.md`):
  - new files are `.ts`/`.tsx`
  - use `import type` for type-only imports
  - all HTTP calls go through `src/lib/api.ts` (`apiRequest`)

---

## Phase 1: Setup (shared infrastructure)

**Purpose**: a test runner for the frontend, and a known-good backend baseline.

- [X] T001 Add Vitest as a dev dependency (`pnpm add -D vitest`) and add the script `"test": "vitest run --passWithNoTests"` in `ui-personal-routine-manager/package.json`. Confirm `pnpm test` exits 0.
- [X] T002 [P] Record the backend baseline. With the database up, run `./gradlew test` in `ms-personal-routine-manager/` and note any tests that already fail under "Baseline" at the end of this file, so later phases aren't blamed for them.

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**:
- **Backend**: remove the single-routine lookup that would crash once a user has two routines (research R1). This must finish before any Weekend routine can exist.
- **Frontend**: the shared walkthrough state machine that US1, US2 and US4 all use.

**⚠️ CRITICAL**: no user-story work starts until this phase is green.

### Backend: type-aware routine lookup (behaviour unchanged)

- [X] T003 In `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/repository/DefaultRoutineRepository.java`, add `Optional<DefaultRoutine> findByUserAndRoutineType(User user, DefaultRoutine.RoutineTypeEnum routineType);` and **delete** `findByUser(User)`, so any caller missed below fails to compile.
- [X] T004 Update `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/DefaultRoutineService.java`:
  - `createDefaultRoutine(userId, routine)`: look up with `findByUserAndRoutineType(user, type)`, where `type` is `routine.getRoutineType()`, or `DAILY` when that is null. Set `routineType` on the new routine before saving.
  - `getDefaultRoutineByUserId(UUID userId)`: becomes `getDefaultRoutineByUserId(UUID userId, RoutineTypeEnum type)` using `findByUserAndRoutineType`. A missing routine throws `ResponseStatusException(HttpStatus.NOT_FOUND, "Default routine not found for user")` in place of `RuntimeException`.
- [X] T005 [P] In `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/DailyRoutineService.java`, replace both `defaultRoutineRepository.findByUser(user)` calls (`createDailyRoutineFromDefault` and `spawnDailyRoutineForUser`) with `findByUserAndRoutineType(user, DefaultRoutine.RoutineTypeEnum.DAILY)`. This is a temporary step: T033 switches them to `resolveTemplateFor`.
- [X] T006 [P] In `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/config/AiRoutineFunctions.java`, replace all 3 `findByUser(user)` calls with `findByUserAndRoutineType(user, DefaultRoutine.RoutineTypeEnum.DAILY)`.
- [X] T007 In `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/api/DefaultRoutineController.java`, make `getDefaultRoutineForUser` call `routineService.getDefaultRoutineByUserId(userId, DefaultRoutine.RoutineTypeEnum.DAILY)`. The `?type=` parameter comes in T032. Depends on T004.
- [X] T008 [P] In `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/RoutineServiceIntegrationTest.java`, replace the 4 `defaultRoutineRepository.findByUser(user)` calls with `findByUserAndRoutineType(user, DefaultRoutine.RoutineTypeEnum.DAILY)`.
- [X] T009 Run `./gradlew build` and `./gradlew test` in `ms-personal-routine-manager/`. They must compile with no `findByUser` left (`grep -rn "findByUser(" src` returns nothing), and test results must match the T002 baseline.

### Frontend: walkthrough state machine

- [X] T010 [P] Create `ui-personal-routine-manager/src/features/walkthrough/types/walkthrough.ts` exporting the types from data-model.md §3–§4, exactly:
  - `WalkthroughContext = 'onboarding' | 'app'`
  - `WalkthroughState` (`{phase:'hidden'}` | `{phase:'slides'; index:0|1|2|3; context}` | `{phase:'tour'; index:0|1|2|3|4}`)
  - `WalkthroughEvent`, a union of `{type:'OPEN'; context}`, `{type:'NEXT'}`, `{type:'BACK'}`, `{type:'JUMP'; index}`, `{type:'SKIP'}`, `{type:'START_TOUR'}`, `{type:'END'}`
  - `SlideContent`, `TourStepContent`, `TourTarget = 'schedule-switch' | 'routine-board' | 'add-task' | 'routine-buddy' | 'finish'`
- [X] T011 [P] Write `ui-personal-routine-manager/src/features/walkthrough/utils/walkthroughReducer.test.ts` **first**, with one test per row of the transition table in data-model.md §3. It must cover:
  - `OPEN` from any phase → `slides(0, ctx)`
  - `NEXT` on slides 0–2 advances, and on slide 3 is a no-op
  - `BACK` on slide 0 / tour 0 is a no-op
  - `JUMP(2)`
  - `SKIP` → `hidden` (never `tour`)
  - `START_TOUR` from `slides(3,'onboarding')` → `tour(0)`
  - `START_TOUR` from `slides(3,'app')` → `hidden`
  - `START_TOUR` from any other slide is a no-op
  - tour `NEXT` 0→4, and `NEXT` on tour 4 is a no-op
  - `END` → `hidden`

  Run `pnpm test` and confirm it fails.
- [X] T012 Implement `ui-personal-routine-manager/src/features/walkthrough/utils/walkthroughReducer.ts` as a pure function `walkthroughReducer(state, event)` with no side effects. `pnpm test` must pass. Depends on T010, T011.
- [X] T013 Create `ui-personal-routine-manager/src/features/walkthrough/hooks/useWalkthrough.ts`. It implements `useWalkthrough({ autoOpen?: WalkthroughContext })`, which returns `{ state, open(ctx), dispatch }` using `useReducer(walkthroughReducer, {phase:'hidden'})`.
  - When `autoOpen` is set, dispatch `OPEN(autoOpen)` once per mount (`useEffect` with an empty dependency list).
  - It must **not** read or write localStorage or call the API (FR-014; data-model §3 invariants).

**Checkpoint**: backend still behaves exactly as before, and the reducer is fully tested. User stories can start. US3's backend work can run alongside US1 and US2.

---

## Phase 3: User Story 1 – Learn what Milos is before setting up (P1) 🎯 MVP

**Goal**: every visit to the setup screen while onboarding is unfinished opens the 4 intro slides first. They can be stepped through or skipped.

**Independent test**: register a new account → Slide 1 opens over the setup screen and matches `resources/D · Slide 1 – What is Milos_.png`. Next, Back, the arrow keys and the dots navigate slides 1–4. Skip or Esc closes to the setup screen. Reload → the slides open again. (quickstart rows 1, 2, 5)

- [X] T014 [P] [US1] Create `ui-personal-routine-manager/src/features/walkthrough/content/walkthroughContent.ts` exporting `SLIDES: SlideContent[]`, copied **verbatim** from walkthrough-script.md Part 1:
  - **1**: icon `calendar`, label "WHAT IS MILOS?", title "Plan your days once. Then just live them.", body "Milos is a time-management app. You set up a default routine for weekdays and one for weekends, and Milos turns them into your plan for each day."
  - **2**: icon `repeat`, label "HOW A DAY WORKS", title "Every day starts from your routine.", body "Each new day starts as a copy of its default routine, weekday or weekend. Follow it as planned, or move, change or tick off tasks as your day really goes."
  - **3**: icon `chart`, label "SEE HOW YOU REALLY SPEND YOUR TIME", title "Your habits, in numbers (coming soon).", body "Milos keeps track of what you planned and what you actually did. Soon you'll be able to see a breakdown of how you really spend your time."
  - **4**: icon `sparkles`, label "LET ROUTINE BUDDY DO THE WORK", title "You don't have to plan every detail.", body "Tell Routine Buddy about your day (\"I work 9 to 5, gym at 6\") and it builds your routine for you. Later, ask it to rearrange things and it will.", callout `{ heading: "First step", text: "Set up your Weekday and Weekend routines, by hand or by chatting with Routine Buddy." }`

  Add a header comment: "Mirrors specs/002-onboarding-instruction/walkthrough-script.md; edit the script first."
- [X] T015 [P] [US1] Create `ui-personal-routine-manager/src/features/walkthrough/components/icons.tsx` with `CalendarIcon`, `RepeatIcon`, `ChartIcon` and `SparklesIcon`: inline 20×20 SVGs using `stroke="currentColor"` and `aria-hidden="true"`. Also export a map `SLIDE_ICONS: Record<SlideContent['icon'], () => JSX.Element>`.
- [X] T016 [US1] Create `ui-personal-routine-manager/src/features/walkthrough/components/IntroSlides.tsx` (`props: { state: WalkthroughState; dispatch: (e: WalkthroughEvent) => void }`). It renders only when `state.phase === 'slides'`, and follows contracts/walkthrough-ui.md:
  - **Dialog**: backdrop plus a card with `role="dialog"`, `aria-modal="true"`, and `aria-labelledby` pointing at the title.
  - **Layout**: icon tile top-left, a **Skip** text button top-right (→ `SKIP`), uppercase label, title, body, and slide 4's callout box.
  - **Footer**: Back (hidden on slide 1) · 4 dots as buttons (`JUMP(i)`, with `aria-label="Go to slide n"` and the active one as a pill) · **Next** on slides 1–3.
  - **Slide 4 footer**: Back · dots · *I'll explore myself* (→ `SKIP`, hidden when `context==='app'`) · primary button **Show me around** (→ `START_TOUR`), which reads **Close** when `context==='app'`.
  - **Keys**: Esc → `SKIP`, ← → `BACK`, → → `NEXT`.
  - **Swipe**: pointer swipe with |dx| > 50px and |dx| > |dy| → `NEXT`/`BACK`.
  - **Focus**: move focus to the card on open, trap Tab inside it, and restore focus to the previously focused element on close.

  Depends on T012, T014, T015.
- [X] T017 [P] [US1] Add slide styles (`.wt-backdrop`, `.wt-slide-card`, `.wt-icon-tile`, `.wt-eyebrow`, `.wt-title`, `.wt-body`, `.wt-callout`, `.wt-dots`, `.wt-dot`, `.wt-dot--active`, `.wt-btn-primary`, `.wt-btn-text`) to `ui-personal-routine-manager/src/App.css`, matching `resources/D · Slide 1–4 …png`:
  - **Backdrop**: dark translucent (`rgba(15,23,42,0.45)`), with the page visible behind it.
  - **Card**: white, about 560px wide, radius 16px, padding 32px.
  - **Icon tile**: 48px, light-blue background (`#e8f1fc`), blue icon (`var(--blue-primary)`).
  - **Eyebrow**: 11px, uppercase, letter-spacing 0.08em, blue.
  - **Title**: about 26px, weight 700.
  - **Body**: 15px, slate.
  - **Callout**: light-blue background, radius 10px, blue "First step" heading.
  - **Active dot**: a 20×6 blue pill. Inactive dots: 6px grey.
  - **Primary button**: blue, radius 8px.
  - **Phones (`@media (max-width: 760px)`)**: the card is full width with 16px side margins (research R10).

  Use the Poppins font already set up.
- [X] T018 [US1] In `ui-personal-routine-manager/src/features/onboarding/pages/OnboardingPage.jsx`, call `const walkthrough = useWalkthrough({ autoOpen: 'onboarding' })` and render `<IntroSlides state={walkthrough.state} dispatch={walkthrough.dispatch} />` as the last child of `.ob-page`. Opening on every mount covers register, login, silent re-auth and revisits, because `App.tsx` already routes users with unfinished onboarding here (FR-001). Depends on T013, T016.
- [X] T019 [US1] Check by hand: run quickstart.md rows 1, 2 and 5 at desktop width, comparing against the 4 slide mockups. Then run `pnpm lint && pnpm build`.

**Checkpoint**: US1 is shippable on its own as the MVP. "Show me around" closes the slides, and the tour comes in US2.

---

## Phase 4: User Story 2 – Guided tour of the setup screen (P2)

**Goal**: "Show me around" on Slide 4 starts a 5-step tour that highlights the real controls, matching the tour mockups.

**Independent test**: open the slides, then press **Show me around** → steps 1–5 highlight the Weekday/Weekend switch, the board, +, Routine Buddy and Ready to roll, matching `resources/D · Tour 1–5 of 5 …png`.
- Step 1 has no Back.
- Step 5 has Back and Got it only.
- Clicking the dimmed area does nothing.
- Esc ends the tour.
- Skipping the slides never starts the tour.

(quickstart rows 3, 4, 5, 12)

- [X] T020 [P] [US2] Write `ui-personal-routine-manager/src/features/walkthrough/utils/placeCard.test.ts` **first**, for `placeCard({ target, card, viewport, side, gap = 12 })` per contracts/walkthrough-ui.md. Cases:
  - the preferred side fits → that side, with the card centered on the target
  - the preferred side overflows → the opposite side
  - both sides on that axis overflow → the other axis
  - nothing fits, or `target === null` → `side: 'center'`, centered in the viewport
  - the result is always clamped inside the viewport with a **16px** margin
  - `arrowOffset` points at the target's center, measured along the card edge

  Confirm the tests fail.
- [X] T021 [US2] Implement `ui-personal-routine-manager/src/features/walkthrough/utils/placeCard.ts` (pure, no DOM access) so T020 passes.
- [X] T022 [P] [US2] Add `TOUR_STEPS: TourStepContent[]` to `ui-personal-routine-manager/src/features/walkthrough/content/walkthroughContent.ts`, with text **verbatim** from walkthrough-script.md Part 2:

  | # | target | side | mobileView | text |
  |---|--------|------|------------|------|
  | 1 | `schedule-switch` | `bottom` | — | "You have two default routines. Switch here to set up each one." |
  | 2 | `routine-board` | `right` | `'board'` | "This is your default routine. Every new day starts as a copy of it." |
  | 3 | `add-task` | `top` | `'board'` | "Add a task yourself: name, start time, length." |
  | 4 | `routine-buddy` | `left` | `'chat'` | "Or just tell Buddy about your day, and it fills in the board for you." |
  | 5 | `finish` | `bottom` | `'board'` | "When both routines look right, finish here. Your changes are already saved as you go." |

  Depends on T014 (same file).
- [X] T023 [US2] Add the `data-tour` anchors from contracts/walkthrough-ui.md:
  - In `ui-personal-routine-manager/src/features/onboarding/pages/OnboardingPage.jsx`:
    - `data-tour="schedule-switch"` on the `.ob-segmented` div
    - `data-tour="routine-board"` on `section.ob-canvas-card`
    - `data-tour="finish"` on the `.ob-ready-btn` button
  - In `ui-personal-routine-manager/src/features/onboarding/components/FabButton.tsx`: accept and spread `data-tour` onto the button, and pass `data-tour="add-task"` from `OnboardingPage.jsx`.
  - In `ui-personal-routine-manager/src/features/onboarding/components/BuddyChat.jsx`: accept a `tourId` prop and set `data-tour={tourId}` on its root element. Pass `tourId="routine-buddy"` only to the **visible** chat; see T037.

  Do not change behaviour or styles.
- [X] T024 [US2] Create `ui-personal-routine-manager/src/features/walkthrough/components/GuidedTour.tsx` (`props: { state; dispatch; onMobileViewChange?: (v: 'board' | 'chat') => void }`). It renders only when `state.phase === 'tour'`, following contracts/walkthrough-ui.md:
  - **Blocker**: a full-screen transparent layer that swallows pointer events, so clicking the dimmed area does nothing.
  - **Spotlight**: a `.wt-spotlight` element placed over the target `document.querySelector('[data-tour="…"]').getBoundingClientRect()`, plus 6px padding. Its large box-shadow dims everything else.
  - **Card**: a `.wt-tour-card` positioned by `placeCard`, with an arrow at `arrowOffset`.
  - **Header**: "n of 5" plus a 5-segment progress bar.
  - **Footer buttons**:
    - Step 1: End tour · Next.
    - Steps 2–4: End tour · Back · Next.
    - Step 5: Back · **Got it** (→ `END`).
  - **Re-measure** on step change, on `resize`, on `scroll` (capture), and through a `ResizeObserver` on the target.
  - **Missing target** → centered card with no spotlight.
  - **Keys**: Esc → `END`, ← → `BACK`, → → `NEXT`.
  - **Focus**: move focus to the card.
  - **Phones** (`matchMedia('(max-width: 760px)')`):
    - The card is a full-width sheet at the bottom, or at the top when the target's center is in the lower half.
    - On each step, call `onMobileViewChange(step.mobileView)` when it is set.
    - Remember the view when the tour started and restore it on `END`.

  Depends on T012, T021, T022.
- [X] T025 [P] [US2] Add tour styles (`.wt-tour-blocker`, `.wt-spotlight`, `.wt-tour-card`, `.wt-tour-arrow`, `.wt-tour-progress`, `.wt-tour-seg`, `.wt-tour-seg--done`, `.wt-tour-sheet`) to `ui-personal-routine-manager/src/App.css`, matching `resources/D · Tour 1–5 of 5 …png`:
  - **Spotlight**: radius 14px, glowing light-blue outline (`0 0 0 3px #8cc8ff, 0 0 18px 4px rgba(26,111,212,.35)`), plus `0 0 0 9999px rgba(15,23,42,0.45)` for the dim. Animate top, left, width and height over 200ms, with no animation when `prefers-reduced-motion` is set.
  - **Card**: white, max width 320px, radius 12px, padding 16px.
  - **Step counter**: blue, 12px.
  - **Progress segments**: 16×3px, blue when done, grey otherwise.
  - **Buttons**: Back is outlined, Next/Got it is blue, End tour is plain text.
  - **Sheet**: full width with 16px margins (≤760px).
- [X] T026 [US2] In `ui-personal-routine-manager/src/features/onboarding/pages/OnboardingPage.jsx`, render `<GuidedTour state={walkthrough.state} dispatch={walkthrough.dispatch} onMobileViewChange={setMobileView} />` next to `<IntroSlides/>`. Depends on T018, T023, T024.
- [X] T027 [US2] Check by hand: quickstart.md rows 3, 4 and 5 at desktop width (compare with the 5 tour mockups), then row 12 at 390px width (step 4 switches to chat, step 5 back to board, the view is restored after the tour). Then run `pnpm lint && pnpm build && pnpm test`.

**Checkpoint**: US1 + US2 together give the full first-run experience.

---

## Phase 5: User Story 3 – Progress is kept and instructions return until onboarding is done (P2)

**Goal**: Weekday and Weekend are really separate routines (decision D2). Every change saves straight away. Failures are visible (FR-011). The instructions keep returning until "Ready to roll", and never after.

**Independent test**:
- As a new user, add a Weekday task by hand and a Weekend task through Routine Buddy, then log out and back in. The slides return, and Skip shows both tabs with their own tasks.
- Stop the backend and drag a task → an error banner appears.
- Press Ready to roll, then log in again → the dashboard opens and there are no slides.
- A Saturday with weekend tasks copies the Weekend routine. A Saturday without them copies Weekday.

(quickstart rows 6, 7, 8, 10, 13, plus the API smoke test)

### Backend tests (write first; they must fail)

- [X] T028 [P] [US3] Add tests to `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/apptest/OnboardingRoutineTest.java`:
  - **(a)** after registering, the user has exactly 2 default routines: "Weekday Routine" (`DAILY`) and "Weekend Routine" (`WEEKEND`), both with 0 tasks.
  - **(b)** for a user with only a `DAILY` routine, `getOrCreateDefaultRoutine(userId, WEEKEND)` creates one empty `WEEKEND` routine, and a second call returns the **same id** (idempotent).
  - **(c)** `GET /api/v1/default-routine/users/{id}` with no `type` returns `routineType` `DAILY`.
  - **(d)** `GET …?type=FOO` returns **400**.

  Use `MockMvc` for (c) and (d) if the test class already uses it; otherwise add `@AutoConfigureMockMvc`.
- [X] T029 [P] [US3] Add `resolveTemplateFor` tests to `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/RoutineServiceIntegrationTest.java`, following the rule in data-model.md §1: "Saturday or Sunday: use `WEEKEND` if it exists and has ≥ 1 task. Otherwise use `DAILY`. Any other day: use `DAILY`." Cases:
  - Wednesday → DAILY
  - Saturday with a WEEKEND routine that has 1 task → WEEKEND
  - Saturday with an empty WEEKEND routine → DAILY
  - Sunday with no WEEKEND routine → DAILY
  - `ensureDailyRoutine(userId, <a Saturday>)` copies the weekend task names when WEEKEND has tasks

### Backend implementation

- [X] T030 [US3] In `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/DefaultRoutineService.java`, add:
  - `getOrCreateDefaultRoutine(UUID userId, RoutineTypeEnum type)`:
    - `DAILY` missing → 404 (`ResponseStatusException`).
    - `WEEKEND` missing → create and save an empty routine named "Weekend Routine" with `routineType = WEEKEND`, then return it.
    - Add the comment `// GET-creates by design: see specs/002-onboarding-instruction/research.md R2`.
  - `public DefaultRoutine resolveTemplateFor(User user, LocalDate date)`: Saturday or Sunday (`getDayOfWeek().getValue() >= 6`) → the `WEEKEND` routine if present with `!getTasks().isEmpty()`; otherwise, and on any other day, → `DAILY`. A missing `DAILY` throws 404.

  Depends on T004.
- [X] T031 [US3] In `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/UserService.java`, make `createUserAndDefaultRoutine` create **two** routines: name "Weekday Routine" with `DAILY`, and name "Weekend Routine" with `WEEKEND`, both empty. Use `routineService.createDefaultRoutine`.
- [X] T032 [US3] In `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/api/DefaultRoutineController.java`, change `getDefaultRoutineForUser` to take `@RequestParam(name = "type", defaultValue = "DAILY") DefaultRoutine.RoutineTypeEnum type` and call `getOrCreateDefaultRoutine(userId, type)`. Make an invalid `type` return **400**: check `api/GlobalExceptionHandler.java`, and if it doesn't map `MethodArgumentTypeMismatchException` to 400 with an `ApiError` body, add that handler. Contract: contracts/default-routine-api.md.
- [X] T033 [US3] Route day creation through the resolver:
  - In `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/DailyRoutineService.java`:
    - `createDailyRoutineFromDefault(user, date)` uses `defaultRoutineService.resolveTemplateFor(user, date)`. Inject `DefaultRoutineService` if it isn't already.
    - `spawnDailyRoutineForUser(user)` uses `resolveTemplateFor(user, LocalDate.now())`.
    - Delete `spawnWeekendRoutineForUser`.
  - In `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/service/cronjobs/DailyTaskSpawningJob.java`, the private `spawnDailyRoutineForUser` just calls `dailyRoutineService.spawnDailyRoutineForUser(user)`, with no weekday/weekend branching.
  - Remove `User.getWeekendDefaultRoutine()` from `model/User.java` if nothing else uses it.

  Watch for a circular dependency if `DefaultRoutineService` injects `DailyRoutineService`. If it does, move `resolveTemplateFor` into `DailyRoutineService` and inject only the repository.
- [X] T034 [US3] Run `./gradlew test` in `ms-personal-routine-manager/`. T028, T029 and all baseline tests must pass. Then run the "API smoke test" in quickstart.md against `./gradlew bootRun`.

### Frontend implementation

- [X] T035 [P] [US3] Write `ui-personal-routine-manager/src/features/onboarding/utils/routineTypeForTab.test.ts` first (`'weekday'` → `'DAILY'`, `'weekend'` → `'WEEKEND'`), then `ui-personal-routine-manager/src/features/onboarding/utils/routineTypeForTab.ts` exporting `routineTypeForTab(tab: 'weekday' | 'weekend'): RoutineType`.
- [X] T036 [P] [US3] Create `ui-personal-routine-manager/src/features/onboarding/api/defaultRoutine.ts`:
  - `export type RoutineType = 'DAILY' | 'WEEKEND'`
  - `export async function fetchDefaultRoutine(userId: string, type: RoutineType): Promise<DefaultRoutine>`, returning `apiRequest<DefaultRoutine>(\`/api/v1/default-routine/users/${userId}?type=${type}\`, { method: 'GET' })`
  - Import `DefaultRoutine` with `import type` from `../types/routine.ts`.
- [X] T037 [US3] Rework routine state in `ui-personal-routine-manager/src/features/onboarding/pages/OnboardingPage.jsx` (data-model.md §5, research R5):
  - **Remove** the local `fetchDefaultRoutine`.
  - **State**: `const [routines, setRoutines] = useState({ weekday: null, weekend: null })`. On mount, load both with `fetchDefaultRoutine(authContext.user.id, 'DAILY'|'WEEKEND')`.
  - **Active routine**: `activeRoutine = routines[scheduleMode]`. `refreshRoutine(tab = scheduleMode)` refreshes only that tab.
  - **Use `activeRoutine` for**:
    - `EditingBoard routine`
    - the FAB's `disabled={!activeRoutine?.id}`
    - `TaskEditModal` create (`createDefaultTasks(activeRoutine.id, …)`)
    - delete and drag persist, then `refreshRoutine()`
  - **Chat**: render **two** `BuddyChat` instances, one per tab. Hide the inactive one (`hidden` attribute, or a wrapper with `display:none`) and give `tourId="routine-buddy"` only to the active one. Each one's `onSend` posts **its own** routine with `submitOnboardingChat(user.id, routines.weekday|weekend, message)`, and `onAfterSend` refreshes that tab.

  Depends on T023, T035, T036.
- [X] T038 [US3] Make save and load failures visible (FR-011, research R9):
  - In `ui-personal-routine-manager/src/features/onboarding/components/EditingBoard.jsx`, add an optional prop `onPersistError(error)` and call it in place of `console.error('Failed to update tasks', error)`.
  - In `OnboardingPage.jsx`:
    - **State**: `const [routineError, setRoutineError] = useState(null)`.
    - **Load failure**: **keep the previously loaded routine** (never replace it with `{ tasks: [] }`) and set "Couldn't load your routine." with a **Retry** button that calls `refreshRoutine()`.
    - **Drag or delete failure**: set "Couldn't save that change. Your board was reloaded." and call `refreshRoutine()`.
    - **Banner**: render it with the existing `.alert.alert-error` markup under the top bar, and clear it on the next successful load.

  `TaskEditModal` already shows its own errors; leave it as is.
- [X] T039 [US3] Apply the setup screen text from walkthrough-script.md Part 2b in `OnboardingPage.jsx`:
  - **Board subtitle**: replace `<span className="ob-block-count">Drag to reorder</span>` with "Every new weekday starts as a copy of this · drag to move" (Weekday tab) or "Every new weekend day starts as a copy of this · drag to move" (Weekend tab), as a subtitle under the `h1`.
  - **Buddy greeting**: set both `BuddyChat` `initialMessage`s to "Hi! I'm your Routine Buddy. Tell me about your day, like \"I wake up at 7:00 and work 9 to 5\", and I'll build the routine. Or tap + to add tasks yourself."
- [X] T040 [US3] Check by hand: quickstart.md rows 6, 7, 8, 10 and 13. Then run `pnpm lint && pnpm build && pnpm test`.

**Checkpoint**: the two routines are real, saving is visible, and the onboarding gate behaves per FR-001, FR-002 and FR-009 to FR-011.

---

## Phase 6: User Story 4 – Replay the instructions on demand (P3)

**Goal**: a **How it works** button replays the instructions: on the setup screen (slides + tour), and on the dashboard after onboarding (slides only, ending with **Close**).

**Independent test**:
- As an onboarded user on the dashboard, press How it works → the slides open from Slide 1. Slide 4 shows **Close** and no *I'll explore myself*. Closing leaves routines and onboarding status unchanged.
- On the setup screen, How it works → slides, then the tour.

(quickstart rows 9, 11)

- [X] T041 [P] [US4] Create `ui-personal-routine-manager/src/features/walkthrough/components/HowItWorksButton.tsx`: a `type="button"` text button labelled "How it works", with class `wt-how-btn` and props `{ onClick: () => void }`.
- [X] T042 [P] [US4] Add `.wt-how-btn` to `ui-personal-routine-manager/src/App.css`, matching the mockup top bar (plain slate text, 14px, no border, blue on hover). Keep it visible at ≤760px.
- [X] T043 [US4] In `ui-personal-routine-manager/src/features/onboarding/pages/OnboardingPage.jsx`, render `<HowItWorksButton onClick={() => walkthrough.open('onboarding')} />` as the first child of `.ob-top-actions`, to the left of the Weekday/Weekend switch as in the mockups. Depends on T018, T041.
- [X] T044 [US4] In `ui-personal-routine-manager/src/features/daily/pages/DailyRoutinePage.jsx`, call `const walkthrough = useWalkthrough({})` (no auto-open). In `.dr-topbar`, render `<HowItWorksButton onClick={() => walkthrough.open('app')} />` just before the **Sign Out** button (wrap both in a flex group if needed). Render `<IntroSlides state={walkthrough.state} dispatch={walkthrough.dispatch} />`. **Do not** render `GuidedTour` here (FR-013). Depends on T016, T041.
- [X] T045 [US4] Check by hand: quickstart.md rows 9 and 11. Confirm that closing the replay makes no network requests (DevTools Network tab; FR-014).

**Checkpoint**: all four user stories work.

---

## Phase 7: Polish & cross-cutting

- [X] T046 [P] Update `ui-personal-routine-manager/CLAUDE.md`:
  - "No test framework is configured" → the `pnpm test` (Vitest) command.
  - The onboarding note "weekday/weekend toggle is visual only" → the two routines are loaded by `?type=`.
  - Add a "Walkthrough" note: `features/walkthrough/`, the content is mirrored from walkthrough-script.md, and the tour relies on `data-tour` attributes (search for `data-tour=` before refactoring the setup screen).
- [X] T047 [P] Update `ms-personal-routine-manager/CLAUDE.md`:
  - Domain model: a user has one routine per type, and registration creates both.
  - "Weekend vs weekday": `resolveTemplateFor` is used by daily creation, spawn and the cron job, and an empty Weekend routine falls back to Weekday.
  - Mention the `?type=` get-or-create.
- [X] T048 Run the full validation:
  - `pnpm test && pnpm lint && pnpm build` in `ui-personal-routine-manager/`
  - `./gradlew test` in `ms-personal-routine-manager/`
  - every row of quickstart.md at desktop width (≥1200px) and phone width (390px)

  Record any failures under "Validation notes" at the end of this file.
- [X] T049 Update the ticket `specs/002-onboarding-instruction/F001-onboarding-instruction.md` in the "Claude Working Notes" section only:
  - Status `Implemented`
  - tick the working-plan items
  - add a Discussion log entry summarising what shipped and any deviations from plan.md

---

## Dependencies & execution order

### Phase dependencies

- **Setup (P1)**: none.
- **Foundational (P2)**: after Setup. **Blocks every user story.** T003 → T004 → T007. T005, T006 and T008 can run in parallel after T003. T009 last. T010 and T011 run in parallel → T012 → T013.
- **US1 (P3)**: after Foundational.
- **US2 (P4)**: after US1, because it extends the same content file and page (T022 needs T014, T026 needs T018).
- **US3 (P5)**:
  - The **backend part (T028–T034) can start right after Foundational**, alongside US1 and US2.
  - The frontend part needs T023 from US2 (the `tourId` pass-through) before T037.
- **US4 (P6)**: after US1 (needs `IntroSlides` and `useWalkthrough`). Independent of US2 and US3.
- **Polish (P7)**: after all stories.

### Story completion order

```text
Setup ─► Foundational ─┬─► US1 ─► US2 ─┐
                       │      └──► US4 ├─► Polish
                       └─► US3 (backend) ─► US3 (frontend, after T023) ┘
```

### Within each story

Tests first (and failing) → pure logic → components → page wiring → manual check.

### Same-file sequencing (never parallel)

- `OnboardingPage.jsx`: T018 → T023 → T026 → T037 → T038 → T039 → T043
- `walkthroughContent.ts`: T014 → T022
- `App.css`: T017 → T025 → T042. Each adds a separate block, but they edit the same file, so run them in sequence.
- `DefaultRoutineService.java`: T004 → T030
- `DailyRoutineService.java`: T005 → T033
- `DefaultRoutineController.java`: T007 → T032
- `RoutineServiceIntegrationTest.java`: T008 → T029

## Parallel examples

```text
# Foundational, after T003:
T005 DailyRoutineService findByUserAndRoutineType
T006 AiRoutineFunctions findByUserAndRoutineType
T008 RoutineServiceIntegrationTest findByUserAndRoutineType
T010 walkthrough types          (frontend, independent)
T011 walkthroughReducer tests   (frontend, independent)

# US1 kickoff:
T014 walkthroughContent SLIDES
T015 icons.tsx
T017 slide CSS

# US3 backend tests while US1/US2 frontend proceeds:
T028 OnboardingRoutineTest additions
T029 resolveTemplateFor tests

# US3 frontend helpers:
T035 routineTypeForTab (+ test)
T036 defaultRoutine.ts API

# US4:
T041 HowItWorksButton
T042 .wt-how-btn CSS
```

## Implementation strategy

### MVP first (US1 only)

1. Phase 1 → Phase 2 (backend lookup refactor + reducer).
2. Phase 3 (US1): the intro slides on every unfinished-onboarding visit.
3. **Stop and validate** with quickstart rows 1, 2 and 5. This is already shippable: users and interviewers get the explanation.

   Caveat: the slides mention two routines, but the Weekend tab doesn't keep its own routine until US3. Ship US3 soon after US1, or together with it.

### Incremental delivery

1. US1 → slides (MVP)
2. US2 → tour on top
3. US3 → real Weekday/Weekend + visible save errors. Its backend part can be built in parallel from the start.
4. US4 → "How it works" replay
5. Polish → docs + full quickstart pass

---

## Baseline

Recorded on 2026-11-20 against the local PostgreSQL container `routine-manager-dbdo` (port 5469). `docker compose` isn't installed, but the container was already running.

`./gradlew test`: **8 tests, 2 failed before any change.**
- `OnboardingRoutineTest.onboardingWorkflowCreatesUserAndDefaultRoutineWithTasks`: 404
- `OnboardingRoutineTest.addDefaultTasksAcceptsSingleTaskObjectPayload`: 404

Both call `POST /api/users` and `GET /api/routine-manager/default-routine/{userId}`. Neither endpoint exists any more (users are created through `/api/v1/auth/register`, and default routines live under `/api/v1/default-routine`). These are stale tests, not caused by this feature. They are left as they are, and the new tests don't use those paths.

## Validation notes

Run on 2026-11-20.

**Automated**
- `pnpm test`: 3 files, **29/29 pass**.
- `pnpm build`: passes.
- `pnpm lint`: 0 errors. 2 warnings, both already there before this feature (`EditingBoard.jsx:121`, `DailyRoutinePage.jsx:75`).
- `./gradlew test`: 17 tests, **15 pass**. The 2 failures are the stale baseline tests (see Baseline). All 9 new tests pass.
- API smoke test (quickstart): no `type` → DAILY. `type=WEEKEND` → the same id on repeated calls. `type=FOO` → 400.

**Manual (quickstart.md)**
- Run as a scripted headless-Chrome pass against `pnpm dev` + `bootRun`, with a freshly registered user, at 1440×900 and 390×844. **40/40 checks pass.**
- Covered: rows 1–12, every slide and tour step compared with the mockups in `resources/`, and no console errors.
- Row 13 (a Saturday copies the Weekend routine) is covered by the backend test `ensureDailyRoutineCopiesWeekendTasksOnSaturday`, not through the UI.

**Deviations from the plan, and what was fixed along the way**
1. **Existing bug fixed** (`src/app/App.tsx`): login and silent re-auth read `onboardingCompleted`, but `GET /api/users/{id}/onboarding/complete` returns the User entity, whose flag is `onboardCompleted`. So onboarded users were always sent back to `/onboarding`, which broke FR-002. The flag is now read as `onboardCompleted`, keeping `onboardingCompleted` as a fallback.
2. **Slide icons** come from the existing Figma icon set in `src/components/icons/` (`CalendarIcon`, `RepeatIcon`, `BarChartIcon`, `SparklesIcon`), not new SVGs. `walkthrough/components/icons.tsx` only maps names to them.
3. **Card alignment**: `placeCard` gained `align: 'start'`, used by tour steps 2 and 4, so their cards sit near the top of tall panels as in the mockups. A unit test was added.
4. **Phone tour, step 1** also switches to the board view, because the Weekday/Weekend switch is hidden in the phone chat view.
5. **Save error text** is "Couldn't save that change." (with Retry), not "…Your board was reloaded.", because the reload itself can fail. The message stays visible after a successful reload. Load failures show "Couldn't load your routine." with Retry.
6. **Removed code**: `DailyRoutineService.spawnWeekendRoutineForUser` and `User.getWeekendDefaultRoutine()`. The cron job now uses `resolveTemplateFor`.
7. **New file**: `ms-personal-routine-manager/.dockerignore`. It keeps `build/libs/`, which the Dockerfile copies.
