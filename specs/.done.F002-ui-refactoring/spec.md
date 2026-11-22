# Feature Specification: UI Refactoring – Sidebar Navigation and Visual Refresh

**Feature Branch**: `F002-ui-refactoring`

**Created**: 2026-11-20

**Status**: Draft

**Input**: Feature request ticket `specs/F002-ui-refactoring/F002-ui-refactoring.md` and design `specs/F002-ui-refactoring/resources/Sidebar-Design.png`. Summary: "UI update – add a sidebar for the web version with Daily Routine, Default Routine and Routine Analytics; update the style to follow the new design, with colours defined in one central place and reused for consistency."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navigate between areas from a sidebar (Priority: P1)

An onboarded user opens the app and lands on today's Daily Routine. A sidebar on the left lists the app's main areas: **Today** (Daily Routine), **Default routine** and **Analytics** (marked "Soon"). The user clicks an entry and the main area switches to that page. The current page is highlighted in the sidebar. The user can hide the sidebar to give the schedule more room and show it again later.

**Why this priority**: Today the app has a single post-onboarding screen and no way to reach other areas. The sidebar is the backbone every other part of this feature hangs off, and is the main fix for "not intuitive".

**Independent Test**: Sign in as an onboarded user, confirm the Daily Routine page shows first with the sidebar visible, click each entry and confirm the right page opens and the highlight follows; hide and re-show the sidebar.

**Acceptance Scenarios**:

1. **Given** a signed-in user who has completed onboarding, **When** they open the app, **Then** the Daily Routine page for today is shown with the sidebar visible and "Today" highlighted.
2. **Given** the sidebar is visible, **When** the user clicks "Default routine", **Then** the Default Routine page opens and "Default routine" is highlighted.
3. **Given** the sidebar is visible, **When** the user clicks "Analytics", **Then** a placeholder page opens saying analytics is coming soon.
4. **Given** the sidebar is visible on a wide screen, **When** the user hides it, **Then** the sidebar collapses, the main content uses the freed space, and a control to show it again stays visible.
5. **Given** the user hid the sidebar, **When** they reload the app on the same device, **Then** the sidebar stays hidden.
6. **Given** a signed-in user who has **not** completed onboarding, **When** they use the app, **Then** no sidebar is shown and they stay in the onboarding flow.
7. **Given** a user is on any sidebar page, **When** they use the browser's back and forward buttons, **Then** they move between the pages they visited, and each page has its own address that can be reloaded or bookmarked.

---

### User Story 2 - Edit the default routine after onboarding (Priority: P2)

An onboarded user wants to change their usual weekday or weekend routine. They pick "Default routine" in the sidebar and get the same editing board they used during onboarding: they can switch between routine types, add tasks, edit them, move or resize them, and delete them. Routine Buddy sits beside the board, one chat per routine type, so they can also ask it to change the routine. There is no "complete onboarding" step on this page.

**Why this priority**: Today the default routine can only be edited during onboarding; afterwards it is locked away. This page gives the sidebar its first real destination beyond the existing daily view.

**Independent Test**: As an onboarded user, open Default routine, add, edit and delete a task, reload the page, and confirm the changes are kept.

**Acceptance Scenarios**:

1. **Given** an onboarded user on the Default Routine page, **When** the page loads, **Then** their current default routine is shown on the editing board.
2. **Given** the Default Routine page, **When** the user adds, edits, moves, resizes or deletes a task, **Then** the change is saved and is still there after a reload.
3. **Given** the user has more than one routine type (for example weekday and weekend), **When** they switch type on the page, **Then** the board shows that type's tasks.
4. **Given** the Default Routine page, **When** it is shown, **Then** there is no "complete onboarding" button, and the Routine Buddy panel for the selected routine type is visible next to the board.
5. **Given** a save fails, **When** the user makes a change, **Then** they see a clear error and the board shows what is actually saved.
6. **Given** the Default Routine page, **When** the user asks Routine Buddy to add or change a task, **Then** the change appears on the board of that routine type and is kept after a reload.

---

### User Story 3 - Refreshed, consistent look across the app (Priority: P2)

