# Implementation Plan: Persist Buddy Chat History (Default Routine & Daily Routine)

**Branch**: `F004-persist-user-s-ai-chat-history-for-both-default-routine-daily-routine` | **Date**: 2026-11-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/F004-persist-user-s-ai-chat-history-for-both-default-routine-daily-routine/spec.md`

## Summary

Buddy chat now lives only in server memory (a 20-message window per conversation) and in React state, so it disappears on reload or restart. This feature makes the database the source of truth:

- Every successful user message and Buddy reply is saved per conversation:
  - (user, default routine): this also covers onboarding.
  - (user, date): Daily Routine.
- Buddy's context is rebuilt from the database on each message as summary + unsummarised messages.
- Every N messages (config, default 20), compaction runs in the background. It updates the summary without touching the visible history.
- New cursor-paged GET endpoints return history 20 messages at a time.
- `BuddyChat` loads the latest page when it opens and lazy-loads older pages on scroll-up.

## Technical Context

**Language/Version**: Backend Java 25 / Spring Boot 4.1; frontend TypeScript + React 19 (`BuddyChat.jsx` stays JS)

**Primary Dependencies**: Spring Data JPA, Spring AI 2.0 (`ChatClient`, Google GenAI), Spring Security (JWT); React, react-markdown

**Storage**: PostgreSQL (local/sit/prod), H2 (fast). There are 2 new tables, `chat_conversation` and `chat_message`. Prod needs the DDL script (no Flyway; prod is `ddl-auto: validate`)

**Testing**: JUnit 5 + `@SpringBootTest` with `spring.ai.active=false` (mock AI + mock summariser); Vitest for pure UI helpers

**Target Platform**: Linux server (EC2, Docker) + static SPA (GitHub Pages)

**Project Type**: Web application (backend + frontend)

**Performance Goals**: The history page shows within 1 s (SC-002). This is one indexed query of ≤ 20 rows. The extra cost per chat message is one locked row update plus 2 inserts

**Constraints**:
- AI context per reply ≤ summary + N messages (SC-004).
- Failed AI calls are never saved (FR-008).
- Compaction never blocks or breaks a reply (FR-014).

**Scale/Scope**: Personal app, a small number of users. Conversations: 2 per user for default routines + 1 per active day. 3 BuddyChat call sites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template (no ratified principles), so there are no constitution gates to check. The project conventions in `ms-personal-routine-manager/CLAUDE.md` and `ui-personal-routine-manager/CLAUDE.md` / `codingrules.md` are used as the de facto gates:

| Convention | Plan complies |
|-----------|---------------|
| UUID PKs, Lombok, constructor injection, `@Transactional` writes | ✅ data-model.md |
| Prod schema is `validate`; changes need explicit DDL | ✅ R6: `db/F004-chat-history.sql` |
| No raw colours in UI; tokens only (`noRawColors.test.ts`) | ✅ The new notice/loader uses semantic tokens |
| Shared components stay in `onboarding/components/` | ✅ `BuddyChat` is extended in place |
| New API code: request/response shapes aligned between UI and backend | ✅ contracts/chat-history-api.md |

**Post-design re-check**: Still passes. The design adds no new projects or frameworks, and no new dependencies.

## Project Structure

### Documentation (this feature)

```text
specs/F004-persist-user-s-ai-chat-history-for-both-default-routine-daily-routine/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md          # includes the baseline manual run from 2026-11-21
├── contracts/chat-history-api.md
├── checklists/requirements.md
└── tasks.md               # /speckit-tasks
```

### Source Code

```text
ms-personal-routine-manager/
├── db/F004-chat-history.sql                                   # NEW prod DDL
└── src/main/java/com/tom/payment/routinemanager/
    ├── api/AIController.java                                  # 2 new GET endpoints; POSTs delegate to ChatConversationService
    ├── config/ChatHistoryProperties.java                      # NEW @ConfigurationProperties("app.chat")
    ├── config/CurrentUserGuard.java                           # NEW ownership check (no-op without auth)
    ├── dto/ChatMessageDto.java, ChatHistoryPage.java          # NEW
    ├── model/ChatConversation.java, ChatMessage.java,
    │   ChatConversationType.java, ChatRole.java               # NEW
    ├── repository/ChatConversationRepository.java,
    │   ChatMessageRepository.java                             # NEW
    └── service/
        ├── AiChatService.java                                 # methods take ChatContext
        ├── GeminiAiChatService.java                           # drop memory advisor; add .messages(context)
        ├── MockAiChatService.java                             # accept + ignore context
        ├── chat/ChatConversationService.java                  # NEW resolve → context → AI → persist → event
        ├── chat/ChatContext.java                              # NEW summary + recent messages
        ├── chat/ChatCompactionService.java                    # NEW @Async AFTER_COMMIT listener
        ├── chat/ChatSummarizer.java                           # NEW interface
        ├── chat/GeminiChatSummarizer.java                     # NEW (spring.ai.active=true), tool-less ChatClient
        └── chat/MockChatSummarizer.java                       # NEW (spring.ai.active=false)
    src/main/resources/application.yml                         # app.chat.* defaults; @EnableAsync
    src/test/java/.../ChatHistoryIntegrationTest.java          # NEW

ui-personal-routine-manager/src/
├── features/onboarding/components/BuddyChat.jsx               # loadHistory prop, scroll-up paging, notice
├── features/onboarding/components/chatHistory.ts (+ .test.ts) # NEW pure merge/cursor helpers
├── features/onboarding/pages/OnboardingPage.jsx               # pass loadHistory (routine id per tab)
├── features/default-routine/api/defaultRoutineChat.ts         # fetchDefaultRoutineChatHistory
├── features/default-routine/pages/DefaultRoutinePage.tsx      # pass loadHistory
├── features/daily/api/dailyRoutineTasks.ts                    # fetchDailyRoutineChatHistory
└── features/daily/pages/DailyRoutinePage.jsx                  # pass loadHistory; key={selectedDate}
```

**Structure Decision**: This is the existing two-project web app. Backend chat persistence goes in a new `service/chat` sub-package. The frontend extends the shared `BuddyChat` in place, so all three chat windows get history through one prop.

## Phase summary

- **Phase 0** ([research.md](./research.md)), decisions R1–R8:
  - DB-owned context, replacing the memory advisor.
  - Persistence above the AI implementation.
  - Cumulative async compaction with a cursor.
  - `seq` cursor paging.
  - `CurrentUserGuard`.
  - Prod DDL script.
  - `BuddyChat` `loadHistory` prop.
  - `app.chat.*` config.
- **Phase 1**: [data-model.md](./data-model.md), [contracts/chat-history-api.md](./contracts/chat-history-api.md), [quickstart.md](./quickstart.md).
- **Baseline manual run (2026-11-21)**: This was against the current code, on a separate mock-AI backend. It confirmed:
  - Both chat POSTs work.
  - No history endpoint exists yet.
  - Unknown userIds are currently accepted. The plan adds a `404`, since persistence would otherwise hit a FK error.
  - The users table is `users`.

## Risks

- **Removing the memory advisor**: If the context building is wrong, Buddy "forgets" mid-conversation. This is covered by quickstart B5 and an integration test that checks the messages passed to `AiChatService`.
- **Prod deploy order**: The DDL must be applied before the new JAR starts, or `validate` fails at startup. Add this to the deploy notes.
- **Compaction cost**: It's one extra AI call every N messages, and asynchronous. It's acceptable at this scale.

## Complexity Tracking

None. There are no constitution violations to justify.
