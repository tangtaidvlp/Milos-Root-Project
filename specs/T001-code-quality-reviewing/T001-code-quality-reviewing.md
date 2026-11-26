# T001 – Code quality reviewing

**Type**: Task
**Parent**: —

## Summary

Fix the structural issues found in the frontend architecture review (`ui-personal-routine-manager/src/`, 2026-11-26). Refactor only: no behaviour change. Review page: https://claude.ai/artifact/Q1i6jVbrp9xXr89JBfy6Tu

| # | Severity | Issue | Evidence | Solution |
|---|---|---|---|---|
| 1 | High | Shared code sits in one feature's folder (`features/onboarding/`) and is reused everywhere | 11 of its files are imported by daily, default-routine, reflection, radial-view, personal-target and `Sidebar.tsx`. This creates 4 import cycles: daily ↔ onboarding, default-routine ↔ onboarding, personal-target ↔ onboarding, radial-view ↔ onboarding | Solution provided|
| 2 | High | `App.tsx` does auth itself | 360 lines, 19 `useState` (10 are form fields, passed to `AuthPage` as 20 props), 5 direct `apiRequest` calls with `as any`, JWT decoded inline. Sign-in and refresh run the session start twice, building the user two different ways (response body vs JWT claims). Breaks the rule "API calls only in a feature's `api/`" | Solution accepted|
| 3 | High | `daily/pages/DailyRoutinePage.jsx` is a god component | 597 lines, 13 `useState`, untyped; 8 unrelated jobs: date helpers, date nav, plan CRUD, reflection mode, reset day, task modal, layout, two Buddy chat setups. Every task handler branches on `target === 'reality'`; `inReflection`/`reflectionReady` are checked in ~20 places | Solution accepted|
| 4 | Medium | The most-reused components are untyped | `EditingBoard.jsx` (614), `BuddyChat.jsx` (280), `BoardToolbar.jsx`, `CompareBoards.jsx`. Nothing checks that `RadialBoard` takes the same props as `EditingBoard`. Real drift: pages pass `label` to both boards, but `EditingBoard` has no `label` prop, so it's silently dropped. `RadialBoard` declares ignored props as `unknown` to fake the shared contract | Solution accepted (in steps 1 and 3)|
| 5 | Low–Medium | One global `App.css` for every feature | 3,711 lines, imported once in `App.tsx`, applies to every page: `.ob-*` 140, `.pt-*` 59, `.rf-*` 57, `.wt-*` 50, `.rv-*` 46 selectors. Costs findability and ownership; class prefixes are the only guard against cross-feature leaks. Dead CSS is negligible (2 of 340 classes: `logo-manager`, `rv-left`). 22 page-level rules reach into board/chat children for the phone board/chat swap | Solution accepted (ongoing, see "Styling")|

## Steps

### Step 0 – Fix B008 first (prerequisite)

[B008](../../AI-project-docs/bugs/B008.MD) is Critical: the frontend stores the access token but never sends it. This only goes unnoticed because the `local` and `fast` profiles turn auth off. Fix it on its own `fix/` branch, in parallel with steps 1 and 3. Step 2 starts only after B008 is merged.

- Why first: step 2 moves the session code that the fix touches (token set on login and refresh, cleared on logout). With B008 fixed, the steps below can be checked with auth on (`SPRING_PROFILES_ACTIVE=sit`) instead of hiding behind the auth-off profiles.
- The `accessToken` is **not** dead code. Keep it: B008 moves it into `lib/api.ts`.

### Step 1 – Move shared code out of onboarding (issues 1, 4)

**Root cause:** code shared by several features lives in one feature's folder, so every other feature reaches into it. The 4 import cycles are a symptom. Once the code has its own home, they go away.

**Where shared code goes:**
- Generic UI with no domain knowledge (like Button or Modal) → `src/components/`
- A pure function with no React, used by 2+ features or by shared code → `src/utils/`
- A domain widget used by 2+ features, with its own hooks, utils and types → its own building-block feature, `features/<name>/`. It has no page; pages import it, and it never imports a page.

