# Research: F009 Smooth scroll sync

## R1. Why the sync feels like friction

**Finding**: `useSyncedScroll` (F007 R12) copies the scrolled board's `scrollTop` to the other board, then ignores all scroll events with a shared lock released on the **next animation frame**. The other board's scroll event (caused by that write) is dispatched asynchronously and can arrive **after** the lock is released. By then, the board the user is scrolling has moved further (trackpad coasting, fast wheel). The stale event then writes the old position back onto that board, so it jumps back and stutters. The two boards fight each other, frame by frame.

## R2. Fix approach

**Decision**: Detect echoes by **value**, not by time. When the hook writes a position to a board, it remembers the position that board actually took (read back after the write, so browser clamping and rounding are included). A scroll event from a board whose position matches that remembered value (within 1px) is our own echo: forget it and do nothing. Any other scroll event comes from the user, so that board leads and the others follow.

**Rationale**: Timing doesn't matter any more, so a late echo can never pull the scrolled board back. Switching boards mid-scroll works: the new board's position differs from what was written to it, so it becomes the leader at once. Small change, inside one hook, no API change for `CompareBoards` or `EditingBoard`.

**Alternatives considered**:
- *Longer lock (timeout / "scroll end")*: still timing-based, and it blocks a real user scroll on the other board during the lock. Rejected.
- *Leader chosen from input events (wheel, pointer, touch, key)*: misses some inputs (scrollbar drag, middle-click autoscroll, assistive tech). More code. Rejected.
- *One shared scroll container for both boards (zero JS, native smoothness)*: best possible smoothness, but each `EditingBoard` owns its scroll area (scroll-to-now, zoom keeps the top time). That makes it a layout refactor. Rejected for now. It's the fallback if the value-based fix still feels laggy (see Risks in plan).

## R3. Test

**Decision**: Add a regression unit test in `useSyncedScroll.test.ts`: plan scrolls, reality follows, plan keeps moving, then reality's late echo arrives after the frame. The plan must keep its newer position. Write it first and watch it fail on the current code (constitution II: a bug fix starts with a failing test at its layer). The existing three tests and the e2e step in `e2e/reflection.spec.ts` stay green. Smoothness itself is checked by hand (`quickstart.md`).
