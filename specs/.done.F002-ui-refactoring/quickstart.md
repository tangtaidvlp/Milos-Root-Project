# Quickstart: Validate F002 UI Refactoring

Manual checks for UI behaviour, plus the automated unit tests. References: [spec.md](./spec.md), [contracts/routes.md](./contracts/routes.md), [contracts/ui-shell.md](./contracts/ui-shell.md), [contracts/style-tokens.md](./contracts/style-tokens.md), design [resources/Sidebar-Design.png](./resources/Sidebar-Design.png).

## Prerequisites

```bash
# Backend (from repo root)
cd ms-personal-routine-manager && docker compose up -d database && ./gradlew bootRun
# Frontend
cd ui-personal-routine-manager && pnpm install && pnpm dev
```

Have two accounts: **A** onboarded with a few default tasks, **B** freshly registered (not onboarded).

## 1. Automated checks

```bash
cd ui-personal-routine-manager
pnpm test     # includes noRawColors, token contrast, sidebarPreference, routineTypeForDate, nowAndNext
pnpm lint
pnpm build
```

Expected: all pass. `noRawColors` lists any file:line with a raw colour outside `tokens.css`.

## 2. Navigation (US1, FR-001–FR-005, FR-015)

1. Sign in as A at ~1440px wide → lands on `/#/today`; sidebar visible, "Today" highlighted.
2. Click "Default routine", then "Analytics" → URL and highlight follow; Analytics shows the "coming soon" card.
3. Browser Back twice → returns through the visited pages. Reload on `/#/default-routine` → same page.
4. Open `/#/dashboard` → replaced by `/#/today`.
5. Sign out → `/#/auth`. Open `/#/analytics` while signed out → `/#/auth`.
6. Sign in as B → onboarding with no sidebar. Type `/#/default-routine` → back to `/#/onboarding`.
7. Finish onboarding as B → lands on `/#/today` with the sidebar, no reload.

## 3. Sidebar hide/show and persistence (FR-006)

1. Click "Hide sidebar" → slim rail, content widens. Reload → still collapsed. Show again → reload → expanded.
2. In a private window → sidebar shows expanded; toggling works; no console errors.

## 4. Narrow screens (US4, FR-007)

1. DevTools device mode 375px → sidebar hidden, burger visible in the header.
2. Burger → overlay with backdrop. Tap "Default routine" → overlay closes and page switches.
3. Open again → Escape closes; open again → tap backdrop closes; focus returns to the burger.
4. With the overlay open, resize to wide → overlay gone, stored wide preference applied.
5. No horizontal page scroll from 360px to 1920px (SC-007).

## 5. Default Routine page (US2, FR-012, FR-013)

1. As A, open Default routine → Weekday routine shown with Routine Buddy on the right; no "Ready to roll". Ask Buddy to add a task → it appears on the board and survives a reload. Weekend tab has its own chat.
1a. At 1024px and 900px the chat stays beside the board on Today, Default routine and onboarding; at 375px it is behind the chat button.
2. Add a task, rename it, drag it, resize it, delete another → reload → changes kept.
3. Switch to Weekend → weekend tasks shown; edit one → reload → kept.
4. Stop the backend, make a change → error banner "Couldn't save that change." with Retry; board shows the last saved state.

## 6. Daily Routine regression and layout (US3, FR-011, FR-016, SC-005, SC-006)

Compare side by side with the design at 1440×900:

- Header: "Today · Weekday routine" breadcrumb (Weekend routine on Sat/Sun), ‹ date ›, "Today", "Sign out".
- Toolbar: clock + Live pill, zoom −/100%/+, Pause clock, Gap clear, Clean up (red), + Add task.
- Cards tinted with left accent bar; completed faded with green check; current task outlined; red now-line with time pill.
- Footer: "Now … · N min left" and "Next: … at HH:MM".
- Routine Buddy panel on the right; ask "Mark my break as done" → task checked.

Regression list (each must still work): previous/next day, pick a date, Today button, add task, edit, drag, resize, delete, complete toggle, zoom, pause/resume, slider, Gap clear drag, Reset day, Clean up, Buddy chat, mobile board/chat swap.

## 7. Replay tour (FR-009)

From each of Today, Default routine and Analytics, click "Replay tour" → intro slides open and close normally.
Onboarding (account B): "How it works" still opens slides and the guided tour, and every tour step points at the right element.

