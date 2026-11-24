# E001 – Personal Target

**Type**: Epic

<!--
  An epic is a big change made of several features, often across services, delivered in phases.
  Describe the goal and list the features below. Then create each one with
  `/speckit-init feature <name>` and set its **Epic** line to this file's ID.
  An epic is not specified directly. Each of its features goes through `/speckit-specify`.
  Delete any section you have nothing to say about. Only "Summary" and "Features" are required.
-->

## Description

<!-- One or two sentences: what is the overall goal? -->
Provide Personal Configuration for users so AI could understand them

## Problem / Motivation

<!-- Why is this needed? Why now? -->
AI need user expectation to help them or guide them or correct them

## Details requirement


2. A "Personal Target" page for users to manage their personal goal, could be up to 3 goals, AI will based on these goals and give user better suggestion or what user expect at AI. (We will have what's their goal, what do they expect the AI to help them)  
- They can set AI tone their, something like below:  

| Archetype | Core Vibe | Best Used For | Example Phrasing |
| :--- | :--- | :--- | :--- |
| **The Tactical Chief of Staff** | Crisp, structured, proactive, zero-fluff. | Morning briefings, time-blocking, reprioritizing a derailed schedule. | *"You have 90 minutes before your next block. Knock out the API refactor now, and push the admin tasks to 4:00 PM."* |
| **The Grounded Stoic** | Calm, objective, non-judgmental, steady. | Missed habits, broken streaks, high stress, or recovery days. | *"You missed yesterday’s workout—that’s data, not failure. Let’s scale today’s session to 20 minutes to rebuild momentum."* |
| **The Socratic Peer** | Curious, analytical, collaborative. | Weekly retrospectives, habit troubleshooting, goal alignment. | *"You’ve pushed deep work past 8:00 PM three days in a row. Is your afternoon energy dipping, or is the task scope too vague?"* |
| **The Warm Anchor** | Encouraging, gentle, low-friction, empathetic. | Burnout recovery, wind-down routines, low-energy mornings. | *"Rough sleep last night. Keep today’s bar low: hydrate, clear your top one priority, and close the laptop by 6:00 PM."* |
| **The High-Accountability Coach** | Direct, challenging, energetic, firm. | Procrastination loops, physical training, strict deadline sprints. | *"You’ve snoozed this block twice. Put the phone in another room, set a 25-minute timer, and start."* |
2. Key Dimensions to Calibrate
If you are defining a system prompt or persona profile for a routine assistant, calibrate it along four axes:

Directiveness (Nudge vs. Command): Should it ask "Would you like to move this task?" or state "I’ve moved this to tomorrow morning so you can rest"? High-performing routine assistants lean slightly directive to reduce the user's decision fatigue.

Emotional Temperature (Warm vs. Clinical): Too clinical feels like a glorified cron job; too bubbly feels patronizing when a user is tired. A warm-pragmatic baseline—friendly in greetings, concise in execution—scales best over long-term daily use.

Friction Tolerance (Forgiving vs. Strict): A good routine specialist distinguishes between laziness (needs firm accountability) and capacity limits (needs compassionate scope reduction).

Verbosity (Micro-copy vs. Coaching): Daily check-ins and reminders require tight, scannable micro-copy (under 2–3 sentences). Deeper coaching tones should only trigger during planning sessions or reflections.

3. Context-Aware Tone Shifting
The most effective routine assistants shift tone automatically based on the time of day and user telemetry:

Morning (Initiation): Energetic, crisp, and decisive. Focuses on clarity and protecting the first high-leverage block.

Midday (Triage): Objective and adaptable. Helps renegotiate the schedule without guilt when unexpected disruptions happen.

Evening (Decompression): Slower, reflective, and validating. Closes open loops so the user can mentally clock out.

Streak-Break / Off-Track: Strictly non-punitive. Avoids guilt-tripping language ("You failed to...") in favor of forward-looking adjustments ("Resetting the baseline for tomorrow...").


## Features (by phase)

| Phase | ID | Feature | Scope |
|---|---|---|---|
| 1 | [F013](../F013-personal-goals/spec.md) | Personal goals | "Personal Target" page with up to 3 goals (goal + what Buddy should help with). Buddy uses them in every chat and can propose goal changes that the user confirms. The page has its own Buddy goals chat (US4), and Buddy checks every new or changed goal is realistic and safe before it's saved (US5); both added 2026-11-24. |
| 2 | [F014](../F014-buddy-tone/spec.md) | Buddy tone | User picks Balanced (default) or one of the 5 archetypes on the Personal Target page. Each tone is a fixed preset of the 4 axes. Buddy never uses guilt-tripping language. |
| 3 | [F015](../F015-context-aware-tone/spec.md) | Context-aware tone | Buddy adjusts the chosen tone to the user's time of day (morning / midday / evening) and keeps replies short in day-to-day chat, saving longer coaching for planning and reflection. |
| Later | — | Off-track tone | Data-driven off-track / streak-break detection. Waits for analytics metrics (decided 2026-11-24). |
| Later | — | Buddy on Analytics | Same Buddy chat with an Analytics setup (history, instructions, tools), built with the Analytics feature. Possible later step: one shared chat on every screen, with only Buddy's context changing (decided 2026-11-24). |

**Status (2026-11-24)**: F013, F014 and F015 are implemented on branch `feat/E001-personal-target` in both repos, with PRs open. The F013 iterations (Buddy chat on Personal Target; Buddy checks goals on save) are done but not committed yet. All automated gates pass. The manual test with real Gemini (each feature's quickstart) is still open before the features are closed.

## Services affected

<!-- e.g. ms-personal-routine-manager, ui-personal-routine-manager -->
all services
- 

## Out of Scope

- 

## Done when
This feature is integrated, all testing done, manual testing from me
<!-- Observable outcomes for the whole epic. -->

- 

## Notes / Open Questions

Ask as much as question you need

### Answered questions (2026-11-25)

1. **Push the iterations?** Yes. Committed and pushed to the E001 PRs.
2. **Existing chats return 500 when the AI fails.** Filed and fixed as B009.
3. **No per-user AI rate limit or timeouts.** Filed and fixed as B010.
4. **Goal saves while Buddy is down.** Block. Users must never be left with an unsafe goal, so FR-024 stays strict.

Needs from you (not questions): a valid `GEMINI_API_KEY` (the current one is rejected), then the manual checks in each quickstart, including F013 E1–E4 and F1–F6. Until then, run the backend with `SPRING_AI_ACTIVE=false` to save goals locally (the mock reviewer accepts everything except text with "impossible").
