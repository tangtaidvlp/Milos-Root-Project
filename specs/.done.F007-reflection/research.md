# Research: F007 Daily Reflection

## R1. Where reflection data lives

- **Decision**: Two new tables, `daily_reflection` (one row per user and date) and `reflection_task`.
- **Rationale**: FR-005 says the plan and the reflection must be independent. Separate tables make that structural rather than a rule each code path must remember. Analytics (FR-022) can join plan and reality by date and `planned_task_id`.
- **Alternatives considered**:
  - A `kind` column on `daily_task`. Rejected: every existing query, cron job, AI tool and the frontend would need a filter, and one missing filter breaks independence.
  - A JSON blob snapshot. Rejected: hard to query for analytics.

## R2. Matching reflection tasks to the plan

- **Decision**: `reflection_task.planned_task_id` is a plain nullable UUID column, set when the reflection is copied and null for tasks the user adds. It is not a foreign key.
- **Rationale**: Renames and time changes keep the match (spec: "renamed task is still matched"). With a plain column, deleting a planned task never fails or cascades. A dangling link is treated as unplanned (spec edge case).
- **Alternatives considered**:
  - Match by name. Rejected: breaks on rename.
  - A foreign key with `ON DELETE SET NULL`. Rejected: the same result can be had without coupling the two schemas, and the H2/Postgres DDL would differ.

## R3. Comparison groups

- **Decision**: `ReflectionComparisonService` (backend) groups each task:
  - planned task with no live link → **skipped**
  - linked task with the same `startTime` and `durationMinutes` → **as planned**
  - linked task with a different time or duration → **changed**
  - reflection task without a live link → **unplanned**

  If two reflection tasks link to the same planned task (not possible through the UI), the first in start order is the match and the rest are unplanned. Totals are the sum of the plan's durations, the sum of the reflection's durations, and a count per group.
- **Rationale**: This is one definition shared by the UI, the AI feedback and tests. It is cheap to compute on every read.
- **Alternatives considered**: Computing the comparison in the frontend. Rejected: Buddy needs the same numbers, and two copies would drift apart.

## R4. AI isolation for reflection chat

- **Decision**: A new interface `ReflectionAiService` with `GeminiReflectionAiService` (its own `ChatClient`, default tools = only `ReflectionAiTools`) and `MockReflectionAiService` (when `spring.ai.active=false`).
- **Rationale**: `GeminiAiChatService` registers daily and default routine tools as *default* tools, and per-call tools cannot remove defaults. A separate client is the only way to guarantee Buddy cannot touch the plan in reflection mode (FR-018). `ChatClient.Builder` is prototype-scoped (the summarizer already gets its own), so a second injection is safe.
- **Alternatives considered**: Telling Buddy in the prompt not to use plan tools. Rejected: not a guarantee.

## R5. Feedback tone

- **Decision**: The feedback prompt contains the comparison JSON and hard rules:
  - open with something genuinely positive
  - at most two suggestions, each phrased as an invitation ("you could try…")
  - never use "failed", "should have", "lazy", "only", "behind" or guilt framing
  - 60–120 words
  - end with a reassuring line

  The mock implementation builds a deterministic warm note from the totals. The note is stored on the reflection.
- **Rationale**: FR-016 and SC-004. Storing the note makes it reappear without new AI cost (FR-017).
- **Staleness**: `content_updated_at` is touched on every reflection task mutation. The note is `stale` when `feedback_at < content_updated_at`, and the UI then offers "Refresh note".

## R6. Overlaps and the time model

- **Decision**: Reflection tasks are never shifted for overlaps. They keep the same time fields as daily tasks (`startTime` HH:mm, `durationMinutes` 1–1440). Midnight-crossing works the same as in the plan, because the board renders it the same way.
- **Rationale**: Reality can overlap. Shifting would record things that didn't happen.

## R7. Date rules

- **Decision**: Creating a reflection or editing its tasks for a date after `LocalDate.now()` (server) returns 400. Creating a reflection never calls `ensureDailyRoutine`. If the day has no saved plan, it starts empty.
- **Rationale**: FR-002 and FR-006. The frontend also disables the toggle for future dates (client date).

## R8. Chat thread

- **Decision**: Add `ChatConversationType.DAILY_REFLECTION`, reusing `chat_conversation.routine_date` and a new partial unique index `ux_chat_conv_reflection`. The `type` column is VARCHAR(32), so no column change is needed. Compaction and history paging work unchanged, because they are keyed by conversation id.

## R9. Colors

- **Decision**: Copied tasks keep their color. The reflection gets its own `color_cursor`, starting from the daily routine's cursor or 0. New reflection tasks go through `TaskColorService.assign`, and updates follow F005 (null keeps the color).

## R10. Frontend composition

