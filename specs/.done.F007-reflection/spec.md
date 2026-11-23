# Feature Specification: Daily Reflection (Plan vs Reality)

**Feature Branch**: `F007-reflection`

**Created**: 2026-11-21

**Status**: Draft

**Input**: Ticket `F007-reflection.md`: "A clone of our daily task, but the note reflects reality: we input what actually happened (the real routine we did), so we can see where we are on track and what we can improve. Reassure the user that everything is okay, don't be harsh, keep it up and improve every day. Data can be collected for analytics. Toggle ON reflection, which first clones the current daily tasks; then the user modifies it to reflect their real day, or asks AI to do it by telling it what happened." Discussion: reflection lives on the Daily Routine page as a toggle that switches on the comparison view.

## Clarifications

### Session 2026-11-22

Enhancement request: "For desktop/large screens, use side by side comparison for reflection rather than tab switching. Use a toggle button named 'Reflection' rather than tabs, placed somewhere that doesn't take much space."

- Q: On a large screen with Reflection on, should the Plan board in the side-by-side view be read-only or editable? → A: Both boards are editable.
- Q: Where should the compact "Reflection" toggle button go? → A: In the board toolbar, next to the clock controls (Pause clock / Gap clear).
- Q: In the side-by-side view, where should the comparison summary and Buddy's note go? → A: The Routine Buddy panel header is made shorter, and Buddy's note sits at the top of the chat window. The totals and group counts stay on the page as a slim strip.
- Q: Should the two side-by-side boards share one toolbar and scroll/zoom together? → A: Yes: one shared toolbar, and scroll and zoom stay in sync so the same times line up.
- Q: When is the screen "large", and what do smaller screens show with Reflection on? → A: Side by side from 1280px wide. Below that, the Reflection toggle switches the single board between Plan and Reality. Tapping a reality task opens a pop-up with that task's comparison status.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record what really happened today (Priority: P1)

On the Daily Routine page, a signed-in user switches on **Reflection** for the day they are viewing. The first time, the app copies that day's planned tasks into a reflection. The user then edits the reflection to match what actually happened. They can move a task's start time, change its duration, remove tasks they skipped, and add things they did that weren't planned. The plan for the day stays as it was.

**Why this priority**: This is the core of the feature. Without a record of reality there is nothing to compare or learn from.

**Independent Test**: Open today on the Daily Routine page with 4 planned tasks. Switch Reflection on and confirm the same 4 tasks appear as the reflection. Shorten one, delete one and add a new one. Switch Reflection off and confirm the plan still shows the original 4 tasks. Reload and switch Reflection on again, and confirm the edited reflection is still there.

**Acceptance Scenarios**:

1. **Given** a day with planned tasks and no reflection yet, **When** the user switches Reflection on, **Then** a reflection is created with a copy of every planned task (name, description, start time, duration, color), and the page shows it in reflection mode.
2. **Given** a reflection already exists for the day, **When** the user switches Reflection on, **Then** the saved reflection is shown and nothing is copied again.
3. **Given** the user is in reflection mode, **When** they add, edit or delete a task, **Then** only the reflection changes and the day's plan is unchanged.
4. **Given** the user edits the plan after the reflection was created, **When** they switch Reflection on, **Then** the reflection is unchanged. The copy is made only once.
5. **Given** a day with no planned tasks, **When** the user switches Reflection on, **Then** an empty reflection is created and the user can add what they did.
6. **Given** the user switches Reflection off, **When** they look at the page, **Then** they see and edit the plan as today, and the reflection is kept.

---

### User Story 2 - See plan vs reality and get gentle feedback (Priority: P2)

In reflection mode, the user sees the plan and what really happened together. Simple comparison facts are shown, such as total planned vs actual time, tasks done as planned, tasks shifted or shortened, tasks skipped, and unplanned tasks added. Buddy gives a short, warm note. It first recognizes what went well, then offers one or two gentle, concrete suggestions for tomorrow. It never scolds.

