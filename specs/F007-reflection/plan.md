# Implementation Plan: Daily Reflection (Plan vs Reality)

**Branch**: `F007-reflection` | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F007-reflection/spec.md`

## Summary

Add a per-day **reflection**: a separate record of what really happened, created the first time the user switches Reflection on for today or a past day. At that moment it copies the day's planned tasks once. The reflection has its own tables, so it can never change the plan, and the plan can never change it. The backend computes the plan-vs-reality comparison: each task is grouped as planned, changed, skipped or unplanned, with totals. The same comparison feeds the UI and Buddy. Buddy gets:

- A **reflection chat** with its own saved thread per day (a new `DAILY_REFLECTION` conversation type that reuses F004 storage and compaction). It has its own tool set and can only edit reflection tasks.
- A **feedback note** written under strict "encouraging tone" rules and stored on the reflection, with a "stale" flag once the reflection changes.

On the frontend, the Daily Routine page gets a Plan / Reality toggle. In Reality mode, the board edits reflection tasks. A comparison panel shows the groups, totals and Buddy's note. BuddyChat switches to the reflection thread.

## Technical Context

**Language/Version**: Backend Java 25 (Spring Boot 4.1). Frontend TypeScript 5 / React 19.

**Primary Dependencies**: Spring Data JPA, Spring AI (Gemini) with `@Tool` beans, Lombok. Frontend: Vite 8, React Router 7, Vitest + Testing Library.

**Storage**: PostgreSQL (prod `ddl-auto: validate`, so a DDL script `db/F007-daily-reflection.sql` is needed); H2 for the `fast` profile and tests.

**Testing**: JUnit 5 + Spring Boot test (`fast` profile, `spring.ai.active=false`) with MockMvc. Vitest logic and component tests. Manual `quickstart.md`.

**Target Platform**: Web SPA plus REST API on EC2.

**Project Type**: Web application (separate backend and frontend projects).

**Performance Goals**: Reflection GET and mutations stay under 300 ms for a day with up to 50 tasks. The comparison is O(n) per request.

**Constraints**: The plan must never change from reflection paths (FR-005/006). Every endpoint checks ownership via `CurrentUserGuard` plus reflection-scoped task lookup (FR-008). No raw colors in the UI (token rules).

**Scale/Scope**: One reflection per user per day. Usually fewer than 30 tasks.

## Constitution Check

`.specify/memory/constitution.md` is still the unfilled template, so it defines no project gates. The plan follows the conventions in the subproject `CLAUDE.md` files instead:

- Constructor injection, Lombok, `@Transactional` writes, UUID ids.
- A DDL script under `db/`, because prod uses validate.
- A feature folder `features/reflection/` with `api/ components/ types/ utils/`, using `lib/api.ts`.
- Semantic CSS tokens only.

**Result: PASS** (pre- and post-design).

## Project Structure

### Documentation (this feature)

```text
specs/F007-reflection/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── reflection-api.md
│   └── reflection-chat-api.md
└── tasks.md            # /speckit-tasks
```

### Source Code

```text
ms-personal-routine-manager/
├── db/F007-daily-reflection.sql
└── src/main/java/com/tom/payment/routinemanager/
    ├── model/DailyReflection.java, ReflectionTask.java, ChatConversationType (+DAILY_REFLECTION), ChatConversation (+forDailyReflection)
    ├── repository/DailyReflectionRepository.java, ReflectionTaskRepository.java
    ├── dto/ReflectionView.java, ReflectionComparison.java, ReflectionTaskInput.java, ReflectionChatRequest.java
    ├── service/reflection/ReflectionService.java, ReflectionComparisonService.java
    ├── service/reflection/ReflectionAiService.java (+ GeminiReflectionAiService, MockReflectionAiService)
    ├── service/aitools/ReflectionAiTools.java
    ├── service/chat/ChatConversationService.java (+ reflection conversation lookup)
    └── api/DailyReflectionController.java, AIController.java (+ reflection chat endpoints)
    test: ReflectionIntegrationTest.java, ReflectionComparisonServiceTest.java

