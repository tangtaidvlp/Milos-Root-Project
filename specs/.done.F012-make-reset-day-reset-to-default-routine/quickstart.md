# Quickstart: validate F012

Prereqs: backend `SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun`, frontend `pnpm dev`, a signed-in, onboarded user.

## Automated
- Backend: `./gradlew test` (component tests in `DailyRoutineComponentTest`, `DefaultRoutineComponentTest`).
- Frontend: `pnpm lint && pnpm test`, then `pnpm test:e2e` (`today-board.spec.ts` reset journey).

## Manual
1. **Reset (weekday)**: On Today (a weekday), add/move/delete a task and tick one done → More → Reset day → Confirm. The board equals the Weekday routine with no ticks. Reload: still equal.
2. **Cancel**: Reset day → Cancel, or press Escape → nothing changes.
3. **Weekend**: Pick the next Saturday → Reset day → Confirm → the board equals the Weekend routine (or Weekday if Weekend is empty).
4. **Past day**: Pick yesterday → Reset day is disabled.
5. **Reflection kept**: Today, turn on Reflection, edit Reality, Reset day → Confirm → Reality unchanged; the summary strip compares against the new plan. Wide screen (≥1280px): the same from the shared toolbar.
6. **Copy**: Default routine page → Copy Weekday to Weekend → Confirm → the Weekend tab equals Weekday; Weekday unchanged. Cancel changes nothing.
7. **No Reset on setup**: The Default routine and Onboarding boards show no Reset day.
8. **Keyboard**: Both dialogs open, confirm and cancel with the keyboard; focus returns to the button.
