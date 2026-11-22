# Feature Specification: User Profile & Configuration Store

**Feature Branch**: `F006-user-profile-configuration-store`

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description: from ticket `specs/F006-user-profile-configuration-store/F006-user-profile-configuration-store.md`. Clicking the profile icon at the bottom left of the sidebar opens a user profile screen showing profile information, the subscription plan and a Sign out button. UI settings (light/dark theme, task board zoom level, more later) are stored on the user's account so a page refresh doesn't reset them.

## Clarifications

### Session 2026-11-21

- Q: Once a user picks Light or Dark, can they switch back to following the device setting? → A: Yes, everywhere — every theme toggle becomes a 3-way Light / Dark / System control.
- Q: Should the Profile screen have a Preferences section to see and change theme and board zoom? → A: Yes, theme + zoom; the sidebar toggle and board zoom buttons stay too.
- Q (analysis follow-up): What does the collapsed desktop sidebar rail show for the profile? → A: The user's avatar, as an "Open profile" control (FR-001, SC-004).
- Q: After sign-out on a shared device, what happens to the theme left on that device? → A: The pre-F006 device theme is copied once, to the first account that signs in on that device after release. Later accounts never inherit it. The sign-in screen keeps showing the last theme used.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - My display settings stay as I left them (Priority: P1)

A signed-in user switches to dark mode and zooms the task board to 150%. They refresh the page, or come back tomorrow on another computer and sign in. The app opens in dark mode and the board is still at 150%.

**Why this priority**: This is the problem the ticket names: settings reset to defaults whenever the page is refreshed, so the app feels inconsistent. Fixing it is the main value of the feature.

**Independent Test**: Sign in, change the theme and the board zoom, then reload the page. Both settings are kept. Sign in as the same user in a fresh browser profile and see the same settings.

**Acceptance Scenarios**:

1. **Given** a signed-in user in light mode, **When** they switch to dark mode and reload the page, **Then** the app shows dark mode after the reload.
2. **Given** a signed-in user with the board at 100%, **When** they zoom to 150% on the Today board and reload, **Then** the Today board opens at 150%.
3. **Given** the user zoomed to 150% on the Today board, **When** they open the Default routine board or the Onboarding board, **Then** that board also opens at 150% (one shared zoom level).
4. **Given** a user who saved dark mode and 75% zoom on device A, **When** they sign in on device B, which has never been used before, **Then** device B shows dark mode and 75% zoom.
5. **Given** a user who has never chosen a theme on any device, **When** they sign in, **Then** the theme follows their operating system's light/dark setting.
6. **Given** a signed-in user who chose Dark, **When** they choose System on any theme control and reload, **Then** the app follows the operating system's setting, on every device they use.
7. **Given** a user who has never zoomed, **When** any board opens, **Then** it opens at 100%.

---

### User Story 2 - Open my profile from the sidebar (Priority: P2)

A signed-in user clicks their avatar and name at the bottom of the sidebar. A Profile screen opens inside the app, with the sidebar still showing. It lists their name, email and subscription plan, has a Preferences section for theme and board zoom, and has a Sign out button.

**Why this priority**: It gives account functions one obvious home, and a place to add settings later. It is useful, but the app still works without it, so it comes second.

**Independent Test**: Click the sidebar user block. The Profile screen opens with the correct name, email and "Free" plan. Pressing Sign out ends the session and returns to the sign-in screen.

**Acceptance Scenarios**:

1. **Given** a signed-in, onboarded user, **When** they click the user block (avatar + name) at the bottom of the sidebar, **Then** the Profile screen opens inside the app shell.
2. **Given** the Profile screen is open, **When** it loads, **Then** it shows the user's display name, email address and subscription plan ("Free plan").
3. **Given** the Profile screen is open, **When** the user presses Sign out, **Then** they are signed out and taken to the sign-in screen, as with the existing Sign out button.
4. **Given** a narrow screen (phone), **When** the user opens the sidebar overlay and taps their user block, **Then** the overlay closes and the Profile screen opens.
5. **Given** the Profile screen is open, **When** the user changes the theme to Dark and the zoom to 125% in its Preferences section, **Then** the app turns dark right away, the sidebar theme control shows Dark, and every board opens at 125%.
6. **Given** the user is on the Profile screen, **When** they reload the page, **Then** the Profile screen is still shown (it has its own address).

