# Feature Specification: Personal Goals

**Feature Branch**: `feat/F013-personal-goals`

**Created**: 2026-11-24

**Status**: Draft

**Epic**: [E001 – Personal Target](../E001-personal-target/E001-personal-target.md) (phase 1)

**Input**: User description: "A 'Personal Target' page for users to manage their personal goals, up to 3 goals. AI will use these goals to give better suggestions or what the user expects of the AI (what their goal is, what they expect the AI to help with)." Draft: [F013-personal-goals.md](F013-personal-goals.md).

## Clarifications

### Session 2026-11-24

- Q: Can Buddy change the user's goals from chat? → A: Yes, with confirmation. Buddy may propose adding or changing a goal; it is saved only after the user confirms.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Set my goals (Priority: P1)

A user opens the new "Personal Target" page from the main navigation and adds up to 3 goals. Each goal has the goal itself ("Run a 10k by March") and, optionally, how Buddy should help ("Keep me training 3 times a week and stop me skipping long runs"). The user can edit or delete goals at any time.

**Why this priority**: Without stored goals Buddy has nothing to use. This is the base of the epic.

**Independent Test**: Add, edit and delete goals on the page, sign in again on another device, and check that the same goals are there and that a 4th goal is refused.

**Acceptance Scenarios**:

1. **Given** a user with no goals, **When** they open Personal Target, **Then** they see a short explanation of what goals are for and an "Add goal" action.
2. **Given** a user with fewer than 3 goals, **When** they add a goal with a goal text, **Then** it is saved and still shown after reload and on another device.
3. **Given** a user with 3 goals, **When** they view the page, **Then** "Add goal" is unavailable and the page says the limit is 3.
4. **Given** a saved goal, **When** the user edits it and saves, **Then** the new text is shown.
5. **Given** a saved goal, **When** the user deletes it and confirms, **Then** it is removed. Cancelling keeps it.
6. **Given** an empty or whitespace-only goal text, **When** the user saves, **Then** the save is refused with a clear message.

---

### User Story 2 - Buddy uses my goals (Priority: P1)

In every Buddy chat (default routine, including onboarding; daily routine; reflection) and in reflection feedback, Buddy takes the user's goals and "how to help" notes into account. Its suggestions support the goals. When a request works against a goal, Buddy says so briefly and then does what the user decides.

**Why this priority**: This is the reason for storing goals: Buddy helps, guides and corrects the user based on what they want.

**Independent Test**: Set the goal "Run a 10k by March, keep me training 3 times a week", ask Buddy to plan tomorrow, and check that the plan includes training or refers to the goal.

**Acceptance Scenarios**:

1. **Given** a user with goals, **When** they ask Buddy for suggestions in any chat, **Then** the suggestions reflect the relevant goals and the help the user asked for.
2. **Given** the goal "Run a 10k by March", **When** the user asks Buddy to delete all of this week's runs, **Then** Buddy briefly points out the conflict with the goal and still follows the user's decision.
3. **Given** a user with no goals, **When** they chat with Buddy, **Then** Buddy behaves as it does today and doesn't bring up goals unless the user asks.
4. **Given** a user who just changed a goal, **When** they send their next message, **Then** Buddy uses the updated goal.

---

### User Story 3 - Buddy proposes goal changes, I confirm (Priority: P2)

In a chat the user says "my new goal is to be in bed by 11 PM", or Buddy suggests refining a goal during a reflection. Buddy shows a proposal (a new goal, or the old and new version of an existing goal) with Confirm and Dismiss. Nothing is saved until the user confirms.

**Why this priority**: It's convenient, but the page (Story 1) already covers managing goals.

**Independent Test**: Ask Buddy in chat to add a goal, dismiss the proposal and check that nothing changed. Ask again, confirm, and check that the goal appears on the Personal Target page.

**Acceptance Scenarios**:

1. **Given** a user with fewer than 3 goals, **When** they ask Buddy to add a goal, **Then** Buddy shows the proposed goal and "how to help" text with Confirm and Dismiss. Confirm saves it; Dismiss saves nothing.
2. **Given** a saved goal, **When** the user asks Buddy to change it, **Then** Buddy shows the current and the proposed version, and only Confirm saves the change.
3. **Given** a user with 3 goals, **When** they ask Buddy to add another, **Then** Buddy explains the limit and offers to replace one of the existing goals as a change proposal.
4. **Given** a proposal on screen, **When** the user ignores it or leaves, **Then** nothing changes.
5. **Given** a user asks Buddy to delete a goal, **When** Buddy replies, **Then** it doesn't delete anything and points the user to the Personal Target page.