**Why this priority**: This answers "where am I on track and what can I improve", but it depends on Story 1's data.

**Independent Test**: Create a plan with 4 tasks, then a reflection where one task ran 30 minutes longer, one was skipped and one unplanned task was added. Confirm the comparison shows each of these differences correctly. Ask for Buddy's note and confirm it is encouraging and names at least one positive and at most two suggestions.

**Acceptance Scenarios**:

1. **Given** a reflection that differs from the plan, **When** the user views reflection mode, **Then** they can see, for each task, whether it went as planned, was changed (time or duration), was skipped, or was unplanned.
2. **Given** a reflection, **When** the user views the comparison, **Then** totals are shown for planned time, actual time, and the number of tasks in each group (as planned, changed, skipped, unplanned).
3. **Given** a reflection, **When** the user asks for feedback, **Then** Buddy writes a short note that starts with something positive, gives no more than two gentle suggestions, and contains no harsh, guilt-inducing or judgmental wording.
4. **Given** a reflection where almost nothing went to plan, **When** Buddy writes feedback, **Then** the tone stays reassuring ("that's okay, tomorrow is a fresh start") rather than critical.
5. **Given** a reflection identical to the plan, **When** the user views the comparison, **Then** every task shows as done as planned, and Buddy celebrates it.
6. **Given** a screen at least 1280px wide, **When** the user switches Reflection on, **Then** the Plan board and the Reality board appear side by side under one shared toolbar. Both can be edited, and scrolling or zooming one moves the other so the same times line up.
7. **Given** a screen narrower than 1280px with Reflection on, **When** the user taps a reality task, **Then** a pop-up shows that task's group (as planned, changed or unplanned), its planned and actual times, and a way to edit it.
8. **Given** a Buddy note exists for the day, **When** Reflection is on, **Then** the note appears at the top of the Buddy chat window, and the comparison totals appear as a slim strip above the board(s).

---

### User Story 3 - Tell Buddy what happened and let it update the reflection (Priority: P3)

In reflection mode, the user chats with Buddy on the Daily Routine page in plain language, for example: "I woke up an hour late, skipped the gym, and spent the afternoon helping a friend move." Buddy updates the reflection to match: it shifts, shortens, removes or adds tasks, and confirms what it changed. This chat is saved for each day, separately from that day's planning chat.

**Why this priority**: This makes reflection fast, but manual editing (Story 1) already delivers the value.

**Independent Test**: With Reflection on for a day that has a gym task at 07:00, tell Buddy "I skipped the gym and read for 30 minutes instead". Confirm the gym task is gone from the reflection, a 30-minute reading task was added, and the plan is untouched. Reload and confirm the reflection chat is still there, and the day's planning chat does not contain it.

**Acceptance Scenarios**:

1. **Given** reflection mode is on, **When** the user describes what happened in the Buddy chat, **Then** Buddy changes only the reflection for that day and tells the user what it changed.
2. **Given** reflection mode is off, **When** the user chats with Buddy, **Then** Buddy works on the plan as today, and the reflection is not changed.
3. **Given** the user has chatted in both modes for a day, **When** they reload the page, **Then** each mode shows its own saved conversation.
4. **Given** the user's description is too vague for Buddy to tell which task they mean, **When** Buddy replies, **Then** it asks a short follow-up question instead of guessing.

---

### Edge Cases

