# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workspace overview

This is the monorepo workspace for **Personal Routine Manager** — an agentic scheduling app that combines a traditional CRUD calendar UI with an AI chat assistant ("Buddy"). It has a decoupled three-tier architecture deployed on AWS.

### Projects

| Directory | What | Stack | Deploy target |
|-----------|------|-------|---------------|
| `ms-personal-routine-manager/` | Backend REST API | Spring Boot 4.1, Java 25, Gradle, PostgreSQL | AWS ECR → EC2 |
| `ui-personal-routine-manager/` | Frontend SPA | React 19, TypeScript, Vite 8, React Router 7 | GitHub Pages (`milos.github.io`) |
| `milos.github.io/` | Local copy of the GitHub Pages output repo (receives `dist/` from the frontend deploy workflow) | Generated HTML/JS/CSS | — |
| `AI-project-docs/` | Requirements (`software-requirement/`) and AWS architecture notes (`AWS-Architect.MD`) | Markdown | — |
| `.specify/` | Spec Kit: constitution, templates, workflows for spec → plan → tasks | Markdown + scripts | — |
| `.claude/skills/` | Project-level `speckit-*` skills | Markdown | — |
| `nginx.conf` | Nginx config for EC2 deployment | — | AWS EC2 |

Do not hand-edit `milos.github.io/`; it is overwritten by the frontend deploy. Make changes in `ui-personal-routine-manager/` instead.

Each subproject has its own `CLAUDE.md` with detailed architecture docs, commands, and conventions. Read the relevant one when working inside that directory.

### How the pieces fit together

- Dev: backend on `localhost:8080`; the frontend (`localhost:5173`) calls it directly via `VITE_API_BASE_URL` in `.env.development`, and the backend's CORS config allows that origin.
- Production (EC2): Nginx (`nginx.conf`) serves the frontend static files and reverse-proxies `/api/*` to the backend on the same instance.
- Auth, profiles, and CI/CD details live in each subproject's `CLAUDE.md`.

### Working across both projects

1. Start the backend: `cd ms-personal-routine-manager && docker compose up -d database && ./gradlew bootRun` (or `SPRING_PROFILES_ACTIVE=fast ./gradlew bootRun` to skip the DB).
2. Start the frontend: `cd ui-personal-routine-manager && pnpm dev`.
3. API contract: the frontend's `src/lib/api.ts` is the fetch wrapper; backend controllers are under `com.tom.payment.routinemanager.api`. Keep request/response shapes aligned between the two.

### Requirements docs and feature workflow

- `AI-project-docs/software-requirement/` holds feature specs written as AI collaboration notes. These are living documents the AI may update during discussion. The folder is currently empty.
- Feature work follows Spec Kit. Principles are in `.specify/memory/constitution.md`. Use the `speckit-*` skills (specify → clarify → plan → tasks → implement → analyze) to drive a feature from spec to code. Templates are in `.specify/templates/`.
- Bugs use the custom `speckit-debug` skill (`/speckit-debug <bug>`), or the gated `bugfix` workflow (`specify workflow run bugfix`). The steps are reproduce → root cause → failing regression test → fix → verify. Each bug gets a report at `specs/###-fix-*/bugfix.md`, based on `.specify/templates/bugfix-template.md`. Large fixes (schema change, breaking API change, wide redesign) are handed off to `/speckit-specify` instead.


### Parallel work (worktrees)
- One work item = one git worktree = one branch = one Claude session. Start one with `/speckit-worktree <ID>`; it creates `../Projects.worktrees/<ID>-<slug>/` with its own branch in the root repo and in `ms-`/`ui-` submodules, and its own `.specify/feature.json`.
- The user decides which items run in parallel. Never switch branches or edit `.specify/feature.json` to jump to another work item; work only inside the current worktree, and never read or edit files in another worktree.
- Create new IDs (`/speckit-init`) only in the main checkout; numbering scans all worktrees.

### Closed specs
- A folder `specs/.done.<dir>/` is a closed (finished) feature or bugfix. Ignore it: do not list, search or read it unless the user names it or a CLAUDE.md pointer sends you there for a specific detail.
- Close a finished feature with `/speckit-close <F### | dir>` (no argument = the current feature in `.specify/feature.json`).

### Bug fix workflow
Bugs are defined in AI-project-docs/bugs folder
Whenever solve a bug, rename it from bugxxx -> .done.bugxxx
During working, ignore bugs with done. postfix
### Engineering standards
- `.specify/memory/constitution.md` is the source of truth for engineering rules (API contracts, testing, migrations, security, AI guardrails, accessibility, CI). It is based on OWASP ASVS, the OWASP Top 10 for LLM Applications, RFC 10017 and WCAG 2.2 AA. Errors use the project's one `ApiError` body, not RFC 9457. Subproject `CLAUDE.md` files and `codingrules.md` must not contradict it.
- Its Sync Impact Report lists where the current code doesn't meet it yet. Don't copy those patterns into new code; fix them when you touch that code.
