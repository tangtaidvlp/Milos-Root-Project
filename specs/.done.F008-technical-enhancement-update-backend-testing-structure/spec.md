# Feature Specification: F008 – Update Backend Testing Structure

**Feature Branch**: `feat/F008-backend-testing-structure`

**Created**: 2026-11-22

**Status**: Draft

**Input**: User description: "Our testing strategy on backend is not strong and gave no value. Our testing doesn't give me benefit, we require a more structural and efficient testing approach for backend. Users: me, CI/CD pipeline." Source of truth for the target rules: the "Testing Strategy (Integration-First Trophy)" section of the backend `CLAUDE.md` at the time (now rewritten as "Testing strategy"), as adjusted by the Clarifications below.

## Clarifications

### Session 2026-11-22

- Q: The new integration-first strategy contradicts constitution Principle II ("most tests are fast unit tests"). How should F008 resolve this? → A: Amend the constitution: Principle II becomes integration-first for the backend; frontend rules are unchanged.
- Q: What should F008 do with the existing backend test suite? → A: Migrate all existing tests to the new structure and add API-level coverage for the untested core journeys (sign-in/registration, default routine, daily routine).
- Q: Should the delivery pipeline run the full test suite and block deployment on failure? → A: Yes. The pipeline runs the full suite and a failure stops the release.
- Q: What should happen to the in-memory database? → A: Keep it for local test runs. The pipeline runs the same tests against a dedicated database of the production type. Which database the tests use is chosen by a profile setting, not by changing test code.
- Q: Which kinds of backend tests should F008 define, and what should each be called? → A: Focus on component tests (the whole backend tested through its API, with only outside services faked). Add only a few integration tests, each checking one connection to an external piece. Unit tests stay limited to complex logic.
- Q: The backend guide still says "no in-memory database, always containerized production-type database". Should component tests still use the in-memory database locally? → A: Yes. In-memory database for local component-test runs, production-type database in the pipeline, switched by one profile setting. The backend guide's "no in-memory database" rule is reworded to match.
- Q: The new sign-in tests show that bad credentials, a duplicate registration and an invalid, revoked or expired refresh token return a server error instead of a rejection. Should F008 fix this or only report it? → A: Fix it in F008. Bad credentials and a bad refresh token are rejected as "not authenticated", a duplicate registration as "already exists", each with a clear message. Component tests check the corrected responses.
- Q: What should component tests cover, and what should unit tests cover? → A: Component tests cover each main user flow (its success path and the main ways the user is refused). Unit tests cover the core business rules and all their edge cases. This replaces "unit tests stay limited to complex logic" above.
- Q: How should component tests act as a signed-in user once security is switched on in tests? → A: Real sign-in. The shared test foundation registers and logs in each test user through the public API and sends the real token on every request, so the backend's normal sign-in checks run in every component test.
- Q: (During implementation, T038) A malformed, tampered or foreign-signed sign-in token makes the backend answer with a server error on any protected endpoint. Fix it in F008 or file it? → A: Fix it in F008: such a request is treated as not signed in and gets "not authenticated".
- Q: (During implementation, T047) Which profile do tests mirror, and what about the duplicate chat sequence numbers found on PostgreSQL? → A: Tests use the `test` profile, the same profile the EC2 backend runs (open-in-view stays at its default). Concurrent chat messages getting the same sequence number (server error) is fixed in F008.

### Session 2026-11-23

- Q: (After `/code-review`) The rewritten testing principle no longer says refusal tests check the error body format, only the status. What should tests check, and should the backend move to the RFC 9457 error standard? → A: Tests check the error body shape on every refusal. No RFC 9457: the one existing error body is the standard. "Not signed in" refusals, which had an empty body, get the same body.

## User Scenarios & Testing *(mandatory)*

The "users" of this feature are the developer (the project owner) and the automated delivery pipeline.

Terms used in this spec:

