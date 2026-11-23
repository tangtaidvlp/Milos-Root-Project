# Feature Specification: Persistent Task Colors, Non-Intrusive Live Mode & Light/Dark Mode

**Feature Branch**: `F005-i-want-color-to-be-persisted`

**Created**: 2026-11-21

**Status**: Draft

**Input**: Ticket `specs/F005-i-want-color-to-be-persisted/F005-i-want-color-to-be-persisted.md`. "Task color now varies on the front-end; I want it persisted in the backend, with the color decided by the backend. Live mode drags the UI to its position even when the user is looking at another point in the chart; it should only run once when the page first renders so the user can see what the current task is." Scope extended during clarification (2026-11-21): enable light/dark mode in the app.

## Clarifications

### Session 2026-11-21

- Q: When existing tasks with no saved color are given one for the first time, should they keep the color they show today? → A: No. Old data gets no special treatment: no migration, backfill or fallback logic for tasks with no saved color. Only tasks created after release are in scope.
- Q: (raised by user) Where is the task palette defined? → A: The backend owns the task palette and serves it to the app. The app shows the palette it gets from the backend and does not keep its own list of task colors.
- Q: Should one task color look the same in light and dark mode, or switch with the theme? → A: Theme-aware. Each palette entry has a stable ID with a light and a dark version, and a task with a palette color stores the ID. A color the user picks stores that exact value, shown the same in both themes.
- Q: Should Buddy be able to set or change a task's color when asked? → A: Yes, by palette color name only (e.g. "make Gym the blue one"). When the user doesn't ask, Buddy leaves color to the backend's assignment.
- Q: (raised by user) Is light/dark mode part of this feature? → A: Yes. The app has no dark theme today. This feature adds a dark theme for the whole app and a way to switch between light and dark.
- Q: Where should the app remember the user's light/dark choice? → A: On the device only. Each browser remembers its own choice; it is not saved to the user's account and does not follow them to other devices.
- Q: How should the backend choose a color for a new task? → A: Round-robin through the palette, in the palette's order, so the palette order (controlled by the backend) controls what the board looks like. When the user creates a task by hand, the create dialog pre-selects the next round-robin color, and the user can keep it or change it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A task keeps its color (Priority: P1)

A user builds and edits their routine (by hand or with Buddy). Each task has a color that stays the same no matter what else changes. Adding, deleting, moving or resizing other tasks, reloading the page, or opening the app on another device does not change it.

**Why this priority**: This is the main pain point in the ticket. Colors that shift after every edit make the board hard to scan and look broken.

**Independent Test**: Note each task's color in a routine. Add a task before the others, delete one, drag another to a new time, then reload. Every task that was already there shows the same color it had before.

**Acceptance Scenarios**:

1. **Given** a routine with tasks A, B and C showing three colors, **When** the user adds task D earlier in the day than A, **Then** A, B and C keep their colors and D gets a color of its own.
2. **Given** a routine with tasks A, B and C, **When** the user deletes B, **Then** A and C keep their colors.
3. **Given** a task with a color, **When** the user moves or resizes it, renames it, or marks it complete, **Then** its color does not change.
4. **Given** a routine viewed on one device, **When** the same user opens it on another device or after a reload, **Then** every task shows the same color on both.
5. **Given** a user creating a task without choosing a color, by hand or through Buddy, **When** the task is saved, **Then** the system assigns it the next palette color in round-robin order and stores it.
6. **Given** the last task created in a routine got palette color 3, **When** the user opens the dialog to create a new task, **Then** palette color 4 is pre-selected. After the last palette color, the sequence wraps back to the first.

---

### User Story 2 - User-chosen color wins (Priority: P2)

On the Default Routine, a user can still choose a task's color in the task edit dialog. That choice is stored and replaces the color the system assigned.

**Why this priority**: The color picker already exists. Keeping it working means automatic colors don't take control away from the user.

**Independent Test**: Open a task in the Default Routine edit dialog, pick a different color, save and reload. The task shows the chosen color.

**Acceptance Scenarios**:

1. **Given** a task with a system-assigned color, **When** the user picks another color in the edit dialog and saves, **Then** the task shows the chosen color after a reload.
2. **Given** a task whose color the user chose, **When** other tasks are added, removed or edited, **Then** that task's color does not change.
3. **Given** a task, **When** the user asks Buddy to change it to a palette color by name (e.g. "make Gym the blue one"), **Then** the task's stored color becomes that palette entry.
4. **Given** the user asks Buddy for a color that isn't in the palette, **When** Buddy replies, **Then** it doesn't change the color and tells the user which palette colors are available.

---

### User Story 3 - Daily tasks match their default-routine color (Priority: P2)

When the day's routine is created from the Default Routine, each daily task has the same color as the default-routine task it came from. A task added only to today's routine gets a system-assigned color that is stored like any other.

**Why this priority**: Users switch between the Default and Daily views. The same activity should look the same in both.

**Independent Test**: Give a Default Routine task a known color, let the next daily routine be created from it, and open the Daily Routine. The matching daily task shows that color.

**Acceptance Scenarios**:

1. **Given** a Default Routine task "Gym" in a given color, **When** a daily routine is created from the Default Routine, **Then** the daily "Gym" task has the same color.
2. **Given** a daily routine, **When** the user or Buddy adds a task only to that day, **Then** it gets a system-assigned color that stays the same across reloads and edits.
3. **Given** a daily routine already created, **When** the user later changes the color of the matching Default Routine task, **Then** the existing daily task keeps its color. The new color applies to daily routines created after the change.

---

### User Story 4 - Live mode centres once and then lets the user scroll (Priority: P1)

When the user opens the Daily Routine, the board scrolls once to the current time so they can see what to do now. After that the user can scroll anywhere on the board, and the view stays where they put it while the clock keeps running.

**Why this priority**: Today the view jumps back to "now" every minute, so the user can't look at other parts of their day. This is the second core complaint in the ticket.

**Independent Test**: Open the Daily Routine and confirm it shows the current time. Scroll to the evening and wait more than two minutes. The view stays on the evening, and the "now" marker and Now/Next footer still update.

**Acceptance Scenarios**:

1. **Given** the user opens the Daily Routine, **When** the board first appears, **Then** it is scrolled so the current time is in view.
2. **Given** the user has scrolled away from the current time, **When** one or more minutes pass in live mode, **Then** the scroll position does not change.
3. **Given** live mode is running, **When** minutes pass, **Then** the current-time marker and the Now/Next footer still update to the new time.
4. **Given** the user has paused live mode and then clicks "Resume live", **When** live mode resumes, **Then** the clock updates again but the view does not move.
5. **Given** the user zooms the board in live mode, **When** the zoom changes, **Then** the view does not jump to the current time.

---

### User Story 5 - Switch between light and dark mode (Priority: P2)

A user can switch the whole app between a light and a dark theme. Every page, including task cards in their palette colors, the chat with Buddy, dialogs and the sign-in page, is readable in both themes.

**Why this priority**: The theme-aware palette (palette entries have light and dark versions) only matters once a dark theme exists. It also lets users use the app comfortably at night, when they check the Daily Routine.

**Independent Test**: Switch to dark mode, then go through sign-in, Default Routine, Daily Routine, Buddy chat and the task edit dialog. Everything is dark and readable. Reload, and the dark theme is still on.

**Acceptance Scenarios**:

1. **Given** a user who has never chosen a theme, **When** they open the app, **Then** it uses the theme their device is set to (light or dark).
2. **Given** the app in light mode, **When** the user switches to dark mode, **Then** the whole app changes to the dark theme straight away, without a reload.
3. **Given** the user chose a theme, **When** they reload or come back later on the same device, **Then** the app opens in the theme they chose.
4. **Given** the user chose dark mode on one device, **When** they open the app on another device, **Then** that device uses its own saved choice, or the device setting if there is none.
5. **Given** dark mode, **When** the user views the routine boards, **Then** tasks with palette colors show the dark version of their color, and tasks with a user-chosen exact color show that color.

---

### Edge Cases

