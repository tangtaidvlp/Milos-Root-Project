---
description: "Task list for F004 – Persist Buddy Chat History"
---

# Tasks: Persist Buddy Chat History (Default Routine & Daily Routine)

**Input**: Design documents from `specs/F004-persist-user-s-ai-chat-history-for-both-default-routine-daily-routine/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/chat-history-api.md](./contracts/chat-history-api.md), [quickstart.md](./quickstart.md)

**Tests**: Included. plan.md names `ChatHistoryIntegrationTest` (backend) and `chatHistory.test.ts` (Vitest), and quickstart.md runs them.

**Organization**: Tasks are grouped by user story, so each story can be built and tested on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 / US2 / US3 from spec.md

## Path Conventions

- Backend root: `ms-personal-routine-manager/`. Java package root: `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/` (written `BE/` below)
- Backend tests: `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/` (written `BE_TEST/` below)
- Frontend root: `ui-personal-routine-manager/src/` (written `FE/` below)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Configuration and schema script used by every story

- [X] T001 Add the `app.chat` defaults to `ms-personal-routine-manager/src/main/resources/application.yml`, as `compaction-threshold: 20` and `history-page-size: 20`, with a comment on each line (research R8).
- [X] T002 [P] Create `BE/config/ChatHistoryProperties.java`. It is a `@ConfigurationProperties("app.chat")` record with `int compactionThreshold` (default 20, must be ≥ 2) and `int historyPageSize` (default 20, must be ≥ 1). Register it with `@EnableConfigurationProperties` (or `@ConfigurationPropertiesScan`) in `BE/RoutinemanagerApplication.java`, and add `@EnableAsync` there.
- [X] T003 [P] Create the idempotent prod DDL `ms-personal-routine-manager/db/F004-chat-history.sql`, copying exactly the SQL in data-model.md § "Production DDL": tables `chat_conversation` and `chat_message`, partial unique indexes `ux_chat_conv_default` / `ux_chat_conv_daily`, and constraint `ux_chat_message_seq`. Add a header comment: "Apply to prod BEFORE deploying F004 (prod uses ddl-auto: validate)".

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Entities, repositories, ownership guard and the AI-service signature change that all stories need

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 [P] Create the enums `BE/model/ChatConversationType.java` (`DEFAULT_ROUTINE`, `DAILY_ROUTINE`) and `BE/model/ChatRole.java` (`USER`, `ASSISTANT`).
- [X] T005 Create the entity `BE/model/ChatConversation.java`, mapped to table `chat_conversation`. Fields, per data-model.md:
  - `id` UUID PK (`GenerationType.UUID`)
  - `@ManyToOne(fetch = LAZY) User user` on `user_id`, NOT NULL
  - `type` `@Enumerated(STRING)`, NOT NULL, length 32
  - `defaultRoutineId` UUID: "Required when `type = DEFAULT_ROUTINE`, null otherwise. Plain column, not a FK"
  - `routineDate` LocalDate: "Required when `type = DAILY_ROUTINE`, null otherwise"
  - `lastMessageSeq` long: "NOT NULL, default 0"
  - `summaryText` `@Column(columnDefinition = "TEXT")`, nullable, "Buddy-only … never returned by the API"
  - `summarizedThroughSeq` long, NOT NULL, default 0
  - `summaryUpdatedAt` Instant, nullable
  - `createdAt` / `updatedAt` Instant, NOT NULL (set in `@PrePersist` / `@PreUpdate`)

  Use Lombok `@Getter @Setter @NoArgsConstructor`. Do NOT add a back-reference collection to `User`. (Depends on T004.)
- [X] T006 Create the entity `BE/model/ChatMessage.java`, mapped to table `chat_message` with `@Table(uniqueConstraints = @UniqueConstraint(name = "ux_chat_message_seq", columnNames = {"conversation_id", "seq"}))`. Fields:
  - `id` UUID PK
  - `@ManyToOne(fetch = LAZY) ChatConversation conversation`, NOT NULL
  - `seq` long, NOT NULL, "unique per conversation; strictly increasing"
  - `role` `@Enumerated(STRING)` `ChatRole`, NOT NULL, length 16
  - `content` TEXT, NOT NULL, "non-blank, stored in full (no truncation)"
  - `createdAt` Instant, NOT NULL

  The entity is immutable after insert (no setters used after creation). (Depends on T005.)
- [X] T007 [P] Create `BE/repository/ChatConversationRepository.java` (`JpaRepository<ChatConversation, UUID>`) with:
  - `Optional<ChatConversation> findByUser_IdAndTypeAndDefaultRoutineId(UUID userId, ChatConversationType type, UUID defaultRoutineId)`
  - `Optional<ChatConversation> findByUser_IdAndTypeAndRoutineDate(UUID userId, ChatConversationType type, LocalDate date)`
  - `@Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select c from ChatConversation c where c.id = :id") Optional<ChatConversation> findByIdForUpdate(UUID id)`

  (Depends on T005.)
