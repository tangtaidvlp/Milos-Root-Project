# Data Model: F008 – Update Backend Testing Structure

F008 adds no database tables or columns. Its "entities" are the parts of the test suite and the settings that select them. The last section maps every existing test to its new home (FR-009).

## 1. Test-suite entities

### Test database option

| Field | Values | Rules |
|---|---|---|
| `testDb` (Gradle property) / `TEST_DB` (env) → `test.db` (system property) | `h2` (default), `postgres` | Any other value fails the build. Declared as a `test` task input, so switching reruns the tests |
| Active Spring profiles | `test` + `test-h2`, or `test` + `test-postgres` | Resolved by `TestDatabaseProfiles` from `test.db`. A missing property means `h2` (IDE runs) |

States: `h2` gives the in-memory database with no external services. `postgres` gives a Testcontainers `postgres:17`, one per run. If Docker is missing, every test fails at context start, with no fallback (FR-003).

### BaseComponentTest (component-test foundation, FR-001)

| Provides | Notes |
|---|---|
| Running backend | `@SpringBootTest` + `@AutoConfigureMockMvc`, so the security filter chain is active |
| `mvc` | MockMvc. Helpers `get/post/put/patch/delete(path, TestUser)` add `Authorization: Bearer …`; `anonymous(...)` sends no token |
| `newUser()` → `TestUser` | Registers and logs in through `/api/v1/auth/register` + `/login` with a unique email |
| `clock` → `MutableClock` | Fixed at Wed 2026-11-18 09:00 (system zone) and reset after each test |
| AI spies | `aiChatService`, `chatSummarizer`, `reflectionAi` (`@MockitoSpyBean`, reset after each test) |
| Repositories | Injected as needed to **check** stored state and to seed states the API can't create (a legacy user with no weekend routine, a revoked refresh token, a corrupt stored setting) |
| JSON helper | Reads bodies into `JsonNode` |

Rules:
- It is the only class with Spring test annotations. Subclasses add none of `@TestPropertySource`, `properties=`, `@MockitoBean`, `@MockitoSpyBean` or `@DirtiesContext` (guarded by `TestStructureRulesTest`).
- Each test creates its own users. No test depends on another test's data or on run order, and nothing is rolled back or cleaned up.

### TestUser

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | From the register response |
| `email` | String | `<prefix>-<uuid8>@example.test` |
| `username` | String | |
| `password` | String | Fixed test password |
| `accessToken` | String | From the login response |

### MutableClock

A `java.time.Clock` with `instant()`, `getZone()`, `setToday(LocalDate)` (keeps 09:00), `setInstant(Instant)`, `advance(Duration)` and `reset()`. It is the `@Primary` `Clock` bean in tests. Production uses `Clock.systemDefaultZone()` from `ClockConfig`.

### TestSupportConfig (`@TestConfiguration`, imported by the base)

| Bean | Purpose |
|---|---|
| `MutableClock` (`@Primary Clock`) | Controlled date (R10) |
| `SyncTaskExecutor` named `taskExecutor` | Runs `@Async` compaction inline after commit (R9) |
| `PostgreSQLContainer` (`@ServiceConnection`, only under profile `test-postgres`) | Production-type database (R2) |

### @RequiresPostgres

A meta-annotation for `@EnabledIfSystemProperty(named = "test.db", matches = "postgres")`, for integration tests that need Postgres-only behaviour. These tests are reported as **skipped** on H2 (FR-008).

## 2. Test kinds (classification rules)

| Kind | Must | Must not |
|---|---|---|
| Component (`component/*ComponentTest`) | Extend `BaseComponentTest`; go through the public API with a real token; per main flow, cover the success path + main refusals (400 / 401 / 403 / 404 / 409); check status, body and, on writes, stored state | Call internal services in place of an API route. The one exception is Buddy's AI tool entry points (spec Assumptions). Also must not repeat the edge-case variations of a core rule |
| Unit (`unit/*Test`) | Test one core business rule and its edge cases; run without Spring and without a database | Mock storage; use Spring test annotations |
| Integration (`integration/*IntegrationTest`) | Check one external connection; add `@RequiresPostgres` if it needs Postgres | Exceed 10 in total |

## 3. Production code touched (no behaviour change except FR-018)

| Change | Files |
|---|---|
| `Clock` bean and injection | new `config/ClockConfig`; `DailyRoutineController`, `AIController`, `DailyRoutineService`, `DailyRoutineAiTools`, `ReflectionService`, `GeminiAiChatService`, `GeminiReflectionAiService`, `CronSupportController`, `AuthenticationService` |
| Scheduling switch | new `config/SchedulingConfig`; `RoutinemanagerApplication` (drop `@EnableScheduling`) |
| Rule extractions | new `funcs/RoutineTemplateRules`, `funcs/DayRules`; `ChatHistoryProperties` (+ `pageSizeFor`, `compactionDue`); call sites in `DefaultRoutineService`, `ChatConversationService`, `ChatCompactionService`, plus the 5 past/future sites |
| Sign-in fixes (FR-018) | `AuthenticationService` (throw `ResponseStatusException` 401/409, Clock for expiry); see [contracts/sign-in-errors.md](contracts/sign-in-errors.md) |
| Bad bearer token → 401 (FR-018, found in T038) | `config/JwtAuthenticationFilter` (catch `JwtException` / `IllegalArgumentException`, continue unauthenticated) |
| Concurrent chat seq (FR-019, found in T047) | `service/chat/ChatConversationService.appendExchange` (`entityManager.refresh(c)` after taking the row lock) |
| Test access to the settings registry | `service/UserSettingsRegistry`: `builtIns()` and the list constructor made `public` (the unit test moved out of the package) |