- **Decision**:
  - `DailyRoutinePage` keeps a `reflectionOn` flag. The effective mode is `reflectionOn && !isFuture(selectedDate)`.
  - In reflection mode, the board gets the reflection's tasks with no `onToggleComplete`, so the completion checkbox is hidden, and the toolbar shows only "+ Add task".
  - `ReflectionPanel` (comparison groups, totals and Buddy's note) sits above the board inside the canvas card.
  - BuddyChat is keyed `${date}:${mode}` so it remounts with the right thread.
  - The page gets `data-reflection="on"` plus a visible "Reality" badge (FR-011).
- **Rationale**: This reuses `EditingBoard`, `TaskEditModal` and `BuddyChat` unchanged.

---

# Enhancement research (2026-11-22): side-by-side layout and compact toggle

## R11. How to show Plan and Reality side by side

- **Decision**: Render two `EditingBoard` instances in a two-column grid (`CompareBoards`). A single `BoardToolbar` sits above both, and each board gets `showToolbar={false}`.
- **Rationale**: `EditingBoard` holds a lot of logic: drag, resize, gap clear, delete confirmation, the now-line and the footer. Two instances reuse all of it unchanged. For the toolbar to be shared, it has to be its own component, so its JSX moves out of `EditingBoard` into `BoardToolbar.jsx`, and `EditingBoard` renders it when `showToolbar` is true (the default). This keeps single-board behaviour byte-for-byte the same.
- **Alternatives considered**: Teach `EditingBoard` to draw several lanes on one track. That gives perfect alignment for free, but means rewriting drag and hit-testing for every lane, which is too risky for a layout change. A second, read-only "mini timeline" was rejected, because the user chose to keep both boards editable.

## R12. Shared clock, zoom and scroll

- **Clock**: Lift `currentTime` / `isLive` and the minute ticker into `useBoardClock()`. When `EditingBoard` receives `clock`, it uses it instead of its own state, so the shared toolbar's Pause and slider drive both now-lines.
- **Zoom**: Nothing to do. `useBoardZoom()` reads one account-level setting (F006), so both boards already zoom together, and each board's "keep the top time in place" effect runs the same way.
- **Scroll**: `useSyncedScroll()` returns a `register(element)` ref callback. A scroll on one element sets `scrollTop` on the others, and a re-entrancy flag (cleared on the next animation frame) stops the boards from bouncing each other. `EditingBoard` exposes its scroll element through a `scrollContainerRef` callback prop. Both boards centre on "now" when they mount, so they start aligned.
- **Alternatives considered**: CSS `scroll-snap` or a single outer scroller. With an outer scroller, each board's footer and the toolbar would scroll away with the content.

## R13. Breakpoint detection

- **Decision**: `useMediaQuery('(min-width: 1280px)')` in `src/hooks/useMediaQuery.ts` (a global hook, built on `matchMedia` plus a change listener, and SSR/test-safe). When it is true and Reflection is on, the page renders `CompareBoards`. Otherwise it renders the single board.
- **Rationale**: The DOM differs between layouts (one board versus two), so CSS alone can't switch them. 1280px was the user's choice.
- **Edge**: Crossing 1280px while Reflection is on keeps the mode and the data. Edits are saved as they happen, so nothing is lost when the layout switches.

## R14. Editing two boards at once

- **Decision**: Page handlers take a `target: 'plan' | 'reality'` instead of reading `inReflection`. Each board gets callbacks bound to its own target. The task modal state stores the target too, so a modal opened from the Plan column saves to the plan even while Reflection is on.
- **Plan edits during reflection**: After a plan change, the page also re-fetches the reflection, so the summary strip updates (the comparison is computed on the server).
- **Gap clear / Reset day**: These stay plan-only (spec Assumptions). The shared toolbar owns `gapClearMode` and passes it to the Plan board only. Reset day only clears the plan's local completion state, and "Clean up" sits in the Plan column header.
- **Buddy** stays the reflection chat while Reflection is on (FR-018), so it can never touch the plan.

## R15. Summary strip and the note in the chat

- **Decision**: Split `ReflectionPanel` into:
  - `ReflectionSummaryStrip`: one line with Planned → Reality (±diff) and four chips, followed by a collapsed "Task by task" `<details>`.
  - `ReflectionNote`: the note text, the stale hint, the get/refresh button and the friendly 503 message, unchanged from the old panel.
- **Note placement**: `BuddyChat` gets a `topSlot` prop, rendered between the header and the thread, which is where the note goes in reflection mode. It also gets a `compactHeader` prop (smaller padding and icon; the subtitle stays on one line) to win back height.
- **Rationale**: This follows the user's answer: shorten the Buddy header and put the note at the top of the chat window. The note also sits next to the Buddy who wrote it.
- **Intro sentence**: The long "Record what really happened…" paragraph is dropped. Its meaning moves into the toggle's `title` and the "Reality" badge.

## R16. Status pop-up on narrow screens

- **Decision**: On screens under 1280px in reflection mode, clicking a reality task opens `ReflectionTaskPopup` instead of the edit modal. The pop-up shows:
  - a group chip,
  - the task name (and the planned name, if it was renamed),
  - the planned and actual start time and duration,
  - **Edit** (which opens the existing `TaskEditModal`) and **Close** buttons.
- **Data**: The pop-up looks up the task in `view.comparison.items` by `actual.id`, using `comparisonLookup.ts`. No new API.
- **Skipped tasks** have no reality card, so they appear in the strip count and in "Task by task".
- **Wide screens** keep the direct edit-on-click, because the comparison is visible side by side.