- [X] T008 [P] Create `BE/repository/ChatMessageRepository.java` (`JpaRepository<ChatMessage, UUID>`) with:
  - `List<ChatMessage> findByConversation_IdAndSeqGreaterThanOrderBySeqAsc(UUID conversationId, long seq)` (context)
  - `List<ChatMessage> findByConversation_IdAndSeqBetweenOrderBySeqAsc(UUID id, long fromInclusive, long toInclusive)` (compaction)
  - `List<ChatMessage> findByConversation_IdOrderBySeqDesc(UUID id, Pageable p)` (newest page)
  - `boolean existsByConversation_IdAndSeqLessThan(UUID id, long seq)` (hasMore)

  (Depends on T006.)
- [X] T009 [P] Create `BE/config/CurrentUserGuard.java` (`@Component`, research R5). Method: `User requireUser(UUID userId)`.
  - Load the user via `UserRepository.findById`. If missing, throw `ResponseStatusException(NOT_FOUND, "User not found")`.
  - If `SecurityContextHolder.getContext().getAuthentication()` is non-null, authenticated, and not anonymous, compare its `getName()` (the email set by `JwtAuthenticationFilter`) with `user.getEmail()`. If they differ, throw `ResponseStatusException(FORBIDDEN)`.
  - With no authentication (local/fast `allowAll`), skip the email check.
  - Return the user.
  - Check that `GlobalExceptionHandler` maps `ResponseStatusException` to the matching status with an `ApiError` body. Add a handler in `BE/api/GlobalExceptionHandler.java` if it doesn't.
- [X] T010 [P] Create the DTOs:
  - `BE/dto/ChatMessageDto.java`: `long seq`, `String role` (lowercase `"user"`/`"assistant"`), `String content`, `Instant createdAt`; static `from(ChatMessage)`.
  - `BE/dto/ChatHistoryPage.java`: `List<ChatMessageDto> messages` (oldest → newest), `boolean hasMore`, `Long nextBefore` (null when `!hasMore`); static `empty()`.

  Shapes follow contracts/chat-history-api.md § "Shared shapes".
- [X] T011 Create `BE/service/chat/ChatContext.java`, a record `(String summary, List<org.springframework.ai.chat.messages.Message> recentMessages)` with static `empty()`.
  - Do NOT use Spring AI types here if `spring.ai.active=false` builds exclude the Spring AI jar. They don't: the starter is always on the classpath (build.gradle).
  - Change `BE/service/AiChatService.java` to `defaultRoutineChat(UUID userId, DefaultRoutine defaultRoutine, ChatContext context, String userMessage)` and `dailyRoutineChat(UUID userId, DailyRoutine dailyRoutine, LocalDate date, ChatContext context, String userMessage)`. Leave `chat(...)` unchanged.
  - Update `BE/service/MockAiChatService.java` to the new signatures, keeping the same reply text and ignoring `context`.
- [X] T012 Update `BE/service/GeminiAiChatService.java` for the new signatures (research R1):
  - Remove `MessageChatMemoryAdvisor` from the builder, the `@Qualifier("defaultRoutineChatMemory") ChatMemory` constructor parameter, the `.advisors(... CONVERSATION_ID ...)` calls in `defaultRoutineChat`/`dailyRoutineChat`, and the whole `ChatMemoryConfig` class at the bottom of the file.
  - Build the prompt as `.system(<existing system text> + (context.summary() != null ? "\n\nSummary of earlier conversation:\n" + context.summary() : ""))`, then `.messages(context.recentMessages())`, then `.user(userMessage)`.
  - Keep `chat(UUID, String)` working without memory (no advisor).

  (Depends on T011.)

