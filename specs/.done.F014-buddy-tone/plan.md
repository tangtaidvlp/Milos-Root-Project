# Implementation Plan: Buddy Tone

**Branch**: `feat/E001-personal-target` (epic branch; F014 = phase 2) | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/F014-buddy-tone/spec.md` (epic [E001](../E001-personal-target/E001-personal-target.md))

## Summary

Users pick one of 6 fixed tones on the Personal Target page, and Buddy talks in it.

- **Storage**: the tone is a new F006 account setting, `buddyTone` (default `BALANCED`, no DDL).
- **Prompt**: a pure formatter turns the tone's fixed preset into a "How you talk" block with three rules for every tone (no guilt, no change to what Buddy may do, point to the page). A new `BuddyContextService` combines this block with the F013 goals block for all four Buddy calls.
- **UI**: the page gets a native radio-card picker that saves at once and rolls back on failure ([research.md](research.md)).

## Technical Context

**Language/Version**: Java 25; TypeScript strict + React 19

**Primary Dependencies**: Spring Boot 4.1, Spring AI 2.0 (Gemini); React Router 7, Vite 8. No new dependencies.

**Storage**: the existing `user_setting` table (one more key). No DDL.

**Testing**: JUnit 5 unit and component tests (mock AI); Vitest + Testing Library; Playwright

**Target Platform**: EC2 (API), GitHub Pages (SPA)

**Project Type**: Web application

**Performance Goals**: The prompt grows by about 0.8 KB.

**Constraints**: Tones are fixed presets; tone never changes Buddy's permissions; no live LLM in tests

**Scale/Scope**: 1 setting key, 1 enum, 2 pure formatters (1 new), 1 small service, 1 UI section

## Constitution Check

| Principle | Check | Result |
|---|---|---|
| I. Contract-first | [settings-buddy-tone.md](contracts/settings-buddy-tone.md) adds an additive key; backend registry and frontend `settingsSchema.ts` change together | PASS |
| II. Testing | Unit: registry and tone prompt. Component: settings flow. Frontend: unit, picker component test, e2e journey. Mock AI only | PASS |
| III. Data | No DDL. New persisted ids are documented and never renamed | PASS |
| IV. Security | The existing settings owner checks and server-side validation apply | PASS |
| V. AI agency | A tone rule states that wording never changes permissions or confirmations. Only the tone id is added to the prompt | PASS |
| VI. Frontend | Native fieldset/radio (WCAG), tokens only, works at 320px | PASS |
| VII–VIII | No new dependencies; nothing new logged | PASS |
| IX. Simplicity | Reuses the settings registry; one context service replaces per-call prompt assembly | PASS |

**Post-design re-check**: unchanged, all PASS.

## Project Structure

### Documentation

```text
specs/F014-buddy-tone/
├── spec.md, plan.md, research.md, data-model.md, quickstart.md
├── contracts/settings-buddy-tone.md, buddy-prompt-tone.md, ui.md
└── tasks.md   # /speckit-tasks
```

### Source Code

```text
ms-personal-routine-manager/src/main/java/com/tom/payment/routinemanager/
├── funcs/BuddyTone.java                      # new enum: ids, display names, style lines
├── funcs/BuddyTonePrompt.java                # new pure formatter
├── service/UserSettingsRegistry.java         # + buddyTone definition
├── service/UserSettingsService.java          # + buddyTone(UUID userId)
├── service/BuddyContextService.java          # new: goals + tone block per user
├── service/GeminiAiChatService.java          # use BuddyContextService
└── service/reflection/GeminiReflectionAiService.java   # use BuddyContextService
ms-personal-routine-manager/src/test/java/com/tom/payment/routinemanager/
├── unit/UserSettingsRegistryTest.java        # + buddyTone cases
├── unit/BuddyTonePromptTest.java             # new
└── component/UserSettingsComponentTest.java  # + buddyTone flow

ui-personal-routine-manager/
├── e2e/personal-target.spec.ts               # + pick tone, reload
└── src/
    ├── App.css                               # + .pt-tone*
    ├── features/settings/types/settings.ts, utils/settingsSchema.ts (+ test)   # + buddyTone
    └── features/personal-target/
        ├── utils/buddyTones.ts (+ .test.ts)  # UI catalogue
        ├── components/BuddyTonePicker.tsx (+ .test.tsx)
        └── pages/PersonalTargetPage.tsx      # + Buddy tone section
```

**Structure Decision**: Same layout as F013. The tone is part of the `personal-target` feature, and its persistence reuses `features/settings/api`.

## Complexity Tracking

No violations.