## 4. Migration inventory (FR-009)

"Kept" means the behaviour stays covered. "Moved to unit" means its variations move, and one representative case stays in the component test.

| Old class (tests) | New home | What happens |
|---|---|---|
| `apptest/OnboardingRoutineTest` (6) | `component/OnboardingComponentTest` | Registration through `/auth/register` → two empty routines; the WEEKEND routine is created on first request for a legacy user (seeded by repository) and reused; `type` defaults to DAILY; `type=FOO` → 400. The 2 tests that call removed endpoints are dropped; their "add tasks" intent moves to `DefaultRoutineComponentTest` |
| `RoutineServiceIntegrationTest` (10) | `component/DefaultRoutineComponentTest`, `component/DailyRoutineComponentTest`, `unit/TaskTimeFunctionsTest`, `unit/RoutineTemplateRulesTest` | Service calls become HTTP: create/replace routine, add/update/delete tasks, today's routine cloned from the template, `completed` flag. Overlap shifting → unit, plus 1 component case. 4 template-choice cases → unit, plus 1 component case (Saturday with weekend tasks) |
| `TaskColorIntegrationTest` (14) | `component/TaskColorComponentTest`, `unit/TaskColorServiceTest` | Component: auto colour on create, chosen colour via PUT, unknown → 400 on create and update (stored value unchanged), `nextColor` shown and `colorCursor` hidden, palette endpoint order, a new day copies colours and cursor, the cron endpoint spawn copies colours, Buddy tools accept palette names and refuse hex/unknown names. Unit: round-robin and wrap, kept preselection advances, other ids and hex don't advance, same name shares a colour, update keeps colour, per-routine cursor |
| `UserSettingsIntegrationTest` (10) | `component/UserSettingsComponentTest`, `unit/UserSettingsRegistryTest` | Component: defaults with no rows, PATCH stored and marked customized, partial PATCH keeps others, one invalid PATCH → 400 with nothing written, unknown user 404, other user's token 403, profile fields with no secrets, a corrupt or unknown stored row is ignored. The 9 invalid-value variations → unit |
| `ChatHistoryIntegrationTest` (10) | `component/ChatHistoryComponentTest`, `unit/ChatHistoryPropertiesTest` | Component keeps all 10 behaviours, with real tokens. Page-size clamping (null, 0, over the max) → unit; one paging walk stays |
| `ChatCompactionIntegrationTest` (2) | `component/ChatCompactionComponentTest`, `unit/ChatHistoryPropertiesTest` | Both behaviours kept, with no polling (sync executor, default threshold 20). The threshold boundary → unit |
| `ReflectionIntegrationTest` (14) | `component/ReflectionComponentTest`, `unit/DayRulesTest` | All 14 kept. The plan is seeded through the daily-routine API; dates come from `MutableClock`. The today/tomorrow/yesterday boundaries → unit |
| `RoutinemanagerApplicationTests` (1) | — | Removed: every component test starts the context |
| `TaskPaletteContrastTest` (1) | `unit/TaskPaletteContrastTest` | Same check; the palette is bound from `application.yml` without Spring |
| `service/UserSettingsRegistryTest` (2) | `unit/UserSettingsRegistryTest` | Mocked repository removed; registry-only assertions plus the moved validation variations |
| `ReflectionComparisonServiceTest` (6) | `unit/ReflectionComparisonServiceTest` | Moved package only |
| — (new) | `component/SignInComponentTest` | Register, login, refresh (cookie), logout (cookie cleared); every FR-018 refusal |
| — (new) | `integration/JwtSecurityIntegrationTest` | Tampered, foreign-key and malformed tokens → 401 |
| — (new) | `integration/ChatSequenceLockingIntegrationTest` (`@RequiresPostgres`) | Concurrent appends → unique, gap-free sequence numbers |
| — (new) | `unit/TestStructureRulesTest` | Enforces the classification rules in §2 |

**Verified 2026-11-23 (T050).** Every behaviour of the 11 old classes maps to a passing test. Notes:
- The 2 `OnboardingRoutineTest` tests that called removed endpoints are dropped. Their "add tasks to a default routine" intent is in `DefaultRoutineComponentTest`; "accepts a single object instead of a list" isn't kept, because the current endpoint takes a list only.
- The walk found one gap: "an update without a colour keeps it, and deletes don't rewind the palette" (old `updatesKeepColorUnlessOneIsSent`, daily part of `dailyTasksUseTheirRoutinesOwnCursor`). It is now `TaskColorComponentTest.updatesKeepTheColourUnlessOneIsSentAndDeletesDoNotRewind`.

`docs/integration-test-flows.md` is rewritten (FR-014) and renamed `docs/test-flows.md`. It lists the main flows → component tests, the core rules → unit tests, and the connections → integration tests.
