# Feature Specification: Buddy Tone

**Feature Branch**: `feat/F014-buddy-tone`

**Created**: 2026-11-24

**Status**: Draft

**Epic**: [E001 – Personal Target](../E001-personal-target/E001-personal-target.md) (phase 2)

**Input**: User description: "Users can set the AI tone (archetypes: Tactical Chief of Staff, Grounded Stoic, Socratic Peer, Warm Anchor, High-Accountability Coach), calibrated on directiveness, emotional temperature, friction tolerance and verbosity." Draft: [F014-buddy-tone.md](F014-buddy-tone.md).

## Clarifications

### Session 2026-11-24

- Q: How should the 4 axes (directiveness, warmth, strictness, verbosity) work? → A: Fixed per tone. Each tone is a preset of the 4 axes, and the user only picks a tone.
- Q: What tone should Buddy use before the user picks one? → A: A 6th built-in tone, "Balanced" (the warm-pragmatic baseline), as the default.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Choose Buddy's tone (Priority: P1)

On the Personal Target page, a "Buddy tone" section lists 6 tones. Each tone shows its core vibe, what it's best for, and an example. The user picks one. Until they do, Balanced is selected.

**Why this priority**: The user needs a way to choose before Buddy can change how it talks.

**Independent Test**: Open Personal Target, check that Balanced is selected, pick Warm Anchor, reload and check from another device that Warm Anchor is still selected.

**Acceptance Scenarios**:

1. **Given** a user who never picked a tone, **When** they open Personal Target, **Then** Balanced is selected.
2. **Given** the tone list, **When** the user selects Warm Anchor, **Then** it is saved, the user sees that it saved, and it stays selected after reload and on other devices.
3. **Given** the tone list, **When** the user looks at a tone, **Then** they see its name, core vibe, best use and example phrase.

---

### User Story 2 - Buddy talks in my tone (Priority: P1)

Buddy replies in the selected tone in every chat (default routine, including onboarding; daily routine; reflection) and in reflection feedback. The tone changes how Buddy talks, not what it is allowed to do.

**Why this priority**: This is the value of the feature. Story 1 alone only stores a choice.

**Independent Test**: Send the same request ("plan my afternoon") under Tactical Chief of Staff and under Warm Anchor, and check that the replies clearly differ in the expected way.

**Acceptance Scenarios**:

1. **Given** the tone Tactical Chief of Staff, **When** the user asks Buddy to plan their afternoon, **Then** the reply is crisp and structured, states a clear plan, and has no small talk.
2. **Given** the tone Warm Anchor, **When** the user sends the same request, **Then** the reply is gentle, encouraging and low-pressure.
3. **Given** any tone, **When** the user says they missed a task, **Then** Buddy uses no blame or guilt language and moves to a next step.
4. **Given** any tone, **When** a request needs the user's confirmation today (for example resetting a day), **Then** Buddy still asks for it.
5. **Given** the user switches tone, **When** they send their next message, **Then** Buddy uses the new tone. Earlier messages stay as they were.

---

### Edge Cases

- A stored tone that no longer exists is treated as Balanced.
- If saving the tone fails, the previous tone stays selected and the user sees an error.
- The user asks Buddy in chat to change its tone ("be harsher"): Buddy tells them to change it on the Personal Target page.
- High-Accountability Coach is firm but never shaming. It challenges the action, not the person.
- Buddy is unavailable: the tone section still works, and the chat shows its usual friendly error.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Personal Target page MUST have a "Buddy tone" section listing these 6 tones: Balanced, Tactical Chief of Staff, Grounded Stoic, Socratic Peer, Warm Anchor, High-Accountability Coach.
- **FR-002**: Each tone MUST show its name, core vibe, best use and example phrase, as in the Tone catalogue below.
- **FR-003**: Users MUST be able to select exactly one tone. The choice is saved to their account and applies on every device.
- **FR-004**: Users who haven't chosen a tone MUST get Balanced.
- **FR-005**: Each tone MUST follow its fixed preset in the Tone presets table below. Users cannot adjust the axes.
- **FR-006**: Buddy MUST use the selected tone in every chat (default routine, including onboarding; daily routine; reflection) and in reflection feedback.
- **FR-007**: A tone change MUST apply from Buddy's next reply. Past messages don't change.
- **FR-008**: In every tone, Buddy MUST NOT use blame, shame or guilt language about missed tasks or habits (for example "You failed to…"). It acknowledges what happened and moves to a next step.
- **FR-009**: The tone MUST change only how Buddy words its replies. It never changes what Buddy may do, what data it uses, or which actions need the user's confirmation.
- **FR-010**: If saving fails, the previously saved tone MUST stay selected and the user MUST see an error.
- **FR-011**: A stored tone that is unknown MUST be treated as Balanced.
- **FR-012**: When asked in chat to change its tone, Buddy MUST point the user to the Personal Target page and not change the saved tone.
- **FR-013**: The tone picker MUST be a single-choice control that works by keyboard alone, is announced correctly by screen readers, meets contrast in both themes, and fits from phone width to desktop.

