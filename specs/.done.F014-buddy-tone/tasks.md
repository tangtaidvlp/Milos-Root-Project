---
description: "Tasks for F014 Buddy Tone"
---

# Tasks: Buddy Tone (F014)

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: These are included because constitution Principle II requires them.

**Paths**: `BE` = `ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/`, `BT` = `ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/`, `FE` = `ui-personal-routine-manager/src/`.

---

## Phase 1: Setup

None. There are no new dependencies and no DDL (the tone is a `user_setting` row).

---

## Phase 2: Foundational (blocks both stories)

- [X] T001 Create the enum `BE/funcs/BuddyTone.java` with the ids `BALANCED`, `CHIEF_OF_STAFF`, `STOIC`, `SOCRATIC_PEER`, `WARM_ANCHOR`, `ACCOUNTABILITY_COACH` (persisted, never renamed). Each id has a `displayName` and a `styleLine`, verbatim from [buddy-prompt-tone.md](contracts/buddy-prompt-tone.md). Add `DEFAULT = BALANCED`, `fromStored(String)` (unknown or null → `BALANCED`) and `ids()`
- [X] T002 Add the setting `buddyTone` to `BE/service/UserSettingsRegistry.java` `builtIns()`:
  - Default `BALANCED`.
  - Parse: JSON string, trimmed, upper-cased, and must be a `BuddyTone` id. Otherwise `IllegalArgumentException("buddyTone must be one of BALANCED, CHIEF_OF_STAFF, STOIC, SOCRATIC_PEER, WARM_ANCHOR, ACCOUNTABILITY_COACH")`.
  - toJson: identity.
- [X] T003 [P] Update `BT/unit/UserSettingsRegistryTest.java`:
  - Key list `theme, boardZoom, buddyTone` (and the extended-registry list).
  - buddyTone default `BALANCED`.
  - `"warm_anchor "` → `WARM_ANCHOR`.
  - Unknown, number or null → the message above.
  - An invalid stored value reads as `BALANCED`.
- [X] T004 [P] Add `buddyTone` to `FE/features/settings/types/settings.ts` (`BuddyToneId` union of the 6 ids) and to `FE/features/settings/utils/settingsSchema.ts` (`normalizeBuddyTone`: a known id, otherwise `'BALANCED'`; default `'BALANCED'`). Update `settingsSchema.test.ts`: the `DEFAULT_SETTINGS` and `normalizeSettings` expectations now include `buddyTone`, plus `normalizeBuddyTone` cases

**Checkpoint**: the tone can be stored and read through `/settings`.

---

## Phase 3: User Story 1 – Choose Buddy's tone (P1) 🎯 MVP

**Goal**: a "Buddy tone" section on the Personal Target page that saves the choice.

**Independent Test**: quickstart A1–A4. The tone persists across a reload and on other devices; a failed save rolls back.

- [X] T005 [P] [US1] Component test: extend `BT/component/UserSettingsComponentTest.java`:
  - The new user's settings have `buddyTone` = `BALANCED`.
  - PATCH `{"buddyTone":"warm_anchor"}` → 200, `WARM_ANCHOR`, stored row, `customized` contains `buddyTone`.
  - PATCH `{"buddyTone":"ROBOT"}` → `error(HttpStatus.BAD_REQUEST)` with the message, and nothing written.
  - Adjust the existing `customized` / key expectations that list keys.
- [X] T006 [P] [US1] Create the UI catalogue `FE/features/personal-target/utils/buddyTones.ts`: `BUDDY_TONES` = 6 entries `{ id, name, vibe, bestFor, example, isDefault }`, copied verbatim from spec.md "Tone catalogue". Add `toneById(id)`. Add the unit test `buddyTones.test.ts`: 6 unique ids equal to the schema ids, exactly one default (`BALANCED`), every field non-empty
- [X] T007 [US1] Create `FE/features/personal-target/components/BuddyTonePicker.tsx` per [ui.md](contracts/ui.md). Props: `{ value, onChange(id): Promise<void> }`. It is a fieldset with a visually hidden legend "Buddy tone", 6 native radio label cards (name + "Default" pill, vibe, "Best for: …", italic example) and `name="buddy-tone"`. Selecting calls `onChange`; radios are disabled while saving. Success shows `role="status"` "Saved."; failure rolls back to the previous value with `role="alert"` "Couldn't save your tone. Please try again."
- [X] T008 [P] [US1] Component test `FE/features/personal-target/components/BuddyTonePicker.test.tsx` (jsdom):
  - The given value is checked.
  - Picking Warm Anchor calls `onChange('WARM_ANCHOR')` and shows "Saved."
  - A rejected `onChange` puts the selection back and shows the error.
  - Every radio has an accessible name.