---

### User Story 3 - Settings store ready for new preferences (Priority: P3)

The product team adds a new preference later, for example a default board view. It can be saved to and loaded from the same per-user settings store without changing how theme and zoom are saved. Users who never set the new preference get its default value.

**Why this priority**: The ticket says "others in the future". This keeps later work cheap, but users don't see it directly.

**Independent Test**: Add a test-only preference key. It saves and loads like theme and zoom. Existing users who never set it get its default, and their theme and zoom are unchanged.

**Acceptance Scenarios**:

1. **Given** a stored settings record without a newly added preference, **When** the user's settings load, **Then** the new preference takes its default value and the other preferences are unchanged.
2. **Given** a settings record containing a preference the app no longer recognises, **When** settings load, **Then** loading still succeeds and the unknown entry is ignored.

---

### Edge Cases

- **Save fails (offline, server error)**: the change still applies on screen right away and stays for the rest of the session. The user sees a short, non-blocking notice that the setting couldn't be saved. The app tries again on the next change of that setting.
- **Settings fail to load at sign-in**: the app uses the last settings known on this device, or the defaults (follow OS, 100%) if there are none. It never blocks the user from using the app.
- **Flash on reload**: on reload the app shows the theme last used on this device until the account's settings arrive. It must not briefly show the wrong theme when this device's last value matches the account.
- **Existing per-device theme**: if the device already has a theme choice from before this feature (F005), it is saved to the first account that signs in there after release, if that account has no saved theme. This happens once per device, so nobody's theme changes because of the upgrade.
- **Two devices change the same setting**: the most recent save wins. A device that is already open picks up the other device's change on its next sign-in or page load, not live.
- **Zoom outside allowed range or invalid stored value**: the board clamps the value to 50%–300% and rounds it to the nearest step of 25%. An unreadable value is treated as 100%.
- **Signed-out screens** (sign-in page): no account is known, so the theme there uses the device's last-used theme, or the OS setting. Theme changes made there are kept on the device only.
- **Rapid repeated zoom clicks**: only the final level needs to be saved. Intermediate levels may be skipped.
- **Change made while settings are still loading**: if the user changes the theme or zoom before the account's settings arrive, their change wins. It is saved to the account, and the loaded value doesn't overwrite it.
- **Sign-out or reload right after a change**: a change that hasn't been saved yet is still sent when the user signs out or leaves the page, so it isn't lost.
- **Shared device**: after sign-out, the sign-in screen keeps the last theme shown. The next user who signs in gets their own account's settings (System and 100% if they have none). The previous user's theme is never copied into their account.

## Requirements *(mandatory)*

### Functional Requirements

**Profile screen**

- **FR-001**: The sidebar user block (avatar, name) MUST be a control that opens the Profile screen. It must be keyboard-reachable and labelled for screen readers (e.g. "Open profile"). When the desktop sidebar is collapsed to its narrow rail, the rail MUST also show the user's avatar as an "Open profile" control.
- **FR-002**: The Profile screen MUST be a page inside the app shell with its own address, so reload and back/forward work. It is available only to signed-in, onboarded users, under the same guard as the other shell pages.
- **FR-003**: The Profile screen MUST show the user's display name and email address. Both are read-only in this feature. The display name is the account's username, or the email when there is no username. The sidebar user block uses the same rule.
- **FR-004**: The Profile screen MUST show the user's subscription plan. Every user is shown as on the "Free plan" in this feature, with no upgrade or payment action.
- **FR-005**: The Profile screen MUST have a Sign out button that behaves exactly like the existing Sign out button: it ends the session and goes to the sign-in screen.
- **FR-005a**: The Profile screen MUST have a Preferences section showing the current theme (Light / Dark / System) and board zoom level (50%–300%, 25% steps). Both can be changed there, with the same immediate-apply and save behaviour as the sidebar toggle and board zoom buttons. A change in one place MUST show in the other without a reload.
- **FR-006**: On narrow screens, choosing the user block in the sidebar overlay MUST close the overlay and open the Profile screen, the same way other sidebar items behave.

**Account-level settings**

