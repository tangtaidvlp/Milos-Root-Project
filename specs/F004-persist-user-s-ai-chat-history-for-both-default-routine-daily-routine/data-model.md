# Data Model: Persist Buddy Chat History

**Feature**: F004 | **Spec**: [spec.md](./spec.md) | **Research**: [research.md](./research.md)

New JPA entities live in `com.tom.payment.routinemanager.model`, and their repositories in `…repository`. All primary keys are UUIDs (`GenerationType.UUID`), following project convention.

## ChatConversation

One chat thread between a user and Buddy about one subject.

| Field | Type | Rules |
|-------|------|-------|
| `id` | UUID | PK |
| `user` | `@ManyToOne User` (`user_id`) | NOT NULL; owner |
| `type` | enum `ChatConversationType` { `DEFAULT_ROUTINE`, `DAILY_ROUTINE` } | NOT NULL, stored as STRING |
| `defaultRoutineId` | UUID (`default_routine_id`) | Required when `type = DEFAULT_ROUTINE`, null otherwise. Plain column, not a FK, so deleting a routine never cascades into chat history (spec: clean-up out of scope) |
| `routineDate` | LocalDate (`routine_date`) | Required when `type = DAILY_ROUTINE`, null otherwise |
| `lastMessageSeq` | long | NOT NULL, default 0. Highest `seq` assigned |
| `summaryText` | TEXT | Nullable. Buddy-only compacted context, never returned by the API |
| `summarizedThroughSeq` | long | NOT NULL, default 0. Messages with `seq <=` this are covered by `summaryText` |
| `summaryUpdatedAt` | Instant | Nullable |
| `createdAt` / `updatedAt` | Instant | NOT NULL |

**Uniqueness**: (`user_id`, `default_routine_id`) where type = DEFAULT_ROUTINE, and (`user_id`, `routine_date`) where type = DAILY_ROUTINE. These are two partial unique indexes in Postgres. The service uses get-or-create and, on a unique-violation race, falls back to re-reading the row.

**Lookup**: `findByUserIdAndTypeAndDefaultRoutineId`, `findByUserIdAndTypeAndRoutineDate`, and `findByIdForUpdate` (`@Lock(PESSIMISTIC_WRITE)`).

## ChatMessage

One stored entry (FR-006). Immutable once written.

| Field | Type | Rules |
|-------|------|-------|
| `id` | UUID | PK |
| `conversation` | `@ManyToOne ChatConversation` (`conversation_id`) | NOT NULL |
| `seq` | long | NOT NULL; unique per conversation; strictly increasing |
| `role` | enum `ChatRole` { `USER`, `ASSISTANT` } | NOT NULL, STRING |
| `content` | TEXT | NOT NULL, non-blank, stored in full (no truncation) |
| `createdAt` | Instant | NOT NULL |

**Index**: unique (`conversation_id`, `seq`). This also serves the paging query `WHERE conversation_id = ? AND seq < ? ORDER BY seq DESC LIMIT ?`.

**Not stored**: Buddy's greeting (FR-009), error replies, failed sends (FR-008), tool-call messages, the system prompt.

## Behaviour rules

1. **Append exchange** (one transaction):
   1. Lock the conversation.
   2. `seq = lastMessageSeq + 1` (USER), `+2` (ASSISTANT).
   3. Update `lastMessageSeq`.
   4. Publish `ConversationAppendedEvent`.

   This runs only after the AI reply succeeds.
2. **Context for Buddy**:
   - `summaryText`, if present, becomes a system message.
   - It is followed by messages with `seq > summarizedThroughSeq`, in order, mapped to `UserMessage`/`AssistantMessage`.
3. **Compaction trigger** (async, after commit):
   1. Lock the conversation.
   2. If `lastMessageSeq - summarizedThroughSeq >= compactionThreshold`, summarise (old summary + messages in `(summarizedThroughSeq, lastMessageSeq]`).
   3. Set `summaryText`, `summarizedThroughSeq = lastMessageSeq`, `summaryUpdatedAt`.

   On failure, log and change nothing.
4. **History page**:
   - `before` absent → newest `limit` messages.
   - Otherwise the newest `limit` with `seq < before`.
   - Returned ascending.
   - `hasMore = exists(seq < first.seq)`.

## State (conversation compaction)

```text
[no summary] --(unsummarised count reaches N)--> [summarised through seq S]
[summarised through S] --(N more messages)--> [summarised through S']   (summary rewritten cumulatively)
compaction failure: state unchanged, retried after next exchange
```

## Production DDL (`ms-personal-routine-manager/db/F004-chat-history.sql`)

Prod runs `ddl-auto: validate`, so this script must be applied before deploying. Column names must match the entities exactly.

```sql
CREATE TABLE IF NOT EXISTS chat_conversation (
  id                      UUID PRIMARY KEY,
  user_id                 UUID NOT NULL REFERENCES users(id),
  type                    VARCHAR(32) NOT NULL,
  default_routine_id      UUID,
  routine_date            DATE,
  last_message_seq        BIGINT NOT NULL DEFAULT 0,
  summary_text            TEXT,
  summarized_through_seq  BIGINT NOT NULL DEFAULT 0,
  summary_updated_at      TIMESTAMP WITH TIME ZONE,
  created_at              TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at              TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_chat_conv_default
  ON chat_conversation (user_id, default_routine_id) WHERE type = 'DEFAULT_ROUTINE';
CREATE UNIQUE INDEX IF NOT EXISTS ux_chat_conv_daily
  ON chat_conversation (user_id, routine_date) WHERE type = 'DAILY_ROUTINE';

CREATE TABLE IF NOT EXISTS chat_message (
  id               UUID PRIMARY KEY,
  conversation_id  UUID NOT NULL REFERENCES chat_conversation(id),
  seq              BIGINT NOT NULL,
  role             VARCHAR(16) NOT NULL,
  content          TEXT NOT NULL,
  created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT ux_chat_message_seq UNIQUE (conversation_id, seq)
);
```

> Check the `users` table name against the `User` entity's `@Table` before applying.
