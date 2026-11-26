# Low-impact issues

> Parked for later; don't work on them unless asked. When one is fixed, set its Status to `Done (<date>, <PR>)`.
> `—` = no ticket yet; file one (`/speckit-feature-init defect <name>`) when we decide to fix it.

| Ticket | Bug | Description | Status |
|---|---|---|---|
| B013 | Timeline board ignores its `label` | Screen readers always hear "Timeline board" instead of "Day plan" / "Plan" / "Reality". See `B013.MD`. | Open |
| — | Settings kept after the session expires | When the 401 refresh fails (B014), the user is signed out but their settings stay in memory until the next sign-in reloads them (`useAuthSession.ts`). | Open |
| — | `console.log` in onboarding submit | `completeOnboarding.ts:13` logs the user ID and default routine to the browser console. | Open |
| — | 3 lint warnings | Redundant `Boolean()` in `EditingBoard.tsx:207`; missing hook dependencies in `useReflectionMode.ts:67` and `useDailyPlan.ts:42`. | Open |
