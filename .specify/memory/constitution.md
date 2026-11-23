<!--
Sync Impact Report
- Version change: 1.0.0 → 2.0.0 (MAJOR: Principles I and II redefined, III phased)
- Modified principles:
  I. "Contract-First API Design (RFC 9457 errors)" → "Contract-First API Design". Errors use
      the one `ApiError` body the backend and frontend already share (`status`, `error`,
      `message`, `timestamp`) instead of RFC 9457 Problem Details: the extra format added code
      and a frontend change for no user benefit (owner decision, F008).
  II. "Test Pyramid with Real Infrastructure" → "Component-First Testing with Real
      Infrastructure". The backend default moves from "most tests are unit tests" to component
      tests per main user flow, unit tests per core business rule (edge cases), and at most
      10 integration tests for external connections. Every refusal test checks the full
      error body shape, not only the status. The frontend bullet now names the testing-trophy
      layers (unit tests for all pure logic, component tests only for complex widgets, 5–10
      Playwright journeys); "Vitest for frontend logic" moved there from the old first
      bullet. The bug-fix rule covers integration and frontend bugs.
  III. Schema rules are phased (owner decision, F008): until production phase 1, Hibernate
      `ddl-auto` builds the schema and `db/<feature>.sql` scripts cover the prod database.
      Flyway arrives with the first stable schema; from then on migrations are mandatory and
      tests build the schema with them (this restores the 1.0.0 "same migrations as
      production" rule, which the first 2.0.0 draft had dropped).
- Other changes: Environments now list the `test` profile; the merge gate names
  `./gradlew build -PtestDb=postgres`.
- Templates: .specify/templates/bugfix-template.md updated (failing component or unit test first).
- Source: specs/.done.F008-technical-enhancement-update-backend-testing-structure (FR-013).
- Known gaps vs. current code (fix through features/bugfixes, not this amendment):
  * Planned for production phase 1, not a defect before then: Flyway baseline from the first
    stable schema; until then tests build the schema with Hibernate, so a `db/*.sql` script
    that doesn't match the entities is not caught by any test (II, III)
  * JWT signing key generated in memory, lost on restart; logout does not revoke the
    refresh token; refresh-token lifetime uses the access-token expiry (IV)
  * Default/daily routine endpoints don't check that the routine belongs to the caller (IV)
  * The `prod` profile (open-in-view off) can't serialise routine entities; JPA entities are
    still returned directly instead of DTOs (I)
  * GitHub Actions pinned by tag, not commit SHA (including the test-report upload step F008
    added); AWS access may use static keys (VII). Deferred: the project is in a local phase
    and CI/CD hardening waits, for cost.
  * The EC2 backend runs the `test` profile, which enables the cron support endpoint, and the
    CI deploy step sets no profile (IV; bug-0007)
  * No Actuator/structured logging baseline confirmed (VIII)
- Closed since 1.0.0: backend CI now runs all tests (Testcontainers PostgreSQL) before deploy (II, VII);
  the "not RFC 9457" gap is gone with the Principle I change, and the security layer's 401 now
  returns `ApiError` too (it had an empty body) (I)

Previous report (1.0.0):
- Version change: (unversioned template) → 1.0.0 (first ratification; an earlier same-day draft
  was never committed and is replaced wholesale)
- Principles (all new):
  I. Contract-First API Design (RFC 9457 errors)
  II. Test Pyramid with Real Infrastructure
  III. Versioned, Backward-Compatible Data Changes (expand/contract)
  IV. Secure by Default (OWASP ASVS, OAuth browser-app BCP)
  V. Constrained AI Agency (OWASP Top 10 for LLM Applications)
  VI. Accessible, Typed, Feature-Sliced Frontend (WCAG 2.2 AA, React 19)
  VII. Supply-Chain & Pipeline Integrity
  VIII. Observability & Operability
  IX. Simplicity
- Added sections: Technology & Deployment Constraints; Development Workflow & Quality Gates;
  Governance
- Removed sections: none
- Templates: none modified (plan/spec/tasks templates read this file at runtime)
- Deferred TODOs: none
- Known gaps vs. current code (fix through features/bugfixes, not this amendment):
  * Backend CI builds with `-x test`; no Testcontainers; integration tests can use H2 (II)
  * No Flyway; schema scripts are applied by hand (III)
  * Error bodies are not RFC 9457 Problem Details (I)
  * JWT signing key generated in memory, lost on restart; logout does not revoke the
    refresh token; refresh-token rotation unverified (IV)
  * GitHub Actions pinned by tag, not commit SHA; AWS access may use static keys (VII)
  * No Actuator/structured logging baseline confirmed (VIII)
-->

# Personal Routine Manager Constitution

## Core Principles

### I. Contract-First API Design

The backend and frontend deploy independently (EC2 vs. GitHub Pages) and share one HTTP contract.

- Every new or changed endpoint MUST be specified in `specs/<feature>/contracts/` before code is
  written, including request, response, error cases and status codes.
- Request/response bodies MUST be dedicated DTOs (Java records preferred); JPA entities MUST NOT
  be serialised directly in new code. Server-computed fields are read-only and ignored on input.
- Every error response MUST use the one error body, `ApiError`: a JSON object with exactly
  `status` (number), `error` (reason phrase), `message` (short text the UI shows) and
  `timestamp` (ISO-8601), including errors raised by the security layer. Status codes follow
  their meaning: 400 validation, 401 unauthenticated, 403 forbidden, 404 missing or not owned,
  409 conflict, 503 upstream (AI) failure. Error bodies MUST NOT leak stack traces, SQL or
  class names. No second error format (such as RFC 9457 Problem Details) is introduced.
- Changes MUST be backward compatible with the currently deployed frontend; breaking changes
  require a new versioned path or an expand/contract rollout (backend first, then UI, then removal).
- Backend and frontend changes to one contract land in the same feature; mirrored registries
  (task palette, user settings schema, AI tool hints) MUST be updated together.

Rationale: independent deploys make contract drift a production bug unless it is designed out.
Source: Spring Framework "Error Responses" reference.

### II. Component-First Testing with Real Infrastructure

- Backend tests come in three kinds, each in its own package and naming:
  - **Component tests** (default): every main user flow is tested through the public API with
    the whole backend running, including security with real sign-in tokens. They check status,
    response body and stored data for the success path and the main refusals. Every refusal
    (4xx/5xx) check in component and integration tests MUST also check the full `ApiError`
    body shape (Principle I), not only the status code. Only external
    services (the AI provider, via the mock implementation) and the clock are controlled.
  - **Unit tests**: every core business rule (calculations, state transitions, parsing, rule
    decisions) and its edge cases, with no Spring context and no database. Storage MUST NOT be
    mocked; rules tangled with storage are separated first, without behaviour change.
  - **Integration tests** (at most 10): each checks one external connection (PostgreSQL-only
    behaviour, the security setup, a provider interface) against the real piece or a faithful
    local stand-in.
- All component and integration tests share one Spring context; no per-class configuration,
  mock beans or `@DirtiesContext`.
- H2 MAY be used for local component-test runs only. CI MUST run every test against PostgreSQL
  via Testcontainers, and PostgreSQL-only tests are skipped (never passed) on H2. Tests build
  the schema the way Principle III prescribes for the current phase: Hibernate until production
  phase 1, the production Flyway migrations after it.
- Frontend tests follow the testing trophy (details in the frontend `CLAUDE.md`, "Testing
  strategy"): strict TypeScript and lint first; every pure logic unit (functions, reducers,
  schemas) MUST have Vitest unit tests covering its edge cases; Testing Library component
  tests only for complex widgets, by user-visible behaviour (roles, labels, text), with the
  backend faked at the feature's API module; 5–10 Playwright e2e tests cover the core
  journeys. No snapshot tests and no coverage targets.
- Every bug fix MUST begin with a failing test at the level where the bug lives. Backend: a
  component test for a user-flow bug, a unit test for a core-business-rule bug, an integration
  test for an external-connection bug (PostgreSQL-only behaviour, security setup). Frontend: a
  unit test for a logic bug, a component test for a widget bug, a Playwright test for a
  journey bug.
- Tests MUST be deterministic and offline: inject `Clock` for dates, seed randomness, and use the
  mock AI implementation; no test may call a live LLM.

Rationale: a test of a whole flow through real infrastructure catches what users would hit
(mapping, validation, security, transactions, SQL); small rule tests keep edge cases fast and
readable; mocks of our own code give false confidence.

### III. Versioned, Backward-Compatible Data Changes

- **Until production phase 1** (current local phase): Hibernate `ddl-auto` MAY build and
  update the schema so the model can change quickly. A change the `prod` database needs (it
  runs `ddl-auto: validate`) ships as an idempotent `db/<feature>.sql` script, applied before
  the new image starts.
- **From production phase 1:** Flyway is adopted with the first stable schema as its baseline
  migration. From then on, schema changes MUST be versioned Flyway migrations committed with
  the code and executed automatically on startup or in the deploy pipeline. Production keeps
  `ddl-auto: validate`, and Hibernate MUST NOT generate schema outside `fast`. CI tests MUST
  build the schema with the same migrations as production, not with Hibernate.
- Changes MUST follow expand → migrate → contract: add new structures alongside old ones, deploy
  code that works with both, backfill, then remove the old structure in a later release. Renames,
  type changes and new `NOT NULL` constraints are never done in one step.
- Persisted identifiers (enum values, palette ids, setting keys) are never renamed or removed
  without a migration.
- Large-table operations MUST avoid long locks (e.g. `CREATE INDEX CONCURRENTLY`, batched
  backfills).
- Reads MUST NOT write: GET endpoints and view paths have no side effects; creation happens only
  on explicit intent.
- Write operations are `@Transactional` at the service layer; side effects that depend on a
  commit run after commit.

Rationale: a single production database with hand-applied scripts is the highest-risk part of
the system; expand/contract is the standard path to zero-downtime changes.

### IV. Secure by Default

Security requirements follow OWASP ASVS (Level 1 minimum, Level 2 for authentication and
session management) and the IETF Best Current Practice for browser-based OAuth apps (RFC 10017).

- Secrets come from environment variables or a secret manager; they MUST NOT appear in source,
  logs, error responses or the client bundle (`VITE_*` variables are public).
- Access tokens are short-lived and held in memory only — never in `localStorage` or
  `sessionStorage`. Refresh tokens live in `HttpOnly`, `Secure`, `SameSite`, path-scoped
  cookies, are rotated on every use, and are revoked on logout and on reuse detection.
- JWT signing keys MUST be stable across restarts (loaded from a secret), use a fixed algorithm
  allow-list, and tokens MUST be validated for signature, expiry, issuer and audience.
- Authorisation is deny-by-default: every user-scoped endpoint checks that the authenticated
  subject owns the resource, and every repository lookup is scoped by owner.
- Authentication MUST be enforced in every deployed environment (`sit`, `prod`); `allowAll` is
  allowed only in `local`, `fast` and tests. Support/debug endpoints MUST NOT exist in `prod`.
- All input is validated server-side with Bean Validation, regardless of client checks.
- CORS lists explicit origins per environment; credentials are never combined with wildcards.
- Production serves only HTTPS (HSTS at Nginx), with security headers (CSP,
  `X-Content-Type-Options`, `Referrer-Policy`, frame protection).
- Login and AI endpoints MUST be rate limited.

Rationale: the app stores personal schedules and chat history and runs on a public host.

### V. Constrained AI Agency

Buddy is designed against the OWASP Top 10 for LLM Applications, in particular Prompt
Injection, Sensitive Information Disclosure, Improper Output Handling and Excessive Agency.

- Least agency: each chat context registers only the tools it needs; tools call the same
  services and validation as the REST API and act only on the authenticated user's data. The
  model never receives database, file-system or network access.
- The user id and permissions are bound server-side; they are never taken from model output or
  prompt text.
- All model output is untrusted: tool arguments are validated like user input, and text is
  rendered as plain text/sanitised markdown, never as raw HTML.
- Prompts treat user content as data; system instructions and tool constraints live server-side
  and are not exposed to the user.
- Destructive or bulk actions (delete all tasks, reset a day) require explicit user
  confirmation in the UI rather than being executed on model initiative alone.
- Only the minimum user data needed for a request is sent to the provider; prompts and chat
  content are not logged at INFO or above in `prod`.
- The provider sits behind an interface with a mock implementation; failures degrade gracefully
  (503 / friendly message, prior state kept, nothing stored for the failed exchange); calls have
  timeouts and per-user rate/cost limits.
- Model ids, limits and thresholds are configuration, not code.

Rationale: an LLM is a non-deterministic, injectable client of the domain and must be held to
stricter rules than the UI.

### VI. Accessible, Typed, Feature-Sliced Frontend

- New code is TypeScript in `strict` mode; `any` needs a justification comment. Existing
  `.jsx` files are converted when substantially changed.
- Code is organised by feature (`src/features/<name>/…`) per `codingrules.md`; shared UI goes
  in `src/components/`, and all HTTP goes through `src/lib/api.ts`.
- State is split by kind: server data is fetched and cached through the feature's API layer
  (a dedicated server-state library MAY be adopted by amendment); UI state stays local;
  global client state is minimal. Derived values are computed, not stored.
- Effects are only for synchronising with external systems; mutations and forms prefer React 19
  Actions/transitions so pending and error states are explicit.
- The UI MUST meet WCAG 2.2 Level AA: semantic HTML and correct roles/labels, full keyboard
  operation with visible, unobscured focus, alternatives to drag interactions, target sizes of
  at least 24×24 CSS px, and AA contrast in both themes (enforced by tests).
- Styling uses semantic design tokens only; raw colour literals are forbidden outside the
  token file and its allowlist.
- Layouts work from 320px phone width to desktop without horizontal scrolling.
- Performance budget: route-level code splitting for heavy pages; Core Web Vitals "good"
  thresholds (LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1) on a mid-range device.

Rationale: accessibility and type safety are much cheaper to keep than to retrofit.
Source: W3C WCAG 2.2; react.dev guidance on effects and Actions.

### VII. Supply-Chain & Pipeline Integrity

- CI runs build, lint, type checks and all automated tests on every push and pull request;
  deploy jobs depend on them passing. Skipping tests in a release pipeline is forbidden.
- Third-party GitHub Actions are pinned to full commit SHAs and updated by Dependabot/Renovate;
  workflow `permissions` default to read-only and are widened per job.
- Cloud access from CI uses OIDC federation (AWS IAM role), not long-lived access keys.
- Dependencies are locked (`pnpm-lock.yaml`, Gradle wrapper + dependency locking or
  version catalog) and scanned for known vulnerabilities in CI; a critical or high CVE with a
  fix available blocks release.
- Container images use a minimal, pinned base image, run as a non-root user, and are scanned
  before push; an SBOM is produced for each release image.
- The same artifact that was tested is the one deployed; production hosts are not modified by
  hand.

Rationale: most real-world compromises of small projects now come through dependencies and CI.
Source: GitHub "Security hardening for GitHub Actions"; OpenSSF/SLSA guidance.

### VIII. Observability & Operability

- Logs are structured (JSON in `prod`) via SLF4J, include a request/correlation id, and contain
  no secrets, tokens or personal content. Errors are logged once, where they are handled.
- Spring Boot Actuator exposes liveness/readiness health checks; only `health` (and `info`) are
  public, everything else is restricted.
- Metrics and traces use Micrometer/OpenTelemetry conventions; AI calls record latency, errors
  and token usage.
- Configuration follows the twelve-factor model: one artifact, environment-specific config via
  environment variables and profiles; profile differences are limited to infrastructure and
  auth.
- Backups of the production database are automated and a restore has been tested.

Rationale: production problems must be diagnosable from telemetry alone, without SSH debugging.

### IX. Simplicity

- Build the simplest design that satisfies the spec (YAGNI). New libraries, layers or
  infrastructure MUST be justified in the plan's Complexity Tracking table.
- When an approach is replaced, the old one is removed in the same or the next feature rather
  than left to coexist (e.g. legacy AI function beans, stale duplicate modules).
- Prefer platform features (Spring Boot auto-configuration, browser APIs, React built-ins) over
  custom frameworks.

Rationale: a small team can only keep moving if each feature leaves the system no harder to
change than before.

## Technology & Deployment Constraints

- Backend: Java 25 (LTS), Spring Boot 4.1, Gradle wrapper, Spring Web MVC, Spring Data JPA,
  Spring Security (JWT resource server), Spring AI (Gemini), PostgreSQL 17, Flyway, Lombok,
  constructor injection only, UUID primary keys.
- Frontend: React 19, TypeScript (strict), Vite 8, React Router 7 with `HashRouter` for
  GitHub Pages, plain CSS with design tokens, Vitest + Testing Library + Playwright, oxlint,
  pnpm.
- Environments: `fast` (H2, no auth, local only), `local` (PostgreSQL, no auth), `test` (auth on;
  the automated test suite, and the EC2 backend today), `sit` and `prod` (auth on).
- Deploy: backend image → AWS ECR → EC2 behind Nginx (TLS, `/api/*` reverse proxy); frontend
  `dist/` → `milos.github.io`. Generated output is never hand-edited.
- Replacing a core technology (framework, database, AI provider, router mode, hosting) requires
  a constitution amendment.

## Development Workflow & Quality Gates

- Features follow Spec Kit: specify → clarify → plan → tasks → implement → analyze. Each plan
  passes the Constitution Check before research and again after design.
- Bugs follow reproduce → root cause → failing regression test → fix → verify, with a report at
  `specs/###-fix-*/bugfix.md`; fixes needing schema or breaking API changes go through
  `/speckit-specify`.
- Merge gate (enforced in CI): backend `./gradlew build -PtestDb=postgres` (all tests on
  Testcontainers PostgreSQL);
  frontend `pnpm build`, `pnpm lint`, `pnpm test`; Playwright e2e for touched journeys;
  dependency vulnerability scan.
- Changes are reviewed before merge (pull request, or a recorded `/code-review` for solo work)
  with this constitution as the checklist.
- Commits are small, scoped to one feature or fix, and use Conventional Commits
  (`feat:`, `fix:`, `docs:` …). Secrets are never committed.
- Each feature updates the relevant subproject `CLAUDE.md` when it adds conventions,
  endpoints or migrations.

## Governance

- This constitution supersedes other practice documents. Subproject `CLAUDE.md` files and
  `codingrules.md` hold detailed guidance and MUST NOT contradict it.
- Amendments are made with `/speckit-constitution`, include a Sync Impact Report, and give the
  reason in the commit message.
- Versioning: MAJOR for removing or redefining a principle, MINOR for adding a principle or
  materially expanding guidance, PATCH for clarifications and wording.
- Compliance: `/speckit-plan` (Constitution Check) and `/speckit-analyze` verify each feature;
  any deviation is recorded with justification in the plan's Complexity Tracking table.
- Code that predates a principle is brought into compliance when next substantially touched,
  or through a dedicated feature or bugfix. Known gaps are tracked in the Sync Impact Report
  until resolved.
- External standards referenced here (OWASP ASVS, OWASP Top 10 for LLM Applications,
  RFC 10017, WCAG 2.2) are reviewed yearly; adopting a newer edition is a MINOR
  amendment.

**Version**: 2.0.0 | **Ratified**: 2026-11-22 | **Last Amended**: 2026-11-23
