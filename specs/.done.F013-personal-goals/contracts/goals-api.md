# Contract: Personal Goals API (F013)

Base path: `/api/v1/users/{userId}/goals`. Controller: `api/PersonalGoalController`.

**All endpoints**:
- Auth uses the bearer JWT in `test`/`sit`/`prod`.
- `CurrentUserGuard.requireUser(userId)` returns 404 `User not found` for an unknown user and 403 when the JWT user ≠ `{userId}`. Without a token, the response is 401 `Please sign in to continue.`
- Every error body is `ApiError` `{status, error, message, timestamp}`.

## Types

```jsonc
// GoalView
{
  "id": "6c1e…",                    // UUID
  "goal": "Run a 10k by March",     // 1–150 chars, trimmed
  "howToHelp": "Keep me training 3x a week", // ≤ 500 chars, or null
  "createdAt": "2026-11-24T09:00:00Z",
  "updatedAt": "2026-11-24T09:00:00Z"
}

// GoalSaveView (POST/PUT response, iteration 2026-11-24: Buddy reviews the goal first)
{
  "goal": { /* GoalView */ } | null,   // set when saved
  "review": null | {                  // set when Buddy refused; nothing was saved
    "reason": "Sleeping 3 hours a night isn't safe for long.",   // 1–300 chars
    "suggestion": { "goal": "Sleep 7 hours a night", "howToHelp": null } | null
  }
}

// GoalRequest (POST/PUT body). Unknown fields are ignored. Server fields (id, dates) are ignored on input.
{ "goal": "Run a 10k by March", "howToHelp": "Keep me training 3x a week" } // howToHelp optional/null
```

## GET `/api/v1/users/{userId}/goals`

200:

```json
{ "goals": [ /* GoalView, oldest first */ ], "limit": 3 }
```

A user with no goals gets `{"goals": [], "limit": 3}`. The GET is read-only and never writes.

## POST `/api/v1/users/{userId}/goals`

Creates a goal after Buddy's review. 201 + `GoalSaveView` with `goal` when saved; 200 + `GoalSaveView` with `review` (and `goal: null`) when Buddy refuses it. Text rules and the limit are checked before the review.

| Status | When | `message` |
|---|---|---|
| 400 | goal missing or blank | `Goal is required.` |
| 400 | goal > 150 after trim | `Goal must be 150 characters or fewer.` |
| 400 | howToHelp > 500 after trim | `How Buddy should help must be 500 characters or fewer.` |
| 409 | user already has 3 goals | `You can have up to 3 goals.` |
| 503 | Buddy couldn't review the goal | `Buddy couldn't check your goal right now. Please try again in a moment.` |

## PUT `/api/v1/users/{userId}/goals/{goalId}`

Replaces both texts: `howToHelp` null or blank clears it. 200 + `GoalSaveView`: `goal` (with `updatedAt` changed) when saved, or `review` when Buddy refuses it (the goal is unchanged). A request that changes nothing is saved without a review.

| Status | When | `message` |
|---|---|---|
| 400 | same validation as POST | as above |
| 404 | the goal doesn't exist or isn't this user's | `Goal not found` |
| 503 | Buddy couldn't review the goal | as POST |

## DELETE `/api/v1/users/{userId}/goals/{goalId}`

204 with no body. 404 `Goal not found` when the goal doesn't exist or isn't this user's.

## Notes

- Backward compatible: new endpoints only.
- The frontend client is `ui-personal-routine-manager/src/features/personal-target/api/goals.ts`.
