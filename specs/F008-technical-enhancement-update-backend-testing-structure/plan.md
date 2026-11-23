# Implementation Plan: F008 – Update Backend Testing Structure

**Branch**: `feat/F008-backend-testing-structure` (create in the root repo and in `ms-personal-routine-manager`; both are on `main` today. Not `refactor/`, because FR-018 changes sign-in behaviour) | **Date**: 2026-11-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F008-technical-enhancement-update-backend-testing-structure/spec.md`

## Summary

Restructure the backend test suite into three kinds:
- **Component tests** cover every main user flow through the real API, with real sign-in tokens, the mock AI and a fixed clock.
- **Unit tests** cover core business rules and their edge cases, with no Spring and no mocked storage.
- **Integration tests** (10 or fewer) check external connections.

Component tests share one Spring context. They run on H2 by default and on a Testcontainers Postgres 17 when `-PtestDb=postgres` is given, which is what CI uses. CI stops skipping tests, so a failure blocks the image push and deploy. (The project is in a local phase: CI/CD hardening is deferred for cost, so the local gates are what count for now.)

Production changes:
- **Behaviour-neutral refactors**: an injected `Clock`, a scheduling switch, and moving four rules out of storage code.
- **Behaviour changes (bug fixes, each started from a failing test)**:
  - Sign-in returns 401/409 instead of 500 for bad input (FR-018).
  - A malformed, tampered or foreign-signed bearer token gets 401 instead of 500 on any protected endpoint (FR-018, found in T038, user decision).
  - Chat messages sent at the same moment no longer get duplicate sequence numbers (FR-019, found in T047): `appendExchange` re-reads the conversation after taking the row lock.
  - A request without a valid token gets a 401 with the shared `ApiError` body instead of an empty body, and every refusal test checks the full body shape (FR-020, found by `/code-review`, owner decision).

Docs follow: constitution Principle II goes to v2.0.0, the backend `CLAUDE.md` testing section is rewritten, the bug-fix template is updated, and the test flow map is renamed.

## Technical Context

**Language/Version**: Java 25 (Gradle toolchain), Gradle wrapper 9.5.1

**Primary Dependencies**: Spring Boot 4.1.0 (Web MVC, Data JPA, Security, Actuator), Spring AI 2.0.0 (Gemini, switched off in tests), jjwt 0.12.3, Lombok. New, test-only: `spring-boot-starter-webmvc-test` (`@AutoConfigureMockMvc`), `spring-boot-testcontainers`, `org.testcontainers:testcontainers-postgresql` (2.0.5 via the Boot BOM)

**Storage**: PostgreSQL 17 (production, CI tests via Testcontainers); H2 2.4 in-memory (local test default, `fast` runtime profile)

**Testing**: JUnit Jupiter 6.0.3, Mockito 5.23 (spies at the AI boundary only), AssertJ, MockMvc with the Spring Security filter chain

**Target Platform**: Linux container on AWS EC2 (prod); GitHub Actions `ubuntu-latest` (CI); macOS dev machine

**Project Type**: Web service (backend of a three-tier app). The frontend is untouched

**Performance Goals**: Full local suite under 3 min, one component class under 1 min, all unit tests under 10 s (SC-003). Baseline: 44 tests in about 7 s across 4 contexts

**Constraints**: No behaviour change except FR-018; no live LLM calls; no `@DirtiesContext` or per-class config; tests must start without `GEMINI_API_KEY`; Docker needed only for `-PtestDb=postgres`

**Scale/Scope**: 11 existing classes / 76 tests migrated. About 14 component, 10 unit and 2 integration classes afterwards. About 12 production files touched. 1 workflow, 3 docs, 1 constitution amendment

No open unknowns. Everything is resolved in [research.md](research.md).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Assessment (pre-design) | Post-design |
|---|---|---|
| I. Contract-first API design (error format amended in 2.0.0) | FR-018 changes error responses of `/api/v1/auth/*`. The contract is written first ([contracts/sign-in-errors.md](contracts/sign-in-errors.md)). The body is the shared `ApiError`, which 2.0.0 makes the one error format (RFC 9457 dropped, owner decision); the security 401 now uses it too (FR-020) | **Pass** (constitution 2.0.0) |
| II. Component-first testing with real infrastructure (was "Test pyramid" in 1.0.0) | The 1.0.0 text ("most tests are fast unit tests") conflicted with the component-first split. **Resolved by FR-013**: amended to v2.0.0 within F008 (R15, T053). Postgres via Testcontainers in CI, H2 locally, deterministic clock, mock AI, bug fixes start with a failing test, every refusal check validates the `ApiError` shape (`error(HttpStatus)`, guarded by `TestStructureRulesTest`): all met | **Pass** (constitution 2.0.0) |
| III. Backward-compatible data changes (phased in 2.0.0) | No schema change. Tests build the schema with `ddl-auto=create-drop`, which 2.0.0 allows until production phase 1 (Flyway comes with the first stable schema) | Pass |
| IV. Secure by default | Tests now run the real JWT filter (improvement). Found: routine endpoints lack ownership checks (R6). Not introduced by F008, filed as a bug, tests don't lock it in. FR-018 messages reveal no account existence on login | Pass (gap recorded) |
| V. Constrained AI agency | `spring.ai.active=false` in all tests; no live calls; the AI-tool past-date freeze is tested via tool entry points | Pass |
| VI. Frontend | Unchanged. The frontend already shows `message` (quickstart 11) | Pass |
| VII. Supply chain & pipeline | CI now runs tests before deploy (closes a known gap). Action SHA-pinning remains an existing gap, not touched substantially (R14) | Pass (gap unchanged) |
| VIII. Observability | No change | Pass |
| IX. Simplicity | Three test-only libraries (justified below). No new Gradle source sets, no ArchUnit, no stub HTTP server. Replaced test styles are removed in this feature (old classes deleted) | Pass |

Gate result: **PASS**. Principles I (error format) and II (testing) are amended inside this feature (constitution 2.0.0).

## Project Structure

### Documentation (this feature)

```text
specs/F008-technical-enhancement-update-backend-testing-structure/
├── spec.md
├── plan.md              # this file
├── research.md          # R1–R16 decisions
├── data-model.md        # test-suite entities + migration inventory
├── quickstart.md        # 14 validation scenarios
├── contracts/
│   ├── sign-in-errors.md
│   └── test-harness.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks (not created here)
```

### Source Code

```text
ms-personal-routine-manager/
├── build.gradle                                   # test deps; testDb property → test.db; validation
├── .github/workflows/gradle-publish.yml           # build -PtestDb=postgres; upload reports on failure
├── CLAUDE.md                                      # Testing strategy rewritten (FR-014)
├── docs/test-flows.md                             # renamed from integration-test-flows.md, rewritten
├── src/main/java/com/tom/payment/routinemanager/
│   ├── RoutinemanagerApplication.java             # drop @EnableScheduling
│   ├── config/ClockConfig.java                    # new
│   ├── config/SchedulingConfig.java               # new, app.scheduling.enabled
│   ├── config/ChatHistoryProperties.java          # + pageSizeFor, compactionDue
│   ├── funcs/DayRules.java                        # new
│   ├── funcs/RoutineTemplateRules.java            # new
│   ├── api/{DailyRoutineController,AIController,CronSupportController}.java   # Clock
│   └── service/{AuthenticationService,DailyRoutineService,DefaultRoutineService,
│                aitools/DailyRoutineAiTools,reflection/ReflectionService,
│                chat/ChatConversationService,chat/ChatCompactionService,
│                GeminiAiChatService,reflection/GeminiReflectionAiService}.java
└── src/test/
    ├── resources/application-test.yml, application-test-h2.yml, application-test-postgres.yml
    └── java/com/tom/payment/routinemanager/
        ├── support/    BaseComponentTest, TestUser, MutableClock, TestSupportConfig,
        │               TestDatabaseProfiles, RequiresPostgres
        ├── component/  SignIn, Onboarding, DefaultRoutine, DailyRoutine, TaskColor,
        │               UserSettings, ChatHistory, ChatCompaction, Reflection  (…ComponentTest)
        ├── unit/       TaskColorService, TaskTimeFunctions, RoutineTemplateRules, DayRules,
        │               ChatHistoryProperties, ReflectionComparisonService, UserSettingsRegistry,
        │               TaskPaletteContrast, TestStructureRules  (…Test)
        └── integration/ JwtSecurityIntegrationTest, ChatSequenceLockingIntegrationTest

.specify/memory/constitution.md                    # Principle II → v2.0.0 (via /speckit-constitution)
.specify/templates/bugfix-template.md              # failing component or unit test first
AI-project-docs/bugs/                              # new bugs: routine ownership, refresh expiry, logout revoke
```

**Structure Decision**: a single Gradle `test` task. Test kinds are separated by package and suffix (R11), with shared support in `support/`. The old test classes are deleted once their replacements pass (Principle IX: no coexisting styles).

## Delivery phases and timeline

Order follows the dependencies. Each phase ends with `./gradlew test` and `./gradlew test -PtestDb=postgres` green.

| Phase | Content | Depends on | Estimate |
|---|---|---|---|
| 0. Branch + baseline | Create branches; run the 5 un-run old classes once against a throwaway Postgres to record the true baseline | — | 0.25 d |
| 1. Foundation (US1) | Gradle switch + validation, test profiles, Testcontainers config, `BaseComponentTest`, `TestUser`, `MutableClock`, sync executor, `@RequiresPostgres`, `TestStructureRulesTest`; production `ClockConfig` + `SchedulingConfig` | 0 | 1 d |
| 2. Sign-in (US5, FR-018) | `SignInComponentTest` written first (fails on the 500 cases) → fix `AuthenticationService` → green; `JwtSecurityIntegrationTest` | 1 | 0.5 d |
| 3. Rule extraction + unit tests (US3) | `DayRules`, `RoutineTemplateRules`, `ChatHistoryProperties` helpers; Clock at call sites; unit tests for all core rules; old component coverage stays green throughout | 1 | 0.75 d |
| 4. Component migration (US4, US5) | Onboarding, default and daily routine, task colour, settings, chat history, compaction, reflection component tests; `ChatSequenceLockingIntegrationTest`; delete the old classes | 1, 3 | 1.5 d |
| 5. Pipeline (US2) | Workflow change; prove it blocks with a deliberately failing PR | 1 | 0.25 d |
| 6. Docs (US6) | Constitution v2.0.0, backend `CLAUDE.md`, bug-fix template, `docs/test-flows.md`, file 3 bugs | 2–4 | 0.5 d |
| 7. Verify | Quickstart 1–14, `/speckit-analyze`, `/code-review` | all | 0.25 d |
| **Total** | | | **about 5 working days** |

## Follow-ups (not in F008)

- Bug: routine endpoints have no ownership check (R6).
- Bug: refresh-token lifetime uses the access-token expiry (R7).
- Bug: logout doesn't revoke the refresh token (constitution gap IV).
- AI-provider integration test against a local stand-in (R13).
- SHA-pin GitHub Actions, including the `actions/upload-artifact@v4` step F008 added (constitution gap VII; deferred while the project is in its local phase).
- Prove the CI gate on a real PR (T052; deferred with CI/CD).
- Bug: Buddy's update/delete tools need an open session (bug-0005).
- Bug: the `prod` profile can't serialise routine entities (bug-0006).
- Bug: the deployed `test` profile exposes the cron support endpoint, and the CI deploy step sets no profile (bug-0007).
- Flyway adoption at production phase 1, with the first stable schema as the baseline; tests then build the schema from the migrations (constitution III, planned).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Principle II text conflicts until amended | The spec (FR-013) redefines the backend testing model | Keeping the old text leaves the constitution contradicting `CLAUDE.md` and the suite. The amendment is scheduled in Phase 6 |
| Three new test-only libraries | Testcontainers (+ Boot integration) gives the production-type database the constitution's merge gate names; `spring-boot-starter-webmvc-test` gives `@AutoConfigureMockMvc` so the security filter chain runs in tests | A GitHub `services:` database differs locally and in CI and needs credentials. Hand-built MockMvc with `springSecurity()` needs `spring-security-test` anyway and repeats Boot's auto-configuration |