**Checkpoint**: The app compiles and starts in `fast` and `local`. Chat POSTs still reply, with no memory yet.

---

## Phase 3: User Story 1 - See my previous chat after reload or sign-in (Priority: P1) 🎯 MVP

**Goal**: Every successful exchange is saved per (user, default routine) and per (user, date). Opening a chat window shows the latest messages. Buddy's context comes from the database, so it survives restarts.

**Independent Test**: quickstart.md A1–A5, A8–A11, C and E1–E4, E6. Send messages in a default-routine chat and a day chat, reload, and both conversations reappear in the right windows, in order.

### Tests for User Story 1

- [X] T013 [P] [US1] Create `BE_TEST/ChatHistoryIntegrationTest.java` with `@SpringBootTest @AutoConfigureMockMvc` and properties `spring.profiles.active=fast`, `spring.ai.active=false`, `app.chat.compaction-threshold=1000`. Register a user via `UserService.createUserAndDefaultRoutine` (or the register endpoint) and load its DAILY routine. Cases:
  - (a) GET `/api/ai/chat/default-routine/{userId}/{routineId}/messages` before any chat returns `{"messages":[],"hasMore":false,"nextBefore":null}` and creates no `chat_conversation` row.
  - (b) After 3 POSTs to `/api/ai/chat/default-routine/{userId}`, GET returns 6 messages, `seq` 1..6, roles alternating `user`/`assistant`, content of the user messages matching what was sent.
  - (c) The daily conversation for `2026-11-21` is separate from the default-routine one and from `2026-11-22`.
  - (d) A blank message returns 400, and the message count is unchanged.
  - (e) An unknown userId on GET and POST returns 404.
  - (f) Another user's `defaultRoutineId` returns 404.
  - (g) Context check: with a `@MockitoSpyBean AiChatService`, the second POST receives a `ChatContext` whose `recentMessages` holds the first exchange (one user + one assistant message).
  - (h) If the `AiChatService` spy throws on a POST, the response is an error status and nothing is saved.

  Write the test first and confirm it fails.

### Implementation for User Story 1

- [X] T014 [US1] Create `BE/service/chat/ChatConversationService.java` (`@Service`, constructor injection). Methods:
  - `Optional<ChatConversation> findDefaultRoutineConversation(UUID userId, UUID routineId)` and `findDailyConversation(UUID userId, LocalDate date)` (read-only, never create).
  - `ChatConversation getOrCreateDefaultRoutineConversation(User user, UUID routineId)` and `getOrCreateDailyConversation(User user, LocalDate date)`. On `DataIntegrityViolationException` from a concurrent insert, re-read and return the existing row.
  - `ChatContext buildContext(ChatConversation c)`: `summaryText` + messages with `seq > summarizedThroughSeq`, mapped `USER → UserMessage`, `ASSISTANT → AssistantMessage`, in `seq` order.
  - `@Transactional void appendExchange(UUID conversationId, String userText, String assistantText)`:
    1. `findByIdForUpdate`.
    2. Insert the USER message with `seq = lastMessageSeq + 1` and the ASSISTANT message with `seq = lastMessageSeq + 2`, both with `createdAt = Instant.now()` (assistant a few ms later, or the same instant; ordering is by seq).
    3. Set `lastMessageSeq += 2`.
    4. Publish `ConversationAppendedEvent(conversationId)` via `ApplicationEventPublisher`.

    Create the event as a record in `BE/service/chat/ConversationAppendedEvent.java`.
  - `ChatHistoryPage getHistory(Optional<ChatConversation> c, Long before, Integer limit)`:
    - Clamp `limit` to `1..historyPageSize`.
    - Empty conversation → `ChatHistoryPage.empty()`.
    - Otherwise query the newest `limit` messages by seq desc, then reverse to ascending.
    - `hasMore = existsByConversation_IdAndSeqLessThan(id, first.seq)`; `nextBefore = hasMore ? first.seq : null`.
    - In this story, `before` may be ignored (null). US2 adds it.

  (Depends on T007, T008, T010, T011.)
