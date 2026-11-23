# Research: F012 Reset day to default routine

## R1. Which template a reset uses
- **Decision**: Reuse `DefaultRoutineService.resolveTemplateFor(user, date)`: Sat/Sun → Weekend routine **if it has tasks**, otherwise Weekday.
- **Rationale**: A reset gives the same result as the day being created fresh (spec Assumption "same rule"). One rule, no new code.
- **Spec impact**: An empty Weekend routine means a weekend day resets to Weekday, not to an empty day. FR-001's confirm text therefore says "your default routine" and doesn't name Weekday/Weekend; the client can't know about the fallback without an extra fetch.
- **Alternatives**: Always use Weekend on Sat/Sun (would disagree with how days are created).

## R2. Reset endpoint shape
- **Decision**: `POST /api/routine-manager/daily-routine/{userId}/{date}/reset` → `204`. The UI then reloads the day with the existing GET.
- **Rationale**: Returning `DailyRoutine` would serialise an entity in new code (constitution I). 204 + the existing reload (`afterPlanChange`, which also refreshes the reflection) needs no new DTO.
- **Alternatives**: Delete-all + add-tasks from the client: two calls, not atomic (breaks FR-004).

## R3. Atomicity and replace
- **Decision**: One `@Transactional` service method: find the day (create from the template if missing), `tasks.clear()` (orphanRemoval deletes rows), copy template tasks with `completed=false`, set `colorCursor` from the template.
- **Rationale**: All-or-nothing (FR-004). Same copy code as `createDailyRoutineFromDefault`, which gets extracted into one private method used by both.

## R4. Past dates
- **Decision**: The server refuses with `400 ApiError` ("Past days can't be reset") using `DayRules.isPast(date, LocalDate.now(clock))`. The UI disables the button when `selectedDate < today`.
- **Rationale**: The server is authoritative (constitution IV, "validate server-side").

## R5. Copy Weekday → Weekend endpoint
- **Decision**: `POST /api/v1/default-routine/users/{userId}/copy-weekday-to-weekend` → `204`. One transaction: get-or-create WEEKEND, `tasks.clear()`, copy the DAILY tasks (name, description, start, duration, colour), set `colorCursor` from DAILY. The UI then reloads the Weekend tab.
- **Rationale**: Atomic (FR-008). Owner-scoped through `CurrentUserGuard` plus lookups by user. The Weekend AI conversation is not touched.

## R6. Removing Reset day from setup pages
- **Decision**: `BoardToolbar` renders Reset day only when an `onResetDay` handler is given, and takes `resetDisabled`. `EditingBoard` gets the optional props `onResetDay`/`resetDisabled` and passes them through. Today and `CompareBoards` pass them; `DefaultRoutineEditor` doesn't. The old local-tick reset (`handleResetSchedule`, `resetSignal`) is removed (constitution IX).
- **Confirm UI**: Reuse `components/ConfirmDialog.tsx`.
