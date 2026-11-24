# Bugfix: No per-user AI rate limit, and AI calls can hang for minutes

**Bugfix Branch**: `fix/B010-ai-rate-limit-timeouts`
**Created**: 2026-11-25
**Status**: Fixed
**Affected project(s)**: both (frontend: one small change)
**Input**: Bug report: `AI-project-docs/bugs/B010.MD`

## 1. Report

**Expected behavior**: per-user limits on AI calls (429, `ApiError` body, nothing stored, AI not called); each AI call has a timeout and a short retry, ending as 503.

**Actual behavior**: unlimited AI calls per user; a slow provider hangs a request for minutes.

**Environment**: any profile with `spring.ai.active=true`; the 4 chats, reflection feedback, goal save review.

**Severity**: High

## 2. Reproduction

Rate limit: send 21 chat messages for one user (all reach the AI). Timeout: see section 4.

**Reproduced?**: Yes, every time

**Smallest reproduction**: `AiRateLimitComponentTest`.

## 3. Investigation

Not needed; cause confirmed from the code and the Spring AI auto-configuration.

## 4. Root Cause

**Location**: `GoogleGenAiChatAutoConfiguration.googleGenAiClient` (Spring AI) and every AI entry point.

**Cause**:
1. No entry point limits calls per user.
2. The Gemini `Client` is built with no HTTP timeout, and the google-genai SDK retries on its own (5 attempts, backoff).
3. With no `RetryTemplate` bean, the chat model uses Spring AI's default: 10 retries, delays up to 3 min each.

**Introduced by**: unknown (never implemented).

**Blast radius**: all AI features. Chat compaction is background and deliberately not limited.

## 5. Regression Test

**Test kind**: Backend: Component (wiring) + Unit (rule).

**Test**: `AiRateLimitComponentTest` (chat 21st message, goal save), `AiRateLimiterTest` (per minute, reopens, per day, users independent, refusal not counted).

**Command**: `./gradlew test --tests '*AiRateLimit*'`

**Failed before fix**: Yes. With the limiter calls removed: `AiRateLimitComponentTest.chatOverTheLimitIs429AndNothingIsStored` and `goalSaveOverTheLimitIs429AndOtherUsersAreNotAffected` failed (status 200 instead of 429). The unit test needs the new class, so it can't fail separately. Frontend: `GoalProposalCard` 429 test and `ReflectionNote` 429 test.

## 6. Fix

**Change summary**: `AiRateLimiter` (in memory, per user, per minute and per day, `Clock`-based) is called right before each AI call, after validation and outside the 503 `try`. `AiClientConfig` (only when `spring.ai.active=true`) provides a Gemini `Client` with an HTTP timeout and SDK retry switched off (the `RetryTemplate` is the only retry layer, so retries don't multiply), and a `RetryTemplate` with `max-retries` and a 1s delay. Config: `app.ai.timeout` 30s, `max-retries` 1, `rate-limit.per-minute` 10, `per-day` 200.

**Files changed**:

- backend: `config/AiCallProperties`, `config/AiClientConfig`, `service/AiRateLimiter`, `api/AIController`, `ReflectionFeedbackService`, `PersonalGoalService`, `application.yml`, test `application-test.yml` (per-minute 20: the busiest test sends 15 messages at one fixed instant), 2 new test classes, `CLAUDE.md`, `docs/test-flows.md`
- frontend: `GoalProposalCard` (429 is retryable), `ReflectionNote` (shows the 429 message), tests, `CLAUDE.md`

**Alternatives rejected**: a library (Bucket4j, Resilience4j): not needed for one instance.

## 7. Verification

- [x] Regression tests pass
- [x] Backend full suite on Postgres: 239 tests, 0 failures (baseline 233 + 6). `./gradlew build -x test` passes
- [x] Frontend: `pnpm test --run` 230 passed (baseline 228 + 2), `pnpm lint` 3 existing warnings, `pnpm build` passes
- [x] Timeout checked by hand: `SPRING_PROFILES_ACTIVE=fast SPRING_AI_ACTIVE=true APP_AI_TIMEOUT=1ms ./gradlew bootRun --args='--server.port=8095'`, one personal-target chat message: 503 "Buddy is unavailable right now" in 0.16s (final config). Before switching off the SDK's own retry it took 16.5s with the same 1ms timeout.
- [x] API contract: 429 uses the existing `ApiError` body; no shape change

**Follow-ups**:
- The limiter is in memory: counts reset on restart and aren't shared if the app ever runs on more than one instance.
