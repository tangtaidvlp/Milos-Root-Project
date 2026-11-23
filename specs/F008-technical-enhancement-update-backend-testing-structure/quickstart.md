# Quickstart: validating F008

Run the backend commands in `ms-personal-routine-manager/`. Commands and naming are in [contracts/test-harness.md](contracts/test-harness.md), and sign-in responses in [contracts/sign-in-errors.md](contracts/sign-in-errors.md).

## Prerequisites

- JDK 25 (Gradle toolchain).
- Docker running, for the Postgres scenarios only.

## Scenarios

| # | Proves | Steps | Expected |
|---|---|---|---|
| 1 | Local default needs nothing (US1-1, SC-003) | Stop Docker. `time ./gradlew test` | Passes in under 3 min. `@RequiresPostgres` tests show as skipped in `build/reports/tests/test/index.html` |
| 2 | Same tests on Postgres, no code edits (US1-2, SC-002, SC-006) | Start Docker. `./gradlew test -PtestDb=postgres` | Passes. The log shows one `postgres:17` container start. Skipped count is 0 |
| 3 | No silent fallback (FR-003) | Stop Docker. `./gradlew test -PtestDb=postgres` | Fails at start-up with "Could not find a valid Docker environment"; no test passes on H2 |
| 4 | Bad switch value is refused | `./gradlew test -PtestDb=mysql` | Build fails, naming `h2` and `postgres` |
| 5 | One shared context (FR-006) | `./gradlew cleanTest test --info \| grep -cE "Started [A-Za-z]+ in [0-9.]+ seconds"` | `1` (Spring logs one "Started …" line per context it builds) |
| 6 | No Gemini key needed (FR-007) | `env -u GEMINI_API_KEY ./gradlew test` | Passes |
| 7 | Single class while working (FR-017) | `time ./gradlew test --tests '*SignInComponentTest'` | Passes in under 1 min |
| 8 | Unit tests are fast (SC-003) | `./gradlew test --tests 'com.tom.payment.routinemanager.unit.*'`, then read the unit total in the report | Under 10 s of test time |
| 9 | Structure rules hold (SC-005) | Temporarily add `@DirtiesContext` to any component test and run `./gradlew test --tests '*TestStructureRulesTest'` | Fails, naming the class. Revert |
| 10 | Sign-in fixes (FR-018, SC-008) | `./gradlew bootRun` with the `fast` profile, then `curl -i -X POST localhost:8080/api/v1/auth/login -H 'Content-Type: application/json' -d '{"email":"nobody@example.test","password":"x"}'` | `401` with `"message":"Invalid email or password."`. Repeat with a registered email and a wrong password: identical body |
| 11 | Frontend shows the reason | Run backend `fast` + `pnpm dev`; sign in with a wrong password | The sign-in form shows "Invalid email or password." instead of a generic error |
| 12 | Pipeline blocks deploy (US2, SC-001) | On a branch, make one assertion fail and open a PR to `main` | The workflow fails at the build step; no image push or deploy; a test-report artifact is attached. Revert |
| 13 | Coverage not lost (FR-009) | Walk the migration table in [data-model.md](data-model.md) §4 against `docs/test-flows.md` | Every old behaviour maps to a passing test |
| 14 | Docs agree (SC-007) | Read constitution Principle II, backend `CLAUDE.md` "Testing strategy" and `.specify/templates/bugfix-template.md` | Same three kinds, same flow/rule split, `./gradlew` commands only, no "No H2" or Redis |

## Validation results (2026-11-23)

Machine: macOS, Docker via Colima (Testcontainers needs `DOCKER_HOST=unix://$HOME/.colima/default/docker.sock` and `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock`).

| # | Result | Evidence |
|---|---|---|
| 1 | ✅ | `./gradlew test` on H2: 135 tests, 0 failed, 1 skipped (`@RequiresPostgres`); about 24 s wall clock, 18 s test time |
| 2 | ✅ | `-PtestDb=postgres`: 135 tests, 0 failed, 0 skipped; one `postgres:17` container (17.12); about 26 s |
| 3 | ✅ | With Docker unreachable (Colima socket not configured), every test failed at context start with `IllegalStateException` from `DockerClientProviderStrategy`; nothing ran on H2 |
| 4 | ✅ | `-PtestDb=mysql` → `testDb must be 'h2' or 'postgres', got 'mysql'` |
| 5 | ✅ | `grep -cE "Started [A-Za-z]+ in [0-9.]+ seconds"` = 1 on both databases |
| 6 | ✅ | `env -u GEMINI_API_KEY ./gradlew clean build -PtestDb=postgres` → 135 tests passed, jar built |
| 7 | ✅ | `--tests '*SignInComponentTest'`: 9 s wall clock |
| 8 | ✅ | Unit package: 52 tests, about 0.4 s test time |
| 9 | ✅ | `@DirtiesContext` added to `OnboardingComponentTest` → `TestStructureRulesTest` failed naming it; reverted |
| 10 | ✅ | `fast` profile on :18080: unknown email and wrong password → identical 401 `Invalid email or password.`; duplicate registration → 409 |
| 11 | ⏳ | Not run: needs a person to look at the sign-in form (`pnpm dev` + backend) |
| 12 | ⏳ | Not run: needs a push to GitHub and a PR (waiting for the user's go-ahead) |
| 13 | ✅ | Coverage walk done (data-model §4 "Verified 2026-11-23"); one gap found and covered |
| 14 | ✅ | Constitution 2.0.0 Principle II, backend `CLAUDE.md` "Testing strategy" and `bugfix-template.md` agree; no `mvnw`, Redis or "No H2" left |