The whole signed-in app follows the new design in `resources/Sidebar-Design.png`: the "Milos" brand mark at the top of the sidebar, a "PLAN" section with the three entries and icons, "Replay tour" and the user's name with their current routine type at the bottom of the sidebar, a header on the daily page with the date, previous/next day arrows, a "Today" button and "Sign out", the schedule card with the live clock and its controls, colour-coded task cards with completion checkboxes, a current-time line, a "Now … / Next …" footer, and the Routine Buddy chat panel on the right. Colours, spacing, corner rounding and shadows come from one shared set of style values, so every screen (including sign-in and onboarding) looks like one product and future screens can reuse them.

**Why this priority**: The motivation is that the UI looks "primitive and unprofessional". It shares P2 with Story 2 because the app is usable without it, but it is what users and the interviewer see first.

**Independent Test**: Compare each signed-in screen with the design side by side; change one shared colour value and confirm every place that uses it updates together.

**Acceptance Scenarios**:

1. **Given** the Daily Routine page on a wide screen, **When** it is compared with the design, **Then** the layout, sections, labels and colour scheme match the design (sidebar left, schedule centre, Routine Buddy right).
2. **Given** the shared style values, **When** the primary colour is changed in that one place, **Then** buttons, the active sidebar entry, links and other primary-coloured elements all update with no other edits.
3. **Given** the sign-in, sign-up and onboarding screens, **When** they are viewed after the change, **Then** they use the same colours, type and component styles as the rest of the app.
4. **Given** the user clicks "Replay tour" in the sidebar, **When** the tour opens, **Then** it is the same product walkthrough that the existing "How it works" control opens today.
5. **Given** the sidebar's user area, **When** it is shown, **Then** it shows the signed-in user's name and the routine type that applies today.

---

### User Story 4 - Sidebar on small screens (Priority: P3)

On a phone-sized screen the sidebar starts hidden. A burger (menu) button opens it over the content, the same way the Android version works. When the user picks an entry, the sidebar closes and the chosen page is shown.

**Why this priority**: The request is mainly for the web version, but the app must stay usable on phones.

**Independent Test**: Open the app at phone width, open the menu with the burger button, pick each entry and confirm the sidebar closes and the page switches.

**Acceptance Scenarios**:

1. **Given** a phone-sized screen, **When** an onboarded user opens the app, **Then** the sidebar is hidden and a burger button is visible.
2. **Given** a phone-sized screen, **When** the user taps the burger button, **Then** the sidebar opens over the content.
3. **Given** the sidebar is open on a phone-sized screen, **When** the user picks an entry, **Then** the sidebar closes and that page is shown.
4. **Given** the sidebar is open on a phone-sized screen, **When** the user taps outside it or presses Escape, **Then** it closes without changing page.

---

### Edge Cases

- A user finishes onboarding: the sidebar appears straight away and they land on Daily Routine without a reload.
- A user who has not completed onboarding types the address of Default routine or Analytics: they are sent back to onboarding.
- A signed-out user opens any sidebar page address: they are sent to sign-in.
- The window is resized from wide to narrow while the sidebar is shown: it switches to the burger behaviour without leaving the sidebar covering the content; resizing back restores the user's saved wide-screen choice.
- The user has no tasks in their default routine: the Default Routine page shows an empty board they can add to, not an error.
- The user's name is long: it is shortened with an ellipsis in the sidebar rather than breaking the layout.
- Keyboard-only users: every sidebar entry, the hide/show control and the burger button can be reached and used with the keyboard, and focus is visible.
- Saved browser preferences are unavailable (for example in private browsing): the sidebar falls back to its default (shown on wide screens) without errors.

## Requirements *(mandatory)*

### Functional Requirements

**Sidebar and navigation**

- **FR-001**: The app MUST show a sidebar on every signed-in page once the user has completed onboarding, and MUST NOT show it on the sign-in, sign-up or onboarding screens.
- **FR-002**: The sidebar MUST contain, under a "PLAN" heading, three entries in this order: "Today" (Daily Routine), "Default routine", and "Analytics" with a "Soon" badge, each with an icon as in the design.
- **FR-003**: Selecting a sidebar entry MUST open the matching page and highlight that entry as active.
- **FR-004**: Each sidebar page MUST have its own address, so it can be reloaded, bookmarked and reached with the browser's back and forward buttons.
- **FR-005**: After sign-in, an onboarded user MUST land on the Daily Routine page for today.
- **FR-006**: On wide screens the sidebar MUST be shown by default and MUST have a control to hide and show it; the choice MUST be remembered on that device.
- **FR-007**: On phone-sized screens the sidebar MUST start hidden, open over the content from a burger button, and close when the user picks an entry, taps outside it, or presses Escape.
- **FR-008**: The sidebar MUST show the "Milos" brand mark at the top, and at the bottom a "Replay tour" entry and the signed-in user's name with the routine type that applies today.
- **FR-009**: "Replay tour" MUST open the existing product walkthrough.
- **FR-010**: "Sign out" MUST stay available on every sidebar page (in the page header, as in the design).