Not everything goes into `src/components/`. The board and Buddy chat carry domain logic, so putting them there would mix layers and turn it into a dumping ground.

**Moves:** move each file, update the imports, and convert each moved `.jsx` to `.tsx`.

| From | To | Why |
|---|---|---|
| `onboarding/components/EditingBoard, BoardToolbar, ToolbarMoreMenu, TaskEditModal`, `onboarding/hooks/useBoardClock`, `onboarding/utils/taskSegments, boardScroll, duration`, `daily/utils/nowAndNext` | `features/board/` | Domain widget used by Today, Default routine, Onboarding, Reflection and Radial view. Fixes cycles 1 and 4 |
| `onboarding/components/BuddyChat, chatHistory`, `onboarding/types/chatHistory`, `personal-target/utils/buddyReply` (+ `GoalProposal` and `BuddyReply` types) | `features/buddy-chat/` | Domain widget used by every chat screen, and by Analytics next. Fixes cycle 3 |
| `onboarding/components/DefaultRoutineEditor`, `onboarding/hooks/useDefaultRoutines`, `onboarding/api/defaultRoutine, defaultRoutineTasks`, `onboarding/types/routine` | `features/default-routine/` | This is default-routine code; onboarding only reuses it. Fixes cycle 2 |
| `onboarding/utils/routineTypeForDate` | `src/utils/` | Pure function also used by `Sidebar.tsx` (shared code must not import a feature) |
| `onboarding/components/FabButton` | `src/components/` | Generic button with no domain logic |
| `onboarding/utils/routineTypeForTab` | `features/default-routine/utils/` | Only default-routine uses it; leaving it would keep an onboarding ↔ default-routine cycle that `import/no-cycle` can't see |

- `GoalProposalCard` stays in `personal-target`. `BuddyChat` gets it through a `renderProposal` prop, so `buddy-chat` never imports `personal-target`.
- Add one `BoardProps` type in `board/` that both `EditingBoard` and `RadialBoard` implement. It replaces `RadialBoard`'s `unknown` placeholder props, and a prop a board ignores must be declared there. Keep `EditingBoard` ignoring `label` for now (fixing it changes what screen readers announce; see the defect list in step 3).
- `CompareBoards.jsx` and `OnboardingPage.jsx` are not converted here; convert them when they're next changed (`codingrules.md`).
- Move the board components' styles out of `App.css` into CSS Modules next to them (`EditingBoard.module.css`, `BoardToolbar.module.css`, …), following "Styling" below. Leave the 22 page-level `[data-mobile-view]` rules in `App.css`.
- Add a short "Styling" section to `ui-personal-routine-manager/codingrules.md` with the layers and rules from "Styling" below.
- Add the `import` plugin and `"import/no-cycle": "error"` to `.oxlintrc.json`.
- Update the "Shared components (quirks)" section of `ui-personal-routine-manager/CLAUDE.md`.
- When this step is done, `onboarding/` holds only `OnboardingPage` and `completeOnboarding`.

### Step 2 – Move auth out of `App.tsx` (issue 2)

**Root cause:** the session (who is signed in) has no owner of its own. It lives in the router file, mixed with routing and form state, and its start-up flow is written twice.

**What `useAuthSession` solves:** one owner and one path for the session lifecycle (start, renew, end). It isn't about reuse: only `App.tsx` calls it, and pages keep reading `user` from `AuthContext`.