- [X] T015 [US1] Change `BE/api/AIController.java` (contracts/chat-history-api.md):
  - Inject `CurrentUserGuard`, `ChatConversationService`, `DefaultRoutineRepository`.
  - **POST `/chat/default-routine/{userId}`**:
    1. `guard.requireUser(userId)`.
    2. Reject a blank `message` with 400.
    3. Require `request.getDefaultRoutine() != null && id != null`. Load the routine by id and require that it belongs to the user (owner id == userId), otherwise 404.
    4. Get or create the conversation, then `buildContext`.
    5. Call `aiChatService.defaultRoutineChat(userId, request.getDefaultRoutine(), context, message)`.
    6. Then `appendExchange(...)`, then return `{reply}`.

    If the AI call throws, rethrow without saving.
  - **POST `/chat/daily-routine/{userId}`**: the same flow. A missing `date` returns 400. The conversation is keyed by `(user, date)`.
  - **Add GET `/chat/default-routine/{userId}/{defaultRoutineId}/messages`** (`@RequestParam(required=false) Long before, Integer limit`): guard, then the routine-ownership 404 check, then `getHistory(findDefaultRoutineConversation(...), before, limit)`.
  - **Add GET `/chat/daily-routine/{userId}/{date}/messages`** (`@PathVariable @DateTimeFormat(iso = DATE) LocalDate date`): same as above. A bad date returns 400.
  - Keep the existing INFO logs, but log only the message length, not the content, for the new GET endpoints.

  (Depends on T009, T014.)
- [X] T016 [P] [US1] Add `fetchDefaultRoutineChatHistory(userId: string, routineId: string, before?: number): Promise<ChatHistoryPage>` to `FE/features/default-routine/api/defaultRoutineChat.ts`.
  - It calls `apiRequest` GET `/api/ai/chat/default-routine/${userId}/${routineId}/messages` (+ `?before=` when given).
  - It validates the shape (`messages` array, `hasMore` boolean), otherwise `throw new ApiError(502, 'Invalid chat history payload')`.
  - Export the types `ChatHistoryMessage = { seq: number; role: 'user' | 'assistant'; content: string; createdAt: string }` and `ChatHistoryPage = { messages: ChatHistoryMessage[]; hasMore: boolean; nextBefore: number | null }` from a new `FE/features/onboarding/types/chatHistory.ts`.
- [X] T017 [P] [US1] Add `fetchDailyRoutineChatHistory(userId: string, date: string, before?: number): Promise<ChatHistoryPage>` to `FE/features/daily/api/dailyRoutineTasks.ts`. It calls GET `/api/ai/chat/daily-routine/${userId}/${date}/messages`, uses the same URL-building pattern as the existing `submitDailyRoutineChat` in that file, and validates the same way as T016.
- [X] T018 [US1] Extend `FE/features/onboarding/components/BuddyChat.jsx` with an optional prop `loadHistory?: (before?: number) => Promise<ChatHistoryPage>` (add it to the JSDoc).
  - On mount, if the prop is given, call `loadHistory()`. Map each message to `{ id: \`h-${seq}\`, seq, role: role === 'assistant' ? 'bot' : 'user', text: content, isError: false }` and put them after the greeting, which always stays first and is never stored (FR-009). Then scroll to the bottom.
  - Keep `hasMore`/`nextBefore` in state for US2.
  - While loading, show a small "Loading earlier messages…" line at the top of the thread.
  - If loading fails, show a notice line "Couldn't load earlier messages." (class `ob-history-notice`). Sending must keep working (FR-013).
  - Guard against setting state after unmount.
  - Without `loadHistory`, the behaviour is unchanged.