**Pages**

- **FR-011**: The Daily Routine page MUST keep all current behaviour (date navigation, live clock and its controls, zoom, gap clear, clean up, add task, task completion, Routine Buddy chat) and present it in the new layout.
- **FR-012**: The Default Routine page MUST let an onboarded user view their default routine and add, edit, move, resize and delete its tasks, for each routine type they have, with changes saved.
- **FR-013**: The Default Routine page MUST NOT show the "complete onboarding" action. It MUST show Routine Buddy beside the board, with a separate conversation for the Weekday and Weekend routines.
- **FR-013a**: On every page that has Routine Buddy (Today, Default routine, onboarding), the chat MUST stay visible beside the board on all screens wider than phone size (761px and up). Only on phone-sized screens may it be swapped with the board behind a chat button.
- **FR-014**: The Analytics page MUST show a "coming soon" placeholder and no data.
- **FR-015**: Users who have not completed onboarding MUST be redirected to onboarding from any sidebar page; signed-out users MUST be redirected to sign-in.

**Visual style**

- **FR-016**: Signed-in screens MUST follow the layout, colours and component styles of `resources/Sidebar-Design.png`.
- **FR-017**: Colours, type sizes, spacing, corner rounding and shadows MUST be defined once in a shared set of named style values, and every screen MUST use those values instead of repeating raw colour codes.
- **FR-018**: The sign-in, sign-up and onboarding screens MUST be restyled with the same shared style values so the app looks consistent end to end.
- **FR-019**: Interactive elements MUST keep a visible keyboard focus state and text MUST meet normal contrast for readability (WCAG AA).

### Key Entities

- **Navigation entry**: an item in the sidebar: label, icon, destination page, optional badge (such as "Soon"), and whether it is active.
- **Sidebar preference**: whether the user wants the sidebar shown or hidden on wide screens; kept per device.
- **Style values**: the shared, named colours and other visual settings that every screen uses.
- **Default routine** (existing): the user's template routine per routine type, made of tasks with start and end times.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An onboarded user can reach each of the three sidebar pages from any other sidebar page in one click (wide screens) or two taps (phone).
- **SC-002**: 100% of onboarded sign-ins land on the Daily Routine page for today.
- **SC-003**: A user can add, change and delete a default-routine task after onboarding and see the change kept after a reload, in under 1 minute per change.
- **SC-004**: Changing one shared colour value updates every screen that uses it, with zero other edits needed; no screen repeats raw colour codes.
- **SC-005**: Side-by-side review of the Daily Routine page against the design shows no missing sections or labels.
- **SC-006**: All Daily Routine features that work before this change still work after it (no regressions).
- **SC-007**: The layout is usable with no horizontal scrolling of the page from phone width (about 360 px) to wide desktop.

## Assumptions

- The visual reference is `specs/F002-ui-refactoring/resources/Sidebar-Design.png` (Daily Routine page on a wide screen). Screens without their own mockup (Default Routine, Analytics, sign-in, onboarding, phone layout) follow the same style and are designed in that spirit.
- "Milos" is the product's own brand name (it matches the app's hosting site).
- The Default Routine page reuses the onboarding editing board and its routine-type switching; it adds no new editing abilities.
- Routine Buddy is on Today, Default routine and onboarding; the Analytics placeholder has no chat because there is no routine to act on.
- The sidebar's shown/hidden choice is stored on the device only, not in the user's account.
- The "routine type that applies today" in the sidebar uses the same rule the Daily Routine page already uses (for example weekday vs weekend).
- The existing "How it works" walkthrough is reused for "Replay tour"; its content may need small text updates to point at the new layout, but no new tour is in scope.
- No backend changes are expected; existing default-routine data and actions are reused.

### Out of Scope

- Any real analytics content (only the placeholder).
- A native mobile app; the phone behaviour here is for the web app on small screens.
- Dark mode or user-selectable themes (the shared style values make it possible later).
