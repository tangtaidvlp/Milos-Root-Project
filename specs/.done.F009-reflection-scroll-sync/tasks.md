---
description: "Tasks for F009 Smooth scroll sync in Reflection compare view"
---

# Tasks: Smooth scroll sync in Reflection compare view

**Input**: `specs/F009-reflection-scroll-sync/` (plan.md, spec.md, research.md, quickstart.md)

**Tests**: One regression unit test, written first (constitution II, research R3).

All paths are relative to `ui-personal-routine-manager/`. There are no setup or foundational phases, since nothing needs to be in place first.

## Phase 1: User Story 1 - Scroll both boards smoothly (Priority: P1) 🎯 MVP

**Goal**: A late echo scroll event can never pull the board the user is scrolling back (plan "Design", research R1/R2).

**Independent Test**: `pnpm test` passes the new late-echo case, then the manual steps in `quickstart.md`.

- [X] T001 [US1] Add a failing test "a late echo does not pull the scrolling board back" to `src/features/reflection/hooks/useSyncedScroll.test.ts`: with fake timers, register plan and reality. Set `plan.scrollTop = 240` and dispatch `scroll` on plan (reality becomes 240). Then `plan.scrollTop = 300` (still coasting), `vi.runAllTimers()`, and dispatch `scroll` on reality (its late echo, still 240). Expect `plan.scrollTop` to be 300. Also add "the user can take over on the other board": after the plan scroll to 240, set `reality.scrollTop = 100`, dispatch `scroll` on reality with no timers run, and expect `plan.scrollTop` to be 100. Run `pnpm test useSyncedScroll` and confirm the first case fails on the current code.
- [X] T002 [US1] In `src/features/reflection/hooks/useSyncedScroll.ts`, replace `syncingRef` and the requestAnimationFrame/setTimeout release with `expectedRef = useRef(new Map<HTMLElement, number>())`. In the listener for element `E`:
  1. If `expectedRef` has `E` and `Math.abs(E.scrollTop - expected) < 1`, delete the entry and return (it's our echo).
  2. Otherwise delete any entry for `E`. For each other element with a different `scrollTop`, set `other.scrollTop = E.scrollTop` and store the read-back `other.scrollTop` in `expectedRef`.

  On register, store the new element's read-back value after the initial alignment. When removing disconnected elements and on unmount cleanup, delete their `expectedRef` entries as well. Update the doc comment to say echoes are detected by position (F009). Keep the exported signature unchanged.
- [X] T003 [US1] Run `pnpm test useSyncedScroll`: the new cases and the three existing ones pass.

**Checkpoint**: US1 complete. Ready for the manual check.

## Phase 2: Polish & Verify

- [X] T004 Run `pnpm lint && pnpm test && pnpm build` in `ui-personal-routine-manager/`.
- [X] T005 Run `pnpm test:e2e reflection` (backend `SPRING_PROFILES_ACTIVE=fast SPRING_AI_ACTIVE=false ./gradlew bootRun` plus `pnpm dev`) per `specs/F009-reflection-scroll-sync/quickstart.md`. If the backend can't be started, skip this and report it.
- [ ] T006 Hand the manual checks in `specs/F009-reflection-scroll-sync/quickstart.md` (steps 1–6) to the user for sign-off (SC-001).

## Dependencies

T001 → T002 → T003 → T004 → T005 → T006. It's a single story, and T001 and T002 touch the same hook, so there's no parallel work.

## Implementation Strategy

US1 is the whole delivery. If the user still feels lag after T006 (no jump-back, just delay), follow up with the shared-scroll-container option (plan "Risks") as a separate change.