- **Future days**: Reflection is not available for days after today. The toggle is disabled with a short explanation, e.g. "You can reflect once the day has happened."
- **Resizing across 1280px while Reflection is on**: The view switches between side by side and the single Reality board without losing edits. Reflection stays on.
- **Editing the plan in the side-by-side view**: This is allowed. Plan edits change only the plan, and the comparison updates.
- **Past days without a saved plan**: The plan is empty. Switching Reflection on creates an empty reflection, and no plan is created as a side effect.
- **Past days with a plan**: Reflection works the same as for today, so users can catch up on previous days.
- **Overlapping tasks in the reflection**: These are allowed, since real days can overlap. Unlike the plan, reflection tasks are never pushed later automatically, because reality is recorded as it happened.
- **Planned task deleted after the reflection was made**: The reflection task that was copied from it counts as unplanned, since there is no longer a plan entry to compare against.
- **Tasks crossing midnight**: Same handling as planned tasks on the Daily Routine page.
- **Task renamed in the reflection**: It is still matched to its original planned task, so the comparison shows "changed", not "skipped + unplanned".
- **Reflection with every task deleted**: All planned tasks show as skipped, and Buddy's note stays kind.
- **AI unavailable**: Manual editing and the comparison still work. The feedback note and the chat show a friendly "Buddy is unavailable right now" message.
- **Switching dates while in reflection mode**: The page stays in reflection mode for the new date if reflection is allowed there. Otherwise it falls back to the plan.
- **Completed checkbox**: Marking a planned task "completed" does not change the reflection. The two stay independent.

## Requirements *(mandatory)*

### Functional Requirements

**Reflection lifecycle**

- **FR-001**: The Daily Routine page MUST offer a compact on/off toggle button labelled "Reflection" for the day being viewed. It MUST sit in the board toolbar, next to the clock controls, and MUST NOT add a row of its own. Plan/Reality tabs MUST NOT be used.
- **FR-002**: The toggle MUST be available for today and past days, and MUST be disabled for future days with an explanation.
- **FR-003**: The first time Reflection is switched on for a day, the system MUST create that day's reflection as a one-time copy of the day's planned tasks: name, description, start time, duration and color.
- **FR-004**: Each user MUST have at most one reflection per day. Switching Reflection on again MUST show the existing reflection without copying again.
- **FR-005**: The reflection and the plan MUST be independent. Edits to one MUST never change the other.
- **FR-006**: Switching Reflection on or off, and viewing a past day, MUST NOT create or change the day's plan.
- **FR-007**: Reflections MUST persist across reloads, sign-out and sign-in, and devices.
- **FR-008**: Users MUST only be able to see and change their own reflections.

**Editing reality**

- **FR-009**: In reflection mode, users MUST be able to add, edit (name, description, start time, duration, color) and delete reflection tasks, using the same editing interactions as planned tasks.
- **FR-010**: Each reflection task copied from a planned task MUST keep a link to that planned task, so the comparison can match them after renames or time changes. Tasks the user adds MUST be marked as unplanned.
- **FR-011**: Reflection mode MUST look clearly different from plan mode, with a visible label or style, so users always know which one they are editing.

**Comparison & feedback**

- **FR-012**: In reflection mode on screens at least 1280px wide, the page MUST show the Plan board and the Reality board side by side, with the board labels visible.
  - Both boards MUST be editable. Each has its own way to add a task, and each edit changes only that board.
  - The two boards MUST share one toolbar (clock, zoom, the Reflection toggle), and their scroll position and zoom MUST stay in sync.
- **FR-012a**: On screens narrower than 1280px, switching Reflection on MUST replace the single board's Plan view with the Reality view, and switching it off MUST bring the Plan back. Tapping a reality task MUST open a pop-up showing its group, planned vs actual start time and duration, and an edit action.
- **FR-012b**: The comparison totals and group counts (FR-014) MUST be shown as a slim, single-line strip above the board(s). The task-by-task breakdown MUST be collapsed by default.
- **FR-013**: The system MUST put each task into exactly one group:
  - **as planned**: linked task with the same start time and duration
  - **changed**: linked task with a different start time or duration
  - **skipped**: planned task with no linked reflection task
  - **unplanned**: reflection task with no linked planned task
- **FR-014**: The system MUST show summary totals: total planned time, total actual time, and the count of tasks in each group.
- **FR-015**: Users MUST be able to request a feedback note from Buddy for the day's reflection.
- **FR-016**: Buddy's feedback MUST be encouraging in tone. It MUST open with something positive, give at most two gentle, actionable suggestions, and avoid harsh, guilt-inducing or judgmental language. This MUST hold even when the day went very differently from the plan.
- **FR-017**: The latest feedback note for a day MUST be saved with the reflection and shown again on return. If the reflection has changed since the note was written, the user MUST be able to ask for a new note.
- **FR-017a**: In reflection mode, Buddy's note and its get/refresh action MUST appear at the top of the Buddy chat window, not in the page body. The Buddy panel header MUST be made shorter to make room for it.

