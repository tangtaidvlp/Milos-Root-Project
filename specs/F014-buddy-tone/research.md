# Research: Buddy Tone (F014)

## R1. Where the tone is stored

- **Decision**: As a new account setting `buddyTone` in the F006 settings registry (`UserSettingsRegistry.builtIns()`). Its value is one of the 6 tone ids and its default is `BALANCED`. It is read and written through the existing `GET/PATCH /api/v1/users/{userId}/settings`. There is no DDL; it is one more row in `user_setting`.
- **Rationale**: The registry exists for exactly this: "add a preference = one definition + the frontend schema entry". It already gives validation, defaults, owner checks and `ApiError` 400s.
- **Alternatives**: A `buddy_tone` column on `users` was rejected (schema change, and `User` is serialised directly). A new endpoint was rejected (it duplicates settings).

## R2. Tone ids (persisted, never renamed)

`BALANCED`, `CHIEF_OF_STAFF`, `STOIC`, `SOCRATIC_PEER`, `WARM_ANCHOR`, `ACCOUNTABILITY_COACH`. Input is case-insensitive and stored upper-case, like `theme`. An unknown stored value reads as `BALANCED` (FR-011). The registry already ignores invalid stored values.

## R3. Saving from the page

- **Decision**: The Personal Target page reads the tone with `fetchUserSettings` and saves it with `saveUserSettings(userId, { buddyTone })`. On failure it rolls back to the last saved tone and shows an inline error (FR-010). The tone is **not** added to the module-level settings store.
- **Rationale**: The store's rule is "a failed save stays applied for this session". That is right for theme and zoom, which are applied in the browser. It is wrong for the tone, because the tone takes effect only on the server, where Buddy reads it. Showing an unsaved tone as selected would mislead the user.
- **Alternatives**: Routing the tone through the store with a special case was rejected: it complicates a shared store for one key.

## R4. Tone in Buddy's prompt

- **Decision**: A pure formatter, `funcs/BuddyTonePrompt.format(BuddyTone)`, builds a "How you talk" block. It has the tone's name, a style line from its fixed preset (directiveness, warmth, strictness, length) and three rules for every tone:
  1. No blame, shame or guilt language about missed tasks; acknowledge, then give a next step. Firm tones challenge the action, never the person.
  2. The tone changes wording only, never what Buddy may do, the data it uses, or which actions need confirmation.
  3. If asked to change tone, point to the Personal Target page.
  The presets live in the enum `funcs/BuddyTone`, one place for ids and styles. The goals block (F013) and the tone block are combined by `service/BuddyContextService.promptBlock(userId, inChat)`, which loads the goals and the tone and calls the pure formatters. All four Buddy calls use it: the default routine and onboarding chat, the daily routine chat, the reflection chat and reflection feedback. F015 adds the time of day to this same service.
- **Rationale**:
  - Fixed presets follow the user's decision ("fixed per tone").
  - One context service keeps the four call sites to one line each.
  - The universal rules cover FR-008, FR-009 and FR-012.
  - Reflection keeps its existing non-judgement `TONE_RULES`; the chosen tone shapes the style inside them. For example, Coach is direct but still kind in a reflection.
- **Alternatives**: Per-axis sliders were rejected by the user. A tone per chat kind is F015.

## R5. Frontend catalogue

- **Decision**: `features/personal-target/utils/buddyTones.ts` holds the 6 tones' UI copy (name, core vibe, best used for, example), mirrored from the spec's Tone catalogue. `settings/utils/settingsSchema.ts` gains `buddyTone` with `normalizeBuddyTone` (an unknown value becomes `BALANCED`). `BuddyTonePicker` is a native radio group: one `<fieldset>`/`<legend>` with 6 labelled radio cards, so arrow keys and screen readers work with no ARIA work (FR-013).

## R6. Testing

- **Backend**:
  - Unit: `UserSettingsRegistryTest` gets buddyTone cases (default, case-insensitive, unknown → 400 message), and the key list becomes `theme, boardZoom, buddyTone`.
  - Unit: `BuddyTonePromptTest` (each tone has a distinct style line, the rules are present).
  - Component: `UserSettingsComponentTest` gets the default `BALANCED`, a PATCH that stores `WARM_ANCHOR`, and an invalid value → 400.
  - Tone wording itself (SC-002, SC-003) is a manual review with real Gemini (quickstart).
- **Frontend**:
  - Unit: `buddyTones` and `normalizeBuddyTone`.
  - Component: `BuddyTonePicker.test.tsx` (select → saved; failure → rollback + error).
  - E2E: `personal-target.spec.ts` picks Warm Anchor, reloads, and checks it is still selected.
