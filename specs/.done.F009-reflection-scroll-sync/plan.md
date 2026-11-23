# Implementation Plan: Smooth scroll sync in Reflection compare view

**Branch**: `F009-reflection-scroll-sync` | **Date**: 2026-11-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F009-reflection-scroll-sync/spec.md`

## Summary

The side-by-side Plan | Reality boards fight each other while scrolling. The sync hook's one-frame lock lets a late "echo" scroll event write an old position back onto the board the user is scrolling ([research R1](research.md)). Fix: tell echoes apart by position instead of by time ([R2](research.md)). The change stays inside `useSyncedScroll.ts`, with one regression unit test added first.

## Technical Context

**Language/Version**: TypeScript 5 (strict), React 19

**Primary Dependencies**: none new (browser scroll events only)

**Storage**: N/A

**Testing**: Vitest + jsdom (hook unit test), Playwright (existing `e2e/reflection.spec.ts` step), manual check per [quickstart.md](quickstart.md)

**Target Platform**: Desktop browsers, window ≥ 1280px (compare view only)

**Project Type**: Web SPA (`ui-personal-routine-manager/`), frontend only

**Performance Goals**: The follower board moves in the same frame as the leader, and the leader's native scrolling (coasting) is never interrupted

**Constraints**: No change to the `CompareBoards` / `EditingBoard` props. Listeners stay passive.

**Scale/Scope**: 1 hook file + its test

## Constitution Check

| Principle | Status |
|-----------|--------|
| I Contract-first API | N/A: no API change |
| II Testing | ✅ Failing regression unit test first (R3). Existing e2e step kept. |
| III Data changes | N/A |
| IV Security | N/A |
| V AI agency | N/A |
| VI Frontend | ✅ Strict TS, stays in `features/reflection/hooks/`, no a11y impact (keyboard scrolling covered in quickstart) |
| VII Supply chain | ✅ No new dependencies |
| VIII Observability | N/A |
| IX Simplicity | ✅ Smallest fix in one hook. The old lock is removed, not kept beside the new logic. |

Post-design re-check: unchanged, passes.

## Design

`useSyncedScroll.ts`:

- Replace `syncingRef` (the time-based lock) with `expectedRef: Map<HTMLElement, number>`, the position the hook last wrote to each follower.
- On a scroll event from element `E`:
  1. If `expectedRef` has `E` and `|E.scrollTop − expected| < 1`: it's our echo. Delete the entry and return.
  2. Otherwise `E` leads: delete any stale entry for `E`. For each other element whose `scrollTop` differs, set `other.scrollTop = E.scrollTop`, then store the **read-back** `other.scrollTop` in `expectedRef` (this covers clamping and rounding).
- When a new board registers, it starts at the current position: record its expected value the same way.
- When a board is removed, also delete its `expectedRef` entry.

No data model or contracts: internal hook with no external interface.

## Project Structure

### Documentation (this feature)

```text
specs/F009-reflection-scroll-sync/
├── spec.md
├── plan.md          # this file
├── research.md
├── quickstart.md
└── checklists/requirements.md
```

### Source Code

```text
ui-personal-routine-manager/src/features/reflection/hooks/
├── useSyncedScroll.ts        # change
└── useSyncedScroll.test.ts   # add "late echo doesn't pull the leader back" case
```

**Structure Decision**: Existing feature folder. No new files.

## Risks

- **Still some lag on a busy main thread**: the browser scrolls the leader off the main thread, but the follower is moved by script. If the fix removes the jump-back but some lag is still felt, the fallback is one shared scroll container for both boards ([R2](research.md) alternative 3). That would be a separate change.