- [X] T009 [US1] In `FE/features/personal-target/pages/PersonalTargetPage.tsx`, add the "Buddy tone" card below "Your goals":
  - Load the tone with `fetchUserSettings(userId)` (`settings/api/userSettings.ts`); show "Loading tone…" while it loads, and an error with Retry if it fails.
  - `onChange` = `saveUserSettings(userId, { buddyTone })`, then set the value from the response.
- [X] T010 [US1] Add `.pt-tone*` styles in `FE/App.css`: token-only cards, a visible checked state (border plus accent) and focus ring, one column at 320px and two from 720px, targets of at least 24px, and a visually hidden legend
- [X] T011 [US1] Extend `ui-personal-routine-manager/e2e/personal-target.spec.ts`: Balanced is checked by default, pick Warm Anchor → "Saved.", reload → Warm Anchor is still checked

**Checkpoint**: users can choose and keep a tone (US1).

---

## Phase 4: User Story 2 – Buddy talks in my tone (P1)

**Goal**: every Buddy call uses the chosen tone, with the rules that apply to every tone.

**Independent Test**: quickstart B1–B5 (real Gemini). Automated: the formatter unit test, and the existing suites stay green.

- [X] T012 [P] [US2] Unit test `BT/unit/BuddyTonePromptTest.java`:
  - Each tone's block contains its display name and its own style line, and the 6 style lines are distinct.
  - Every block has the 3 rules for every tone (no blame/shame/guilt; wording never changes permissions or confirmations; change tone on the Personal Target page).
  - `BuddyTone.fromStored(null/"x")` is `BALANCED`.
- [X] T013 [US2] Create the pure formatter `BE/funcs/BuddyTonePrompt.java`: `format(BuddyTone)` returns the exact text in [buddy-prompt-tone.md](contracts/buddy-prompt-tone.md)
- [X] T014 [US2] Add `BuddyTone buddyTone(UUID userId)` (read-only) to `BE/service/UserSettingsService.java`: read the user's `buddyTone` row and use `BuddyTone.fromStored` on the effective value
- [X] T015 [US2] Create `BE/service/BuddyContextService.java`: `promptBlock(UUID userId, boolean inChat)` = `PersonalGoalPrompt.format(goalService.list(userId), inChat)` + `BuddyTonePrompt.format(settingsService.buddyTone(userId))`
- [X] T016 [US2] Use `BuddyContextService.promptBlock(userId, true)` in place of the goals-only block in `BE/service/GeminiAiChatService.java` (both chats) and in `BE/service/reflection/GeminiReflectionAiService.java` `chat`. Use `promptBlock(userId, false)` for `feedback`, keeping the existing `TONE_RULES` and the "connect to a goal" line. Remove the now-unused direct `PersonalGoalService` use where it is only for the block (keep it for `GoalProposalTool`)

**Checkpoint**: Buddy uses the tone everywhere.

---

## Phase 5: Polish

- [X] T017 [P] Add `BuddyTonePromptTest` and the extended `UserSettingsRegistryTest`/`UserSettingsComponentTest` counts to `ms-personal-routine-manager/docs/test-flows.md`
- [X] T018 [P] Update `ms-personal-routine-manager/CLAUDE.md`: the UserSetting bullet gets `buddyTone`, and the AI note gets `BuddyContextService` and the tone block
- [X] T019 [P] Update `ui-personal-routine-manager/CLAUDE.md`: the personal-target bullet gets the Buddy tone section, why it isn't in the settings store, and `buddyTone` in the settings schema
- [X] T020 Gates: backend `./gradlew build -PtestDb=postgres`; frontend `pnpm lint && pnpm build && pnpm test`; `pnpm test:e2e` (all journeys)
- [X] T021 Run quickstart A1–A4 through the automated tests and e2e. Leave B1–B5 (real Gemini wording) for the user's manual check

- [X] T022 Analyze remediation E1: `BT/component/BuddyContextComponentTest.java`. The tone saved via PATCH and a goal saved via POST reach `BuddyContextService.promptBlock` (chat has the proposal rule; feedback doesn't)

**Results (2026-11-24)**: backend `./gradlew build -PtestDb=postgres` 191/191 plus the context test 2/2; frontend lint (no new warnings), build and 218 unit/component tests pass; Playwright 10/10. Quickstart B1–B5 (tone wording with real Gemini) are left for the user's manual check.

---

## Dependencies & Execution Order

- Foundational (T001–T004) → US1 (T005–T011) and US2 (T012–T016). The two stories are independent of each other.
- US2 T013 needs T001; T014 needs T001 and T002; T015 needs T013 and T014; T016 needs T015.
- Polish runs after both stories.

## Parallel examples

- T003 and T004 after T001/T002; T005, T006, T008 and T012 together.

## Implementation strategy

1. MVP = Foundational + US1 (the choice is stored and visible).
2. US2 makes Buddy use it.
3. Polish and gates.
