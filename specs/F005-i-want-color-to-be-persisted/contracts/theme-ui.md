# Contract: Theme (UI)

## Document attribute

`<html data-theme="light" | "dark">` — always present after boot, holds the **effective** theme. All theme-dependent CSS keys off it. Set first by an inline script in `index.html` (before CSS paints), then kept in sync by `src/theme/`.

## Tokens (`src/styles/tokens.css`)

- `:root { … }` — unchanged light values.
- `:root[data-theme="dark"] { … }` — redefines tier-2 semantic tokens only (values: `resources/dark-theme-palette.md`). New dark primitives are added to the tier-1 block with a `-dark` suffix or new names; `noRawColors` stays satisfied because they live in `tokens.css`.
- `:root { color-scheme: light; } :root[data-theme="dark"] { color-scheme: dark; }`.

## Task card variables

Set inline by the board per card (from `resolveTaskColor`):

| Variable | Palette colour | Exact colour | Unresolved |
|----------|----------------|--------------|------------|
| `--task-accent-light` | entry.light.accent | the colour | unset |
| `--task-bg-light` | entry.light.bg | unset | unset |
| `--task-accent-dark` | entry.dark.accent | the colour | unset |
| `--task-bg-dark` | entry.dark.bg | unset | unset |

Board CSS:

```css
.ob-board-task { --task-accent: var(--task-accent-light, var(--color-border-strong));
           --task-bg: var(--task-bg-light, color-mix(in srgb, var(--task-accent) 14%, var(--color-bg-surface))); }
:root[data-theme="dark"] .ob-board-task { --task-accent: var(--task-accent-dark, var(--color-border-strong));
           --task-bg: var(--task-bg-dark, color-mix(in srgb, var(--task-accent) 14%, var(--color-bg-surface))); }
```

The existing `.ob-board-task` rules (`App.css`) already read `var(--task-bg, …)` and `var(--task-accent, …)`; their fallbacks to `--color-task-3-*` are replaced. The `--color-task-N-*` tokens are removed (the palette now comes from the backend).

## Theme module (`src/theme/`)

```ts
type ThemePreference = 'light' | 'dark' | null        // null = follow device
type Theme = 'light' | 'dark'
const THEME_KEY = 'milos.theme'
readThemePreference(storage): ThemePreference         // never throws
writeThemePreference(storage, pref: ThemePreference)  // null removes the key; never throws
resolveTheme(pref, prefersDark: boolean): Theme
useTheme(): { theme: Theme; preference: ThemePreference; toggle(): void }
```

`toggle()` sets the preference to the opposite of the current effective theme and applies it immediately (no reload). While `preference === null`, a `prefers-color-scheme` change updates the theme live.

## Theme switch control

`components/ThemeToggle.tsx` — `<button type="button" aria-pressed={theme==='dark'} aria-label="Dark mode">` with sun/moon icon (`components/icons`). Variants: sidebar row (icon + "Dark mode" label; icon-only in rail) and compact icon (auth page, onboarding header).