- [X] T019 [US1] Add `.ob-history-notice` and `.ob-history-loading` styles to `FE/App.css`, using only semantic tokens from `FE/styles/tokens.css`: small, centred, `var(--color-text-secondary)`. No raw colours (`noRawColors.test.ts`).
- [X] T020 [US1] Wire up `FE/features/default-routine/pages/DefaultRoutinePage.tsx`: pass `loadHistory={(before) => fetchDefaultRoutineChatHistory(userId, routines[tab].id, before)}` to each tab's `BuddyChat`, only when `routines[tab]?.id` exists. Make sure the chat mounts (or re-keys, e.g. `key={\`${tab}-${routines[tab]?.id ?? 'none'}\`}`) after the routine has loaded, so history isn't requested with an undefined id.
- [X] T021 [US1] Wire up `FE/features/onboarding/pages/OnboardingPage.jsx` the same way as T020, using that page's per-tab routine data, so onboarding chats load from the same default-routine conversation (FR-003).
- [X] T022 [US1] Wire up `FE/features/daily/pages/DailyRoutinePage.jsx`: add `key={selectedDate}` and `loadHistory={(before) => fetchDailyRoutineChatHistory(user.id, selectedDate, before)}` to `BuddyChat`. Use the same date-string format already passed to `submitDailyRoutineChat`. Changing the date remounts the chat and loads that day's history (research R7).

**Checkpoint**: US1 is fully working. Run quickstart A1–A5, A8–A11, C, E1–E4, E6.

---

## Phase 4: User Story 2 - Scroll back through long conversations (Priority: P2)

**Goal**: Show the newest 20 messages first. Scrolling to the top loads older pages of up to 20, keeps the reading position, and stops at the first message.

**Independent Test**: quickstart A6, A7 and E5. Build a conversation of 30+ messages, open it, scroll up, and everything appears in order with no gaps or duplicates.

### Tests for User Story 2

- [X] T023 [P] [US2] Add paging cases to `BE_TEST/ChatHistoryIntegrationTest.java`:
  - (a) After 15 exchanges (30 messages), GET with no `before` returns `seq` 11..30, `hasMore:true`, `nextBefore:11`.
  - (b) GET `?before=11` returns `seq` 1..10, `hasMore:false`, `nextBefore:null`.
  - (c) The union of (a) and (b) is exactly 1..30.
  - (d) `?limit=500` is clamped to 20.
  - (e) `?limit=5&before=11` returns `seq` 6..10, `hasMore:true`.
- [X] T024 [P] [US2] Create the pure helper `FE/features/onboarding/components/chatHistory.ts` and its tests `FE/features/onboarding/components/chatHistory.test.ts`. Exports:
  - `toChatItems(messages: ChatHistoryMessage[])`, using the mapping from T018.
  - `prependOlder(current, olderItems)`, which dedupes by `seq`, keeps ascending order, and never moves the greeting or items without a `seq` (greeting, unsaved/error bubbles) out of position. The greeting stays first; new live bubbles stay last.
  - `nextCursor(page)`, which returns `page.hasMore ? page.nextBefore : null`.

  Tests cover dedupe, ordering, an empty page, and keeping the greeting first. Write the tests first.

### Implementation for User Story 2

- [X] T025 [US2] Implement `before` in `ChatConversationService.getHistory` in `BE/service/chat/ChatConversationService.java`: when `before != null`, query the newest `limit` messages with `seq < before`. Add `List<ChatMessage> findByConversation_IdAndSeqLessThanOrderBySeqDesc(UUID id, long seq, Pageable p)` to `BE/repository/ChatMessageRepository.java`. Compute `hasMore`/`nextBefore` from the first returned message, as in T014.
- [X] T026 [US2] Add scroll-up paging to `FE/features/onboarding/components/BuddyChat.jsx`, using the helpers from T024:
  - Add an `onScroll` handler on `threadRef`. When `scrollTop <= 40`, `hasMore` is true, and no load is in flight, call `loadHistory(nextBefore)`.
  - Record `prevHeight = scrollHeight` before updating state. Prepend with `prependOlder`. In a `useLayoutEffect` tied to that prepend, set `scrollTop += scrollHeight - prevHeight` so the view doesn't jump.
  - The existing auto-scroll-to-bottom effect must NOT run on prepend. Change it to run only when a message is appended at the end (track the last item id instead of `messages.length`).
  - When `hasMore` is false, make no more requests.
  - If a page fails, show the `ob-history-notice` line and allow a retry on the next scroll-up.