**AI-assisted reflection**

- **FR-018**: While reflection mode is on, the Buddy chat on the Daily Routine page MUST act on the reflection for that day, not the plan.
- **FR-019**: While reflection mode is off, Buddy MUST behave as it does today and MUST NOT change the reflection.
- **FR-020**: The reflection chat MUST be saved per day as its own conversation, separate from that day's planning chat. It MUST follow the same history and lazy-loading behaviour as existing Buddy chats (F004).
- **FR-021**: After changing the reflection, Buddy MUST tell the user in its reply what it added, changed or removed.

**Data for analytics**

- **FR-022**: Reflection data MUST be stored in a way that supports later analysis of plan vs reality over time: per-task links to the plan, times, durations, the four groups, and dates.

### Key Entities

- **Daily Reflection**: What actually happened on one day for one user. It has a date, belongs to a user, holds a list of reflection tasks, and stores the latest feedback note with the time it was written. Each user has at most one per day.
- **Reflection Task**: One activity the user actually did. It has a name, description, start time, duration and color, plus an optional link to the planned task it came from. With no link, the task is unplanned.
- **Reflection Chat Conversation**: The saved Buddy conversation about a day's reflection. It is separate from the planning conversation for the same day.
- **Daily Routine / Daily Task** (existing): The plan for the day. This feature does not change it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can turn Reflection on and record a typical day's changes (up to 3 edits) in under 2 minutes by hand, or under 1 minute by telling Buddy.
- **SC-002**: In 100% of tested cases, editing the reflection leaves the plan unchanged, and editing the plan leaves an existing reflection unchanged.
- **SC-003**: Every task is put into the correct group (as planned, changed, skipped, unplanned) in 100% of tested cases, including renamed tasks.
- **SC-004**: In a review of at least 20 feedback notes across good, mixed and bad days, every note opens positively, has at most two suggestions, and contains no harsh or judgmental wording.
- **SC-005**: Reflection data and chats survive a reload and a sign-out and sign-in for 100% of tested days.
- **SC-006**: In user testing, at least 80% of users say the feedback made them feel encouraged rather than judged.

## Assumptions

- Reflection lives on the existing Daily Routine page as a mode toggle, not on a separate page (user decision).
- Days that can be reflected: today and past days. Future days are blocked (user decision).
- Feedback is a plan vs reality comparison plus a short, encouraging note from Buddy (user decision).
- Reflection chat uses its own saved thread per day, separate from the planning chat. Claude proposed this, the user may revise it, and it reuses the F004 chat history behaviour.
- The copy from plan to reflection happens once, when Reflection is first switched on. There is no automatic re-sync, and the user edits the reflection manually or through Buddy afterwards.
- The plan's "completed" checkbox stays as it is and is independent of reflection.
- Analytics dashboards, trends over weeks, streaks and charts are out of scope. This feature only stores reflection data in an analysis-ready form.
- No reminders or notifications to reflect are included.
- Reflection tasks use the same color palette and color rules as daily tasks (F005).
- The visual reference is the existing Daily Routine page. No mockups were provided. The 2026-11-22 screenshot of the old tabbed layout showed the summary panel and the tabs taking too much vertical space, which led to the compact layout in FR-001, FR-012 to FR-012b and FR-017a.
- In the side-by-side view, toolbar actions that change many tasks at once (Gap clear, Reset day) keep acting on the plan only, as today. In the Reality board, edits are made per task or through Buddy.
- In the side-by-side view, the Buddy chat is the reflection chat (FR-018). Buddy does not change the plan while Reflection is on, even though the user can edit the plan by hand there.
