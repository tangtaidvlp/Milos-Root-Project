# Data Model: Context-Aware Tone (F015)

Nothing new is stored. These are pure rules and value types.

## TimeOfDay (`funcs/TimeOfDay` enum)

| Window | Local time | Style (prompt) |
|---|---|---|
| `MORNING` | 05:00–11:59 | energetic, crisp and decisive; clarity, and protect the first important block of the day |
| `MIDDAY` | 12:00–16:59 | objective and adaptable; re-plan around disruptions without guilt |
| `EVENING` | 17:00–04:59 | slower, reflective and validating; close open items so the user can switch off |

- `of(LocalTime)`: morning if 05:00 ≤ t < 12:00; midday if 12:00 ≤ t < 17:00; evening otherwise.
- `parse(String)`: an optional `LocalTime`. Only `HH:mm` with HH 00–23 and mm 00–59 is accepted; anything else, null included, is empty.

## ChatKind (`funcs/ChatKind` enum)

- `DAY_TO_DAY`: at most 3 sentences of text unless the user asks for more detail; a requested plan or task list doesn't count.
- `DEEP`: longer coaching is allowed when it helps.

## BuddyCall (`service/BuddyCall` enum)

| Call | inChat (proposal tool rule) | ChatKind |
|---|---|---|
| `DEFAULT_ROUTINE_CHAT` (includes onboarding) | true | DEEP |
| `DAILY_CHAT` | true | DAY_TO_DAY |
| `REFLECTION_CHAT` | true | DEEP |
| `REFLECTION_FEEDBACK` | false | DEEP |