ui-personal-routine-manager/src/
├── features/reflection/
│   ├── api/reflection.ts
│   ├── types/reflection.ts
│   ├── components/ReflectionPanel.tsx (+ .test.tsx)
│   └── utils/reflectionAvailability.ts (+ .test.ts), formatMinutes.ts (+ .test.ts)
├── features/daily/pages/DailyRoutinePage.jsx   # Plan/Reality toggle, routes handlers
└── App.css                                     # .rf-* styles
```

**Structure Decision**: This is a web application with the two existing subprojects. The backend gets a new `service/reflection` package. The frontend gets a new `features/reflection` module, which the existing Daily page composes.

## Key Design Decisions (see research.md)

1. **Separate tables** (`daily_reflection`, `reflection_task`) rather than a flag on `DailyTask`. This guarantees independence and keeps analytics queries simple.
2. **Link by `planned_task_id`** (a plain UUID column, not a foreign key). Renames still match. If the planned task is deleted, the reflection task counts as unplanned.
3. **The server computes the comparison** and returns it in every reflection response. The UI, Buddy feedback and future analytics all share one definition.
4. **Reflection endpoints are scoped by `{userId}/{date}`**. Every task id is looked up inside that reflection, so ownership is enforced.
5. **A separate AI service and ChatClient** hold only `ReflectionAiTools`, so the reflection chat cannot edit the plan.
6. **No auto-shifting** of overlapping reflection tasks.
7. **Feedback is stored on the reflection** (`feedback_text`, `feedback_at`). It is `stale` when `content_updated_at > feedback_at`.

## Complexity Tracking

None.

---

## Enhancement 2026-11-22: side-by-side layout and compact Reflection toggle

**Spec input**: spec.md "Clarifications, Session 2026-11-22", FR-001, FR-012, FR-012a, FR-012b and FR-017a.

**Scope**: frontend only. No backend, API, data-model or DDL changes. The existing `ReflectionView` already contains everything the new layout shows.

### Summary

- **Toggle**: the Plan/Reality tablist under the date row is replaced by a compact **"Reflection"** toggle button (`aria-pressed`) in the board toolbar.
- **Wide screens (≥ 1280px)** with Reflection on: two boards (Plan | Reality) sit side by side under **one shared toolbar**. They share one clock, and their scroll and zoom stay in sync. Both boards are editable, and each column header has its own "+ Add".
- **Narrow screens (< 1280px)**: the toggle swaps the single board. Tapping a reality task opens a **status pop-up** (group, planned vs actual, Edit).
- **Summary**: the large comparison panel becomes a **one-line summary strip**, with "Task by task" collapsed.
- **Buddy's note** moves to the **top of the Buddy chat**, and the chat header becomes compact in reflection mode.

### Technical Context (delta)

- **New global hook**: `src/hooks/useMediaQuery.ts`.
- **New feature hooks**:
  - `features/reflection/hooks/useSyncedScroll.ts`
  - `features/onboarding/hooks/useBoardClock.ts` (the clock state lifted out of EditingBoard)
- **Board**: `EditingBoard.jsx` gains optional, backward-compatible props: `showToolbar`, `clock`, `gapClearMode`, `scrollContainerRef`. Its toolbar JSX moves into `BoardToolbar.jsx`, which `EditingBoard` itself uses, so the markup isn't duplicated.
- **Chat**: `BuddyChat.jsx` gains optional props `topSlot` and `compactHeader`.
- **Testing**: Vitest for the hooks and the new components. The e2e spec is rewritten for the toggle, plus a side-by-side test at 1400px and a pop-up test at 900px.

### Constitution Check (re-evaluated)

There are still no constitution gates. The `CLAUDE.md` / `codingrules.md` conventions are kept:

- Feature folders, and a global hook placed in `src/hooks/`.
- `lib/api.ts` is unchanged.
- Semantic tokens only.

**PASS**.

### Source changes

```text
ui-personal-routine-manager/src/
├── hooks/useMediaQuery.ts (+ .test.ts)                         # NEW (global)
├── features/onboarding/
│   ├── components/BoardToolbar.jsx                             # NEW: extracted from EditingBoard
│   ├── components/EditingBoard.jsx                             # + showToolbar, clock, gapClearMode, scrollContainerRef
│   ├── components/BuddyChat.jsx                                # + topSlot, compactHeader
│   └── hooks/useBoardClock.ts (+ .test.ts)                     # NEW: live clock state (time, live/paused)
├── features/reflection/
│   ├── components/ReflectionToggle.tsx                         # NEW
│   ├── components/ReflectionSummaryStrip.tsx (+ .test.tsx)     # NEW (replaces the panel's totals/details)
│   ├── components/ReflectionNote.tsx (+ .test.tsx)             # NEW (note + get/refresh, shown in the chat top slot)
│   ├── components/ReflectionTaskPopup.tsx (+ .test.tsx)        # NEW (narrow screens)
│   ├── components/CompareBoards.jsx                            # NEW: shared toolbar + Plan | Reality boards
│   ├── components/ReflectionPanel.tsx (+ .test.tsx)            # REMOVED (split into strip + note)
│   ├── hooks/useSyncedScroll.ts (+ .test.ts)                   # NEW
│   └── utils/comparisonLookup.ts (+ .test.ts)                  # NEW: comparison item for a reality task id
├── features/daily/pages/DailyRoutinePage.jsx                   # target-aware handlers, layout switch
└── App.css                                                     # .rf-* updates; @media (min-width: 1280px)
e2e/reflection.spec.ts                                          # toggle + side-by-side + pop-up
```

### Key design decisions (research.md R11–R16)

11. **Two boards under one toolbar**, not one board with two lanes. The board's drag, resize and gap-clear logic stays untouched.
12. **A lifted clock and synced scrolling**. The two boards always show the same "now" and the same hours.
13. **A JS media query at 1280px** chooses between the side-by-side layout and the single board. CSS handles the styling.
14. **Target-aware page handlers**. Every task action says which board it belongs to, so both boards stay editable at once.
15. **The summary strip and the note in the chat** replace the large panel.
16. **A status pop-up on narrow screens**, reusing the comparison data that is already loaded.
