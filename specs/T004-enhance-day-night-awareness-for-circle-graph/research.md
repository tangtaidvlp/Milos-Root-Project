# Research: Day & night awareness for the circle graph

Measured from `resources/day-clock-light.png` (520 px, centre 260,260; clock radius = rim outer edge = 200 px).

## R1 Proportions

- **Decision**: rim track stays `radius - track … radius` (sketch: 180–200 px, track ≈ 0.1 r, same as today's `clamp(0.11 r, 10, 24)`). Centre disc radius = `0.62 × radius` (sketch 123/200), replacing `radius - track - 18`. The band is the ring between the disc and the track's inner edge.
- **Rationale**: matches the sketch; keeps the existing track and arc lanes.
- **Alternatives**: keep the current disc and draw a thin band — rejected, no room for icon + label.
- Centre text sizes already scale from `discRadius`; `CENTRE_DETAILS_FROM` (64) still decides the "until" line, so small clocks drop it earlier. Acceptable.

## R2 Day/night geometry

- **Decision**: `minutesToAngle` puts 00:00 at the top. Night = 18:00 → 06:00 = angles 270° → 90° (through 0°); day = 90° → 270°. Draw each half of the band as a filled half-annulus path (`annulusPath(cx, cy, inner, outer, startAngle, sweep)`), and the rim track as two 180° stroked arcs (existing `arcPath`), night colour and day colour.
- **Rationale**: pure function, unit-testable; reuses existing arc helpers.

## R3 Marks

- **Decision**: hour ticks as today. Add a minor tick at every 15 minutes that is not an hour (72 ticks), shorter and lighter, drawn only when `radius >= 90` (they clutter tiny clocks). Hour ticks and numbers: hours 19–23 and 01–05 use the night tone, 07–11 and 13–17 the day tone; 00, 06, 12, 18 stay neutral and emphasised (existing `is-major`). In dark mode 06 and 18 sit in a pill (rounded rect behind the number, `--color-bg-muted`-like token).
- **Rationale**: sketch shows 3 small marks per hour and tinted numbers.

## R4 Icons and labels

- **Decision**: inline the two SVG icons as React components (`SunIcon`, `MoonIcon`) with the paths from `resources/icon-sun.svg` / `icon-moon.svg`, `stroke="currentColor"`, c2pa metadata dropped. Night: moon + "NIGHT" centred in the band at the top (angle 0); day: sun + "DAY" at the bottom (angle 180). The band (`radius - track - discRadius`) needs 36 px for icon + label; from 22 px only the icon shows, centred; below that neither (review: the default Today layout with Buddy open has a ~30 px band).
- **Rationale**: no asset loading, colour from tokens, no untrusted markup.

## R5 Colours (tokens)

Values from the task table; the table gives one value for band/icon/label (both themes) and two for the rim track.

| Token | Light | Dark |
|---|---|---|
| `--color-clock-night-band` | #20336F | #20336F |
| `--color-clock-day-band` | #FFF8EE | #FFF8EE |
| `--color-clock-night-ink` (moon + NIGHT) | #EEF1FB | #EEF1FB |
| `--color-clock-sun` | #C9781F | #C9781F |
| `--color-clock-day-ink` (DAY) | #3B2F1E | #3B2F1E |
| `--color-clock-night-track` | #DDE3F4 | #272D47 |
| `--color-clock-day-track` | #F6E9D4 | #342A1D |
| `--color-clock-night-tone` (night ticks/numbers) | pick to match sketch, ≥ 3:1 on `--color-bg-surface` | same |
| `--color-clock-day-tone` (day ticks/numbers) | pick to match sketch, ≥ 3:1 on `--color-bg-surface` | same |

Contrast checks: label inks ≥ 4.5 on their band; sun ≥ 3 on day band (graphic); tones ≥ 3 on surface (same rule as `--color-text-muted`, which hour numbers use today).
