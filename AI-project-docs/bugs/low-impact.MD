# Low-impact issues

> Parked for later; don't work on them unless asked. When one is fixed, set its Status to `Done (<date>, <PR>)`.
> `—` = no ticket yet; file one (`/speckit-feature-init defect <name>`) when we decide to fix it.

| Ticket | Bug | Description | Status |
|---|---|---|---|
| B013 | Timeline board ignores its `label` | Screen readers always hear "Timeline board" instead of "Day plan" / "Plan" / "Reality". See `B013.MD`. | Open |
| — | Settings kept after the session expires | When the 401 refresh fails (B014), the user is signed out but their settings stay in memory until the next sign-in reloads them (`useAuthSession.ts`). | Open |
| — | `console.log` in onboarding submit | `completeOnboarding.ts:13` logs the user ID and default routine to the browser console. | Open |
| — | 3 lint warnings | Redundant `Boolean()` in `EditingBoard.tsx:207`; missing hook dependencies in `useReflectionMode.ts:67` and `useDailyPlan.ts:42`. | Open |
| — | Decide: keep or remove Push mode "push up" | Push mode can also push the tasks above when a task is dragged up (T002). It is turned off for now by the front-end toggle `PUSH_UP_ENABLED = false` in `ui-personal-routine-manager/src/config/featureFlags.ts`; with it off, dragging a task up still brings the tasks below along, but the tasks above stay (an Overlay-off task stops at the end of the one above). Keep: set it to `true`. Remove: delete the toggle and the `pushUp` part of the filter in `board/utils/dragPreview.ts` (plus its "Push-up on" tests). | Open |
