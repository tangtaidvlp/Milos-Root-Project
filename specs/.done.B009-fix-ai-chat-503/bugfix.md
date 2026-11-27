# Bugfix: AI chats return 500 instead of 503 when Buddy fails

**Bugfix Branch**: `fix/B009-ai-chat-503`
**Created**: 2026-11-25
**Status**: Fixed
**Affected project(s)**: ms-personal-routine-manager
**Input**: Bug report: `AI-project-docs/bugs/B009.MD`

## 1. Report

**Expected behavior**: AI failure on a chat gives 503 with the `ApiError` body and a friendly message; nothing stored (constitution Principle V).

**Actual behavior**: 500 "Unexpected error" from `GlobalExceptionHandler.handleUnexpected`.

**Environment**: any profile; `POST /api/ai/chat/default-routine/{userId}`, `/daily-routine/{userId}`, `/daily-reflection/{userId}`.

**Severity**: Medium

## 2. Reproduction

1. Make `aiChatService.defaultRoutineChat` / `dailyRoutineChat` or `reflectionAi.chat` throw.
2. Send a chat message.

**Reproduced?**: Yes, every time

**Smallest reproduction**: the 3 component tests in section 5.

## 3. Investigation

Not needed; cause confirmed from the code.

## 4. Root Cause

**Location**: `api/AIController.java`, the 3 chat handlers

**Cause**: the AI call is not wrapped, unlike the Personal Target chat, so the exception reaches the catch-all handler (500).

**Introduced by**: F004 / F007 (before the Personal Target chat added the 503 catch)

**Blast radius**: only these 3 endpoints. Nothing was stored (exchange is saved after the reply).

## 5. Regression Test

**Test kind**: Backend: Component (user flow)

**Test**:
- `ChatHistoryComponentTest#failedDefaultRoutineAiCallIs503AndStoresNothing` (new)
- `ChatHistoryComponentTest#failedAiCallStoresNothing` (daily; existed but asserted 500, now 503)
- `ReflectionComponentTest#chatAiFailureIs503AndNothingIsStored` (new)

**Command**: `./gradlew test --tests '*ChatHistoryComponentTest' --tests '*ReflectionComponentTest'`

**Failed before fix**: Yes. 3 of 27 failed: `HTTP status ==> expected: <503> but was: <500>`.

## 6. Fix

**Change summary**: new private `AIController.callAi(userId, call)` catches `RuntimeException`, logs at WARN (user id + exception, no message text) and throws 503 `ReflectionFeedbackService.AI_UNAVAILABLE`. Used by all 4 chats, including Personal Target (its inline try/catch is removed). No AI service throws `ResponseStatusException`, so no pass-through.

**Files changed**:

- `ms-personal-routine-manager/src/main/java/.../api/AIController.java`: `callAi` helper, used by the 4 chats
- `ChatHistoryComponentTest`, `ReflectionComponentTest`: regression tests
- `ms-personal-routine-manager/docs/test-flows.md`: counts and AI failure entries

**Alternatives rejected**: handle in `GlobalExceptionHandler` (would turn every unexpected error into 503).

## 7. Verification

- [x] Regression tests pass (also `PersonalTargetChatComponentTest`)
- [x] Full suite on Postgres: `./gradlew test -PtestDb=postgres`: 233 tests, 0 failed, 0 skipped (baseline 231 + 2 new)
- [x] `./gradlew build -x test`: BUILD SUCCESSFUL
- [x] Original reproduction no longer shows the bug
- [x] API contract unchanged (503 uses the existing `ApiError`)

**Follow-ups**: none.
