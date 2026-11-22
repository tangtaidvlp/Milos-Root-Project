# Research: Persist Buddy Chat History

**Feature**: F004 | **Date**: 2026-11-21 | **Spec**: [spec.md](./spec.md)

The Technical Context had no open unknowns after reading the code. The decisions below settle the design choices the spec leaves open.

## R1. Where Buddy's conversation memory comes from

- **Decision**: Remove `MessageChatMemoryAdvisor` + in-memory `MessageWindowChatMemory` from `GeminiAiChatService`. A new `ChatHistoryService` builds Buddy's context from the database (latest summary + messages after it) and passes it to the prompt as explicit messages (`ChatClient.prompt().messages(...)`). After a successful reply, the user message and the reply are saved together in one transaction.
- **Rationale**: The advisor writes the user message to memory *before* the model call. So a failed call leaves an unanswered message (breaks FR-008). It also stores a plain message window, with no place for a summary (FR-010/FR-012). If we own the context, both rules are easy to meet, and the context survives restarts because it is rebuilt from stored data every time.
- **Alternatives considered**:
  - *Custom `ChatMemory` backed by JDBC/JPA* (or Spring AI's `JdbcChatMemoryRepository`): this survives restarts. But it still saves the user message before the call, and it still has no summary concept.
  - *Keep the advisor and also write to our own tables*: two sources of truth that drift apart after a restart.

## R2. Where persistence sits relative to the AI implementation

- **Decision**: The controller calls `ChatConversationService`. That service resolves the conversation (with an ownership check), loads the context, calls `AiChatService` with the context, saves the exchange, then triggers compaction. `AiChatService` methods get an extra `ChatContext` parameter. `MockAiChatService` ignores it.
- **Rationale**: History is saved in the `fast` and mock profiles too, so the feature can be tested end to end without Gemini. The AI implementations stay stateless.
- **Alternatives considered**: Saving inside `GeminiAiChatService`. Mock mode would then lose history, and saving would be duplicated in each implementation.

## R3. Compaction strategy

- **Decision**: Compaction is cumulative and based on a cursor.
  - Each conversation keeps `summary_text` and `summarized_through_seq`.
  - After an exchange is saved, if the number of messages with `seq > summarized_through_seq` is ≥ `app.chat.compaction-threshold` (default 20), the system runs a summarisation call. This call uses a separate `ChatClient` with no tools. Its input is the previous summary plus those messages, and it returns a new summary. The cursor then moves to the highest message it covered.
  - The run is **asynchronous**, after commit (`@Async` + `@TransactionalEventListener(AFTER_COMMIT)`), so the user's reply is not delayed.
  - If it fails, the cursor stays where it was, so the next exchange tries again (FR-014).
  - Buddy's context = summary (as a system message) + messages after the cursor. That is at most N + 1 messages, plus the 2 in flight (SC-004).
- **Rationale**: This is simple and gives a bounded context. The original messages are never touched (FR-011).
- **Alternatives considered**:
  - *Synchronous compaction*: adds a second AI round-trip to every Nth reply.
  - *Rolling window with no summary* (today's behaviour): loses older facts (fails SC-005).
  - *Keep the last K messages unsummarised after compaction*: the context is a little richer, but there's one more setting to tune. Can be added later.
- **Concurrency**: The compaction job takes a `PESSIMISTIC_WRITE` lock on the conversation row and checks the threshold again before calling the AI, so two triggers can't both summarise. A mock/no-op `ChatSummarizer` is used when `spring.ai.active=false`. It concatenates a truncated digest, so tests can check that the cursor moves.

## R4. Message ordering and pagination

- **Decision**: Each conversation has its own increasing `seq` (long). It is assigned while holding a `PESSIMISTIC_WRITE` lock on the conversation row, which also updates `last_message_seq`. History is paged with a cursor: `GET …/messages?before=<seq>&limit=20`. It returns the newest `limit` messages with `seq < before`, sorted oldest-first, plus `hasMore`.
- **Rationale**: A cursor avoids the duplicates and gaps that offset paging gives when new messages arrive while the user scrolls up (SC-003). `seq` makes ordering exact even if two messages have the same timestamp.
- **Alternatives considered**: Offset/page numbers (shift when new messages arrive); `createdAt` + id cursor (more fiddly, and ties are possible).

## R5. Ownership enforcement (FR-007)

- **Decision**: Add a `CurrentUserGuard` component. When an `Authentication` exists (sit/prod JWT), it loads the user by the principal's email and requires `user.id == {userId}` in the path, otherwise 403. In `allowAll` profiles (local/fast, no authentication) it is a no-op, which matches how the rest of the API behaves there. The guard is applied to the new history endpoints and the two existing chat POST endpoints. For the default-routine chat, the server also checks that the default routine belongs to the user, using the routine id rather than trusting the full routine object in the body.
- **Rationale**: Today no controller checks path `userId` against the token. Chat history is personal text, so the new read endpoints must not be readable across users.
- **Alternatives considered**: A global per-user check for every controller. That's the right long-term fix, but it's outside this feature's scope.

## R6. Schema management in production

- **Decision**: Add the new tables as JPA entities (`ddl-auto: update` creates them on local/fast/sit). Ship an idempotent DDL script `ms-personal-routine-manager/db/F004-chat-history.sql` (`CREATE TABLE IF NOT EXISTS …`). It is applied to the prod database before deploying, because prod uses `ddl-auto: validate` and there's no Flyway yet.
- **Rationale**: This follows the current deployment reality without bringing in a migration framework as a side effect of this feature. `AWS_DEPLOYMENT.md` already lists Flyway as separate pending work.
- **Alternatives considered**: Adding Flyway now. It needs a baseline of the existing schema, which is bigger than this feature.

## R7. Frontend history loading and lazy scroll

- **Decision**: `BuddyChat` gets an optional prop, `loadHistory(before?: number) => Promise<{ messages, hasMore, nextBefore }>`.
  - On mount, it loads the latest page and shows it below the greeting, scrolled to the bottom.
  - When the thread is scrolled to within ~40px of the top and `hasMore` is true, it loads the next page and prepends it. It keeps the reading position by restoring `scrollTop += newScrollHeight - oldScrollHeight`.
  - Paging logic (merge/dedupe by `seq`, cursor tracking) lives in a pure helper `chatHistory.ts` so Vitest can test it.
  - If loading fails, a small notice appears ("Couldn't load earlier messages"), and sending still works (FR-013).
  - The Daily page adds `key={selectedDate}` to `BuddyChat`, so changing the date remounts the chat and loads that day's history. Today the same chat window carries over across dates, while the server keeps a separate conversation for each date.
- **Rationale**: This is the smallest change. All three call sites (onboarding, default routine, daily) get history by passing one extra prop.
- **Alternatives considered**: IntersectionObserver sentinel (works too, but `onScroll` with a threshold is simpler with the existing `threadRef`); a global chat store (not needed).

## R8. Configuration

- **Decision**: `application.yml`:
  ```yaml
  app:
    chat:
      compaction-threshold: 20   # messages since last summary before compacting
      history-page-size: 20      # max messages per history request
  ```
  These are bound to a `ChatHistoryProperties` record (`@ConfigurationProperties("app.chat")`). The server caps `limit` at `history-page-size`.
- **Rationale**: Meets the ticket's "20 is configurable from config file". The page size is also a setting, but per the spec it is not something users can change.
