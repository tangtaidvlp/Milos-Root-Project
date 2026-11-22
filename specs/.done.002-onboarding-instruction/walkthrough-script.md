# Walkthrough Script: Onboarding Instruction

**Feature**: [spec.md](./spec.md) · **Ticket**: [F001](./F001-onboarding-instruction.md)
**Status**: Reviewed 2026-11-20 · open choices resolved (see Decisions)

This file holds the exact wording and the step-by-step behaviour of the intro slides and the guided tour. The spec says *what* must happen (FR-003 to FR-008, FR-012, FR-013). This script says *what the user sees and does*. Edit the wording here freely. If a change alters behaviour (new steps, different order), update the spec too.

No open choices left. Decisions are recorded at the end of this file.

**Visual design**: the desktop mockups in [resources/](./resources/) are the source of truth for layout and look: 4 slides (`D · Slide 1–4 …png`) and 5 tour steps (`D · Tour 1–5 of 5 …png`). If this script and a mockup disagree on layout, follow the mockup. If they disagree on wording, raise it. There are no phone mockups yet, so phone behaviour follows the rules below.

---

## Part 1 – Intro slides (4 screens)

### Layout

- A centered white card on top of the setup screen, which is dimmed behind it. The board and chat stay faintly visible.
- **Top left**: a small rounded icon tile for the slide (see each slide below).
- **Top right**: a **Skip** link on every slide. It closes the slides and opens the setup screen with no tour (FR-008).
- **Above the headline**: a small uppercase blue label, for example "WHAT IS MILOS?". Then the bold headline, then one short paragraph.
- **Bottom**: four progress dots, where the current one is a wider blue pill. **Back** sits on the left and **Next** (blue button) on the right. Back is hidden on slide 1.

### Navigation

| Input | Action |
|-------|--------|
| **Next** / → key / swipe left | Next slide |
| **Back** / ← key / swipe right | Previous slide |
| Tap a progress dot | Jump to that slide |
| **Skip** / Esc | Close the slides and open the setup screen, no tour |

### Slide 1 – What is Milos?

Icon: calendar · Label: WHAT IS MILOS?

> **Plan your days once. Then just live them.**
>
> Milos is a time-management app. You set up a default routine for weekdays and one for weekends, and Milos turns them into your plan for each day.

### Slide 2 – How a day works

Icon: two arrows (repeat) · Label: HOW A DAY WORKS

> **Every day starts from your routine.**
>
> Each new day starts as a copy of its default routine, weekday or weekend. Follow it as planned, or move, change or tick off tasks as your day really goes.

### Slide 3 – See how you really spend your time

Icon: bar chart · Label: SEE HOW YOU REALLY SPEND YOUR TIME

> **Your habits, in numbers (coming soon).**
>
> Milos keeps track of what you planned and what you actually did. Soon you'll be able to see a breakdown of how you really spend your time.

### Slide 4 – Let Routine Buddy do the work · What to do first

Icon: sparkles · Label: LET ROUTINE BUDDY DO THE WORK

> **You don't have to plan every detail.**
>
> Tell Routine Buddy about your day ("I work 9 to 5, gym at 6") and it builds your routine for you. Later, ask it to rearrange things and it will.

Below the paragraph is a light-blue callout box with a small blue heading **First step**:

> Set up your Weekday and Weekend routines, by hand or by chatting with Routine Buddy.

Bottom row of this slide, from left to right: **Back** · progress dots · *I'll explore myself* (text link) · **Show me around** (blue button).

- **Show me around**: starts the guided tour.
- *I'll explore myself*: same as Skip.

---

## Part 2 – Guided tour (5 steps on the setup screen)

### Layout

- The screen dims except for one control, which keeps full color and gets a glowing light-blue outline.
- A small white speech-bubble card sits next to the highlighted control, with a little arrow pointing at it. It shows:
  - **Top**: a blue step counter ("2 of 5"), followed by a 5-segment progress bar with the completed segments filled.
  - **Middle**: one or two sentences.
  - **Bottom**: an **End tour** link on the left. **Back** (outlined) and **Next** (blue) on the right.
