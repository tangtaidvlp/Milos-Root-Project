# Data Model: Live Clock Off During Onboarding

No stored data changes. No backend, API or database changes.

## Board view settings (in memory, per board instance)

| Name | Type | Source | Notes |
|------|------|--------|-------|
| `liveClock` | boolean, default `true` | prop from the page | `false` on the setup screen, `true` (default) on the dashboard |
| `currentTime` | minutes 0–1439 | existing state | only used when `liveClock` is `true` |
| `isLive` | boolean | existing state | only used when `liveClock` is `true` |
| scroll anchor | minutes, `360` (06:00) | constant | used when `liveClock` is `false`, on first load and when `routine.id` changes |

## Behaviour by mode

| | `liveClock = true` (dashboard) | `liveClock = false` (setup screen) |
|---|---|---|
| Clock readout, Pause/Resume, slider, now-line, "Now: …" | shown | not rendered |
| Current-task highlight | yes | no |
| Timer | ticks every 60 s | none |
| Scroll on open | to now − 260 px | 06:00 at top |
| Scroll on zoom | re-centres on now | keeps the top time of day in place |
| Scroll on routine switch | n/a (dashboard unchanged) | 06:00 at top |