### Tone catalogue

| Tone | Core vibe | Best used for | Example phrase |
| :--- | :--- | :--- | :--- |
| **Balanced** (default) | Friendly, pragmatic, concise. Offers one clear recommendation. | Everyday use. | *"Morning! Your first focus block starts at 9:00. I'd do the report first and move the emails to after lunch. Sound good?"* |
| **Tactical Chief of Staff** | Crisp, structured, proactive, zero-fluff. | Morning briefings, time-blocking, reprioritising a derailed schedule. | *"You have 90 minutes before your next block. Knock out the API refactor now, and push the admin tasks to 4:00 PM."* |
| **Grounded Stoic** | Calm, objective, non-judgmental, steady. | Missed habits, high stress, recovery days. | *"You missed yesterday's workout. That's data, not failure. Let's scale today's session to 20 minutes to rebuild momentum."* |
| **Socratic Peer** | Curious, analytical, collaborative. | Weekly retrospectives, habit troubleshooting, goal alignment. | *"You've pushed deep work past 8:00 PM three days in a row. Is your afternoon energy dipping, or is the task scope too vague?"* |
| **Warm Anchor** | Encouraging, gentle, low-friction, empathetic. | Burnout recovery, wind-down routines, low-energy mornings. | *"Rough sleep last night. Keep today's bar low: hydrate, clear your top one priority, and close the laptop by 6:00 PM."* |
| **High-Accountability Coach** | Direct, challenging, energetic, firm. | Procrastination loops, physical training, strict deadline sprints. | *"You've snoozed this block twice. Put the phone in another room, set a 25-minute timer, and start."* |

### Tone presets

The axes are directiveness (asks / suggests / directs), warmth (low / medium / high), strictness (forgiving / balanced / firm) and length (brief / moderate).

| Tone | Directiveness | Warmth | Strictness | Length |
| :--- | :--- | :--- | :--- | :--- |
| Balanced | Suggests | Medium | Balanced | Brief |
| Tactical Chief of Staff | Directs | Low | Balanced | Brief, structured |
| Grounded Stoic | Suggests | Medium | Forgiving | Brief |
| Socratic Peer | Asks | Medium | Balanced | Moderate |
| Warm Anchor | Asks | High | Forgiving | Brief |
| High-Accountability Coach | Directs | Low | Firm | Brief |

"Directs" means Buddy states a clear plan instead of asking. It still asks for confirmation wherever FR-009 requires it.

### Key Entities

- **Tone preference**: the one tone a user has chosen. If none is stored, it is Balanced.
- **Tone**: one of the 6 fixed entries in the catalogue, with its presets.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can find and change Buddy's tone in under 30 seconds from the Personal Target page.
- **SC-002**: In a blind manual review of replies to the same 5 requests under each tone, the reviewer matches at least 80% of replies to the right tone.
- **SC-003**: In a manual test set of missed-task conversations, no reply in any tone contains blame or guilt language.
- **SC-004**: The chosen tone is the same on every device after sign-in, every time.

## Assumptions

- Builds on F013: the "Buddy tone" section sits on the Personal Target page created there.
- Example phrases come from the epic draft. The Balanced example was written for this spec.
- The tone is changed on the page only. Changing it from chat is out of scope.
- Out of scope: time-of-day and context shifts (F015); data-driven off-track detection (later, with analytics). The no-guilt rule (FR-008) still applies whenever the user mentions missing something.
