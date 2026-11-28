# Feature Specification: Day & night awareness for the circle graph

**Feature Branch**: `T004-enhance-day-night-awareness-for-circle-graph`

**Created**: 2026-11-28

**Status**: Draft

**Input**: Task draft [T004-enhance-day-night-awareness-for-circle-graph.md](T004-enhance-day-night-awareness-for-circle-graph.md). Design source of truth: [resources/day-clock-light.png](resources/day-clock-light.png), [resources/day-clock-dark.png](resources/day-clock-dark.png), icons in [resources/](resources/).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See day and night at a glance (Priority: P1)

The circle graph shows 24 hours, but people read a circle like a 12-hour clock. The circle is split into a night half (top, 18:00 → 00:00 → 06:00) and a day half (bottom, 06:00 → 12:00 → 18:00), each with its own colour, icon and label, so users instantly know which part of the circle is day and which is night.

**Why this priority**: This is the reason for the task; without it the 24-hour circle stays confusing.

**Independent Test**: Open any page with the circle graph and check the two halves against the sketches.

**Acceptance Scenarios**:

1. **Given** the circle graph is shown, **When** the user looks at it, **Then** the top half (18:00–06:00) has the night colour, a moon icon and the label "NIGHT", and the bottom half (06:00–18:00) has the day colour, a sun icon and the label "DAY".
2. **Given** the app is in dark mode, **When** the circle graph is shown, **Then** it uses the dark-mode colours from the colour table and matches `day-clock-dark.png`.
3. **Given** tasks and the current-time hand are on the circle, **When** the day and night halves are shown, **Then** tasks, the hand and the centre details stay readable and clickable as before.

---

### User Story 2 - Smaller centre circle (Priority: P2)

The centre circle shrinks to the ratio in the sketch so the day/night band between it and the rim is wide enough to show the icons and labels.

**Why this priority**: Needed for the band to be visible; on its own it adds little.

**Independent Test**: Compare the centre circle size with the rim size against the sketch.

**Acceptance Scenarios**:

1. **Given** the circle graph is shown, **When** the user compares the centre circle with the rim, **Then** the centre circle's radius is about 60% of the rim's outer radius (sketch: 123 of 200 px), and the centre still shows date, time, current task and "until" line as before.

---

### User Story 3 - Minute marks (Priority: P3)

Small marks every 15 minutes between the hour marks help users read times more precisely.

**Why this priority**: A refinement on top of the day/night split.

**Independent Test**: Count the marks between two hour marks.

**Acceptance Scenarios**:

1. **Given** the circle graph is shown, **When** the user looks between two hour marks, **Then** there are 3 small marks (every 15 minutes), shorter and lighter than the hour marks.
2. **Given** the sketch, **When** the hour marks and numbers are shown, **Then** the night-side marks and numbers use the night tone and the day-side ones use the day tone, with 00, 06, 12 and 18 emphasised.

### Edge Cases

- Small circle (narrow screen): the icons, labels and minute marks hide when they no longer fit, rather than overlapping tasks or the centre text.
- A task that crosses 06:00 or 18:00 is drawn as one continuous arc over both halves.
- The view-only circle (no live clock) shows the same day/night halves.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The band between the centre circle and the rim MUST be split at 06:00 and 18:00: night on the top half, day on the bottom half.
- **FR-002**: Colours MUST follow this table (light / dark mode where two versions are given):

  | Part | Night | Day |
  |---|---|---|
  | Band fill | #20336F | #FFF8EE |
  | Icon | Moon #EEF1FB | Sun #C9781F |
  | Label ("NIGHT" / "DAY") | #EEF1FB | #3B2F1E |
  | Rim track, light mode | #DDE3F4 | #F6E9D4 |
  | Rim track, dark mode | #272D47 | #342A1D |

- **FR-003**: The night half MUST show the moon icon and "NIGHT" near its top; the day half MUST show the sun icon and "DAY" near its bottom, as in the sketches, using the icons in `resources/`.
- **FR-004**: The centre circle radius MUST be about 60% of the rim's outer radius, matching the sketch.
- **FR-005**: The circle MUST show a small mark every 15 minutes between hour marks.
- **FR-006**: Hour marks and numbers MUST use the night tone on the night half and the day tone on the day half; 00, 06, 12 and 18 MUST be emphasised (larger/bolder; 06 and 18 in a pill in dark mode, as in the sketch).
- **FR-007**: Tasks, the current-time hand, task labels, dragging and clicking MUST work as before.
- **FR-008**: Text and icons MUST keep WCAG 2.2 AA contrast against their band colour in both modes.
- **FR-009**: The day/night decoration MUST NOT be announced by screen readers (decorative only); the chart's accessible name stays as today.
- **FR-010**: The centre circle MUST keep the plain surface colour; it no longer takes the current task's colour (the task pill inside it still does). Added on owner review.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can tell, without reading the numbers, whether any point on the circle is day or night.
- **SC-002**: The circle graph matches the light and dark sketches side by side in colours, proportions and marks (reviewed by the owner).
- **SC-003**: All existing circle-graph behaviour (tasks, now hand, labels, drag) still works; no existing test needs a behaviour change.

## Assumptions

- Day/night is fixed at 06:00–18:00 / 18:00–06:00, as in the sketch; not based on sunrise, location or the user's sleep routine.
- Applies everywhere the circle graph is shown (live Today view and view-only/setup boards).
- Light/dark mode follows the app's existing theme setting.
- "Done when" is the owner's own review against the sketches.
- Out of scope: changes to the timeline (board) view, task colours, or the centre text content.
