# Research: F008 – Update Backend Testing Structure

Each decision below resolves an open point from the spec or the Technical Context in [plan.md](plan.md). Findings come from reading the code at `ms-personal-routine-manager` commit `aa4efe4` and the Spring Boot 4.1.0 BOM in the local Gradle cache.

## R1. How tests choose their database (FR-002, FR-003, SC-006)

- **Decision**: One Gradle property, `-PtestDb=h2|postgres` (or the env var `TEST_DB`), default `h2`. The `test` task passes it to the test JVM as the system property `test.db`, and declares it as a task input so switching it reruns the tests rather than reporting them up to date. Any other value fails the build. `BaseComponentTest` uses `@ActiveProfiles(resolver = TestDatabaseProfiles.class)`. The resolver returns `test` + `test-h2` or `test` + `test-postgres`; with no property set (an IDE run) it returns the H2 pair.
- **Rationale**: One switch, zero code edits, and it works from the IDE and Gradle alike. Profiles keep the database config in YAML, next to the other profiles.
- **Alternatives considered**:
  - Two Gradle tasks (`test`, `testPostgres`) were rejected as more build logic for the same result.
  - Using `SPRING_PROFILES_ACTIVE` directly was rejected because it would also pick up `local` or `fast` from a developer's shell.

## R2. Where the production-type database comes from (FR-003, FR-011)

- **Decision**: Testcontainers 2.0.5 (managed by the Boot 4.1 BOM), with `postgres:17`. A `@TestConfiguration` with `@Profile("test-postgres")` declares a `PostgreSQLContainer` bean marked `@ServiceConnection`. Spring starts it once per cached context, so there is one container per run. The same mechanism runs locally and in CI. If Docker is unavailable, Testcontainers throws on context start and every test fails with "Could not find a valid Docker environment". There is no fallback to H2 (FR-003).
- **Rationale**:
  - The constitution's merge gate already names Testcontainers.
  - It needs no `services:` block or credentials in the workflow, and each run gets a throwaway database.
  - It matches what the backend `CLAUDE.md` already describes.
  - The image is PostgreSQL 17 as the constitution pins it. `docker-compose.yml` uses `postgres:trixie`, which is a dev convenience and not the contract.
- **Alternatives considered**:
  - A GitHub Actions `services: postgres` container plus env-var datasource was rejected: a second mechanism, a different one locally, and connection settings in YAML.
  - Reusing the docker-compose dev database was rejected because tests would write into the developer's data.
- **New test dependencies**: `org.springframework.boot:spring-boot-testcontainers`, `org.testcontainers:testcontainers-postgresql`. The class is `org.testcontainers.postgresql.PostgreSQLContainer`, as the 2.x module was renamed.

## R3. Test profiles and their settings

- **Decision**: Three new files under `src/test/resources/`:
  - **`application-test.yml`** (always active):
    - `spring.ai.active=false` (mock AI, FR-007).
    - A placeholder `spring.ai.google.genai.api-key`, so the context starts without `GEMINI_API_KEY`. That key was set in the shell during the 2026-11-22 baseline runs, so this is still unproven and quickstart scenario 6 verifies it.
    - `spring.jpa.hibernate.ddl-auto=create-drop`.
    - `app.scheduling.enabled=false` (R8).
    - CORS origin `http://localhost`.
  - **`application-test-h2.yml`**: an in-memory H2 URL (`jdbc:h2:mem:f008;DB_CLOSE_DELAY=-1`) and `H2Dialect`, as `application-fast.yml` does today.
  - **`application-test-postgres.yml`**: `PostgreSQLDialect`. The datasource comes from `@ServiceConnection`.
- **Rationale**: Test-only profiles leave `fast`, `local`, `sit` and `prod` untouched (FR-016). The `test` profile is not in `SecurityConfig`'s allow-all list (`local`, `fast`), so the JWT filter is active in tests, as decided in clarification 5. `CronSupportController` is already `@Profile({"local","fast","test"})`, so the cron endpoint exists in tests.

## R4. One shared Spring context (FR-006)

- **Finding**: the baseline run built 4 contexts for the 4 `fast` classes. The causes were different `properties` (compaction threshold 4 vs 1000), different `@MockitoSpyBean` sets, and `@ActiveProfiles` on some classes only.
- **Decision**:
  - All component tests extend `BaseComponentTest`, which carries the only `@SpringBootTest`, `@AutoConfigureMockMvc`, profile resolver and `@Import(TestSupportConfig)`.
  - It declares all three spies (`AiChatService`, `ChatSummarizer`, `ReflectionAiService`) with `@MockitoSpyBean`. The default `MockReset.AFTER` restores them after each test.
  - No subclass may add `@TestPropertySource`, `properties=`, spy/mock beans or `@DirtiesContext`. A unit test with no Spring context enforces this (R11).
  - The compaction threshold stays at the production default (20) for everyone (R9).
