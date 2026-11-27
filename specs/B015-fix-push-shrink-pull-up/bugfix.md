# Bugfix: Push mode — a shorter task doesn't bring the tasks below up

**Bugfix Branch**: `fix/B015-fix-push-shrink-pull-up`
**Created**: 2026-11-27
**Status**: Fixed
**Affected project(s)**: ui-personal-routine-manager
**Input**: Bug report: "Push mode - Scale out doesn't drag below task up" (`AI-project-docs/bugs/.done.B015.MD`)

## 1. Report

**Expected behavior**: In Push mode, making a task shorter brings the tasks after it up with its end, keeping the gaps (same as a move, F017 T020).

**Actual behavior**: The tasks below stay where they are.

**Environment**: Today board, Push mode, mouse or touch.

**Severity**: Medium (workaround: move the tasks by hand).

## 2. Reproduction

**Steps**:

1. Push mode on; Work 09:00–11:00, Lunch 12:00–13:00.
2. Drag Work's bottom edge up 1 hour.

**Reproduced?**: Yes, every time.

**Smallest reproduction**: `previewPositions(tasks, resize(30), true)` returns only the resized task.

## 3. Investigation

| # | Hypothesis | How it was tested | Result |
|---|------------|-------------------|--------|
| H1 | The Push mode preview ignores a shorter resize | Read `previewPositions` resize branch; unit test | Confirmed: `if (!pushMode \|\| delta <= 0)` returns only the dragged task |

## 4. Root Cause

**Location**: `ui-personal-routine-manager/src/features/board/utils/dragPreview.ts` (resize branch of `previewPositions`)

**Cause**: T002 FR-013 said "making a task shorter MUST NOT move any other task". F017 (T020) made the tasks below follow a move both ways, but the resize rule was not aligned.

**Introduced by**: T002 FR-013 (by design at the time); left inconsistent by F017 T020.

**Blast radius**: Push mode resize on every timeline board (Today, Default routine, Onboarding, Reflection plan). Saving uses the same preview map, so no other path changes.

## 5. Regression Test

**Test kind**: Frontend: Unit (logic)

**Test**: `ui-personal-routine-manager/src/features/board/utils/dragPreview.test.ts` — "B015: in Push mode a shorter task brings the tasks below up with its end" (+ "B015: without Push mode a shorter task moves nothing else").

**Failure before fix**: `AssertionError: expected undefined to be 570` (the task below was not in the preview).

## 6. Fix

In Push mode, a shorter resize moves every task that starts at or after the task's old end up by the same amount (gaps kept). No clamp is needed: those tasks never pass the new end. Normal mode is unchanged.

**Alternatives considered**: closing only the gap right below (chain pull) — rejected, a move already shifts the whole rest of the day, so resize matches that.

## 7. Verification

- [x] Regression test passes
- [x] `pnpm test`: 377 pass
- [x] `pnpm lint` (0 errors), `pnpm build`
- [x] e2e today-board: 6 pass, 1 skipped (overnight toggle off)
- [x] Original reproduction in the browser (Playwright, Push mode): Work 09:00–11:00 → 09:00–10:00, Lunch 12:00 → 11:00, kept after reload
