---

description: "Task list for F008 – Update Backend Testing Structure"
---

# Tasks: F008 – Update Backend Testing Structure

**Input**: Design documents from `specs/F008-technical-enhancement-update-backend-testing-structure/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Tests are this feature's deliverable, so test tasks are included throughout. For the sign-in fix (FR-018), the failing test is written before the fix.

**Organization**: Tasks are grouped by user story. The phase order follows dependencies, not only priority: US2 (pipeline gate, P1) can only be switched on after US4 has removed the old tests, which need a developer database and a Gemini key.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: The user story the task belongs to (US1–US6 from spec.md)

## Path Conventions

- `B/` = `ms-personal-routine-manager/` (backend repo, a git submodule of the root repo)
- `M/` = `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/`
- `T/` = `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/`
- `R/` = `ms-personal-routine-manager/src/test/resources/`
- `F/` = `specs/F008-technical-enhancement-update-backend-testing-structure/`
- Run every `./gradlew` command from `B/`.
- **Transition rule**: until T048 deletes the old test classes (root package `T/*.java`, `T/apptest/`, `T/service/`), a plain `./gradlew test` also runs them, and some need the dev Postgres on :5469. Checkpoints therefore select the new packages with `--tests 'com.tom.payment.routinemanager.component.*' --tests 'com.tom.payment.routinemanager.unit.*' --tests 'com.tom.payment.routinemanager.integration.*'`. That full selection is called **NEW** below.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Branches, dependencies, the database switch, and the true baseline

- [X] T001 Create branch `feat/F008-backend-testing-structure` from `main` in the root repo and in `B/` (the submodule). Don't push yet
- [X] T002 Record the true baseline. Start a throwaway Postgres (`docker run -d --rm --name f008-baseline -p 55432:5432 -e POSTGRES_PASSWORD=postgres postgres:17`), then in `B/` run `SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:55432/postgres ./gradlew test --tests '*OnboardingRoutineTest' --tests '*RoutineServiceIntegrationTest' --tests '*TaskColorIntegrationTest' --tests '*RoutinemanagerApplicationTests' --tests '*TaskPaletteContrastTest'`. Add the pass/fail counts per class as a new row "Previously un-run classes" in the R16 table of `F/research.md`. Stop the container afterwards
- [X] T003 Add the test dependencies to `B/build.gradle` (versions come from the Boot BOM; don't pin them): `testImplementation 'org.springframework.boot:spring-boot-starter-webmvc-test'`, `testImplementation 'org.springframework.boot:spring-boot-testcontainers'`, `testImplementation 'org.testcontainers:testcontainers-postgresql'`. Verify with `./gradlew dependencies --configuration testRuntimeClasspath | grep -E "testcontainers|webmvc-test"` (expect Testcontainers 2.0.5). Keep `runtimeOnly 'com.h2database:h2'` as is
- [X] T004 Add the database switch to the `test` task in `B/build.gradle`:
  - Read `def testDb = (findProperty('testDb') ?: System.getenv('TEST_DB') ?: 'h2').toString()`.
  - If it is not `h2` or `postgres`, throw `new GradleException("testDb must be 'h2' or 'postgres', got '${testDb}'")`.
  - Add `systemProperty 'test.db', testDb` and `inputs.property('testDb', testDb)`.
  - Keep `useJUnitPlatform()`.

  Verify that `./gradlew test -PtestDb=mysql --tests none` fails with that message (quickstart #4)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Behaviour-neutral production changes that every test kind relies on: a controllable clock, and switchable scheduling (research R8, R10)

**⚠️ CRITICAL**: No user story work starts before this phase is done

- [X] T005 [P] Create `M/config/ClockConfig.java`: a `@Configuration` with `@Bean public Clock clock() { return Clock.systemDefaultZone(); }`
- [X] T006 [P] Create `M/config/SchedulingConfig.java` (`@Configuration`, `@EnableScheduling`, `@ConditionalOnProperty(name = "app.scheduling.enabled", havingValue = "true", matchIfMissing = true)`) and remove `@EnableScheduling` (and its import) from `M/RoutinemanagerApplication.java`. Keep `@EnableAsync`
- [X] T007 Inject `java.time.Clock` by constructor (add a `private final Clock clock` field; the classes use `@RequiredArgsConstructor` or explicit constructors, so extend whichever is used).
  - Use `LocalDate.now(clock)` for every `LocalDate.now()` / `java.time.LocalDate.now()` in `M/api/DailyRoutineController.java`, `M/api/AIController.java`, `M/service/DailyRoutineService.java` (2 sites), `M/service/aitools/DailyRoutineAiTools.java` (2), `M/service/reflection/ReflectionService.java`, `M/service/GeminiAiChatService.java` (3) and `M/service/reflection/GeminiReflectionAiService.java` (1).
  - Use `LocalDateTime.now(clock)` in `M/api/CronSupportController.java`.
  - Leave `Instant.now()` uses alone (entities, `ChatConversationService`, `UserSettingsService`, `ApiError`, `ReflectionFeedbackService`, `ChatCompactionService`) and `AuthenticationService`, which is handled in T036.

  Verify that `grep -rnE "LocalDate(Time)?\.now\(\)" M` prints nothing and `./gradlew compileJava` passes
- [X] T008 Prove there is no behaviour change: `./gradlew test --tests '*ChatHistoryIntegrationTest' --tests '*ChatCompactionIntegrationTest' --tests '*ReflectionIntegrationTest' --tests '*UserSettingsIntegrationTest' --tests '*ReflectionComparisonServiceTest' --tests '*UserSettingsRegistryTest'` gives 44 tests, all green (same as the 2026-11-22 baseline)

**Checkpoint**: Foundation ready

---

## Phase 3: User Story 1 – Component tests run on the local or production-like database by setting (Priority: P1) 🎯 MVP

**Goal**: One shared component-test foundation (real backend, real sign-in tokens, mock AI, fixed clock) that runs on H2 by default and on Testcontainers Postgres with `-PtestDb=postgres`. It is proven by migrating the settings tests onto it.

**Independent Test**: `./gradlew test --tests '*UserSettingsComponentTest'` and the same with `-PtestDb=postgres` both pass with no code change (quickstart #1–#4, #6).

- [X] T009 [P] [US1] Create `R/application-test.yml` with:
  - `spring.ai.active: false`
  - `spring.ai.google.genai.api-key: test-key-not-used`
  - `spring.jpa.hibernate.ddl-auto: create-drop`
  - `app.scheduling.enabled: false`
  - `app.cors.allowed-origins: http://localhost`

  Don't set `spring.profiles.active`
- [X] T010 [P] [US1] Create `R/application-test-h2.yml` with `spring.datasource.url: jdbc:h2:mem:f008;DB_CLOSE_DELAY=-1`, `driver-class-name: org.h2.Driver`, `username: sa`, `password: ""`, and `spring.jpa.database-platform: org.hibernate.dialect.H2Dialect` (same reason as `application-fast.yml`: H2 rejects `FOR NO KEY UPDATE`)
- [X] T011 [P] [US1] Create `R/application-test-postgres.yml` with only `spring.jpa.database-platform: org.hibernate.dialect.PostgreSQLDialect`. The datasource comes from `@ServiceConnection` (T016)
- [X] T012 [P] [US1] Create `T/support/MutableClock.java`, a `java.time.Clock` subclass:
  - Default instant: 2026-11-18T09:00 in `ZoneId.systemDefault()` (a Wednesday).
  - Methods: `instant()`, `getZone()`, `withZone(ZoneId)` (returns a fixed clock at the current instant), `setToday(LocalDate)` (keeps 09:00), `setInstant(Instant)`, `advance(Duration)` and `reset()` (back to the default).
  - Store the current instant in a `volatile` field
- [X] T013 [P] [US1] Create `T/support/TestDatabaseProfiles.java` implementing `org.springframework.test.context.ActiveProfilesResolver`. Read `System.getProperty("test.db", "h2")`: `h2` returns `{"test","test-h2"}`, `postgres` returns `{"test","test-postgres"}`, anything else throws `IllegalStateException("test.db must be h2 or postgres")`
- [X] T014 [P] [US1] Create the annotation `T/support/RequiresPostgres.java`: `@Target({TYPE, METHOD})`, `@Retention(RUNTIME)`, meta-annotated with `@EnabledIfSystemProperty(named = "test.db", matches = "postgres", disabledReason = "needs -PtestDb=postgres")`
- [X] T015 [P] [US1] Create `T/support/TestUser.java`: `public record TestUser(UUID id, String email, String username, String password, String accessToken)`
- [X] T016 [US1] Create `T/support/TestSupportConfig.java` (`@TestConfiguration(proxyBeanMethods = false)`) with:
  - `@Bean @Primary MutableClock testClock()`
  - `@Bean(name = "taskExecutor") TaskExecutor taskExecutor()` returning `new SyncTaskExecutor()`. This makes `@Async` compaction run inline after commit; it is safe because `compactIfDue` already uses `REQUIRES_NEW` (research R9).
  - A nested `@TestConfiguration(proxyBeanMethods = false) @Profile("test-postgres") static class Postgres` with `@Bean @ServiceConnection PostgreSQLContainer postgres()` returning `new PostgreSQLContainer(DockerImageName.parse("postgres:17"))` (class `org.testcontainers.postgresql.PostgreSQLContainer`).

  Depends on T012
- [X] T017 [US1] Create `T/support/BaseComponentTest.java`, an abstract class:
  - **Annotations**: `@SpringBootTest`, `@AutoConfigureMockMvc` (registers the Spring Security filter chain), `@ActiveProfiles(resolver = TestDatabaseProfiles.class)`, `@Import(TestSupportConfig.class)`.
  - **Fields**: `@Autowired protected MockMvc mvc`, `@Autowired protected MutableClock clock`, `@MockitoSpyBean protected AiChatService aiChatService`, `@MockitoSpyBean protected ChatSummarizer chatSummarizer`, `@MockitoSpyBean protected ReflectionAiService reflectionAi`, and `protected final ObjectMapper json = new ObjectMapper()` (same Jackson type the existing tests use).
  - **`@AfterEach void resetClock()`**: calls `clock.reset()`.
  - **`protected TestUser newUser(String prefix)`**: email `prefix + "-" + UUID.randomUUID().toString().substring(0, 8) + "@example.test"`, password `"Test-pass-123"`.
    - `POST /api/v1/auth/register` with `{email, username, password}`, expecting 201.
    - `POST /api/v1/auth/login` with `{email, password}`, expecting 200.
    - Build the `TestUser` from the login body's `accessToken` and `user.id`.
  - **`protected TestUser newUser()`**: calls `newUser("user")`.
  - **`protected MockHttpServletRequestBuilder as(TestUser u, MockHttpServletRequestBuilder req)`**: adds `Authorization: Bearer <token>`.
  - **`protected String body(Object o)`** and **`protected JsonNode read(ResultActions r)`**: JSON helpers.

  Depends on T013, T015, T016
- [X] T018 [US1] Create `T/unit/TestStructureRulesTest.java` (plain JUnit, no Spring context). Find the classes under the packages `com.tom.payment.routinemanager.component`, `.unit` and `.integration` with Spring's `ClassPathScanningCandidateComponentProvider(false)` plus an accept-all `TypeFilter` (this is a utility, not a context). Fail with the class name when:
  - a non-abstract class in `component` doesn't end in `ComponentTest`, in `integration` doesn't end in `IntegrationTest`, or in `unit` doesn't end in `Test`;
  - a `component` or `integration` class doesn't extend `BaseComponentTest`;
  - a class in these packages is annotated with `@SpringBootTest`, `@ActiveProfiles`, `@TestPropertySource`, `@DirtiesContext`, `@Import` or `@AutoConfigureMockMvc`, or declares a field with `@MockitoBean` / `@MockitoSpyBean`;
  - a `unit` class extends `BaseComponentTest`;
  - there are more than 10 `integration` classes.
- [X] T019 [US1] Create `T/component/UserSettingsComponentTest.java` extending `BaseComponentTest`. It replaces `T/UserSettingsIntegrationTest.java`, with every request using a real token. Use `@Autowired UserSettingRepository` to check or seed rows. Tests:
  1. A new user's GET `/api/v1/users/{id}/settings` returns theme `SYSTEM`, boardZoom `1.0`, empty `customized`, and no rows.
  2. PATCH `{"theme":"dark"}` returns `DARK` with `customized` containing `theme`, and a later GET still shows it.
  3. PATCH boardZoom 1.5 then theme LIGHT keeps both, with 2 customized.
  4. After PATCH theme LIGHT, PATCH `{"theme":"BLUE"}` and PATCH `{}` each return 400, and GET still shows LIGHT, zoom 1.0, `customized == [theme]`.
  5. User A's token on GET and PATCH of a random UUID returns 404.
  6. User B sets DARK. A's token gets 403 on GET and PATCH of B's settings, A's own GET returns 200, and B's theme is still DARK.
  7. GET with no token returns 401.
  8. GET `/profile` returns id, username, email, `plan.code FREE`, `plan.name "Free plan"`, with no `passwordHash` and no `defaultRoutines`.
  9. Profile of a random UUID returns 404; profile of another user returns 403.
  10. A seeded unknown key `fontSize=14` is ignored.
  11. A seeded `boardZoom=banana` falls back to 1.0, is not customized, and PATCH 2.0 fixes it.

  The other invalid-value variations move to unit tests (T032)
- [X] T020 [US1] Delete `T/UserSettingsIntegrationTest.java` once T019 passes with both `./gradlew test --tests '*UserSettingsComponentTest'` and `-PtestDb=postgres`
- [X] T021 [US1] Checkpoint, running **NEW**:
  - With default H2, and with `-PtestDb=postgres` (Docker on).
  - With Docker stopped and `-PtestDb=postgres`: must fail with "Could not find a valid Docker environment" (quickstart #3).
  - `env -u GEMINI_API_KEY ./gradlew test --tests '*UserSettingsComponentTest'` must pass (quickstart #6).

  If #6 fails, fix only `R/application-test.yml` (for example, exclude the Google GenAI auto-configuration there) and note it in `F/research.md` R3

**Checkpoint**: The foundation works on both databases; MVP reached

---

## Phase 4: User Story 3 – Each test sits at the right level (Priority: P2)

**Goal**: Core business rules live in storage-free code and are covered by fast unit tests for all their edge cases (research R12).

**Independent Test**: `./gradlew test --tests 'com.tom.payment.routinemanager.unit.*'` passes in under 10 s of test time, with no Spring context and no mocks of storage.

### Rule extraction (behaviour-neutral; depends on T007)

- [X] T022 [P] [US3] Create `M/funcs/DayRules.java`: a `final` class with a private constructor, `public static boolean isPast(LocalDate date, LocalDate today)` (`date.isBefore(today)`) and `public static boolean isFuture(LocalDate date, LocalDate today)` (`date.isAfter(today)`). Replace the inline comparisons with `today = LocalDate.now(clock)`:
  - `isFuture` in `M/api/AIController.java` (~line 150) and `M/service/reflection/ReflectionService.java` (~line 240);
  - `isPast` in `M/service/aitools/DailyRoutineAiTools.java` (~lines 49 and 88) and `M/service/GeminiAiChatService.java` (~line 85).

  Don't change `DailyRoutineService`'s `isEqual` check
- [X] T023 [P] [US3] Create `M/funcs/RoutineTemplateRules.java` with `public static DefaultRoutine.RoutineTypeEnum templateTypeFor(LocalDate date, boolean weekendRoutineHasTasks)`: returns `WEEKEND` when the day is Saturday or Sunday and the flag is true, otherwise `DAILY`.

  Rewrite `DefaultRoutineService.resolveTemplateFor(User, LocalDate)` in `M/service/DefaultRoutineService.java` to keep the exact behaviour:
  - On weekends only, look up the WEEKEND routine filtered to non-empty tasks.
  - Pass its presence to `templateTypeFor`.
  - Return that routine when the result is `WEEKEND`; otherwise return the DAILY routine or the same `ResponseStatusException(NOT_FOUND, "Default routine not found for user")`
- [X] T024 [P] [US3] Add two methods to the record `M/config/ChatHistoryProperties.java`:
  - `public int pageSizeFor(Integer requested)`: `Math.max(1, Math.min(requested == null ? historyPageSize : requested, historyPageSize))`. Use it in `ChatConversationService.getHistory` (`M/service/chat/ChatConversationService.java`, ~line 148).
  - `public boolean compactionDue(long messagesPastCursor)`: `messagesPastCursor >= compactionThreshold`. Use it in `ChatCompactionService.compactIfDue` (`M/service/chat/ChatCompactionService.java`, ~line 81) so the condition becomes `c == null || !properties.compactionDue(c.getLastMessageSeq() - c.getSummarizedThroughSeq())`.
- [X] T025 [US3] Prove T022–T024 changed no behaviour: rerun the T008 selection plus `--tests '*UserSettingsComponentTest' --tests '*RoutineServiceIntegrationTest'` (the latter against the T002-style throwaway Postgres), all green

### Unit tests (each file independent)

- [X] T026 [P] [US3] Create `T/unit/DayRulesTest.java`:
  - With today = 2026-11-18: yesterday is past and not future; today is neither; tomorrow is future and not past.
  - Year boundary, with today = 2027-01-01: 2026-12-31 is past.
- [X] T027 [P] [US3] Create `T/unit/RoutineTemplateRulesTest.java`:
  - 2026-11-16 to 2026-11-20 (Mon–Fri) give DAILY whether the flag is true or false.
  - 2026-11-21 and 2026-11-22 (Sat, Sun) give WEEKEND with the flag true, and DAILY with it false.

  This replaces the 4 `resolveTemplateFor…` cases of `RoutineServiceIntegrationTest`
- [X] T028 [P] [US3] Create `T/unit/ChatHistoryPropertiesTest.java` with `new ChatHistoryProperties(4, 20)` and nulls:
  - Null arguments default to threshold 20 and page size 20.
  - Threshold 1 and page size 0 throw `IllegalArgumentException`.
  - `pageSizeFor`: null → 20, 0 → 1, -5 → 1, 5 → 5, 500 → 20.
  - `compactionDue`: 3 → false, 4 → true, 10 → true (threshold 4).
- [X] T029 [P] [US3] Create `T/unit/TaskColorServiceTest.java`. Build `TaskPaletteProperties` directly with the 8 `PaletteColor(id, label, Shade, Shade)` entries in this order:
  - green/Green, orange/Orange, blue/Blue, grey/Grey, slate/Slate, peach/Peach, pink/Pink, purple/Purple
  - any valid hex values

  Create `new TaskColorService(palette)` (check its constructor first), and drive `assign(int cursor, List<T>, getName, getColor, setColor)` with a tiny local `record`/class task. Cases come from `T/TaskColorIntegrationTest.java` US1:
  1. 10 colourless tasks in separate calls give the 8 ids then green, orange, and the cursor ends at "blue".
  2. Pre-selected `green` at cursor 0 is kept and advances.
  3. `pink` at cursor 1 is kept and doesn't advance.
  4. `#FF0000` is kept and doesn't advance.
  5. In one call, "Sleep", " sleep " and "Read" give green, green, orange.
  6. `requireValid("gold")` throws `ResponseStatusException` with 400.
  7. `paletteIdFor("Purple")` → `purple`; `paletteIdFor("#ff0000")` and `paletteIdFor("gold")` → empty.
  8. `unknownColorMessage("gold")` contains "Available colors:" and all 8 labels.
- [X] T030 [P] [US3] Create `T/unit/TaskTimeFunctionsTest.java`. Read `M/funcs/TaskTimeFunctions.java` first and assert its **current** behaviour:
  - `standardiseTasks`: inserting 09:30/30 into an existing 09:00/60 moves the existing task to 10:00 and keeps 60 min; a non-overlapping task is untouched; a chain of two following tasks shifts in order.
  - The same three cases for `shiftOverlappingTasks` with `DailyTask`.
- [X] T031 [P] [US3] Move `T/ReflectionComparisonServiceTest.java` to `T/unit/ReflectionComparisonServiceTest.java`. Change only the package line and the imports; the 6 tests stay as they are
- [X] T032 [P] [US3] Create `T/unit/UserSettingsRegistryTest.java` to replace `T/service/UserSettingsRegistryTest.java`, which you then delete. There is no Mockito and no `UserSettingsService`. Keep the registry-only assertions:
  - `keys() == [theme, boardZoom]`, the defaults, `parse("theme"," light ") == "LIGHT"`, `parse("boardZoom",1.25) == "1.25"`, `isValidStored("boardZoom","3.0")`, an unknown key throws.
  - The extension case: a registry built from `builtIns()` plus `compactMode` has key order `[theme, boardZoom, compactMode]`, `parse("compactMode", true) == "true"`, and `"yes"` throws.

  Add the variations moved from component level: `parse` throws `IllegalArgumentException` for theme `"BLUE"`, theme `3`, boardZoom `0.25`, `3.25`, `1.1` and `"1.5"` (a string); `isValidStored("boardZoom","banana")` is false
- [X] T033 [P] [US3] Create `T/unit/TaskPaletteContrastTest.java` to replace `T/TaskPaletteContrastTest.java`, which you then delete. Load `B/src/main/resources/application.yml` with `new YamlPropertySourceLoader().load("app", new ClassPathResource("application.yml"))`, then bind `"app.task-palette"` to `TaskPaletteProperties` with `new Binder(ConfigurationPropertySources.from(sources))`; there is no application context. Keep the WCAG maths and the ≥ 4.5 assertions for light (`#1F2937`) and dark (`#E6EBF2`) text on every palette background
- [X] T034 [US3] Checkpoint: `./gradlew test --tests 'com.tom.payment.routinemanager.unit.*'` is green. `build/reports/tests/test/index.html` shows a unit total under 10 s (quickstart #8)

**Checkpoint**: All core rules are unit-tested without Spring or mocked storage

---

## Phase 5: User Story 5 – Core journeys covered, and sign-in refuses bad input properly (Priority: P2)

**Goal**: Component tests for sign-in, default routines and daily routines, plus the FR-018 fix (contract: [contracts/sign-in-errors.md](contracts/sign-in-errors.md)).

**Independent Test**: `./gradlew test --tests '*SignInComponentTest' --tests '*DefaultRoutineComponentTest' --tests '*DailyRoutineComponentTest' --tests '*JwtSecurityIntegrationTest'` is green on both databases, and no sign-in refusal returns 500.

### Failing tests first (FR-018)

- [X] T035 [US5] Create `T/component/SignInComponentTest.java`, one test per row of `F/contracts/sign-in-errors.md`, plus the success paths. Use `@Autowired UserRepository` and `RefreshTokenRepository` for checks and seeding.
  - **Success paths**:
    1. Register returns 201 with `userId`, `email` and `userName`, and `UserRepository.findByEmail` finds the user.
    2. Login returns 200 with a non-blank `accessToken` and `user.id`, and a `Set-Cookie` for `refresh_token` that is HttpOnly with path `/api/v1/auth/refresh`.
    3. `POST /refresh` with that cookie returns 200 and a non-blank `accessToken`.
    4. `POST /logout` returns 200 with a `refresh_token` cookie that has Max-Age 0.
  - **Refusals**:
    1. Login with an unknown email returns 401 and message `Invalid email or password.`
    2. Login with a wrong password returns a body whose `status`, `error` and `message` are identical to the unknown-email case.
    3. Registering a duplicate email returns 409 with message `An account with this email already exists.`, and there is still exactly one user with that email.
    4. Refresh with no cookie returns 401 with `Refresh token not found`.
    5. Refresh with an unknown cookie value returns 401 with `Your session has expired. Please sign in again.`
    6. A revoked token (log in, load it with `findByTokenVal`, `setIsRevoked(true)`, save) gives 401 with the same message.
    7. An expired token (log in, then `clock.advance(Duration.ofDays(8))`) gives 401 with the same message.
    8. A token whose user doesn't exist (save a `RefreshToken` with a random `userId` and a future expiry from `clock.instant()`) gives 401 with the same message.
  - **Hygiene**: no response body contains the email address or `Exception`.

  Run it and confirm the refusal tests fail with 500 before T036
- [X] T036 [US5] Fix `M/service/AuthenticationService.java` (and the refresh-token handling it calls):
  - Inject `Clock`.
  - Unknown email and wrong password throw `new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid email or password.")`.
  - A duplicate email in `register` throws `new ResponseStatusException(HttpStatus.CONFLICT, "An account with this email already exists.")`.
  - Unknown, revoked or expired refresh tokens, and a missing user, throw `new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Your session has expired. Please sign in again.")`.
  - Use `clock.instant()` both when computing the refresh-token expiry in `login` and when checking it in `refresh`. **Keep** `accessTokenExpiration` as the duration (that bug is filed in T058), and don't change how access JWTs are generated.
  - Don't touch `GlobalExceptionHandler`. Its `ResponseStatusException` handler already gives the `ApiError` body.
- [X] T037 [US5] Run `./gradlew test --tests '*SignInComponentTest'` on H2 and on Postgres: all green
- [X] T038 [P] [US5] Create `T/integration/JwtSecurityIntegrationTest.java` (extends `BaseComponentTest`; it is the "security setup" connection). Use the protected endpoint `GET /api/v1/users/{id}/settings` of `newUser()`:
  - A valid token gives 200.
  - No `Authorization` header gives 401.
  - `Bearer garbage` gives 401.
  - The valid token with its last character changed gives 401.
  - A token for the same email signed by another key (`Jwts.builder().subject(id).claim("email", email).signWith(Jwts.SIG.HS256.key().build()).compact()`) gives 401.
  - `Basic dXNlcjpwYXNz` gives 401.

  If any case returns 500, stop and report it as a finding. Don't change `JwtAuthenticationFilter` in F008; file it with T058

  **Outcome (2026-11-23):** garbage, tampered and foreign-signed tokens returned 500 (the JWT exception escaped the filter). The user chose to fix it in F008 (spec Clarifications, FR-018 widened). `M/config/JwtAuthenticationFilter.java` now catches `JwtException` / `IllegalArgumentException` and continues unauthenticated, so the request gets 401. All 6 cases pass.

### Journey tests

- [X] T039 [P] [US5] Create `T/component/DefaultRoutineComponentTest.java`, everything through `/api/v1/default-routine` with a real token:
  1. GET `/users/{id}` returns the DAILY routine "Weekday Routine" with 0 tasks.
  2. POST `/{routineId}/tasks` with a list of 2 tasks (07:00/15, 08:00/30) returns 200 with ids and computed `endTime`; a later GET shows 2 tasks.
  3. **Overlap (one representative case)**: an existing 09:00/60 plus a new 09:30/30 moves the existing task to 10:00.
  4. PUT `/tasks` renames a task; GET shows the new name.
  5. DELETE `/tasks?taskIds=<a>&taskIds=<b>` returns 204, and GET shows 0 tasks.
  6. PUT `/{id}` with name "Updated Name" and one task replaces both.
  7. POST `/{routineId}/tasks` with `"color":"gold"` returns 400.
  8. GET with no token returns 401.

  Don't assert anything about another user's access (a bug is filed for it, research R6)
- [X] T040 [P] [US5] Create `T/component/DailyRoutineComponentTest.java`. The clock is Wed 2026-11-18. Set up weekday tasks "Morning Coffee" 08:00/15 through the default-routine API.
  1. GET `/api/routine-manager/daily-routine/{userId}` (no date) returns today's routine with "Morning Coffee", `completed=false`, and the row persisted (`DailyRoutineRepository.findByUserAndDate`).
  2. GET `?date=2026-11-25` returns a routine with no tasks, and no row exists for that date.
  3. **Template choice (one representative case)**: after adding weekend tasks "Long run" and "Brunch" to the WEEKEND routine (GET `?type=WEEKEND`, then POST tasks), POST `/daily-routine/{userId}?date=2026-11-21` returns tasks in the order [Long run, Brunch].
  4. POST `/daily-routine/{routineId}/tasks` adds 2 tasks; PUT `/daily-routine/tasks` sets `completed=true` on one and renames it, and the stored values match; DELETE `/daily-routine/tasks?taskIds=…` returns 204 and the tasks are gone.
  5. **Past-day freeze**: read `M/service/aitools/DailyRoutineAiTools.java` first. For date 2026-11-17, `updateDailyTasks` with a new start time is refused and the stored start time is unchanged, while a name-only change succeeds. `@Autowired` the tools bean in the test.
  6. GET with no token returns 401.
- [X] T041 [US5] Checkpoint: **NEW** is green on H2 and on Postgres. Quickstart #10 and #11 (manual: wrong-password message shown in the UI)

**Checkpoint**: Sign-in is fixed; the three missing journeys are covered

---

## Phase 6: User Story 4 – Existing tests migrated without losing coverage (Priority: P2)

**Goal**: Every remaining old class is rebuilt on the foundation (data-model §4) and then deleted.

**Independent Test**: No test classes remain outside `component/`, `unit/`, `integration/` and `support/`. Full `./gradlew test` and `-PtestDb=postgres` are green with one Spring context (quickstart #5), and every behaviour in the data-model §4 table maps to a passing test.

- [X] T042 [P] [US4] Create `T/component/OnboardingComponentTest.java` to replace `T/apptest/OnboardingRoutineTest.java`, which you then delete:
  1. `newUser()` (registration) leaves 2 default routines in `DefaultRoutineRepository` for the user; GET `?type=DAILY` returns "Weekday Routine" (DAILY, 0 tasks) and `?type=WEEKEND` returns "Weekend Routine" (WEEKEND, 0 tasks).
  2. **Legacy user**: register, then delete the WEEKEND routine with the repository. Two GETs of `?type=WEEKEND` return the same id with 0 tasks.
  3. No `type` returns DAILY.
  4. `type=FOO` returns 400.
  5. No token returns 401.

  The 2 old tests that called removed endpoints are dropped; their intent is covered by T039
- [X] T043 [P] [US4] Create `T/component/TaskColorComponentTest.java` to replace `T/TaskColorIntegrationTest.java`, which you then delete. Everything goes through the API unless noted:
  1. The first created task with no colour is `green`, and the routine's `nextColor` becomes `orange`.
  2. GET of the routine shows `nextColor` and no `colorCursor`.
  3. PUT `/api/v1/default-routine/tasks` with `pink`, then `#AA3300`, is stored; `gold` gives 400 and the stored value stays `#AA3300`. The same for `/api/routine-manager/daily-routine/tasks` with `purple` and `gold`.
  4. GET `/api/v1/task-palette` returns 8 colours in the order green, orange, blue, grey, slate, peach, pink, purple, with `colors[0].light.accent == "#10A36B"` and `colors[0].dark.bg == "#1B3836"`.
  5. A new weekday (POST `/daily-routine/{userId}?date=2026-11-25`) copies the template's colours and continues its `nextColor`. Recolouring the template afterwards leaves that day unchanged.
  6. With the weekday template holding Gym 07:00 and Rest 12:00 (no colours), `POST /api/support/cron/spawn-daily-task` (with a token) gives today's routine colours [green, orange] by start time and `nextColor` blue.
  7. **Buddy tools** (`@Autowired DefaultRoutineAiTools`, `DailyRoutineAiTools`; direct calls allowed by the spec): `"Purple"` is stored as `purple`. `#ff0000` and `gold` get a reply containing "Available colors:" and all 8 labels, and the stored colour is unchanged. Daily-tool `addDailyTasks` with `pink` replies "Successfully…"; with `gold` it lists the palette.

  The round-robin variations live in T029
- [X] T044 [P] [US4] Create `T/component/ChatHistoryComponentTest.java` to replace `T/ChatHistoryIntegrationTest.java`, which you then delete. Port all 10 tests with real tokens and the base `aiChatService` spy, keeping `DAY = 2026-11-21`:
  - Empty history creates no row.
  - Exchanges are stored in order (seq 1..6, user/assistant alternating, no `summary` field).
  - Conversations are separate per date and per routine.
  - A blank message gives 400 and nothing is stored; a missing date gives 400.
  - An unknown user gives 404 (A's token, random UUID).
  - Another user's routine gives 404 (A's token, B's routine id).
  - The second message gets the first exchange as context (ArgumentCaptor on `defaultRoutineChat`).
  - A failed AI call (`doThrow` on `dailyRoutineChat`) gives 5xx and nothing is stored.
  - Paging: 15 exchanges give a newest page of seq 11..30 with `hasMore`, `nextBefore` 11; `?before=11` gives 1..10 with no more; `?limit=5&before=11` gives 6..10. Clamping edge cases are covered in T028.
- [X] T045 [P] [US4] Create `T/component/ChatCompactionComponentTest.java` to replace `T/ChatCompactionIntegrationTest.java`, which you then delete. Use the default threshold of 20 and the synchronous executor; there is **no** `Thread.sleep` and no polling.
  - **Compaction**: send 10 daily exchanges for 2026-11-21, the first being "I prefer workouts in the morning". Right after that, the conversation (read through `ChatConversationService.findDailyConversation`) has `summarizedThroughSeq == 20` and summary text containing that sentence. History returns 20 messages and the raw body has no "summary". The next send's captured `ChatContext` has a non-null summary and 0 recent messages; the one after has 2.
  - **Failure**: `doThrow` on `chatSummarizer.summarize(any(), anyList())`. After 10 exchanges, `summarizedThroughSeq == 0`, the summary is null, and there was exactly 1 summarize call. After the 11th exchange there are ≥ 2 calls, the cursor is still 0, and history shows 22 messages.
- [X] T046 [P] [US4] Create `T/component/ReflectionComponentTest.java` to replace `T/ReflectionIntegrationTest.java`, which you then delete. Port all 14 tests with real tokens:
  - TODAY is `LocalDate.now(clock)` (2026-11-18), tomorrow is 2026-11-19, and the past day is 2026-11-15.
  - Seed the plan through the API (POST `/api/routine-manager/daily-routine/{userId}?date=` then POST `/daily-routine/{routineId}/tasks`).
  - Read the plan with `DailyRoutineRepository` inside an `@Autowired TransactionTemplate`.
  - Use the base `reflectionAi` spy for the 503 case.
  - Keep the 5 ms pause before the "stale" edit, because the timestamps come from entity `Instant.now()`.
  - The "another user's reflection task" case uses user B's own token on B's base URL with A's task id, expecting 404.
- [X] T047 [US4] Create `T/integration/ChatSequenceLockingIntegrationTest.java`, annotated `@RequiresPostgres` and extending `BaseComponentTest`. For one user and date 2026-11-21, send 8 daily chat messages concurrently from 8 threads (an `ExecutorService` with a start latch, each `mvc.perform(...)` expecting 200). History then holds 16 messages with seq exactly 1..16, no duplicates or gaps. On H2 the report shows it as skipped
- [X] T062 [US4] Fix FR-019 (found by T047 on Postgres: concurrent messages all got seq 3 → 500 on the `ux_chat_message_seq` unique constraint). Cause: with open-in-view on (the `test` profile the EC2 backend runs), `findByIdForUpdate` takes the row lock but returns the conversation already cached in the request's persistence context. Fix in `M/service/chat/ChatConversationService.java` `appendExchange`: inject `EntityManager` and call `entityManager.refresh(c)` right after the locking query. T047 failed before the fix and passes after it. The test profile keeps open-in-view at its default (spec Clarifications, T047 bullet)
- [X] T063 [US5] FR-020 (from `/code-review` finding 3; owner decision 2026-11-23: check the body shape, no RFC 9457). Add `error(HttpStatus)` to `S/BaseComponentTest.java` (status + exact `ApiError` fields + reason phrase + non-blank message + ISO timestamp); replace all 57 bare refusal checks in `component/` and `integration/`; add `refusalsAreCheckedWithTheErrorBodyShape` to `unit/TestStructureRulesTest.java` (fails on a bare `status().isXxx()` refusal, checked by temporarily adding one). Fix found by the new check: `M/config/SecurityConfig.java` entry point wrote an empty 401, now writes `ApiError` ("Please sign in to continue.") with the app's `JsonMapper`. Constitution 2.0.0 Principle I: `ApiError` is the one error format; Principle II: refusal checks include the body shape. 136 tests pass on H2 and Postgres
- [X] T048 [US4] Delete `T/RoutineServiceIntegrationTest.java` (covered by T027, T030, T039, T040) and `T/RoutinemanagerApplicationTests.java`, then remove the now-empty `T/apptest/` and `T/service/` folders. `find B/src/test/java -name '*.java'` must list only files under `support/`, `component/`, `unit/` and `integration/`
- [X] T049 [US4] Tighten `T/unit/TestStructureRulesTest.java` (T018). Also scan the whole `com.tom.payment.routinemanager` test package and fail for any test class outside `component`, `unit`, `integration` and `support`. Run the full `./gradlew test` and `./gradlew test -PtestDb=postgres`; both green. Quickstart #5: exactly 1 "Started … in … seconds" line per run
- [X] T050 [US4] Coverage walk (FR-009, quickstart #13): for each row of `F/data-model.md` §4, find the new test(s) covering every behaviour listed for the old class. Add any missing test before continuing, and note the outcome under §4 as "Verified <date>"

**Checkpoint**: The old suite is gone; nothing is lost; one context per run

---

## Phase 7: User Story 2 – Deployment is blocked when tests fail (Priority: P1)

**Goal**: CI runs the full suite on Testcontainers Postgres before building the image; a failure stops the push and deploy.

**Independent Test**: A PR with one deliberately failing assertion makes the workflow fail at the build step; no ECR push or EC2 deploy runs; a test-report artifact is attached (quickstart #12).

**Depends on**: Phase 6 (old classes needed the dev DB and the Gemini key)

- [X] T051 [US2] Edit `B/.github/workflows/gradle-publish.yml`:
  - In step "Build with Gradle", replace `./gradlew clean build -x test` with `./gradlew clean build -PtestDb=postgres`.
  - Right after it, add a step "Upload test report" with `if: failure()`, `uses: actions/upload-artifact@v4`, and `with: { name: test-report, path: build/reports/tests/test }`. (Pinned by tag like the workflow's other actions. SHA pinning, constitution VII, is a deferred known gap while CI/CD waits; see the plan's Follow-ups.)
  - Don't add `GEMINI_API_KEY` to the job, and don't change triggers or later steps.
- [ ] T052 [US2] **Deferred (2026-11-23): the project is in a local phase and CI/CD is not set up yet, for cost.** Do this when CI/CD resumes. Prove the gate (quickstart #12). **Ask the user before pushing.** Push the branch, open a draft PR to `main` with one extra commit that breaks an assertion in `T/unit/DayRulesTest.java`, and confirm the build fails, the push and deploy steps are skipped, and the `test-report` artifact exists. Then revert that commit and confirm the workflow goes green

**Checkpoint**: Failing tests can no longer reach production

---

## Phase 8: User Story 6 – The rules are written down once and agree everywhere (Priority: P3)

**Goal**: The constitution, the backend guide, the bug-fix template and the flow map use the same three test kinds and commands.

**Independent Test**: Quickstart #14: reading the four documents side by side shows no contradiction, only `./gradlew` commands, and no "No H2" or Redis.

- [X] T053 [US6] Run `/speckit-constitution` to amend `.specify/memory/constitution.md` Principle II per `F/research.md` R15:
  - **Backend rules**: component tests cover main user flows through the API with real sign-in, mock AI and an injected Clock; unit tests cover core business rules and their edge cases, with no Spring and no mocked storage; integration tests (≤ 10) only check external connections.
  - **Databases and pipeline**: H2 only for local component runs; CI runs everything on PostgreSQL via Testcontainers; every bug fix starts with a failing component or unit test.
  - Keep the frontend bullets.
  - Version 1.0.0 → **2.0.0**; update the Sync Impact Report (remove the "CI -x test / no Testcontainers / H2" gap, add the routine-ownership gap) and the "Last Amended" date.
- [X] T054 [P] [US6] Rewrite `B/CLAUDE.md` from `F/contracts/test-harness.md`:
  - **Testing strategy**: replace "Testing Strategy (Integration-First Trophy)" with a "Testing strategy" section covering the three kinds, where each lives, the naming, the base class, what is allowed, the commands, and the bug-fix rule. Drop "No H2", Redis, `./mvnw` and "Keep Unit Tests Minimal".
  - **Commands block**: update the test commands, including `-PtestDb=postgres`.
  - **Profile table**: add rows for `test`, `test-h2` and `test-postgres`.
  - **Auth flow**: say that the JWT filter is active in the `test` profile.
  - **Deployment**: replace "Tests are skipped in CI (-x test)" with the new gate.
  - **"Rules for new code → Tests" bullet**: update it.
  - **Flow map**: point the "Flow map" line to `docs/test-flows.md`.
- [X] T055 [P] [US6] Update `.specify/templates/bugfix-template.md` (read it first). The reproduction step requires a failing **component test** for a bug in a user flow or a **unit test** for a bug in a core business rule, written before any production change, with the `./gradlew test --tests '<Class>'` command
- [X] T056 [P] [US6] Rename `B/docs/integration-test-flows.md` to `B/docs/test-flows.md` with `git mv` and rewrite it for the new suite:
  - Main flows → component test classes (success path and refusals covered).
  - Core rules → unit test classes.
  - Connections → integration tests.
  - The updated endpoint coverage table: auth is now ✅; routine endpoints are ✅ for HTTP, with the ownership gap noted.
  - How to run each kind.
  - The "last verified" date and commit.
- [X] T057 [P] [US6] Update the testing references in the root `CLAUDE.md` (the "Working across both projects" and "Engineering standards" sections) if they mention backend test rules or commands. Otherwise leave it unchanged and note "no change" in this task
- [X] T058 [P] [US6] File the bugs found during F008 in `AI-project-docs/bugs/` (`bug-0001.MD` is an empty placeholder, so use the bug-fix template's sections). Six were filed:
  - `bug-0002.MD`: routine endpoints in `DefaultRoutineController` / `DailyRoutineController` don't check that the routine, task or `userId` belongs to the caller (research R6).
  - `bug-0003.MD`: `AuthenticationService.login` saves the refresh-token expiry with `accessTokenExpiration` (15 min) instead of `refreshTokenExpiration` (7 days).
  - `bug-0004.MD`: `POST /api/v1/auth/logout` doesn't revoke the stored refresh token.

  - `bug-0005.MD`: Buddy's update/delete tools read lazy task lists without a transaction (found in T040).
  - `bug-0006.MD`: the `prod` profile (open-in-view off) can't serialise routine entities, so every routine read is a 500 (found in T047).
  - `bug-0007.MD`: the deployed `test` profile exposes the cron support endpoint, and the CI deploy step sets no profile (found in T047).

  The 500 found in T038 was fixed in F008 instead of being filed (see T038 Outcome).

**Checkpoint**: The documentation matches the code

---

## Phase 9: Polish & Cross-Cutting Concerns

- [X] T059 Run quickstart #1–#14 and add a "Validation results (<date>)" section at the end of `F/quickstart.md` with pass/fail and the measured times (full suite H2, full suite Postgres, one class, unit total)
- [X] T060 Add an "After F008" row to the R16 table in `F/research.md`: number of classes and tests per kind, runtimes on H2 and Postgres, and the context count
- [X] T061 Run `/speckit-analyze` for spec/plan/tasks consistency, then `/code-review` on the backend branch. Fix the findings before asking the user to commit

---

## Dependencies & Execution Order

### Phase dependencies

| Phase | Depends on | Blocks |
|---|---|---|
| 1 Setup (T001–T004) | — | everything |
| 2 Foundational (T005–T008) | T001 | all stories |
| 3 US1 foundation (T009–T021) | Phase 2, T003, T004 | US3, US5, US4, US2 |
| 4 US3 rules + unit (T022–T034) | Phase 2 (T007), T018 | US4 (T048 deletes classes US3 replaces) |
| 5 US5 journeys + sign-in (T035–T041) | US1 | US4 (T048) |
| 6 US4 migration (T042–T050) | US1, US3, US5 | US2 |
| 7 US2 pipeline (T051–T052) | US4 | — |
| 8 US6 docs (T053–T058) | US3, US4, US5 (describes the final suite) | Polish |
| 9 Polish (T059–T061) | all | — |

### Story notes

- **US1** is the MVP: everything else builds on `BaseComponentTest`.
- **US3 and US5** can run in parallel after US1. US3 changes production rule code; US5 changes `AuthenticationService`. They touch no shared files.
- **US2** is P1 but must come after US4: switching the gate on earlier would fail CI on the old classes, which need the dev database and the Gemini key.

### Within phases

- T035 (failing tests) → T036 (fix) → T037 (green). Never reverse.
- T022–T024 (extraction) → T025 (proof of no change) → unit tests T026–T030 may start as soon as their rule exists.
- Each old class is deleted only after its replacement is green on **both** databases.

---

## Parallel Examples

### US1

```text
T009 application-test.yml   | T010 application-test-h2.yml | T011 application-test-postgres.yml
T012 MutableClock           | T013 TestDatabaseProfiles    | T014 RequiresPostgres | T015 TestUser
→ then T016 → T017 → T018/T019 (sequential)
```

### US3

```text
T022 DayRules | T023 RoutineTemplateRules | T024 ChatHistoryProperties   (different files)
→ T025
T026 | T027 | T028 | T029 | T030 | T031 | T032 | T033                      (one test file each)
```

### US5 / US4

```text
US5: T038 JwtSecurityIntegrationTest | T039 DefaultRoutineComponentTest | T040 DailyRoutineComponentTest
US4: T042 Onboarding | T043 TaskColor | T044 ChatHistory | T045 ChatCompaction | T046 Reflection
```

---

## Implementation Strategy

### MVP first (US1)

1. Phases 1–2 (setup, clock, scheduling switch).
2. Phase 3: the foundation and the settings tests on both databases.
3. **Stop and validate**: quickstart #1–#4 and #6. This already proves the H2/Postgres switch and real-token component tests.

### Incremental delivery

1. US3: rules extracted, fast unit tests.
2. US5: sign-in fixed (the only behaviour change), journeys covered.
3. US4: the old suite replaced, nothing lost, one context.
4. US2: CI gate on (needs the user's go-ahead to push).
5. US6 and Polish: docs, constitution v2.0.0, validation, review.

### Commit guidance

Commit only when the user asks. Suggested commit points (Conventional Commits) are one per phase checkpoint: `test:` for test-only phases, `fix(auth):` for T036, `refactor:` for T005–T007 and T022–T024, `ci:` for T051, `docs:` for Phase 8. Each commit ends with the attribution line required by the session.

---

## Notes

- [P] means a different file with no dependency on an incomplete task.
- Repository use in component tests is limited to **checking** stored state and **seeding** states the API can't create (legacy user, revoked or orphan refresh token, corrupt setting row).
- Mocks and spies are only the three AI-boundary spies in `BaseComponentTest`. Nothing else is mocked.
- If a task reveals behaviour that contradicts this list (for example, a 500 from the JWT filter), stop, report it, and file a bug instead of changing production behaviour outside FR-018.
