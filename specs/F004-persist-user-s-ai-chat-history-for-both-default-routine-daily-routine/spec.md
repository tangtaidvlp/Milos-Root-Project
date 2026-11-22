# Feature Specification: Persist Buddy Chat History (Default Routine & Daily Routine)

**Feature Branch**: `F004-persist-user-s-ai-chat-history-for-both-default-routine-daily-routine`

**Created**: 2026-11-21

**Status**: Draft

**Input**: Ticket `F004-persist-user-s-ai-chat-history-for-both-default-routine-daily-routine.md`: "Persist the user's AI chat into storage and load it when the user logs into the app, so chats stay in the Buddy chat window. Compact the conversation after every 20 messages (configurable) to save tokens. Reloading the page still shows history, lazy-loaded at most 20 messages at a time."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See my previous chat after reload or sign-in (Priority: P1)

A signed-in user has talked with Routine Buddy about one of their default routines, or about a specific day in Daily Routine. Later they reload the page, sign out and back in, or come back on another day. When they open the same routine or day, the Buddy chat window shows the conversation they had before, with the most recent messages at the bottom.

**Why this priority**: This is the core pain point: chats disappear today, so users lose context and can't see what they and Buddy agreed on.

**Independent Test**: Send a few messages in a default routine's chat and in a day's chat, reload the page, and confirm both conversations reappear in the right windows, in order.

**Acceptance Scenarios**:

1. **Given** a user has exchanged messages with Buddy about default routine A, **When** they reload the page and open default routine A, **Then** those messages are shown in the order they were sent.
2. **Given** a user has chatted about Daily Routine for 2026-11-20, **When** they sign out, sign in again and open 2026-11-20, **Then** that day's conversation is shown.
3. **Given** a user has chats for default routine A and default routine B, **When** they open routine B, **Then** only routine B's conversation is shown (no mixing between routines or days).
4. **Given** a user completed onboarding by chatting with Buddy about a default routine, **When** they later open that routine's chat on the Default Routine page, **Then** the onboarding messages are part of that conversation's history.
5. **Given** a user has never chatted about a routine or day, **When** they open its chat, **Then** they see only Buddy's usual greeting.

---

### User Story 2 - Scroll back through long conversations (Priority: P2)

A user with a long conversation opens the chat. They see the latest 20 messages straight away. When they scroll to the top, older messages load in pages of up to 20, until the start of the conversation.

**Why this priority**: Long histories must not slow down opening the chat, but users still need to reach older messages.

**Independent Test**: Create a conversation with 50 messages, open the chat, confirm 20 are shown; scroll up twice and confirm all 50 become visible in the correct order, without duplicates.

**Acceptance Scenarios**:

1. **Given** a conversation has 50 messages, **When** the user opens it, **Then** the 20 most recent messages are shown.
2. **Given** the user is viewing the latest 20 of 50 messages, **When** they scroll to the top, **Then** the previous 20 messages load above, and the user's reading position is kept.
3. **Given** all messages are loaded, **When** the user scrolls to the top, **Then** no more loading is attempted and the start of the conversation is clear.

---

### User Story 3 - Buddy remembers the conversation without growing cost (Priority: P3)

As a conversation grows, Buddy keeps answering with awareness of what was said earlier, including after a reload or a server restart. After every 20 messages (configurable), older parts of the conversation are condensed into a summary that Buddy uses as context in place of the full older messages, so AI usage does not grow without limit.

**Why this priority**: Keeps answers relevant over long conversations while controlling AI token cost. The user-facing history (Story 1 and 2) delivers value even without it.

**Independent Test**: In one conversation, state a preference early ("I prefer workouts in the morning"), continue past 20 messages, restart the app, then ask Buddy about it. Buddy's reply reflects the preference. All original messages are still visible in the chat window.

**Acceptance Scenarios**:

1. **Given** a conversation reaches the compaction threshold (default 20 messages since the last compaction), **When** the next message is sent, **Then** the older messages are condensed into a summary for Buddy's context, and the user still sees every original message in the chat window.
2. **Given** an operator changes the threshold setting to 30, **When** the app runs with that setting, **Then** compaction happens after every 30 messages.
3. **Given** the server restarts, **When** the user sends a new message in an existing conversation, **Then** Buddy's reply takes the earlier conversation (summary plus recent messages) into account.

---

### Edge Cases