- **FR-007**: The system MUST store each user's UI settings on their account, not only on the device. The settings MUST be returned to that user on every sign-in and page load, on any device.
- **FR-008**: The system MUST store the theme setting with three states: Light, Dark, or System. System is also the starting value for users who have never chosen. With System, the app follows the operating system's light/dark setting and updates when that setting changes.
- **FR-009**: Every theme control (sidebar, onboarding top bar, sign-in header) MUST be a 3-way Light / Dark / System choice that shows which option is active. When signed in, a change MUST apply immediately and be saved to the account. On signed-out screens, it is kept on the device only.
- **FR-010**: The system MUST store one board zoom level per user, shared by the Today, Default routine and Onboarding boards. Default is 100%, the allowed range is 50%–300%, and it moves in 25% steps (today's limits).
- **FR-011**: Changing the zoom on any board MUST apply immediately and be saved to the account. Every board MUST open at the saved zoom level.
- **FR-012**: Users MUST only be able to read and change their own settings.
- **FR-013**: When a setting cannot be saved, the change MUST still apply for the current session, and the user MUST see a non-blocking notice. When settings cannot be loaded, the app MUST fall back as described in Edge Cases and stay usable.
- **FR-014**: A theme chosen on the device before this feature (F005) MUST be copied at most once per device: to the first account that signs in there after release, and only if that account has no saved theme. After that, the device MUST NOT copy its theme into any account.
- **FR-015**: The device MUST remember the last-applied theme so the first screen after a reload has no visible theme flash. The account value MUST take over once it loads.
- **FR-016**: The settings store MUST allow new named preferences to be added later, each with its own default. Adding one MUST NOT require changing or migrating existing preferences. Unknown or missing entries MUST NOT break loading.
- **FR-017**: A new user's account MUST start with default settings: theme System (follow OS) and zoom 100%. No setup step is needed.

### Key Entities

- **User Settings**: the UI preferences that belong to one user account. It holds the theme (Light, Dark or System; default System) and the board zoom level (50%–300%, default 100%), and is open to more named preferences later. Each user has exactly one set, created with defaults when needed. It records when it was last updated.
- **User Profile (view)**: the account information shown on the Profile screen: display name, email and subscription plan. The plan is shown as "Free" for everyone in this feature, and nothing new is stored for it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of test runs, after changing the theme or zoom and reloading, the app shows the changed values, with no manual re-selection.
- **SC-002**: A user signing in on a second device sees the same theme and zoom they last saved, in 100% of test runs.
- **SC-003**: After a reload, the app's first visible screen shows the correct theme, with no flash of the opposite theme, whenever this device last used the same theme as the account.
- **SC-004**: A user can reach their Profile screen from any app page in 1 click on wide screens (sidebar expanded or collapsed to the rail), or 2 taps on phones (open the menu, then tap the user block).
- **SC-005**: When the settings service is unavailable, the user can still use every page, and theme/zoom changes still apply for the session.
- **SC-006**: Existing users who chose a theme on only one device before this release, or the same theme on every device, see that theme after it ships. A user who chose different themes on different devices ends up with the theme from the first device they sign in on after release.

## Assumptions

- **Subscription plan**: no plans or billing exist yet. The Profile screen shows "Free plan" for every user, with no upgrade action (Discussion log, Q1). Real plans are a future feature.
- **Theme default**: when the user has never chosen a theme, the app follows the OS setting (Discussion log, Q2). This replaces the draft's "default Light mode". If the OS reports no preference, Light is used.
- **Zoom scope**: one zoom level shared by all boards (Discussion log, Q3).
- Profile information is read-only. Editing name, email, password or avatar, and deleting the account, are out of scope.
- The existing Sign out button in each page header stays. The Profile screen adds another way to sign out.
- Theme controls stay where they are today, but each becomes a 3-way Light / Dark / System choice. The Profile screen also gets a Preferences section for theme and zoom (Clarifications).
- Changes made on another device show up on the next sign-in or page load, not live.
- The sidebar collapsed/expanded state stays a per-device preference (as today) and is not moved to the account in this feature.
- No design mockups were supplied (`resources/` is empty). The Profile screen follows the existing app-shell page layout and style tokens.
- **Testing**: automated logic tests (the existing approach) cover settings defaults, validation and fallback. The ticket asks for React tests, so the key flows (change theme or zoom → reload → kept; open Profile → Sign out) should also be checked in a browser-level test. The plan chooses the tool, with headless, scripted browser runs recommended, plus a manual check in `quickstart.md`.
