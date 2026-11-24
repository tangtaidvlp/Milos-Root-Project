# Feature Specification: Context-Aware Tone

**Feature Branch**: `feat/F015-context-aware-tone`

**Created**: 2026-11-24

**Status**: Draft

**Epic**: [E001 – Personal Target](../E001-personal-target/E001-personal-target.md) (phase 3)

**Input**: User description: "The assistant shifts tone based on time of day: Morning (energetic, crisp, decisive), Midday (objective, adaptable), Evening (slower, reflective, validating). Daily check-ins use tight micro-copy (2–3 sentences); deeper coaching only in planning sessions or reflections." Draft: [F015-context-aware-tone.md](F015-context-aware-tone.md).

## Clarifications

### Session 2026-11-24

- Q: When should Buddy treat the user as "off track" (streak-break tone)? → A: Deferred. It will use data analytics or new metrics later, so off-track detection is out of scope here.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Buddy matches my time of day (Priority: P1)

Buddy adjusts the user's chosen tone to the user's local time of day. In the morning it is crisp and decisive and protects the first important block. At midday it helps re-plan around disruptions without guilt. In the evening it is calm and reflective and helps close open items so the user can switch off. The chosen tone stays recognisable.

**Why this priority**: This is the main behaviour of the feature.

**Independent Test**: Send "what should I do now?" at 08:00, 14:00 and 21:00 local time under the same tone, and check that each reply fits its time window and still sounds like the chosen tone.

**Acceptance Scenarios**:

1. **Given** it is 08:00 for the user, **When** they ask "what should I do now?", **Then** Buddy's reply is crisp and decisive and points to the first important block of the day.
2. **Given** it is 14:00 and a meeting overran, **When** the user asks Buddy to fix the afternoon, **Then** Buddy re-plans objectively, without guilt.
3. **Given** it is 21:00, **When** the user asks about their day, **Then** Buddy is calm and reflective and helps them close open items and wind down.
4. **Given** the user chose High-Accountability Coach, **When** they chat in the evening, **Then** the reply is calmer than in the morning but still direct and firm.
5. **Given** the user's local time differs from the server's, **When** they chat, **Then** Buddy uses the user's local time.

---

### User Story 2 - Short in day-to-day chat, deeper when planning or reflecting (Priority: P2)

Buddy keeps its replies short in the day-to-day chat (the Today page chat). It gives longer coaching only when planning (the default routine chat) or reflecting (the reflection chat and feedback).

**Why this priority**: It improves daily use, but Story 1 delivers value without it.

**Independent Test**: Ask a simple question in the Today chat and check the reply has at most 3 sentences. Ask "why do I keep missing my evening tasks?" in the reflection chat and check that Buddy can give a fuller coaching reply.

**Acceptance Scenarios**:

1. **Given** the Today chat, **When** the user asks a simple question, **Then** Buddy's reply has at most 3 sentences of text.
2. **Given** the Today chat, **When** the user explicitly asks for detail, **Then** Buddy may answer at length.
3. **Given** the reflection chat, **When** the user asks for coaching, **Then** Buddy may give a longer reply.
4. **Given** any chat, **When** the user asks for a plan or task list, **Then** the list doesn't count towards the 3-sentence limit.

---

### Edge Cases

- At a window boundary (11:59 or 12:00), the window is set by the local time when the message is sent.
- Between midnight and 05:00 the evening window applies, so Buddy leans towards rest and wind-down.
- In a conversation that crosses a boundary, each reply uses the current window.
- Planning tomorrow at 22:00 uses the evening window. The window comes from the time now, not from the date being planned.
- If the user's local time is unknown, Buddy replies in the chosen tone with no time-of-day adjustment.
- The user mentions missing something: no off-track detection is done, but F014's no-guilt rule applies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Buddy MUST adjust each reply to the user's local time of day using 3 windows: Morning 05:00–11:59, Midday 12:00–16:59, Evening 17:00–04:59.
- **FR-002**: Morning replies MUST be energetic, crisp and decisive, and focus on clarity and protecting the first important block of the day.
- **FR-003**: Midday replies MUST be objective and adaptable, and help re-plan around disruptions without guilt.
- **FR-004**: Evening replies MUST be slower, reflective and validating, and help close open items so the user can switch off.
- **FR-005**: The time-of-day adjustment MUST keep the user's chosen tone recognisable. It changes energy and pacing, not the tone's character, and never what Buddy may do.
- **FR-006**: The time of day MUST be the user's local time when they send the message.
- **FR-007**: If the user's local time is unknown, Buddy MUST reply in the chosen tone without a time-of-day adjustment.
- **FR-008**: In the day-to-day chat (Today chat), Buddy's text MUST be at most 3 sentences unless the user asks for more detail. Plans or task lists the user asked for don't count.
- **FR-009**: In planning (default routine chat) and reflection (reflection chat and feedback), Buddy MAY give longer coaching replies.
- **FR-010**: FR-001 to FR-007 MUST apply in every Buddy chat and in reflection feedback.

### Key Entities

- **Time-of-day window**: Morning, Midday or Evening, derived from the user's local time when a message is sent. Nothing new is stored.
- **Chat kind**: day-to-day (Today) or deep (default routine, reflection). It decides how long replies may be.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a manual test of the same requests sent in each window, at least 80% of replies are judged to fit their window's style.
- **SC-002**: At least 90% of Buddy's replies to simple questions in day-to-day chats have 3 sentences of text or fewer.
- **SC-003**: Replies use the user's local window in 100% of time-zone and boundary-time test cases.
- **SC-004**: In a blind review, the chosen tone is still recognised in at least 80% of time-adjusted replies.

## Assumptions

- Builds on F014 (tones). Before the user picks a tone, the adjustment applies to Balanced.
- Windows are fixed and not configurable. The behaviour is always on, with no setting to turn it off.
- Local time comes from the user's device.
- Out of scope: data-driven off-track / streak-break detection and its tone. It is a later E001 feature that waits for analytics metrics.
