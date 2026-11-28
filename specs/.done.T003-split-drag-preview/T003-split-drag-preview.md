# T003 – Split drag preview into move and resize

**Type**: Task
**Parent**: F017

## Summary

`previewPositions` in `ui-personal-routine-manager/src/features/board/utils/dragPreview.ts` grew through T002, F017 and B015 into one long function that mixes move and resize, Push and Normal mode, both directions, and the `PUSH_UP_ENABLED` / `OVERNIGHT_TASKS_ENABLED` toggles. The "place each task at its shifted start" loop is repeated four times. Split it so each case reads on its own. No behaviour change.

## Done when

- `previewPositions` only does the shared setup (overnight clamp, `latestStart`) and hands off to a move part and a resize part, like the existing `previewStrictMove` / `previewStrictResize`.
- One small helper writes "task at start + shift" into the result; the four copies use it.
- `let delta` in the resize part becomes `const` where it's never reassigned.
- All tests pass unchanged (`pnpm test`, `pnpm lint`, `pnpm build`, e2e `today-board`); no test is edited.

## Notes

- Refactor only (zero behaviour change): existing tests must stay green.
- Found in the B015 review (ui-personal-routine-manager#12).