## 8. Consistent style (FR-017, FR-018, SC-004)

1. Sign-in, sign-up and onboarding use the same blue, fonts, buttons and inputs as the shell, and show the "Milos" brand.
2. In `tokens.css`, temporarily change `--color-accent` to a vivid colour → active nav, primary buttons, user chat bubbles, send button and links all change. Revert.

## 9. Accessibility (FR-019)

Tab through the sidebar, header and toolbar: every control is reachable with a visible focus ring; the active nav entry is announced as current page.

## Validation run – 2026-11-21

Run by Claude in headless Chromium against the Vite dev server, with the backend **mocked** (no real data written) and the clock fixed to Thu 19 Nov 2026 10:42.

| Section | Result | Notes |
|---------|--------|-------|
| §1 Automated | Pass | `pnpm test` 79/79, `pnpm build` OK, `pnpm lint` 0 errors (2 old warnings) |
| §2 Navigation | Pass | `/today` landing, nav + `aria-current`, Back, reload, `/dashboard` → `/today`, not-onboarded → `/onboarding`. Sign-in/sign-out against the real backend **not run** |
| §3 Hide/show + persistence | Pass | Survives reload both ways; blocked `localStorage` works with no errors |
| §4 Narrow screens | Pass | Burger, focus in/out, Escape, backdrop, pick-to-close, resize to wide; no horizontal scroll at 360/768/1024/1440/1920 |
| §5 Default Routine | Partly | Page, Weekday/Weekend, no Buddy / no "Ready to roll", empty-state hint checked. **Save/reload against the real backend and the save-error banner not run** |
| §6 Daily layout | Partly | Side-by-side with the mock at 1440×900 and 1024: matches. **Regression list (drag, resize, complete, Buddy chat, Clean up, …) not exercised** |
| §7 Replay tour | Pass | Slides open from the sidebar; onboarding tour 1–5 finds every target at 1440 and 375px |
| §8 Consistent style | Pass | Auth and onboarding use tokens and the Milos brand; `noRawColors` green |
| §9 Accessibility | Partly | Focus ring, labels, `aria-expanded`, contrast test pass; full keyboard walk-through not done |

## End-to-end run – 2026-11-21 (real backend)

Headless Chromium against `pnpm dev` (5173) and the backend on 8080 (`local` profile, PostgreSQL), with a new throwaway account `e2e-f002-1795200050136@example.test`. **Result: 30/30 steps pass.**

- §2: sign up → sign in → onboarding (no sidebar, slides auto-open, `/default-routine` sends you back) → add Weekday + Weekend tasks → "Ready to roll" → `/today` with sidebar, no reload. Sign out → `/auth`; `/analytics` while signed out → `/auth`; sign in again → `/today`; `/dashboard` → `/today`.
- §5: add, rename, drag (+1h), resize, delete on the Default routine page, all kept after reload; Weekend edit kept; a failed save (PUT aborted in the browser) shows "Couldn't save that change." and the board keeps the saved time.
- §6 regression list: day cloned from the default routine; add, rename, drag, resize, complete (kept after reload), delete with confirm, zoom, pause/resume, slider, Gap clear, Reset day, next/previous day, Today button, Clean up, Now/Next footer, Routine Buddy chat (real Gemini; the task appeared and survived a reload; the reply took 70–95 s).
- §7: Replay tour from the sidebar. §9: Tab reaches sidebar links with a visible focus ring.
- Breadcrumb and sidebar show "Weekend routine" on Saturday.

Not covered: the native date picker popup, and the phone-width checks against the real backend (those passed earlier with mocked data).

## Update run – 2026-11-21 (Routine Buddy on Default routine, chat always visible)

- Real backend, account `e2e-f002-1795200050136@example.test`: chat visible on Default routine; "Add a task called E2E Default Buddy at 18:00 for 30 minutes" → reply after 54 s, task on the weekday board 18:00–18:30, kept after reload; Weekend tab shows its own chat. **Pass.**
- Mocked backend screenshots at 1440, 1024 and 900px: chat beside the board on Today, Default routine and onboarding; at 375px the board/chat swap works and the message box is clear of the "View schedule" button. The earlier 33 behaviour checks still pass (the old "no Buddy on Default routine" check is now intentionally reversed).

