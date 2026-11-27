# Data Model: Buddy Tone (F014)

## 1. Tone preference (stored)

There is no new table. The tone is one row in `user_setting` (F006): `setting_key = 'buddyTone'`, `setting_value` = a tone id. No row, or an invalid stored value, means `BALANCED`.

| Key | Values | Default | Input rule | Error (400) |
|---|---|---|---|---|
| `buddyTone` | `BALANCED`, `CHIEF_OF_STAFF`, `STOIC`, `SOCRATIC_PEER`, `WARM_ANCHOR`, `ACCOUNTABILITY_COACH` | `BALANCED` | JSON string, case-insensitive, trimmed, stored upper-case | `buddyTone must be one of BALANCED, CHIEF_OF_STAFF, STOIC, SOCRATIC_PEER, WARM_ANCHOR, ACCOUNTABILITY_COACH` |

Ids are persisted, so they are never renamed or removed without a migration (constitution III).

## 2. BuddyTone (fixed catalogue, `funcs/BuddyTone` enum)

| Id | Display name | Directiveness | Warmth | Strictness | Length |
|---|---|---|---|---|---|
| `BALANCED` | Balanced | Suggests | Medium | Balanced | Brief |
| `CHIEF_OF_STAFF` | Tactical Chief of Staff | Directs | Low | Balanced | Brief, structured |
| `STOIC` | Grounded Stoic | Suggests | Medium | Forgiving | Brief |
| `SOCRATIC_PEER` | Socratic Peer | Asks | Medium | Balanced | Moderate |
| `WARM_ANCHOR` | Warm Anchor | Asks | High | Forgiving | Brief |
| `ACCOUNTABILITY_COACH` | High-Accountability Coach | Directs | Low | Firm | Brief |

Each enum constant has a display name and one prompt style line that puts the preset into words. The UI copy (core vibe, best used for, example) is in the frontend catalogue `features/personal-target/utils/buddyTones.ts`. It comes from spec.md "Tone catalogue", and its ids are the same.

## 3. Buddy context (not stored)

`BuddyContextService.promptBlock(userId, inChat)` = `PersonalGoalPrompt.format(goals, inChat)` (F013) + `BuddyTonePrompt.format(tone)`. It is appended to the system text of every Buddy call. F015 adds the time of day here.
