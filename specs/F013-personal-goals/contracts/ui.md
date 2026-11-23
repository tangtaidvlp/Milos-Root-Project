# Contract: UI – Personal Target page and proposal card (F013)

## Navigation

- **Sidebar**: a new `NAV_ENTRIES` item `{ id: 'personal-target', label: 'Personal Target', path: '/personal-target', icon: TargetIcon }`, placed after Default routine and before Analytics.
- **Route**: `/personal-target` is a shell route (inside `RequireOnboarded` + `AppShell`). It renders `PersonalTargetPage` (`features/personal-target/pages/`).

## Personal Target page

- `<PageHeader>` title "Personal Target".
- **Goals card** (`section.ui-card`, heading "Your goals"). This is the only section in F013; F014 adds "Buddy tone" below it.
  - **Loading**: a "Loading goals…" status.
  - **Load error**: an inline error with Retry. Never an empty list on failure.
  - **Empty**: one line explaining the goals ("Buddy uses your goals to tailor its suggestions. Add up to 3.") and an "Add goal" button.
  - **List**: up to 3 goal items in API order. Each shows the goal, its "How Buddy should help" text (if any), and Edit and Delete buttons. Button accessible names include the goal text, for example "Edit goal: Run a 10k".
  - **Add/Edit form**: inline in the card.
    - "Goal" text input (required, `maxLength` 150, with a visible count "n/150").
    - "How should Buddy help?" textarea (optional, `maxLength` 500, with "n/500").
    - Save and Cancel buttons. Save is pending while the request runs.
    - Client-side checks use `goalRules.ts`. A server 400/409 message shows inline under the form, and the entered text is kept.
    - Only one form is open at a time.
  - **Limit**: with 3 goals the "Add goal" button is disabled, and a note says "You can have up to 3 goals."
  - **Delete**: `ConfirmDialog` ("Delete this goal?"). On confirm it calls DELETE and the item disappears. Cancel keeps the goal. On failure the item stays and the error shows.
- Labels are visible and tied to their inputs. Everything works by keyboard. Focus moves to the form's first field on Add/Edit and back to the triggering button on Cancel. Style uses tokens only (`.pt-*` classes in `App.css`). There is no horizontal scroll at 320px.

## Buddy chat proposal card

- `BuddyChat` renders `GoalProposalCard` under a bot message that carries a `goalProposal`.
- **Card content**:
  - The title is "New goal" for ADD or "Change goal" for UPDATE.
  - For UPDATE, the card shows "Now" and "Proposed" for both texts.
  - For ADD, the card shows the proposed goal and the "how to help" text.
- **Buttons**: Confirm and Dismiss.
- **States**:
  - **Pending**: buttons disabled while saving.
  - **Saved**: "Saved to your goals." with a link to `/personal-target`.
  - **Dismissed**: "Not saved."
  - **Error**: the server's `message`. The card stays actionable only for a network error (status 0); 4xx errors are final.
- The status area is `role="status"` so screen readers announce the outcome.
- On phones (≤ 760px) pages normally switch back to the board after Buddy replies. A reply with a proposal keeps the chat view open so the card is seen: `BuddyChat` calls `onAfterSend({ hasGoalProposal })`.
