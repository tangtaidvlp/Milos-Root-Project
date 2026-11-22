# Contract: Routes and Guards

All routes are hash routes (`/#/today`), because the app is served from GitHub Pages.

| Path | Page | Shell (sidebar) | Signed out | Signed in, not onboarded | Signed in, onboarded |
|------|------|-----------------|-----------|--------------------------|----------------------|
| `/` | redirect | – | → `/auth` | → `/onboarding` | → `/today` |
| `/auth` | `AuthPage` | no | show | → `/onboarding` | → `/today` |
| `/onboarding` | `OnboardingPage` | no | → `/auth` | show | → `/today` |
| `/today` | `DailyRoutinePage` | yes | → `/auth` | → `/onboarding` | show |
| `/default-routine` | `DefaultRoutinePage` | yes | → `/auth` | → `/onboarding` | show |
| `/analytics` | `AnalyticsPage` (placeholder) | yes | → `/auth` | → `/onboarding` | show |
| `/dashboard` | legacy | – | → `/auth` | → `/onboarding` | → `/today` (replace) |
| `*` | redirect | – | same as `/` | same as `/` | same as `/` |

Rules:

- The three shell routes are children of one layout route wrapped in a single guard (FR-015).
- Redirects use `replace`, so Back never lands on a redirect.
- Completing onboarding sets the onboarded flag, and `/onboarding` then redirects to `/today` with no reload.
- Sign out clears auth state; the guard then sends the user to `/auth`.
- The Daily page's selected date is not part of the URL (unchanged from today). Reloading `/today` always shows today.