- A message fails to send, or Buddy returns an error: the error bubble is shown for that session only and is not saved. The user's message is saved only if Buddy's reply is also saved, so the history never has an unanswered message.
- Compaction fails (for example, the AI service is unavailable): the user's chat still works, the original messages are kept, and compaction is retried on a later message.
- A default routine is deleted: its conversation is no longer reachable from the UI. Clean-up is out of scope.
- A user opens a past or future date in Daily Routine: that date's conversation (if any) is shown, the same as for today.
- Very long single messages are stored and shown in full.
- Two browser tabs open on the same conversation: each tab shows what was stored when it loaded. A reload shows the merged, correctly ordered history.
- History cannot be loaded (network or server error): the chat window shows Buddy's greeting with a short notice that earlier messages couldn't be loaded, and the user can still send messages.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST durably store every successful user message and Buddy reply in Default Routine chats and Daily Routine chats, so they survive page reloads, sign-out/sign-in and server restarts.
- **FR-002**: Conversations MUST keep their current scoping: one conversation per user per default routine, and one conversation per user per Daily Routine date.
- **FR-003**: Messages sent during onboarding to the default-routine Buddy MUST be stored in that default routine's conversation and appear in its history afterwards.
- **FR-004**: When a user opens a chat window for a default routine or a date, the system MUST show that conversation's most recent messages, up to 20, oldest at the top.
- **FR-005**: Users MUST be able to load older messages in pages of up to 20 by scrolling to the top of the chat window, until the beginning of the conversation is reached.
- **FR-006**: Each stored message MUST record who sent it (user or Buddy), its text, and when it was sent. Messages MUST be shown in the order they were sent.
- **FR-007**: A user MUST only be able to read their own conversations. Requests for another user's history MUST be refused.
- **FR-008**: Failed sends and Buddy error responses MUST NOT be stored. A user message MUST be stored together with Buddy's reply, or not at all.
- **FR-009**: Buddy's greeting MUST continue to appear at the top of every chat window and MUST NOT be stored as part of the history.
- **FR-010**: After every N messages in a conversation since its last compaction (N defaults to 20 and is set in the application's configuration), the system MUST produce a condensed summary of the older messages and use it, with the recent messages, as Buddy's context.
- **FR-011**: Compaction MUST NOT remove or change any message the user can see. The full original history MUST remain viewable.
- **FR-012**: Buddy's context for a conversation MUST be rebuilt from stored data (latest summary plus messages after it), so Buddy keeps context after a server restart.
- **FR-013**: If history cannot be loaded, the chat MUST stay usable, and the user MUST see a short notice that earlier messages couldn't be loaded.
- **FR-014**: If compaction fails, the user's message flow MUST NOT be interrupted, and compaction MUST be attempted again on a later message.

### Key Entities *(include if feature involves data)*

- **Conversation**: A chat thread between one user and Buddy about one subject. Its subject is either a default routine or a Daily Routine date. It is owned by exactly one user.
- **Chat Message**: One entry in a conversation. It has a sender (user or Buddy), text content, the time it was sent, and its order in the conversation.
- **Conversation Summary**: A condensed version of a conversation's older messages, used only as Buddy's context. It records which messages it covers and when it was made. Users never see it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of successfully exchanged messages are visible again after a page reload, a sign-out/sign-in, and a server restart.
- **SC-002**: When a user opens a chat window with existing history, the latest messages appear within 1 second on a normal connection, whatever the total length of the conversation.
- **SC-003**: Each history load shows at most 20 messages, and scrolling back reaches the first message of a 100-message conversation with no missing or duplicated messages.
- **SC-004**: In a conversation with 100 or more messages, the amount of context sent to the AI per reply stays within the size of one summary plus at most N recent messages. It does not grow with total conversation length.
- **SC-005**: In a test where a fact is stated early and asked about after compaction and a server restart, Buddy's reply reflects that fact.
- **SC-006**: 0 cases where one user can see another user's chat messages.

## Assumptions

- The Buddy chat windows affected are on the Default Routine page, the Daily Routine page, and the onboarding flow (which already shares the default-routine conversation).
- Users can't clear or delete chat history in this feature. History is kept indefinitely. Clearing chats may be a later feature.
- Conversations of deleted default routines are left as they are. Clean-up is out of scope.
- The page size of 20 for lazy loading is fixed. The compaction threshold N (default 20) is configurable by operators, not by end users.
- A "message" counts both user messages and Buddy replies when applying the compaction threshold.
- Summaries are internal to Buddy and are not shown in the UI.
- Chats made before this feature ships are not recovered. History starts from the first message after release.
- Existing sign-in and per-user access rules apply. No new roles or permissions are introduced.
