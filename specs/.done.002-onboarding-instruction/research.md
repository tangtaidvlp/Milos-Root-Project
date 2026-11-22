# Research: Onboarding Instruction

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Date**: 2026-11-20

Each entry records the decision, why, and what else was considered. Facts about current code were checked against the repos on 2026-11-20.

---

## R1. Where the Weekend routine lives

**Decision**: Reuse the existing `DefaultRoutine` entity with `routineType = WEEKEND`. Each user has at most one routine per type (`DAILY` = weekday, `WEEKEND`). No new table or column.

**Rationale**:
- The enum value `WEEKEND` exists already (`DefaultRoutine.RoutineTypeEnum`), and so does `User.getWeekendDefaultRoutine()`.
- The midnight cron job (`DailyTaskSpawningJob`) already prefers a weekend routine on Saturday and Sunday.
- Because the column already exists, `ddl-auto: validate` in `prod` keeps passing. No migration is needed.

**Alternatives considered**:
- A new `WeekendRoutine` entity: duplicates the model and the AI tools. Rejected.
- Day-of-week rules on tasks: much larger change, and not what the spec asks for. Rejected.

**Blocking finding**: `DefaultRoutineRepository.findByUser(user)` returns `Optional<DefaultRoutine>`. Once a user has two routines, Spring Data throws `IncorrectResultSizeDataAccessException` from every caller. There are 7 call sites in `main`:
- `DefaultRoutineService` ×2
- `DailyRoutineService` ×2
- `config/AiRoutineFunctions` ×3

There are 4 more in `RoutineServiceIntegrationTest`. All of them must move to a type-aware lookup **before** any weekend routine can be created. → Add `findByUserAndRoutineType(User, RoutineTypeEnum)` and remove `findByUser`.

---

## R2. How users get a Weekend routine

**Decision**:
1. **New users**: `UserService.createUserAndDefaultRoutine` creates both routines, "Weekday Routine" (`DAILY`) and "Weekend Routine" (`WEEKEND`). Both start empty.
2. **Existing users** (they only have `DAILY`): `GET /api/v1/default-routine/users/{userId}?type=WEEKEND` gets the weekend routine, or creates an empty one if it is missing. It is idempotent, so calling it again returns the same routine.

**Rationale**: no migration tool is set up (Hibernate `ddl-auto` only), so a backfill script would be a one-off manual step. Get-or-create on first read is a single round trip, and it can't leave a user without a weekend tab.

**Alternatives considered**:
- Backfill SQL: needs manual production access, and it is easy to forget for `sit`. Rejected.
- `404` then the client calls `POST`: two round trips, plus a race if both tabs load at once. Rejected.
- Creating the weekend routine as a copy of the weekday tasks: surprising for users, and it fights R3's fallback. Rejected.

**Trade-off**: a GET that can write. This is acceptable because it is idempotent and only ever creates the one missing, empty routine. It is documented in the contract.

---

## R3. Which routine a day is copied from

**Decision**: one helper, `DefaultRoutineService.resolveTemplateFor(user, date)`:
- **Saturday or Sunday**: use `WEEKEND` if it exists **and has at least one task**. Otherwise use `DAILY`.
- **Any other day**: use `DAILY`.

All three places that create a day from a template go through it:
- `DailyRoutineService.createDailyRoutineFromDefault` (used by `getOrCreateDailyRoutine` and `ensureDailyRoutine`)
- `DailyRoutineService.spawnDailyRoutineForUser`
- `DailyTaskSpawningJob`

**Rationale**:
- Today, opening a weekend date on the dashboard always copies the weekday routine, while the cron job copies the weekend one. That inconsistency gets worse once weekend routines are real.
- The "has tasks" rule covers the spec edge case "finish without setting up both routines". Users who skip the weekend tab keep getting their weekday plan on weekends instead of an empty day. Without the rule, R2 would make every weekend empty for those users.

**Alternatives considered**: always use `WEEKEND` on weekends. Rejected, because empty weekends would be a regression for every existing user.

---

## R4. API shape for two routines

**Decision**: add an optional `type` query parameter (`DAILY` | `WEEKEND`, default `DAILY`) to `GET /api/v1/default-routine/users/{userId}`. All other default-routine endpoints are already routine-id based and stay unchanged. See [contracts/default-routine-api.md](./contracts/default-routine-api.md).

**Rationale**: backwards compatible. The current client call without `type` keeps getting the weekday routine.

**Alternatives considered**:
- `GET /users/{userId}/all` returning a list: the client would have to pick by type anyway, and the GET-creates rule (R2) gets murkier. Rejected.
- Separate `/weekend` path: endpoints multiply for no gain. Rejected.

---

## R5. Routine Buddy with two routines

**Decision**:
- **Backend**: no change. The setup screen sends the routine of the **active tab** as `defaultRoutine` in `POST /api/ai/chat/default-routine/{userId}`. `DefaultRoutineAiTools` already act on a routine by id. The chat memory id is `userId-routineId`, so the two routines get separate threads on the server.
- **Frontend**: render one `BuddyChat` per tab and hide the inactive one, so each tab keeps its own visible thread, matching the server.

**Alternatives considered**:
- One shared chat thread: the server has two memories, so the visible history would not match what the AI remembers. Rejected.
- Remounting a single chat on tab switch (`key=`): loses the visible history on every switch. Rejected.

---

## R6. Building the slides and tour: library or custom

