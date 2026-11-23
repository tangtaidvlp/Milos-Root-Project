# Feature Specification: Smooth scroll sync in Reflection compare view

**Feature Branch**: `F009-reflection-scroll-sync`

**Created**: 2026-11-23

**Status**: Draft

**Input**: Draft [F009-reflection-scroll-sync.md](F009-reflection-scroll-sync.md): "Enhance smoothness of Dashboard sync in Reflection mode". The user finds the synced scrolling of the side-by-side Plan | Reality boards (Reflection mode, wide screens) not smooth.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Scroll both boards smoothly (Priority: P1)

On a wide screen in Reflection mode, the user scrolls either the Plan or the Reality board. Both boards move together with no lag, stutter, jumping back or slowing down, so the same times stay level side by side.

**Why this priority**: This is the whole task. A jerky sync makes comparing plan and reality tiring.

**Independent Test**: Open Today on a ≥ 1280px screen, turn Reflection on, scroll each board with a trackpad (including fast flicks), mouse wheel and scrollbar drag. Both boards should move as one.

**Acceptance Scenarios**:

1. **Given** the compare view is open, **When** the user scrolls the Plan board with a trackpad flick, **Then** the Reality board follows in step and the Plan board's scroll keeps its natural speed and coasting, without jumping back.
2. **Given** the compare view is open, **When** the user scrolls the Reality board, **Then** the Plan board follows the same way.
3. **Given** the user has finished scrolling, **When** both boards stop, **Then** they show the same top time.
4. **Given** the user scrolls one board and then quickly switches to the other, **When** they scroll the second board, **Then** both boards follow it without fighting or snapping back.

### Edge Cases

- Mouse wheel, trackpad flick with coasting, scrollbar drag and keyboard (arrow keys, Page Up/Down) all sync smoothly.
- Changing zoom, date or the clock does not make the boards jump relative to each other.
- If one board is taller than the other, the shorter one stops at its end and the longer one keeps scrolling. Both line up again when scrolling back.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Scrolling either board in the compare view MUST move the other board to the same position with no visible lag.
- **FR-002**: The board the user is scrolling MUST keep its native scroll feel (speed, coasting). The sync MUST NOT slow it down, pull it back or make it stutter.
- **FR-003**: When scrolling stops, both boards MUST show the same position.
- **FR-004**: All scroll inputs (wheel, trackpad, scrollbar drag, keyboard) MUST sync the same way.
- **FR-005**: Existing compare view behaviour (shared clock, shared zoom, editing on both boards, a newly shown board starting at the other's position) MUST stay unchanged.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The user tries the compare view by hand and agrees that the scrolling feels smooth (from the draft's "Done when").
- **SC-002**: In repeated fast trackpad flicks on either board, the scrolled board never jumps back, and both boards end on the same time every time.

## Assumptions

- Only the side-by-side compare view (≥ 1280px) is in scope. The single-board view below 1280px has no sync and is unchanged.
- The boards stay in sync by position, as today. No new behaviour such as smooth animated scrolling or scroll snapping is added.
- Verification is by hand. An automated check is added only if it can reliably catch a regression (e.g. the scrolled board jumping back).