**Checkpoint**: US1 and US2 both work. Run quickstart A6, A7, E5 and E7.

---

## Phase 5: User Story 3 - Buddy remembers the conversation without growing cost (Priority: P3)

**Goal**: Every N messages (default 20, config `app.chat.compaction-threshold`), older messages are condensed in the background into a summary used as Buddy's context. The visible history is never changed, and Buddy keeps context after restarts.

**Independent Test**: quickstart B1–B5. Use threshold 4. After 2 exchanges, `summarized_through_seq > 0` and the summary is set. GET history still returns every original message. With real AI, a fact stated early is remembered after compaction and a restart.

### Tests for User Story 3

- [X] T027 [P] [US3] Create `BE_TEST/ChatCompactionIntegrationTest.java` (`spring.ai.active=false`, `app.chat.compaction-threshold=4`). Use Awaitility if it's on the test classpath, otherwise a short polling loop with a timeout. Cases:
  - (a) After 2 exchanges (4 messages), within 5 s the conversation has `summarizedThroughSeq == 4` and a non-null `summaryText`.
  - (b) GET history still returns all 4 messages, and the response JSON contains no `summary` field.
  - (c) After a 3rd exchange, `ChatContext.recentMessages` has 2 messages and `summary` is non-null (check via a `@MockitoSpyBean AiChatService`).
  - (d) With a `@MockitoBean ChatSummarizer` that throws, chat POSTs still return 200, messages are still saved, `summarizedThroughSeq` stays 0, and the summariser is called again after the next exchange.

### Implementation for User Story 3

- [X] T028 [P] [US3] Create the interface `BE/service/chat/ChatSummarizer.java` with `String summarize(String previousSummary, List<ChatMessage> messages)`. Then create `BE/service/chat/MockChatSummarizer.java` (`@Service @ConditionalOnProperty(name = "spring.ai.active", havingValue = "false", matchIfMissing = true)`). It returns `previousSummary` (if any) + `"\n"` + `"USER: …/ASSISTANT: …"` lines, each truncated to 80 chars, with the whole result capped at 2000 chars.
- [X] T029 [P] [US3] Create `BE/service/chat/GeminiChatSummarizer.java` (`@Service @ConditionalOnProperty(name = "spring.ai.active", havingValue = "true")`).
  - Build its own `ChatClient` from the injected `ChatClient.Builder` with NO tools and NO advisors.
  - System prompt: "Summarise this conversation between a user and their routine assistant. Keep user preferences, decisions, constraints and any changes made to routines/tasks. Max 200 words. Plain text."
  - User content: the previous summary (if any), followed by the transcript lines.
  - Return `.call().content()`.
- [X] T030 [US3] Create `BE/service/chat/ChatCompactionService.java` (`@Service`) with `@Async @TransactionalEventListener(phase = AFTER_COMMIT) public void onAppended(ConversationAppendedEvent e)`. It calls a `@Transactional(propagation = REQUIRES_NEW)` method (through a self-proxy or a separate bean, so the transaction actually applies) that:
  1. Calls `findByIdForUpdate`.
  2. If `lastMessageSeq - summarizedThroughSeq < props.compactionThreshold()`, returns.
  3. Loads messages `(summarizedThroughSeq, lastMessageSeq]` with `findByConversation_IdAndSeqBetweenOrderBySeqAsc(id, summarizedThroughSeq + 1, lastMessageSeq)`.
  4. Calls `summarizer.summarize(summaryText, msgs)`.
  5. Sets `summaryText`, `summarizedThroughSeq = lastMessageSeq` (the value read under the lock), and `summaryUpdatedAt = now`.
  6. Logs at INFO: `Compacted conversation {id} through seq {n}`.

  Wrap the whole thing in try/catch: on any exception, log WARN with the conversation id and change nothing (FR-014). Never rethrow to the caller. (Depends on T014, T028, T029.)