- **Rationale**: One context per database option means one start-up per run, which matters most on Postgres, where it includes the container.

## R5. Signing in during component tests (FR-001, clarification 5)

- **Decision**: `BaseComponentTest.newUser()` registers a unique user through `POST /api/v1/auth/register`, logs in through `POST /api/v1/auth/login`, and returns a `TestUser(id, email, username, password, accessToken)`. Request helpers add `Authorization: Bearer <token>`. `@AutoConfigureMockMvc` registers the Spring Security filter chain, so the real `JwtAuthenticationFilter` and `CurrentUserGuard` run on every request.
- **Cost**: two BCrypt operations (default strength 10, about 50–100 ms each) per test user. With about 120 component tests and 1–2 users each, that adds roughly 15–25 s, which fits SC-003 (under 3 min).
- **Consequences**:
  - `UserSettingsIntegrationTest.signInAs` (the hand-set `SecurityContextHolder`) is deleted.
  - The "other user" checks use a second real user's token.
  - Each flow gets at least one no-token request, which must return 401.
- **Alternatives considered**: the rejected options B, C and D from clarification 5.

## R6. Routines have no ownership check (found while designing R5)

- **Finding**:
  - `DefaultRoutineController` and `DailyRoutineController` take a routine id, task ids or a `userId` and never compare them with the caller. Any signed-in user can read or edit another user's routines.
  - The constitution's ownership rule says to look up every user-owned entity by (user, id) and return 404 otherwise. These endpoints break it.
- **Decision**: F008 does not fix this, because FR-016 allows no behaviour change except FR-018. A task files it as a bug in `AI-project-docs/bugs/` (next number after `bug-0001`). The routine component tests check the 401 for a request with no token, but do **not** assert that another user's request succeeds, so the future fix only adds tests.
- **Rationale**: an ownership fix changes the API for every routine endpoint and the frontend's error handling. It deserves its own `fix` that starts with a failing component test.

## R7. Sign-in fixes (FR-018)

- **Finding**: `AuthenticationService` throws a bare `RuntimeException` for an unknown email, a wrong password, a duplicate registration, and an unknown, revoked or expired refresh token. `GlobalExceptionHandler.handleUnexpected` turns each into a 500. A missing refresh cookie already throws `ResponseStatusException(401)`.
- **Decision**: throw `ResponseStatusException` with:
  - **401** and "Invalid email or password." for an unknown email or a wrong password. The message is the same in both cases, so it doesn't reveal whether the account exists.
  - **409** and "An account with this email already exists." for a duplicate registration.
  - **401** and "Your session has expired. Please sign in again." for an unknown, revoked or expired refresh token, or a deleted user.

  `handleResponseStatus` already maps these to the existing `ApiError` body (`status`, `error`, `message`, `timestamp`), and the frontend shows `body.message`.
- **Expiry checks use the Clock**: `AuthenticationService` reads `clock.instant()` for refresh-token expiry (R10), so a test can expire a token by moving the clock.
- **Out of scope, filed as bugs**:
  - Refresh tokens are saved with `accessTokenExpiration` (15 min) instead of `refreshTokenExpiration` (7 days). See `AuthenticationService.login`.
  - Logout doesn't revoke the stored refresh token. The constitution's Sync Impact Report already tracks this.

  Both are behaviour changes outside FR-018.
- **Alternatives considered**: returning RFC 9457 `ProblemDetail` was rejected for now. The frontend reads `message`, not `detail`, and every other endpoint uses `ApiError`. Switching one endpoint group would break the frontend and split the error format. **Update 2026-11-23:** the owner dropped RFC 9457 altogether. Constitution 2.0.0 Principle I makes `ApiError` the one error format, so this is no longer a deviation (FR-020).

## R8. Scheduled job during tests (spec edge case)

- **Decision**: move `@EnableScheduling` from `RoutinemanagerApplication` to a new `SchedulingConfig` with `@ConditionalOnProperty(name = "app.scheduling.enabled", havingValue = "true", matchIfMissing = true)`. The test profile sets it to `false`. The spawn job is still testable through `POST /api/support/cron/spawn-daily-task`.
- **Rationale**: no behaviour change in any real profile, because the property is missing there and defaults to on. A CI run that crosses midnight can't spawn routines mid-test.

## R9. Async chat compaction without polling (FR-007)

