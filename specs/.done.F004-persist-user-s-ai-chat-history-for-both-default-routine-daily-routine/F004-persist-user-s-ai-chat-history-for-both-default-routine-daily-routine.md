# F004 – Persist user's AI Chat history for both Default Routine & Daily Routine

<!--
  Describe the feature you want in plain language, then run `/speckit-specify F###` (this file's ID),
  or `/speckit-specify` with no arguments. The command reads this file as the feature description,
  writes `spec.md` next to this file in the same `specs/F###-<slug>/` folder.
  Put mockups, screenshots and other reference files in this folder's `resources/` subfolder; Claude reads them as part of the request.
  Claude discusses open questions with you and keeps its understanding, plan and decisions in a
  "Claude Working Notes" section at the end of this file. Edit your sections; leave that one to Claude.
  Focus on WHAT and WHY. Leave HOW (tech stack, APIs, code) to `/speckit-plan`.
  Delete any section you have nothing to say about. Only "Summary" is required.
-->

## Summary
Chat remain in User AI chat window
We need to persist user chat into database and load them when user log into the app
<!-- One or two sentences: what do you want to build? -->


## Problem / Motivation
Chat are missing, not good
<!-- What pain point or need does this address? Why now? -->


## Users
End user
<!-- Who uses this? (e.g., signed-in user, guest, admin) -->


## What the user should be able to do
See their history chat
<!-- Main flows, one per bullet, most important first. -->

- 

## Rules & Constraints
Conversation are stored into database and reload
Supporting storing compact conversation after every 20 chat messages (for token optimising) (20 is configurable from config file)
<!-- Business rules, limits, validations, things that must or must not happen. -->

- 

## Out of Scope

<!-- What this feature explicitly does NOT include. -->

- 

## How we know it works
Reload page still load the history chat, can lazy load when user load up, maximum 20 messages per reload
<!-- Observable outcomes or acceptance examples. -->

- 

## Notes / Open Questions

<!-- Anything else: references, mockups, ideas, unknowns. -->


## Claude Working Notes

<!-- Maintained by /speckit-specify. Edit the sections above; Claude updates this one. -->

**Status**: Spec generated
**Last updated**: 2026-11-21

### My understanding
- Today Buddy chat lives only in server memory (last 20 messages per conversation) and in browser state; a page reload or server restart loses it.
- Conversations are already scoped: one per user + default routine, and one per user + day for Daily Routine. Persistence keeps that scoping.
- On opening a chat window, the user sees their most recent messages (up to 20), and can lazy-load older ones in pages of 20.
- To limit AI token use, after every N messages (default 20, configurable) the conversation is compacted into a summary that Buddy uses as context.

### Working plan
- [x] Agree on open questions
- [x] Generate spec at `specs/F004-persist-user-s-ai-chat-history-for-both-default-routine-daily-routine/spec.md`
- [x] Validate spec against the quality checklist
- [ ] Next: `/speckit-clarify` or `/speckit-plan`

### Assumptions
- Only the owning signed-in user can read their chat history.
- Failed / error bot messages are not persisted.
- Buddy's greeting (initial message) is a UI element, not stored history.
- Full original history stays viewable; compaction summaries are only Buddy's context.
- Onboarding chat is part of the default routine's conversation.
- No clear/delete history in this feature; history kept indefinitely.
- Lazy-load page size is fixed at 20; compaction threshold N (default 20) is operator config.

### Discussion log
- 2026-11-21 — Q: After compaction, what does the user see when scrolling back? Options: full history / summary replaces old. **Answer**: Full history. **Decision**: Keep all original messages viewable; summary is internal context only.
- 2026-11-21 — Q: Persist the onboarding chat too? Options: yes, same thread / no, exclude. **Answer**: Yes, same thread. **Decision**: Onboarding messages belong to that default routine's conversation.
- 2026-11-21 — Q: Allow clearing chat history? Options: out of scope / clear per conversation. **Answer**: Out of scope. **Decision**: No clear action; history kept indefinitely.

### Result
- Spec: `specs/F004-persist-user-s-ai-chat-history-for-both-default-routine-daily-routine/spec.md`
- Checklist: all 16 items pass on first validation (`checklists/requirements.md`).