- **Main user flow**: one thing a user does with the app from start to finish, such as signing in, editing the weekday routine, chatting with Buddy, changing a setting, or reflecting on a day.
- **Core business rule**: a decision the backend makes on its own, such as which colour a new task gets, how overlapping tasks are moved, which routine a new day is copied from, how a reflection is compared with the plan, or whether a setting value is allowed.
- **Component test**: tests the whole backend as one piece, through its public API. Everything inside the backend is real (request handling, validation, security, business rules, stored data). Only things outside it are faked: the AI provider and the current date. Component tests cover the main user flows: the success path, plus the main ways a user is refused (invalid input, not signed in, not their data, not found).
- **Unit test**: checks one core business rule on its own, without starting the backend or any database. Unit tests cover the rule's edge cases and variations.
- **Integration test**: checks that the backend really works with one specific external piece, such as the production-type database or the AI provider's interface. There are only a few, and each covers one connection.

### User Story 1 – Component tests run on the local or production-like database by setting (Priority: P1)

As the developer, I write a component test once and run it either on the fast in-memory database on my machine or on a dedicated production-type database. I switch between them with one profile setting, without editing any test. The pipeline uses the production-type database.

**Why this priority**: Everything else builds on this. Without a shared component-test foundation and a switchable database, the suite cannot be both fast locally and trustworthy in the pipeline.

**Independent Test**: Run the same component test class twice, once with the local setting and once with the production-type setting. It passes both times and reports which database it used.

**Acceptance Scenarios**:

1. **Given** no database setting is given, **When** the developer runs the backend tests locally, **Then** the component tests run against the in-memory database and need no other services.
2. **Given** the production-type database setting is selected, **When** the same tests run, **Then** they run against a dedicated production-type database, and no test code was changed.
3. **Given** a new component test, **When** the developer writes it, **Then** it reuses one shared test foundation that supplies the running backend, an API client, a signed-in test user, and access to the stored data.
4. **Given** several test classes in one run, **When** the suite executes, **Then** the backend environment is reused rather than rebuilt for each class.

---

### User Story 2 – Deployment is blocked when tests fail (Priority: P1)

As the developer, I want the pipeline to run the full backend suite against the dedicated production-type database before building and deploying. That includes the component, unit and integration tests. A failing test must stop the release.

**Why this priority**: Today the pipeline skips tests and deploys anyway, so tests give no protection in production. This is the main source of the "no value" pain.

**Independent Test**: Push a change with a deliberately failing test. The pipeline reports the failure and no new image is published or deployed.

**Acceptance Scenarios**:

1. **Given** a push to the backend, **When** the pipeline runs, **Then** it runs the full test suite against a dedicated production-type database before any image is built.
2. **Given** at least one test fails, **When** the pipeline finishes, **Then** no image is pushed and no deployment happens.
3. **Given** all tests pass, **When** the pipeline finishes, **Then** the image built from that same commit is the one deployed.

---

### User Story 3 – Each test sits at the right level (Priority: P2)

As the developer, I want main user flows checked by component tests and the edge cases of core business rules checked by unit tests, so each test is fast where it can be and realistic where it must be.

**Why this priority**: Today edge cases are tested by starting the whole backend (for example nine invalid-setting variations, ten colour assignments, four template-choice cases), which is slow and hides what is really being checked. Meanwhile some main flows are only tested by calling internal services directly.

**Independent Test**: Review the suite against the flow map. Every main user flow has a component test, every core business rule has unit tests for its edge cases, and no edge-case variation is repeated at component level.

**Acceptance Scenarios**:

1. **Given** a main user flow, **When** its component tests run, **Then** they cover the success path and the main ways the user is refused, checking response status, response body and stored data.
2. **Given** a core business rule, **When** its unit tests run, **Then** they cover its edge cases and variations without starting the backend or any database.
3. **Given** a core business rule that can only be reached through code that also reads or writes stored data, **When** it is unit-tested, **Then** the rule is first separated from the storage code, with no change in behaviour, so it can be tested without mocking storage.
4. **Given** a check about one external connection (for example behaviour only the production-type database has), **When** it is written, **Then** it is an integration test.

---

### User Story 4 – Existing tests are migrated without losing coverage (Priority: P2)

As the developer, I want every existing backend test moved to the right level under the new rules, so the suite is consistent and nothing that is checked today stops being checked.

**Why this priority**: The current suite mixes styles: some API tests, some tests that call internal services directly, one unit test built on a mocked storage layer, and an empty start-up test.

