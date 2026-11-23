# Contract: Backend test harness

This is the developer-facing interface of the test suite: commands, switches, naming and pipeline behaviour. The backend `CLAUDE.md` testing section is rewritten from this file (FR-014).

## Commands (run in `ms-personal-routine-manager/`)

| Purpose | Command |
|---|---|
| Full suite, local default (H2, no Docker) | `./gradlew test` |
| Full suite on Postgres (Docker required) | `./gradlew test -PtestDb=postgres` |
| One class while working | `./gradlew test --tests '*DailyRoutineComponentTest'` |
| One class on Postgres | `./gradlew test -PtestDb=postgres --tests '*ChatSequenceLockingIntegrationTest'` |
| Only unit tests | `./gradlew test --tests 'com.tom.payment.routinemanager.unit.*'` |
| Only component tests | `./gradlew test --tests 'com.tom.payment.routinemanager.component.*'` |
| What CI runs | `./gradlew clean build -PtestDb=postgres` |

`TEST_DB=postgres` (env) is equivalent to `-PtestDb=postgres`. Any other value than `h2` or `postgres` fails the build with a message listing the allowed values.

## Behaviour guarantees

| Situation | Result |
|---|---|
| `testDb=h2` | All component, unit and integration tests run; `@RequiresPostgres` tests are reported **skipped** |
| `testDb=postgres` | Everything runs against one `postgres:17` container per run |
| `testDb=postgres`, no Docker | The run fails at start-up ("Could not find a valid Docker environment"); never falls back to H2 |
| `GEMINI_API_KEY` unset | Tests still start and pass (mock AI) |
| Docker via Colima (macOS) | Set `DOCKER_HOST=unix://$HOME/.colima/default/docker.sock` and `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock`, or Testcontainers can't find Docker |
| Any run | No live AI call; dates come from the test clock (Wed 2026-11-18 09:00 unless a test changes it) |

## Writing a test

| Kind | Location / name | Extends | Allowed | Not allowed |
|---|---|---|---|---|
| Component | `component/<Flow>ComponentTest` | `BaseComponentTest` | API calls with `newUser()` tokens; repositories to check state or seed what the API can't create; AI spies for failures; `clock` | Calling services in place of API routes (except Buddy tool entry points); repeating a rule's edge-case variations; any Spring test annotation |
| Unit | `unit/<Rule>Test` | nothing | Plain JUnit 5 + AssertJ on one rule | Spring context, database, mocked storage |
| Integration | `integration/<Connection>IntegrationTest` | `BaseComponentTest` | `@RequiresPostgres` for Postgres-only behaviour | More than 10 in the suite |

**Refusals:** check every 4xx/5xx with `andExpect(error(HttpStatus.X))` from `BaseComponentTest`. It checks the status and the whole `ApiError` body: JSON with exactly `status`, `error` (reason phrase), a non-blank `message` and an ISO-8601 `timestamp`. A bare `status().isNotFound()` in a component or integration test fails `TestStructureRulesTest` (FR-020). Check the message text separately where the flow promises one.

Bug fixes start with the failing test of the right kind: a component test for a flow bug, a unit test for a rule bug.

## Pipeline (`.github/workflows/gradle-publish.yml`)

| Trigger | Step | On test failure |
|---|---|---|
| Push to `main`, PR to `main` | `./gradlew clean build -PtestDb=postgres` | Job fails; the image build, ECR push and EC2 deploy steps don't run; test reports are uploaded as an artifact |
