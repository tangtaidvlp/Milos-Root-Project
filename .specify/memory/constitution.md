<!--
Sync Impact Report
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
- Error responses MUST use RFC 9457 Problem Details (`application/problem+json`, Spring
  `ProblemDetail`) with correct status semantics: 400 validation, 401 unauthenticated,
  403 forbidden, 404 missing or not owned, 409 conflict, 503 upstream (AI) failure. Problem
  bodies MUST NOT leak stack traces, SQL or class names.
- Changes MUST be backward compatible with the currently deployed frontend; breaking changes
  require a new versioned path or an expand/contract rollout (backend first, then UI, then removal).
- Backend and frontend changes to one contract land in the same feature; mirrored registries
  (task palette, user settings schema, AI tool hints) MUST be updated together.

Rationale: independent deploys make contract drift a production bug unless it is designed out.
Source: RFC 9457; Spring Framework "Error Responses" reference.

### II. Test Pyramid with Real Infrastructure

- Most tests are fast unit tests of domain/service logic (JUnit 5; Vitest for frontend logic).
- Persistence, transactions and queries MUST be verified with integration tests against
  PostgreSQL via Testcontainers, running the same migrations as production. H2 MAY be used for
  quick local runs but MUST NOT be the only evidence for database behaviour.
- Web-layer contracts MUST be covered by slice or MockMvc tests asserting status codes and
  Problem Details bodies.
- Frontend components are tested by user-visible behaviour (Testing Library: roles, labels,
  text), not implementation details; critical journeys are covered by Playwright e2e.
- Every bug fix MUST begin with a failing regression test.
- Tests MUST be deterministic and offline: inject `Clock` for dates, seed randomness, and use the
  mock AI implementation; no test may call a live LLM.

Rationale: tests that mock away the database or the clock give false confidence; real
dependencies in containers catch dialect, locking and migration issues before production.

### III. Versioned, Backward-Compatible Data Changes

- Schema changes MUST be versioned migrations (Flyway) committed with the code and executed
  automatically on startup or in the deploy pipeline, and tested in CI against PostgreSQL.
  Production keeps `ddl-auto: validate`; Hibernate MUST NOT generate schema outside `fast`/tests.
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
- Environments: `fast` (H2, no auth, local only), `local` (PostgreSQL, no auth), `sit` and
  `prod` (auth on).
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
- Merge gate (enforced in CI): backend `./gradlew build` including Testcontainers tests;
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
  RFC 9457, RFC 10017, WCAG 2.2) are reviewed yearly; adopting a newer edition is a MINOR
  amendment.

**Version**: 1.0.0 | **Ratified**: 2026-11-22 | **Last Amended**: 2026-11-22
