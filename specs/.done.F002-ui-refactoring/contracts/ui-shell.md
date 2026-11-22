# Contract: App Shell, Sidebar and Page Slots

Visual reference: [../resources/Sidebar-Design.png](../resources/Sidebar-Design.png).

## AppShell (layout route)

Renders, left to right on wide screens: `Sidebar` | page `<Outlet/>`. Owns:

- `useSidebar()` state ([data-model.md §3](../data-model.md))
- `useWalkthrough()` and `<IntroSlides/>` for "Replay tour" (context `'app'`, slides only)
- passes `onLogout` and `user` to pages through outlet context

Outlet context given to pages (`src/components/layout/shellContext.ts`, read with `useShellContext()`):

```ts
type ShellOutletContext = {
  user: AuthUser
  onLogout: () => void
  openSidebar: () => void        // used by the page header's burger on narrow screens
  isMobile: boolean
  isMobileOpen: boolean          // burger aria-expanded
  menuButtonRef: RefObject<HTMLButtonElement | null>  // focus returns here when the overlay closes
}
```

## Sidebar

Wide screen, expanded (top → bottom):

1. Brand: "M" mark + "Milos"
2. Section label "PLAN"
3. Nav entries from `navEntries` ([data-model.md §1](../data-model.md)), icon + label (+ "Soon" pill); active entry has the accent tint background and `aria-current="page"`
4. Spacer
5. "Replay tour" (spark icon) → opens the walkthrough slides
6. User block: avatar circle (initial), name (ellipsis if long), today's routine label ("Weekday routine")
7. Collapse control ("Hide sidebar")

Wide screen, collapsed: a slim rail with the "Show sidebar" control only; main content takes the rest of the width.

Narrow screen (≤ 760px): hidden by default. The page header shows a burger button (`aria-expanded`, `aria-controls="app-sidebar"`). When open, the sidebar slides over the content with a backdrop and the content behind is `inert`. It closes on nav entry choice, backdrop click or Escape, and focus returns to the burger.

Accessibility: `<nav aria-label="Main">`; every control reachable by Tab with a visible focus ring; Escape closes the mobile overlay.

## Page header (shared pattern)

`<PageHeader actions={…}>{title}</PageHeader>` (`src/components/layout/PageHeader.tsx`). It reads the shell context itself, so pages only pass the title and actions:

- left: burger button (narrow screens only), then the page's title content
- right: page actions, then "Sign out" (FR-010)

Daily: breadcrumb "Today · {routine label}", `‹ {Weekday, D Mon YYYY} › [Today]` (short "Thu 19 Nov" at ≤ 760px).
Default routine: title "Default routine", Weekday/Weekend switch as the action.
Analytics: title "Analytics".

## EditingBoard additions

| Prop | Type | Purpose |
|------|------|---------|
| `toolbarActions` | ReactNode? | Rendered at the right end of the board toolbar (Daily: "Clean up", "+ Add task") |
| `showFooter` | boolean (default = `liveClock`) | Shows the Now / Next footer ([data-model.md §5](../data-model.md)) |

Existing props and behaviour are unchanged. The "Now: …" status line is replaced by the footer.

## DefaultRoutineEditor (extracted from OnboardingPage)

`features/onboarding/components/DefaultRoutineEditor.tsx`, state in `features/onboarding/hooks/useDefaultRoutines.ts`.

| Prop | Type | Purpose |
|------|------|---------|
| `userId` | string | Owner of the default routines |
| `className` | string | Page root class (`ob-page` / `drt-page`); the root carries `data-mobile-view` |
| `renderHeader` | `(switcher) => ReactNode` | Header row; receives the Weekday/Weekend switch to place (onboarding: top bar with "How it works" + "Ready to roll"; Default routine: `PageHeader` action) |
| `banner` | ReactNode? | Extra banner under the routine error (onboarding: completion error) |
| `renderAside` | `(state) => ReactNode`? | Right-hand panel: one BuddyChat per tab (onboarding uses the onboarding chat; Default routine uses `features/default-routine/api/defaultRoutineChat.ts`, same endpoint without the "Onboarding:" framing) |
| `extraFabs` | ReactNode? | Extra floating buttons (onboarding: open chat on narrow screens) |
| `mobileView` | `'board' \| 'chat'`? | Board/chat swap (onboarding) |
| `children` | ReactNode? | Rest of the page (footer, slides, guided tour) |

Must keep these `data-tour` targets on equivalent elements: `schedule-switch`, `routine-board`, `add-task` (both "+ Add task" in the board header and the phone FAB; the tour picks the visible one), `routine-buddy` (aside), `finish` (header action).

## AnalyticsPage

Header plus one centred card: chart icon, "Analytics is coming soon", one line of supporting text. No data requests.

## Routine Buddy visibility (F002 update, 2026-11-21)

On Today, Default routine and onboarding the chat panel sits beside the board at every width from 761px up (`--chat-panel-width: clamp(280px, 28vw, 360px)`). At ≤ 760px the existing board ⇄ chat swap applies (chat button / "View schedule").

