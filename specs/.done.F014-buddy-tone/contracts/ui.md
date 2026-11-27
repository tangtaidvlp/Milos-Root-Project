# Contract: UI – Buddy tone section (F014)

The Personal Target page (F013) gets a second card below "Your goals":

- `section.ui-card` with the heading "Buddy tone" and one line: "Choose how Buddy talks to you. You can change it any time."
- `BuddyTonePicker` (`features/personal-target/components/`):
  - A `<fieldset>` with a visually hidden `<legend>` "Buddy tone", holding 6 native radio inputs (`name="buddy-tone"`), each wrapped in a label card.
  - Each card shows the **name** (Balanced has a "Default" pill), the core vibe, "Best for: …" and the example phrase in italics. The data comes from `utils/buddyTones.ts`.
  - **Selection**: the radio whose id equals the saved tone. While loading, "Loading tone…" is shown. If the load fails, an inline error with Retry is shown.
  - **Change**: picking a card saves at once (`saveUserSettings(userId, { buddyTone })`):
    - While the save runs, the radios are disabled.
    - On success, a polite `role="status"` line says "Saved.".
    - On failure, the selection rolls back to the previous tone and an inline `role="alert"` says "Couldn't save your tone. Please try again."
- Keyboard: arrow keys move between radios (native behaviour), and focus is visible. Cards are at least 24×24 px targets, use tokens only and fit one per row at 320px (two columns from 720px). The styles are `.pt-tone*` classes in `App.css`.