| New / changed | Holds |
|---|---|
| `features/auth/api/auth.ts` | `login`, `register`, `refresh`, `logout`, `fetchOnboardingStatus`, with typed responses and no `as any`. Also `decodeJwt` |
| `features/auth/hooks/useAuthSession.ts` | State: `user`, `isOnboardCompleted`, `isChecking`, with `isLoggedIn` computed from `user`. Actions: `signIn`, `signUp`, `signOut`, `markOnboarded`. Login and refresh share one `startSession`: one `toAuthUser()`, one settings load, one onboarding-status fetch. It sets and clears the access token through `setAccessToken()` in `lib/api.ts`, which B008 adds |
| `AuthPage` | Owns its form fields, errors and mode. Props go from 20 to 2 (`onSignIn`, `onSignUp`) |
| `OnboardingPage` | Owns its "completing / error" state, calls `completeOnboarding`, then `markOnboarded()` |
| `App.tsx` | `useAuthSession()` + providers + routes only (about 120 lines) |
| Delete | `src/context/Auth.ts` (unused duplicate of `AuthContext.ts`). Also the no-op `useEffect` on `accessToken`, if B008 hasn't already removed it |

- **Keep the access token.** After B008 it lives in `lib/api.ts`, not in `App.tsx` state.
- **Drop the `setUser(...)` call in `handleSignUp`.** Registering doesn't sign the user in, and with `isLoggedIn` computed from `user` that call would redirect the user. Nothing on the page reads it.
- Test `useAuthSession` with `vi.mock('../api/auth.ts')`: sign-in and refresh produce the same `user`, sign-out clears the user and the token.

### Step 3 – Split `DailyRoutinePage` (issues 3, 4)

**Root cause:** one component owns 8 unrelated jobs, so every Today feature (F007, F010, F012, F013, F016) landed in it, and plan and reflection logic are interleaved.

| New | State it owns | Actions it exposes | Takes over (current lines) |
|---|---|---|---|
| `daily/utils/dateInput.ts` | none (pure functions) | `toDateInputValue`, `parseDateInputValue`, `nextDefaultDraftTask` | L49-72 |
| `daily/hooks/useSelectedDate()` | `selectedDate`, plus computed `todayValue`, `isToday`, `isPast`, `isFuture` | `setDate`, `shift(±1)`, `goToday` | L79, L100-103, L230-234 |
| `daily/hooks/useDailyPlan(userId, date, { onChanged })` | `routine`, `loadError`, `isResetting`, `resetFailure` | `refresh`, `submitTask(mode, task)`, `persistTasks`, `deleteTask`, `toggleComplete`, `cleanUp`, `resetDay` | L106-121, the plan half of L210-317. Includes create-on-first-write and keeping the done flag |
| `reflection/hooks/useReflectionMode(userId, date, isFuture)` | `reflectionOn`, `reflection`, `error`, plus computed `inReflection`, `reflectionReady` | `toggle`, `start`, `refresh`, `submitTask`, `persistTasks`, `deleteTask`, `requestFeedback`, `sendChat` | L90-92, L126-189, the reality half of L210-278. Includes the stale-response guard and create-on-enter |
| `daily/components/DateNav.tsx` | none | props: `date`, `onShift`, `onPick`, `onToday` | JSX L386-417, `openDatePicker` L362-374 |

- **The page keeps view state only** (about 250 lines, converted to `.tsx`): task modal and its target, reset confirm, reflection popup task, phone board/chat swap, Timeline/Circle, hidden chat panel, compare vs single layout, the two `BuddyChat` setups and the JSX.
- **Same action names on both hooks** (`submitTask`, `persistTasks`, `deleteTask`): the page picks one with `const actions = target === 'reality' ? reflection : plan`, which replaces the three `if (target === 'reality')` branches.
- **Plan → reflection refresh** is wired once: `useDailyPlan(…, { onChanged: reflection.refresh })`.
- **Unit tests** (mock the feature `api/` modules): the stale-response guard, create-on-enter, create-on-first-write, keeping the done flag.