**Independent Test**: Compare the behaviours listed in the current flow map (`docs/integration-test-flows.md`) with the migrated suite. Each one is still covered by a component, unit or integration test.

**Acceptance Scenarios**:

1. **Given** an existing test of a main user flow, **When** it is migrated, **Then** it becomes a component test that goes through the public API.
2. **Given** an existing test of edge-case variations of a core business rule, **When** it is migrated, **Then** the variations move to unit tests and one representative case stays in the flow's component test.
3. **Given** the migrated suite, **When** it runs, **Then** every behaviour covered before is still covered.

---

### User Story 5 – Core journeys are covered, and sign-in refuses bad input properly (Priority: P2)

As the developer, I want component tests for the main flows that have no API-level test today: sign-in and registration (register, log in, refresh, log out), managing default routines, and managing daily routines. Where sign-in currently answers bad input with a server error, I want it fixed.

**Why this priority**: These are the app's most-used flows and have no API-level protection. Sign-in also hides "wrong password" behind a generic server error, which confuses users and looks like a crash in monitoring.

**Independent Test**: Run the new component test classes. They exercise each flow's success path and its refusals through the public API, and every sign-in refusal gets a client error with a clear message.

**Acceptance Scenarios**:

1. **Given** the sign-in flow, **When** its tests run, **Then** they cover successful registration, login, token refresh and logout, and every refusal: wrong email or password, an already-registered email, and a missing, unknown, revoked or expired refresh token.
2. **Given** a wrong password, an unknown email, or a missing, unknown, revoked or expired refresh token, **When** the request is made, **Then** the backend answers "not authenticated" with a clear message, never a server error.
3. **Given** an email that is already registered, **When** someone registers with it again, **Then** the backend answers "already exists" with a clear message, and no second account is created.
4. **Given** the default-routine flow, **When** its tests run, **Then** they cover creating, reading, updating and deleting a routine and its tasks, plus at least one refused invalid input.
5. **Given** the daily-routine flow, **When** its tests run, **Then** they cover the same operations and the "past days are frozen" scheduling rule.

---

### User Story 6 – The rules are written down once and agree everywhere (Priority: P3)

As the developer (and the AI assistant working with me), I want the constitution, the backend guide and the bug-fix workflow to use the same three test kinds, the same split between flows and rules, and the correct commands.

**Why this priority**: Conflicting rules and mixed terms lead to inconsistent tests. The current backend guide uses "integration test" for API-level tests, says unit tests should be minimal, and mentions a cache service the project doesn't have.

**Independent Test**: Read the constitution, the backend guide and the bug-fix template side by side. They define component, unit and integration tests the same way, and every command in them works.

**Acceptance Scenarios**:

1. **Given** the constitution, **When** it is read, **Then** Principle II says, for the backend: component tests cover main user flows; unit tests cover core business rules and their edge cases; integration tests only check external connections; the in-memory database is for local component-test runs only; and the pipeline uses the production-type database.
2. **Given** the backend guide, **When** the developer copies a test command from it, **Then** the command runs with the project's Gradle wrapper, for a single test class and for the full suite.
3. **Given** a bug fix, **When** it starts, **Then** the documented workflow requires a failing test that reproduces the bug before any production code changes. It is a component test when the bug is in a user flow and a unit test when it is in a core business rule.

### Edge Cases