- Tasks that existed before this feature and have no stored color are out of scope. No migration, backfill or special display logic is built for them. Users can recreate them or set their color in the edit dialog.
- A routine has more tasks than the palette has colors. Round-robin wraps back to the first entry, so colors repeat, but each task's own color is still stable.
- Two tasks next to each other in time can share a color (e.g. after deletes, or after wrapping round). That's acceptable with round-robin.
- Buddy splits a task that crosses midnight into two parts. Both parts get the same color.
- A user-chosen color that is not in the palette is stored and shown as chosen.
- The user reloads the Daily Routine page. That counts as a new first load, so the board scrolls to the current time once.
- The user switches away from the Daily Routine and comes back within the app. That counts as a new first load, so the board scrolls to "now" once.
- The user changes the date on the Daily Routine page. That is not a new first load: the board keeps its scroll position. Only opening or reloading the page scrolls to "now".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST store a color for every task created in the Default Routine or in any Daily Routine.
- **FR-002**: When a task is created without a color (manually, through Buddy, or by any other creation path), the system MUST assign one from the task palette and store it.
- **FR-003**: Assigned colors MUST go round-robin through the task palette, in the palette's order: each new task in a routine gets the palette entry after the one most recently assigned in that routine, wrapping back to the first after the last. The first task in a new Default Routine gets the first palette entry. A Daily Routine created from the Default Routine continues the Default Routine's sequence, so its first day-only task gets the color the Default Routine would assign next. A color picked by the user or by Buddy that isn't the next one is stored but doesn't move the sequence. The palette order defined by the backend sets the color sequence.
- **FR-004**: When a user creates a task by hand in a dialog that shows a color, the dialog MUST pre-select the next round-robin palette color for that routine. If the user keeps it, the task stores that palette entry. If the user picks another color, their choice is stored (FR-007).
- **FR-005**: A task's stored color MUST NOT change when other tasks are created, deleted, reordered, moved or resized, or when the task itself is moved, resized, renamed or marked complete.
- **FR-006**: The app MUST show each task in its stored color and MUST NOT decide a task's color from its position in the list.
- **FR-007**: Users MUST still be able to choose a task's color in the Default Routine task edit dialog. The chosen color MUST be stored and replace the assigned one.
- **FR-008**: When a Daily Routine is created from the Default Routine, each daily task MUST take the color of the default-routine task it comes from.
- **FR-009**: Tasks that existed before this feature with no stored color are out of scope. The system MUST NOT add migration, backfill or fallback logic for them. Any task whose color can't be shown (no stored color, an unknown palette ID, or the palette failing to load) gets the board's default neutral style. That is the same for every task, not something built for old data.
- **FR-010**: The backend MUST be the single source of the task palette and MUST make it available to the app. The app MUST get the palette from the backend and MUST NOT keep its own separate list of task colors.
- **FR-011**: A task with a palette color MUST show that entry's light version in the light theme and its dark version in the dark theme. A task with a user-chosen exact color MUST show that color in both themes.
- **FR-012**: Palette entry IDs MUST stay valid over time. If an entry's light or dark version changes, every task that uses it MUST show the new version, without changing the task.
- **FR-013**: When Buddy splits a task into parts (e.g., across midnight), all parts MUST get the same color.
- **FR-014**: In live mode, the Daily Routine board MUST scroll to the current time exactly once, when the board is first shown.
- **FR-015**: After that first scroll, the board MUST NOT change the scroll position because of clock ticks, resuming live mode, zooming, or saving a task.
- **FR-016**: The current-time marker and the Now/Next footer MUST keep updating every minute in live mode, whatever the scroll position.
- **FR-017**: Buddy MUST be able to set a task's color to a palette entry chosen by name when the user asks. Buddy MUST NOT set exact color values. When the user doesn't mention color, Buddy MUST leave the color to the system's assignment.
- **FR-018**: The app MUST offer a light theme and a dark theme covering every page and dialog.
- **FR-019**: Users MUST be able to switch between light and dark from the app, from any page, and the change MUST take effect straight away without a reload.
- **FR-020**: Until the user chooses a theme, the app MUST follow the device's light/dark setting.
- **FR-021**: The user's theme choice MUST be remembered on the device (per browser), so the app opens in the chosen theme next time on that device, including on the sign-in page. It MUST NOT be stored in the user's account.
- **FR-022**: Text and key interface elements MUST stay readable in both themes (WCAG AA contrast for normal text).

### Key Entities *(include if feature involves data)*

- **Default Routine Task (template)**: A recurring task in the user's Default Routine. It gains a required, stored color (assigned by the system or chosen by the user).
- **Daily Task**: A task in a specific day's routine. It gains a required, stored color, copied from its default-routine task when created from one, or assigned by the system otherwise.
- **Task Palette**: The fixed set of task colors, owned by the backend and read by the app. It starts from the 8 tints the app uses today. Each entry has a stable ID, a light-theme version and a dark-theme version (an accent and a card background for each). The system picks assigned colors from this set.
- **Task Color (value stored on a task)**: Either a palette entry ID (system-assigned, or set by Buddy by name; follows the theme) or an exact color the user chose (looks the same in both themes).
- **Theme Preference**: The user's choice of light or dark, or no choice yet (follow the device). Stored per device, not on the account.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After any sequence of 10 mixed edits (add, delete, move, resize, rename, complete) to a routine, 100% of the tasks that were there before the edits still show their original color.
- **SC-002**: The same routine opened on two different devices or browsers shows identical colors for 100% of its tasks.
- **SC-003**: 100% of daily tasks created from the Default Routine show the same color as their default-routine task.
- **SC-004**: In live mode, a user who has scrolled away from the current time sees 0 automatic scroll jumps over a 10-minute session.
- **SC-005**: On first opening the Daily Routine, the current time is visible on the board without any scrolling by the user.
- **SC-006**: In dark mode, 100% of pages and dialogs show the dark theme, with no light-only panels left.
- **SC-007**: Switching theme takes effect in under 1 second, with no page reload.
- **SC-008**: The product owner confirms all three behaviours (colors, live mode, theme) in a manual check of the sign-in, Default Routine and Daily Routine pages.

## Assumptions

- The visual reference is the app's existing 8-tint task palette for light mode. The proposed dark theme colors, for the task palette and every other color in the app, are in `resources/dark-theme-palette.md`. They keep each light color's hue and pass the same contrast checks as the light theme.
- Assigned colors come from the backend's palette, whose entries switch with the theme so they stay readable in light and dark themes. User-chosen colors can be any color, as today, and don't switch with the theme.
- The Daily Routine edit dialog keeps having no color picker. Daily tasks get their color from the default routine or by assignment.
- Only tasks created after release are in scope for stored colors. Old data is left as it is.
- Changing a Default Routine task's color does not recolor daily routines that already exist.
- The Default Routine (setup) board keeps its current scroll behaviour: it opens at 06:00 and keeps the time at the top of the view when zooming. Only the live-mode behaviour changes.
- "First load" means each time the Daily Routine board is mounted: opening the page, reloading, or navigating back to it.
- Pausing and resuming the live clock, and dragging the time slider, keep their current meaning. They just never move the scroll position by themselves.