- Exceptions shown in the mockups:
  - **Step 1** has no Back button.
  - **Step 5** has no End tour link. It shows **Back** and **Got it**.
- Clicking the dimmed area does nothing, so the tour can't be closed by accident. Esc means End tour.

### Steps

| Step | Highlights | Card text |
|------|------------|-----------|
| Step | Highlights | Card position (desktop) | Card text |
|------|------------|-------------------------|-----------|
| 1 of 5 | **Weekday / Weekend switch** (top bar) | Below the switch | "You have two default routines. Switch here to set up each one." |
| 2 of 5 | **Routine board** (whole card) | To the right of the board, near its top | "This is your default routine. Every new day starts as a copy of it." |
| 3 of 5 | **+ button** (bottom-right of board) | Above the button | "Add a task yourself: name, start time, length." |
| 4 of 5 | **Routine Buddy chat** (whole panel) | To the left of the panel, near its top | "Or just tell Buddy about your day, and it fills in the board for you." |
| 5 of 5 | **Ready to roll** button | Below the button | "When both routines look right, finish here. Your changes are already saved as you go." Button: **Got it** (ends the tour) |

Step 1, step 5 and slide 4 talk about two separate routines. Weekday/Weekend separation ships with this feature (see Decisions).

### Phone behaviour

- **Step 4**: the chat lives in a hidden panel, so the tour switches to the chat view for this step.
- **Step 5**: the tour switches back to the board view.
- **Placement**: the cards sit above or below the highlighted control, never on top of it.

---

## Part 2b – Setup screen changes shown in the mockups

The mockups also show some changes to the setup screen itself:

| Where | Today | In the mockups |
|-------|-------|----------------|
| Top bar | none | A **How it works** text link, to the left of the Weekday/Weekend switch |
| Board header subtitle | "Drag to reorder" | "Every new weekday starts as a copy of this · drag to move" (presumably "weekend" on the Weekend tab) |
| Routine Buddy greeting | "Hi! I'm your Routine Buddy. We can build your schedule together. Try telling me your first habit…" | "Hi! I'm your Routine Buddy. Tell me about your day, like "I wake up at 7:00 and work 9 to 5", and I'll build the routine. Or tap + to add tasks yourself." |

The zoom (− 100% +) and **Gap clear** controls in the mockups already exist and don't change.

---

## Part 3 – After the tour and on later visits

| Situation | What happens |
|-----------|--------------|
| Tour ends (**Got it**, **End tour**, or Esc) | Normal setup screen. A **How it works** link stays in the top bar. |
| Next visit, onboarding not finished | The slides start again from Slide 1. Skip opens the saved board. |
| **How it works** on the setup screen | The slides, then the tour |
| Onboarding finished | Nothing appears on its own. **Replay tour** in the sidebar (F002) replays the slides only, with no tour. Slide 4's main button reads **Close** instead of **Show me around**. |

---

## Decisions (2026-11-20)

| # | Topic | Decision |
|---|-------|----------|
| D1 | Slide 3 wording | Version B ("coming soon"). Routine Buddy's daily chat only receives that day's routine, so it can't analyse past days yet. Spec FR-003(c) updated to match. |
| D2 | Weekday vs Weekend | Keep the two-routine wording. Making the Weekday/Weekend switch keep two separate routines is in scope for F001. |
| D3 | Slide 2 wording | "Each morning, Milos copies…" changed to "Each new day starts as a copy of its default routine, weekday or weekend." A day's plan is created when that day is first opened, not at a fixed morning time, and it must match FR-003(b) ("matching default routine"). |
| D4 | Visual design | The desktop mockups in `resources/` (added 2026-11-20) are the reference for layout and look. They confirm D1 to D3. They add slide icons and labels, the "First step" callout, the tour progress bar, the step 1 and step 5 button exceptions, and the setup screen text changes in Part 2b. |