**Found during review, out of scope (behaviour change):** file these as a separate defect, so this step stays a pure refactor.
- [L113-115](../../ui-personal-routine-manager/src/features/daily/pages/DailyRoutinePage.jsx#L113-L115): a failed plan load shows an empty board with no error (breaks "never a silent empty state").
- [L218](../../ui-personal-routine-manager/src/features/daily/pages/DailyRoutinePage.jsx#L218) and [L226](../../ui-personal-routine-manager/src/features/daily/pages/DailyRoutinePage.jsx#L226): a failed delete is only logged to the console.
- [EditingBoard.jsx:104-123](../../ui-personal-routine-manager/src/features/onboarding/components/EditingBoard.jsx#L104-L123): the timeline has no `label` prop, so the "Day plan" / "Reality" / "Plan" labels pages pass are dropped, and it always announces "Timeline board" ([L401](../../ui-personal-routine-manager/src/features/onboarding/components/EditingBoard.jsx#L401)).

### Styling – ongoing rule (issue 5)

Not a step of its own. It applies from step 1 onward, and to every later change.

| Layer | File(s) | Scope |
|---|---|---|
| 1. Tokens | `styles/tokens.css` | Global CSS variables, both themes. Unchanged |
| 2. Primitives | `styles/base.css` (`.ui-btn`, `.ui-card`, …) | Global, generic, no domain knowledge. Unchanged |
| 3. Component styles | `Foo.module.css` next to `Foo.tsx` | Scoped by Vite CSS Modules. Replaces `App.css` one component at a time |

**Rules:**
1. Values come only from tokens (already enforced by `noRawColors.test.ts`, which also scans `.module.css`).
2. A component styles only its own elements. It never reaches into a child's classes; pass a prop or a `className` instead.
3. Variants use `data-*` attributes or props, not new global classes.
4. Promote a pattern to `base.css` as `.ui-*` only once a second feature needs it.

**Migration:** no big bang. When a component is touched, give it a `.module.css` and move its rules out of `App.css`. Class names stop mattering to tests, since no code or test selects by class.

**Later, when one of those pages is next touched (not in this task):**
- The 22 `[data-mobile-view]` rules belong in one shared `ChatPageLayout` component (`main` + `chat` slots) that replaces the board/chat swap repeated in Onboarding, Default routine, Today and Personal Target. Analytics would be the fifth.
- Switch `AuthPage`'s 2 old `.btn` / `.btn--primary` buttons to `.ui-btn`, and delete the unused `logo-manager` and `rv-left`.

**Not chosen:** Tailwind (a rewrite that works against the token tests) and CSS-in-JS (runtime cost).

## Done when

- `pnpm lint` passes with `import/no-cycle` on, and shows no cycles between features.
- No file outside a feature's `api/` calls `apiRequest`.
- `App.tsx` and `DailyRoutinePage` are each under ~300 lines, with no `.jsx` left in `board/`, `buddy-chat/` or `daily/pages/`.
- `pnpm build`, `pnpm test` and `pnpm test:e2e` (all journeys) are green, with no behaviour change, against a backend with auth on (`SPRING_PROFILES_ACTIVE=sit`).

## Notes

- Branch type: `refactor/`. Runs in parallel with B008 in its own worktree. **Order: step 1 → step 3 → step 2**, because step 2 builds on B008's token setter and waits for its merge, while steps 1 and 3 don't touch auth. Until B008 is merged, e2e runs against `fast` (auth off); the final auth-on run happens after it.
- **One step at a time:** fix → review → test → commit, then start the next step. Never start a step before the previous one is committed. Each step leaves `pnpm lint`, `pnpm test` and the touched e2e journeys green.
- Size: roughly 2.5–3.5 days in total (step 1 is 1–2 days, step 2 half a day, step 3 one day). That is bigger than a typical task. If you want separate reviews or merges, split it into T001 (step 1), T002 (step 2) and T003 (step 3).
- Do step 1 before Analytics starts. Analytics reuses `BuddyChat`, and would otherwise add another dependency on `onboarding`.
- Step 2 also isolates the session code where backend bug-0003 (refresh fails after 15 minutes) shows up.
