# Contract: Style Tokens

Single source: `ui-personal-routine-manager/src/styles/tokens.css`, imported first by `src/index.css`.

## Rules

1. Raw colour literals (hex, `rgb()`, `rgba()`, `hsl()`) may appear **only** in `tokens.css`, in the primitive tier.
2. Components and stylesheets use **semantic** tokens, never primitives directly.
3. JS/JSX inline styles use `var(--token)` strings (e.g. task tints), never literals.
4. Allowlist: third-party brand logos in `src/features/auth/pages/AuthPage.tsx` (Google, Facebook, Apple marks), and the `<input type="color">` default in `TaskEditModal.tsx` (the input only accepts a literal hex).
5. Enforced by `src/styles/noRawColors.test.ts` (fails the build's test run on any violation).
6. Text/background pairs listed under "Contrast pairs" must reach WCAG AA 4.5:1; checked in the same test.

## Tier 1 – Primitives (seed values, re-sample from the design during implementation)

```css
--color-white: #FFFFFF;
--color-slate-50:  #F7F9FC;  --color-slate-100: #F0F3F8;  --color-slate-200: #E6EBF2;
--color-slate-400: #A0AABB;  --color-slate-500: #6B778C;  --color-slate-900: #1A202C;
--color-blue-50:   #EAF2FD;  --color-blue-600:  #1F6FDB;  --color-blue-700:  #1A5DBA;
--color-red-500:   #E04848;  --color-red-50:    #FDECEC;
--color-green-500: #34C38F;  --color-green-50:  #E7F7EF;
--color-purple-500:#7C5CE6;  --color-purple-50: #F1EDFC;
/* task tints: 8 accent/bg pairs – green, peach, blue, grey, slate, orange, pink, purple */
```

## Tier 2 – Semantic tokens

| Group | Tokens |
|-------|--------|
| Surfaces | `--color-bg-app`, `--color-bg-surface`, `--color-bg-subtle`, `--color-bg-sidebar`, `--color-bg-overlay` |
| Borders | `--color-border`, `--color-border-strong` |
| Text | `--color-text-primary`, `--color-text-secondary`, `--color-text-muted`, `--color-text-on-accent` |
| Accent | `--color-accent`, `--color-accent-hover`, `--color-accent-soft` (active nav bg), `--color-accent-text` (accent text on soft bg) |
| Status | `--color-danger`, `--color-danger-soft`, `--color-success`, `--color-success-soft` |
| Board | `--color-now-line`, `--color-task-current`, `--color-task-{1..8}-accent`, `--color-task-{1..8}-bg` |
| Chat | `--color-chat-bot-bg`, `--color-chat-user-bg`, `--color-chat-user-text` |
| Focus | `--focus-ring` |
| Type | `--font-family`, `--font-size-{xs,sm,md,lg,xl}`, `--font-weight-{regular,medium,semibold}` |
| Spacing | `--space-{1..8}` (4px scale) |
| Radius | `--radius-{sm,md,lg,pill}` |
| Shadow | `--shadow-{sm,md,lg}` |
| Layout | `--sidebar-width` (≈232px), `--sidebar-rail-width`, `--chat-panel-width` (≈360px), `--header-height` |
| Layers | `--z-sidebar`, `--z-backdrop`, `--z-modal`, `--z-tour` |

Legacy names in `index.css` (`--blue-primary`, `--text`, `--bg`, …) are kept as aliases of semantic tokens during migration and deleted once unused.

## Contrast pairs (must pass 4.5:1)

- `--color-text-primary` on `--color-bg-surface`
- `--color-text-secondary` on `--color-bg-surface`
- `--color-text-on-accent` on `--color-accent`
- `--color-accent-text` on `--color-accent-soft` (active nav label; the mock's plain accent is 4.3:1, so a darker text token is used)
- `--color-danger` on `--color-bg-surface` ("Clean up")
- `--color-text-primary` on each `--color-task-{n}-bg`

`--color-text-muted` is for non-essential labels (hour gutter, breadcrumb) and must reach 3:1.