- **A component test passes on the in-memory database but fails on the production-type database** (dialect, locking, or query differences): the pipeline result decides, and the failure blocks deployment. The developer can reproduce it locally by switching the profile setting. If the difference is about the database itself, an integration test is added for it.
- **Behaviour only the production-type database supports** (for example row-locking syntax): it is covered by an integration test. With the local in-memory setting, that test is reported as skipped, not as passed.
- **The production-type database is selected but cannot be reached or started**: the run fails at once with a clear message. It never silently falls back to the in-memory database.
- **A core business rule is tangled with storage code**: it is separated first (no behaviour change, proven by the component tests staying green), then unit-tested. Storage is never mocked.
- **Test data isolation**: tests in a shared environment must not depend on each other's data or on run order. Each test creates its own data, for example a unique user.
- **AI assistant calls**: no test calls the live AI provider. Component tests fake the AI service. An integration test for the AI connection uses a local stand-in for the provider.
- **Date-dependent rules** (past days frozen, reflections per date): tests control the current date, so results do not change with the day the suite runs.
- **Scheduled background jobs** must not fire during tests in a way that changes data under test.
- **Failed sign-in**: the refusal message must not reveal whether the email is registered.
- **Request without a token, or with another user's token**: component tests for each main flow include at least one such request and expect "not authenticated" or "not allowed". The checks run for real, not with a faked user. Flows that share endpoints (chat history and chat compaction) may share this check.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The backend MUST provide one shared component-test foundation. It supplies the running backend, an API client, a signed-in test user, and access to stored data, and all component tests use it. Test users MUST be registered and signed in through the public API, and every component-test request MUST carry the real sign-in token and pass the same sign-in checks as in production. No test may fake a signed-in user or switch those checks off.
- **FR-002**: The database that component tests use MUST be chosen by a single profile setting. The local default MUST be the in-memory database. The other option MUST be a dedicated database of the production type. Switching MUST require no change to test code.
- **FR-003**: When the production-type option is selected and that database is unavailable, the test run MUST fail with a clear message instead of falling back to the in-memory database.
- **FR-004**: Component tests MUST cover the main user flows through the public API, with only external services (the AI provider) and the current date faked. For each flow they MUST cover the success path and the main ways the user is refused, and MUST check the response status, the response body and, for write operations, the stored data. Every new feature and every bug in a user flow MUST include at least one component test.
- **FR-005**: Unit tests MUST cover the core business rules and their edge cases. They MUST run without starting the backend or any database, and MUST NOT mock data storage. Edge-case variations of a rule MUST be tested at unit level, not repeated in component tests.
- **FR-006**: The test suite MUST reuse the backend environment across test classes. No test may force the environment to be rebuilt.
- **FR-007**: Tests MUST be deterministic and offline. The current date is controlled, the live AI provider is never called, and test data does not leak between tests.
- **FR-008**: Integration tests MUST each verify one connection between the backend and an external piece (the production-type database, the AI provider's interface, or the security setup), using the real piece or a local stand-in that speaks the same protocol (for example, a stub HTTP server for the AI provider). F008 covers the database and security connections; an AI-provider integration test is a follow-up. Integration tests that need the production-type database MUST run whenever it is selected (always in the pipeline), and MUST be reported as skipped on the local in-memory setting.
- **FR-009**: All 11 existing backend test classes MUST be migrated into component, unit or integration tests that follow FR-001 to FR-008. Each one is kept, converted, split or removed, and no behaviour that is currently covered may lose coverage.
- **FR-010**: New component tests MUST cover the sign-in flow (register, login, refresh, logout, and every refusal listed in FR-018), default-routine management, and daily-routine management, including the past-day scheduling freeze.
- **FR-011**: The delivery pipeline MUST run the full backend test suite against a dedicated production-type database on every push to the main branch and every pull request targeting it, before the image is built.
- **FR-012**: The delivery pipeline MUST NOT push or deploy an image when any test fails.
- **FR-013**: Constitution Principle II MUST be amended for the backend: component tests cover main user flows; unit tests cover core business rules and their edge cases without mocking storage; integration tests are limited to external-connection checks. It MUST allow the in-memory database only for local component-test runs and require the production-type database in the pipeline. The constitution version and the Sync Impact Report MUST be updated.
- **FR-014**: The backend guide MUST define the three test kinds and the flow/rule split as this spec does. It MUST give working Gradle wrapper (`./gradlew`) commands for running one test class and the full suite, with each database option. It MUST also drop the mention of a cache service the project doesn't use, replace the "keep unit tests minimal" and "no in-memory database" rules to match FR-002 and FR-005, and update the test flow map (`docs/integration-test-flows.md`, renamed `docs/test-flows.md`) to the new structure.
- **FR-015**: The bug-fix workflow and template MUST require a failing test that reproduces the bug before any production code changes: a component test for a bug in a user flow, a unit test for a bug in a core business rule.
- **FR-016**: The application's own runtime profiles (including the quick local "fast" run) and all user-visible behaviour MUST stay as they are today. The only exceptions are the sign-in and token fixes in FR-018, the chat-sequence fix in FR-019 and the "not signed in" error body in FR-020. Separating core business rules from storage code (US3) MUST NOT change behaviour.
- **FR-017**: The documented workflow MUST require running the affected test class while a change is in progress, and the full suite passing before a task is closed.
- **FR-018**: Sign-in MUST refuse bad input with a client error, never a server error. A wrong password, an unknown email, and a missing, unknown, revoked or expired refresh token MUST get a "not authenticated" response. Registering an email that already exists MUST get an "already exists" response and create no account. Each response MUST carry a short, human-readable message, and a failed login MUST NOT reveal whether the email exists. A request to any protected endpoint whose sign-in token is malformed, tampered with or signed by someone else MUST get "not authenticated", never a server error.
- **FR-019**: Chat messages sent to the same conversation at the same moment MUST each get their own sequence number; none may fail with a server error because another message arrived at the same time.
- **FR-020**: Every refusal MUST return the one shared error body (status, reason, short message, time), including "not signed in". Every refusal check in component and integration tests MUST check that full body shape, not only the status, and the suite MUST fail when a test checks only the status.

### Key Entities

- **Component test foundation**: the shared base every component test builds on. It provides the running backend, the API client, a test user registered and signed in through the public API (with its real token), stored-data access, test-data helpers, and the faked AI service and date.
- **Test database profile**: the single setting that chooses between the local in-memory database and the dedicated production-type database.
- **Core business rule**: a self-contained decision the backend makes (see Terms), testable on its own once separated from storage code.
- **Integration test**: a small, separately named group of tests, each checking one external connection. Database integration tests run only on the production-type database.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of pipeline runs execute the full backend suite against the production-type database, and 0 deployments happen after a failed test run.
- **SC-002**: Every component test passes on both database options. Integration tests number 10 or fewer, and each one names the single external connection it checks.
- **SC-003**: The full local suite on the in-memory database finishes in under 3 minutes on the developer's machine, a single component test class in under 1 minute, and the whole unit-test set in under 10 seconds.
- **SC-004**: Every main user flow in the flow map has at least one success-path and one refusal component test, including the three that have none today (sign-in, default routine, daily routine).
- **SC-005**: Every core business rule in the flow map has unit tests for its edge cases. No unit test mocks data storage, no component test calls internal services in place of the public API, and no test forces the backend environment to be rebuilt.
- **SC-006**: Switching the database option needs exactly one setting change and zero code edits.
- **SC-007**: The constitution, the backend guide and the bug-fix template use the same three test kinds and the same flow/rule split, and show no contradictions about backend testing when reviewed.
- **SC-008**: 0 sign-in requests with bad input, and 0 requests with a bad sign-in token, get a server error. Every refusal case in FR-018 returns its client error and message.

## Assumptions

- All test commands use the project's Gradle wrapper (`./gradlew`), for a single test class and for the full suite. Maven (`mvn`, `./mvnw`) is not used anywhere.
- The core business rules in scope are the ones the current tests already exercise: task colour assignment, overlap shifting, weekday/weekend template choice, plan-vs-reality comparison, settings validation and defaults, chat history paging, and the past-day and future-day date rules. The flow map lists them; new rules are added to it as features add them.
- Mocking or spying is allowed only at true external boundaries (the AI provider, the clock) and for simulating provider failures. It is not allowed for the project's own storage or services.
- Buddy's task tools are called by the AI, not through the public API. Component tests may call those tool entry points directly, the same way the AI would, because no API route reaches them while the AI is faked.
- The sign-in fixes (FR-018) follow the bug-fix rule inside F008: the failing component test for each wrong response is written first, then the fix.
- The frontend already shows the message of any failed login or registration and does not retry on "not authenticated", so FR-018 needs no frontend change. Users will see the real reason instead of a generic error.
- Each test kind follows its own naming convention, so the developer can tell them apart and select one class by name. The exact convention is a planning decision.
- The pipeline environment can provide a dedicated production-type database for the test run. How it is provisioned is decided in planning.
- The frontend testing rules and the frontend's end-to-end setup are out of scope and unchanged.
- Adding a schema-migration tool is out of scope. Tests use the same schema setup the application uses today.
- Out of scope: coverage targets for AI chat tool behaviour beyond what existing tests already cover, performance or load testing, and the frontend pipeline.