- **Finding**: `ChatCompactionService.onAppended` is `@Async` + `@TransactionalEventListener(AFTER_COMMIT)`. `compactIfDue` already runs in its own `REQUIRES_NEW` transaction. It is the only `@Async` method in the codebase.
- **Decision**: `TestSupportConfig` provides a `SyncTaskExecutor` as the `taskExecutor` bean, so `@Async` runs on the calling thread right after commit. Compaction is then finished when the request returns. `waitFor` and `Thread.sleep` are removed. With the production threshold of 20, the compaction test sends 10 exchanges, which is cheap with the mock AI.
- **Rationale**: deterministic, needs no property override (R4), and is safe because the work already uses its own transaction.
- **Trade-off**: the test no longer proves that compaction runs off the request thread. No requirement asks for that, and a deferred AI or timing integration test could cover it later.

## R10. Controlled current date (FR-007)

- **Finding**: there are 7 `LocalDate.now()` call sites used for business rules: `DailyRoutineController`, `AIController`, `DailyRoutineService` (2), `DailyRoutineAiTools` (2) and `ReflectionService`. Another 4 feed "today's date" into AI prompts or the past-date check: `GeminiAiChatService` (3) and `GeminiReflectionAiService` (1). `Instant.now()` is used for timestamps in entities and services.
- **Decision**:
  - Add a `ClockConfig` bean, `Clock.systemDefaultZone()`.
  - Inject `Clock` into those classes and use `LocalDate.now(clock)`. `AuthenticationService` also uses `clock.instant()` for refresh-token expiry (R7).
  - Entity `@PrePersist` timestamps stay on system time: entities can't take injected beans, and no rule depends on them except reflection "stale" (`feedback_at < content_updated_at`), which only needs ordering.
  - Tests get a `MutableClock` (`@Primary`), fixed by default at Wednesday 2026-11-18 09:00 in the system zone and reset after each test. Tests may call `clock.setToday(...)` or `clock.advance(...)`.
- **Rationale**: the constitution requires an injected `Clock`. Behaviour is unchanged because the production clock is the system clock (FR-016).

## R11. Naming, packages and the "one context" guard

- **Decision**:

  | Kind | Package | Class suffix | Base |
  |---|---|---|---|
  | Component | `…routinemanager.component` | `ComponentTest` | `BaseComponentTest` |
  | Unit | `…routinemanager.unit` | `Test` | none (no Spring) |
  | Integration | `…routinemanager.integration` | `IntegrationTest` | `BaseComponentTest`; Postgres-only classes add `@RequiresPostgres` |
  | Support | `…routinemanager.support` | — | — |

- **Selecting a kind**: by package, for example `./gradlew test --tests 'com.tom.payment.routinemanager.unit.*'`.
- **Postgres-only marker**: `@RequiresPostgres` is a meta-annotation for `@EnabledIfSystemProperty(named = "test.db", matches = "postgres")`. JUnit reports such tests as skipped on H2 (FR-008).
- **Guard**: `TestStructureRulesTest` (unit) scans the test classes with reflection and fails when:
  - a component or integration class doesn't extend `BaseComponentTest`;
  - a class outside `support` declares `@TestPropertySource`, `@DirtiesContext`, `@MockitoBean` or `@MockitoSpyBean`;
  - a unit test class has a Spring annotation.

  This makes SC-005 checkable on every run without adding ArchUnit.
- **Alternatives considered**:
  - A separate Gradle source set (`componentTest`) was rejected as build complexity, since one `test` task is enough.
  - JUnit `@Tag` filtering was rejected because packages already separate the kinds.
  - ArchUnit was rejected for one rule set; plain reflection is enough (Principle IX).

## R12. Separating core business rules from storage (FR-005, US3)

| Rule | Where it lives today | Storage-free? | F008 change |
|---|---|---|---|
| Task colour assignment (round-robin, wrap, preselection, same-name share, validation) | `TaskColorService` (needs only `TaskPaletteProperties`) | Yes | None. Unit-test it with a palette built in the test |
| Overlap shifting | `funcs/TaskTimeFunctions` (static) | Yes | None |
| Weekday/weekend template choice | `DefaultRoutineService.resolveTemplateFor` (mixed with two repository look-ups) | No | Extract `funcs/RoutineTemplateRules.templateTypeFor(LocalDate, boolean weekendHasTasks)`; the service keeps the look-ups and calls the rule |
| Plan-vs-reality comparison | `ReflectionComparisonService` | Yes | None (test exists) |
| Settings validation and defaults | `UserSettingsRegistry` | Yes | None. Drop the mocked-repository part of the existing test |
| Chat history page size | Inline in `ChatConversationService.getHistory` | No | Extract `ChatHistoryProperties.pageSizeFor(Integer requested)` |
| Compaction due | Inline in `ChatCompactionService.compactIfDue` | No | Extract `ChatHistoryProperties.compactionDue(long messagesPastCursor)` |
| Past / future day | Inline `isBefore` / `isAfter(LocalDate.now())` at 5 sites (`AIController`, `DailyRoutineAiTools` ×2, `ReflectionService`, `GeminiAiChatService`) | No | Extract `funcs/DayRules.isPast(date, today)` / `isFuture(date, today)`; call sites pass `LocalDate.now(clock)` |
| Palette contrast (WCAG AA) | `TaskPaletteContrastTest` boots the whole context to read the palette | — | Bind `TaskPaletteProperties` from `application.yml` with Boot's `Binder` (no context) in a unit test |