---

### Edge Cases

- Text longer than the limit is refused, with a message that states the limit.
- Goal text that contains instructions such as "ignore your rules" is treated as the user's own words. It never changes Buddy's rules or what Buddy may do.
- A 4th goal saved from a second tab or device at the same time is refused. A user never ends up with more than 3 goals.
- The user confirms a proposal whose goal was deleted, or after reaching 3 goals elsewhere: the confirm is refused with the reason, and nothing changes.
- Buddy is unavailable: the Personal Target page still works, and the chat shows its usual friendly error.
- The user deletes their last goal: the page shows the empty state again.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Signed-in users MUST be able to open a "Personal Target" page from the main navigation.
- **FR-002**: Users MUST be able to add, edit and delete goals on that page. Each goal has a goal text (required, up to 150 characters) and a "how Buddy should help" text (optional, up to 500 characters). Leading and trailing spaces are ignored.
- **FR-003**: The system MUST allow at most 3 goals per user and refuse a 4th, whether it comes from the page or from chat.
- **FR-004**: Deleting a goal on the page MUST ask for confirmation.
- **FR-005**: Goals MUST be saved to the user's account, shown in the order they were created, and be the same on every device.
- **FR-006**: Only the owner MUST be able to see or change their goals.
- **FR-007**: Buddy MUST take the user's current goals and "how to help" notes into account in every Buddy chat (default routine, including onboarding; daily routine; reflection) and in reflection feedback.
- **FR-008**: Buddy MUST use the latest saved goals from the next message after a change.
- **FR-009**: When a request works against one of the user's goals, Buddy MUST say so briefly and then follow the user's decision.
- **FR-010**: Buddy MUST treat goal text as information about the user, never as instructions that change its rules or let it act outside the user's own data.
- **FR-011**: When the user has no goals, Buddy MUST NOT bring up goals unless the user asks.
- **FR-012**: In chat, Buddy MAY propose a new goal or a change to an existing one. A proposal MUST show the full proposed goal (and for a change, the current version) with explicit Confirm and Dismiss actions.
- **FR-013**: A proposal MUST be saved only when the user confirms it. Dismissing or ignoring it MUST change nothing.
- **FR-014**: Confirming a proposal MUST apply the same rules as the page (limit, lengths, ownership). If the proposal is no longer valid, the user MUST see why and nothing is saved.
- **FR-015**: Buddy MUST NOT delete goals from chat. It points the user to the Personal Target page instead.
- **FR-016**: The page MUST work by keyboard alone, have labelled fields, meet contrast in both themes, and fit from phone width to desktop.

### Key Entities

- **Personal Goal**: belongs to one user. It has a goal text, an optional "how Buddy should help" text, and created/updated times. Each user has at most 3.
- **Goal Proposal**: a new goal or a change suggested by Buddy in chat. It waits on screen until the user confirms or dismisses it, and is never a goal until confirmed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can add their first goal in under 1 minute from opening the page.
- **SC-002**: 100% of attempts to save a 4th goal, from the page or from chat, are refused.
- **SC-003**: In a manual test of 10 planning requests made with goals set, at least 8 of Buddy's replies reflect a relevant goal.
- **SC-004**: No goal is ever created or changed from chat without the user's confirmation.
- **SC-005**: Goals saved on one device are shown on another device after sign-in, every time.

## Assumptions

- No mockup was provided. The page follows the existing app style (cards like the Profile page) and sits in the sidebar.
- Goals are plain text. No deadline, progress, status or reordering. A date can be written in the goal text.
- Goals aren't part of onboarding. Users set them on the page or through Buddy.
- A proposal can be confirmed only while it is on screen. After a reload, the user asks Buddy again.
- Existing sign-in, Buddy chats and chat history are reused.
- Out of scope: Buddy tone, which is added to the same page in F014; context-aware tone (F015); off-track detection (later, with analytics).
