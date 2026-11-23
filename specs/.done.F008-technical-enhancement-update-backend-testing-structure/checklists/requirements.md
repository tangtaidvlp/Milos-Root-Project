# Specification Quality Checklist: F008 – Update Backend Testing Structure

**Created**: 2026-11-22 · **Feature**: [spec.md](../spec.md)

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value; readable by non-technical stakeholders
- [x] All mandatory sections completed
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable and technology-agnostic
- [x] Acceptance scenarios cover the primary flows
- [x] Edge cases identified
- [x] Scope clearly bounded (in/out)
- [x] Dependencies and assumptions identified

## Notes

- This is a technical enhancement whose users are the developer and the delivery pipeline. The spec therefore uses generic terms ("in-memory database", "production-type database", "pipeline", "profile setting") and names no frameworks or libraries. The one exception is the Gradle wrapper (`./gradlew`), which the user asked to name explicitly. Tool choices (container approach, base class, naming suffixes, how the pipeline provides the database) are left to `/speckit-plan`.
- Test kinds and the flow/rule split are defined once at the top of "User Scenarios & Testing": component tests cover main user flows, unit tests cover core business rules and their edge cases, integration tests cover external connections. They are used consistently throughout.
- The user's clarifications (component-test focus; in-memory database locally, dedicated production-type database in CI/CD, switched by profile) override the "No H2" line in the backend `CLAUDE.md`. FR-014 covers updating that line.
- Sign-in defects (server error on bad credentials, duplicate registration, bad refresh token) are fixed inside F008 (FR-018), as the user decided during clarification. These are the only production behaviour changes.