**Decision**: custom, with no new runtime dependency.
- **Slides**: a modal card.
- **Tour**: an overlay with a "spotlight" element. The spotlight is positioned over the target's `getBoundingClientRect()`, and a large `box-shadow` dims everything else. The card is positioned next to the spotlight.
- **Targets**: found by `data-tour="<id>"` attributes.
- **Re-measuring**: on `resize`, on `scroll` (capture), and through a `ResizeObserver` on the target.

**Rationale**:
- The mockups use a specific look: glowing outline, card with arrow, 5-segment progress, and exceptions on steps 1 and 5. That is easier to match exactly than to theme a library.
- The rest of the app uses no UI libraries (plain CSS, no framework).
- The logic is small: 5 fixed steps and one screen.

**Alternatives considered**:
- `react-joyride`: heavy, and its React 19 support has lagged. Rejected.
- `driver.js` and `shepherd.js`: imperative DOM APIs that don't fit React state well, and restyling them to the mockups would cost as much as building it. Rejected.

---

## R7. Walkthrough state

**Decision**: a pure reducer, `walkthroughReducer`, wrapped by a `useWalkthrough` hook.

State:

```ts
type WalkthroughState =
  | { phase: 'hidden' }
  | { phase: 'slides'; index: number; context: 'onboarding' | 'app' }
  | { phase: 'tour'; index: number }
```

Events: `OPEN(context)`, `NEXT`, `BACK`, `JUMP(i)`, `SKIP`, `START_TOUR`, `END`.

Rules:
- The tour only starts from `START_TOUR`, which is the "Show me around" button (FR-008).
- In the `app` context, the slides end with **Close**, and there is no tour (FR-013).
- `OnboardingPage` dispatches `OPEN('onboarding')` on every mount. That covers register, login, silent re-auth and revisits (FR-001), because `App.tsx` already routes users with unfinished onboarding to `/onboarding` on all of them.
- Nothing is persisted (spec Assumptions: no "seen" record).

**Rationale**: a reducer keeps every navigation rule in one testable function with no DOM, so FR-005, FR-007, FR-008 and FR-013 can be unit tested.

---

## R8. Testing approach

**Decision**:
- **Frontend**: add **Vitest** as the only new dev dependency, with a `pnpm test` script and the default node environment. Unit-test:
  - `walkthroughReducer` (all navigation rules)
  - `placeCard` (pure positioning and flipping maths)
  - `routineTypeForTab`

  The visual and interactive behaviour is checked by hand with [quickstart.md](./quickstart.md).
- **Backend**: extend the existing `@SpringBootTest` tests (they run on the default `local` profile, so PostgreSQL must be up):
  - two routines per user after register
  - get-or-create weekend
  - `type` parameter defaulting
  - `resolveTemplateFor` rules (weekday, weekend with tasks, empty weekend → fallback)

**Rationale**: the frontend currently has no test framework. Vitest comes from the Vite team and needs no config beyond a script. A DOM test setup (jsdom + Testing Library) would roughly double the setup for little gain on 9 fixed screens.

**Alternatives considered**: Playwright end-to-end tests. Good later, but they need the backend running in CI. Deferred.

---

## R9. Showing save failures (FR-011)

**Findings**:
- `OnboardingPage.refreshDefaultRoutine` swallows errors and replaces the routine with `{ tasks: [] }`. This also caused bug 001.
- `EditingBoard` only does `console.error` when a drag fails to save.
- `TaskEditModal` already shows save errors in the modal.

**Decision**:
- A failed refresh **keeps the last loaded routine** and shows an inline error banner on the setup screen ("Couldn't load your routine. Retry").
- Drag and delete failures show the same banner ("Couldn't save that change. Your board was reloaded."), followed by a refresh, so the board never shows something unsaved.
- `EditingBoard` gets an `onPersistError` callback in place of the `console.error`.

---

## R10. Phone behaviour (no phone mockups)

**Decision**: the breakpoint is `max-width: 760px`, the same one the existing `ob-page` uses for its board/chat switch.
- **Slides**: full-width card with 16px side margins. Swipe changes slides when the horizontal pointer movement is over 50px and larger than the vertical movement.
- **Tour**: the card becomes a full-width bottom sheet. It sits above the bottom of the screen, or at the top when the target is in the lower half.
  - Step 4 switches `mobileView` to `'chat'`.
  - Step 5 switches it back to `'board'`.
  - Leaving the tour restores the view the user had before it started.

---

## R11. Where the content lives

**Decision**: one file, `features/walkthrough/content/walkthroughContent.ts`, holds all slide and step text plus each step's target id and preferred card side. It mirrors [walkthrough-script.md](./walkthrough-script.md): edit the script first, then this file.

---

## R12. "How it works" after onboarding

**Decision**: `DailyRoutinePage`'s top bar gets a **How it works** text button to the left of **Sign Out**. It opens the slides in the `app` context: Slide 4's primary button reads **Close**, and *I'll explore myself* is hidden. `OnboardingPage`'s top bar gets the same button, which opens the `onboarding` context (slides, then the tour).

---

## R13. Setup screen text from the mockups

**Decision**: implement walkthrough-script Part 2b with the instruction feature:
- **Board subtitle**: "Every new weekday starts as a copy of this · drag to move". On the Weekend tab it reads "weekend day", for grammar.
- **Routine Buddy greeting**: the new greeting text.
- **"How it works" link**: in the top bar.

The board title follows the tab ("Weekday Routine" / "Weekend Routine"), as it already does.