**Checkpoint**: All three stories work. Run quickstart B1–B4, and B5 with a real Gemini key.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T031 [P] Update `ms-personal-routine-manager/CLAUDE.md` § "AI integration":
  - Replace "Conversation memory: in-memory window of last 20 messages per conversation" with: the DB-backed history (`chat_conversation`/`chat_message`), the summary + cursor compaction (`app.chat.compaction-threshold`), and the async compaction.
  - Add the two GET history endpoints to the API table notes.
  - Add the prod DDL step (`db/F004-chat-history.sql`) to § Deployment.
- [X] T032 [P] Update `ui-personal-routine-manager/CLAUDE.md` § "Shared components (quirks)" / "Feature behavior": describe the `BuddyChat` `loadHistory` prop, the scroll-up paging, and the daily `key={selectedDate}` remount.
- [X] T033 [P] Add a "Before deploying F004" note to `ms-personal-routine-manager/AWS_DEPLOYMENT.md`: run `psql … -f db/F004-chat-history.sql` against the prod DB before the new image starts, because `ddl-auto: validate` fails startup if the tables are missing.
- [X] T034 Run `cd ms-personal-routine-manager && ./gradlew test` and `cd ui-personal-routine-manager && pnpm test && pnpm lint && pnpm build`. Fix any failures, including `noRawColors.test.ts` and TypeScript errors in the files changed in T016–T026.
- [ ] T035 (A–D done and recorded; E1–E7 browser checks and B5 pending, see quickstart Results) Run the full manual validation in `specs/F004-persist-user-s-ai-chat-history-for-both-default-routine-daily-routine/quickstart.md` (sections A–E), on a separate backend port (e.g. 8099) so any dev server on 8080 is left alone. Record the results under a "Results" heading at the end of quickstart.md.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: depends on Setup. Blocks all stories.
- **US1 (Phase 3)**: depends on Phase 2. This is the MVP.
- **US2 (Phase 4)**: depends on US1 (it extends `getHistory` and `BuddyChat` from T014/T018).
- **US3 (Phase 5)**: depends on Phase 2 and on T014 (`appendExchange` publishes the event, and `buildContext` already reads the summary). It is independent of US2, so US2 and US3 can be built in parallel after US1.
- **Polish (Phase 6)**: after the stories you plan to ship.

### Task-level dependencies

- T004 → T005 → T006 → T007/T008
- T011 → T012
- T007, T008, T010, T011 → T014 → T015
- T016/T017 → T018 → T020/T021/T022 (T019 alongside T018)
- T024 → T026; T025 on its own (backend)
- T028, T029 → T030

### Parallel Opportunities

- Phase 1: T002 ∥ T003.
- Phase 2: T004 first. Then T007 ∥ T008 (after T005/T006), and T009 ∥ T010 ∥ T011 at any time in the phase.
- US1: T013 (test) ∥ T016 ∥ T017 while the backend T014/T015 is in progress.
- US2: T023 ∥ T024. T025 (backend) ∥ T026 (frontend).
- US3: T027 ∥ T028 ∥ T029.
- Polish: T031 ∥ T032 ∥ T033.

## Parallel Example: User Story 1

```text
Backend dev:   T013 (write failing test) → T014 → T015
Frontend dev:  T016 ∥ T017 → T018 + T019 → T020 ∥ T021 ∥ T022
```

## Parallel Example: after US1

```text
Track A (US2): T023 ∥ T024 → T025 ∥ T026
Track B (US3): T027 ∥ T028 ∥ T029 → T030
```

## Implementation Strategy

### MVP (User Story 1 only)

1. Phase 1 + Phase 2 (T001–T012).
2. Phase 3 (T013–T022). Chats survive reload, sign-in and restart, the latest page is shown, and Buddy's context comes from the DB.
3. **Stop and validate**: quickstart A1–A5, A8–A11, C, E1–E4, E6.
4. Before a prod deploy, apply `db/F004-chat-history.sql` (T003/T033).

Note: with only US1 shipped, Buddy's context is the full unsummarised conversation, so it grows with conversation length. Ship US3 soon after US1 if conversations get long.

### Incremental Delivery

1. MVP (US1).
2. Add US2 (lazy scroll-back) and US3 (compaction) in either order, or in parallel.
3. Polish (T031–T035).
