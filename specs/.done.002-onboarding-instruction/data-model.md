# Data Model: Onboarding Instruction

**Feature**: [spec.md](./spec.md) · **Research**: [research.md](./research.md)

There are no new database tables or columns. One existing entity gets a new rule, and the rest of the state lives only in the browser.

---

## 1. DefaultRoutine (backend, existing; rules change)

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | unchanged |
| `name` | string | New users get "Weekday Routine" and "Weekend Routine". Existing rows keep "Default Routine". |
| `routineType` | enum `DAILY` \| `WEEKEND` | `DAILY` means the **weekday** routine. The name stays as it is to avoid a data migration. |
| `user` | → User | unchanged |
| `tasks` | → RoutineTaskTemplate[] | unchanged |

**Rules**

- **One per type**: a user has **at most one** `DefaultRoutine` per `routineType`. This is enforced in `DefaultRoutineService`, which looks up by `(user, routineType)` before creating, and not by a DB constraint, since the schema stays unchanged (R1).
- **Weekday always exists**: every user has a `DAILY` routine, created at registration as today.
- **Weekend on demand**: a `WEEKEND` routine is created at registration for new users, or the first time it is requested for existing users (R2). It always starts with no tasks.
- **Template for a day** (R3), via `resolveTemplateFor(user, date)`:
  - **Saturday or Sunday**: use `WEEKEND` if it exists and has ≥ 1 task. Otherwise use `DAILY`.
  - **Any other day**: use `DAILY`.

**Lifecycle**

```text
register ──► DAILY (empty) + WEEKEND (empty)
existing user ──► DAILY only ──first GET ?type=WEEKEND──► DAILY + WEEKEND (empty)
tasks added/edited/deleted per routine id (unchanged endpoints and AI tools)
```

---

## 2. Onboarding status (backend, existing; unchanged)

`User.onboardCompleted: boolean`. It is read by `GET /api/users/{id}/onboarding/complete` and set by `POST` to the same path. It decides whether `/onboarding` (and therefore the instructions) is shown. This feature only reads it.

---

## 3. WalkthroughState (frontend, in memory only)

```ts
type WalkthroughContext = 'onboarding' | 'app'

type WalkthroughState =
  | { phase: 'hidden' }
  | { phase: 'slides'; index: 0 | 1 | 2 | 3; context: WalkthroughContext }
  | { phase: 'tour'; index: 0 | 1 | 2 | 3 | 4 }
```

| Event | From | To | Spec |
|-------|------|----|------|
| `OPEN(ctx)` | any | `slides(0, ctx)` | FR-001, FR-012, FR-013 |
| `NEXT` | `slides(i<3)` | `slides(i+1)` | FR-005 |
| `NEXT` | `slides(3)` | no-op. The last slide uses explicit buttons. | — |
| `BACK` | `slides(i>0)` / `tour(i>0)` | `i-1` | FR-005, FR-007 |
| `JUMP(j)` | `slides(*)` | `slides(j)` | walkthrough script, Part 1 |
| `SKIP` | `slides(*)` | `hidden`. The tour does **not** start. | FR-005, FR-008 |
| `START_TOUR` | `slides(3, 'onboarding')` | `tour(0)` | FR-006 |
| `START_TOUR` | `slides(3, 'app')` | `hidden` (the button reads "Close") | FR-013 |
| `NEXT` | `tour(i<4)` | `tour(i+1)` | FR-007 |
| `END` | `tour(*)` | `hidden` ("End tour", "Got it", Esc) | FR-007 |

**Invariants**

- Nothing in this state is saved. Every mount of `OnboardingPage` dispatches `OPEN('onboarding')`.
- Opening, skipping or ending never calls the API (FR-014).

---

## 4. Walkthrough content (frontend, static)

```ts
type SlideContent = {
  id: 'what' | 'day' | 'habits' | 'buddy'
  icon: 'calendar' | 'repeat' | 'chart' | 'sparkles'
  label: string            // uppercase eyebrow, e.g. "WHAT IS MILOS?"
  title: string
  body: string
  callout?: { heading: string; text: string } // slide 4 "First step"
}

type TourStepContent = {
  target: TourTarget       // matches a data-tour attribute
  text: string
  side: 'top' | 'bottom' | 'left' | 'right'   // preferred card side on desktop
  mobileView?: 'board' | 'chat'               // view to switch to on phones
}

type TourTarget = 'schedule-switch' | 'routine-board' | 'add-task' | 'routine-buddy' | 'finish'
```

Values come from [walkthrough-script.md](./walkthrough-script.md). The UI contract is in [contracts/walkthrough-ui.md](./contracts/walkthrough-ui.md).

---

## 5. Setup screen tab → routine type (frontend)

| Tab (`scheduleMode`) | `routineType` | Board title | Board subtitle |
|----------------------|---------------|-------------|----------------|
| `weekday` | `DAILY` | Weekday Routine | Every new weekday starts as a copy of this · drag to move |
| `weekend` | `WEEKEND` | Weekend Routine | Every new weekend day starts as a copy of this · drag to move |

The page keeps both routines in state: `{ weekday?: DefaultRoutine; weekend?: DefaultRoutine }`. It refreshes only the routine of the tab that changed.