Every extraction is a pure move with no logic change. The component tests that already cover each flow must stay green before and after (FR-016).

## R13. Integration tests to add (FR-008, SC-002 ≤ 10)

| Test | Connection | Runs on | Why |
|---|---|---|---|
| `ChatSequenceLockingIntegrationTest` | Postgres row locking (`@Lock(PESSIMISTIC_WRITE)` on `ChatConversationRepository`) | Postgres only (`@RequiresPostgres`) | Concurrent appends to one conversation must get unique, gap-free `seq` numbers. This is the reason `application-fast.yml` needs `H2Dialect`, and H2 can't prove it |
| `JwtSecurityIntegrationTest` | Spring Security + JWT filter | Both | A tampered token, a token signed by another key, a malformed header, and a missing token each give 401 on a protected endpoint. A valid token passes |

- **Deferred**: an AI-provider integration test (Gemini client against a local stand-in) needs an HTTP stub library and a way to override the Google GenAI SDK endpoint. That is new infrastructure with no current defect behind it, so it's listed in the plan's follow-ups.
- **Not added**: checking the manual `db/*.sql` scripts against Postgres needs the base schema, which only exists as Hibernate output. That belongs with the Flyway adoption (constitution gap III).

## R14. Delivery pipeline (FR-011, FR-012, SC-001)

- **Decision**: in `.github/workflows/gradle-publish.yml`:
  - Replace `./gradlew clean build -x test` with `./gradlew clean build -PtestDb=postgres`. `build` runs `test`, and a failure stops the job before the image build, push and deploy steps.
  - Add an `actions/upload-artifact` step with `if: failure()` for `build/reports/tests/test`.
  - Don't set `GEMINI_API_KEY` for the build step.
- **Unchanged**: the triggers are already push to `main` plus pull requests to `main`, which matches FR-011. Docker is available on `ubuntu-latest` for Testcontainers.
- **Not in scope**: SHA-pinning the actions (constitution VII gap). Only one step changes, which doesn't count as substantially touching the workflow. It's listed as a follow-up.

## R15. Constitution amendment (FR-013)

- **Decision**: run `/speckit-constitution` during implementation to rewrite Principle II for the backend:
  - component tests cover main user flows;
  - unit tests cover core business rules and their edge cases, with no mocked storage;
  - integration tests (10 or fewer) only check external connections;
  - H2 is allowed only for local component-test runs, and the pipeline uses Postgres via Testcontainers.

  Frontend bullets stay. Remove "integration tests can use H2" and "CI builds with -x test" from the Sync Impact Report's known gaps, and add the ownership gap (R6).
- **Version**: governance says that redefining a principle is a MAJOR change, so **1.0.0 → 2.0.0**.

## R16. Baseline measurements (2026-11-22)

| Measure | Value |
|---|---|
| Test classes / tests | 11 / 76 |
| Run on H2 (`fast`) + pure unit | 6 classes, 44 tests, all passing, about 7 s, 4 Spring contexts |
| Not run (default `local` → dev Postgres, Gemini on) | 5 classes, 32 tests |
| Known broken | 2 `OnboardingRoutineTest` methods call removed endpoints |
| Previously un-run classes (T002, throwaway `postgres:17`, Gemini key set) | 32 tests: `RoutineServiceIntegrationTest` 10/10, `TaskColorIntegrationTest` 14/14, `RoutinemanagerApplicationTests` 1/1, `TaskPaletteContrastTest` 1/1, `OnboardingRoutineTest` 4/6 (the 2 removed-endpoint tests fail). Baseline total: 74/76 passing |
| After F008 (2026-11-23) | 20 classes / 135 tests: 9 component (76), 9 unit (52, plus the structure guard), 2 integration (7). All pass on H2 (1 Postgres-only skip) and Postgres. 1 Spring context. About 24 s (H2) / 26 s (Postgres) for the full `./gradlew test` |
