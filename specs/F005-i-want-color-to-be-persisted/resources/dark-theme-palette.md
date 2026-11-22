# F005 – Proposed dark theme colors

Dark versions of every color token in `ui-personal-routine-manager/src/styles/tokens.css`, based on the light values. This is a proposal for `/speckit-plan`: change any value here before planning.

## How the dark values were picked

- **Surfaces** use the same cool blue-grey (slate) family as the light theme, darkened. The page background is darkest, and cards and panels sit slightly lighter on top of it.
- **Task colors (accents)** keep the same hue as their light version but are lighter and slightly brighter, so they stand out on a dark background.
- **Task card backgrounds** are each accent mixed 16% into the dark card surface: a dark tint of the task's color, the way the light theme uses a pale tint.
- **Buttons** keep white text, so the button blue stays deep enough for 4.5:1 contrast with it.
- Every pair checked by `src/styles/contrast.test.ts` passes in dark mode: 4.5:1 for text, and 3:1 for muted text.

## Task palette (light → dark)

Contrast is measured against the dark card surface `#161C25`.

| ID | Name | Light accent | Light bg | **Dark accent** | **Dark bg** | Text on dark bg | Accent vs card surface |
|----|------|-------------|----------|-----------------|-------------|-----------------|---------------------|
| 1 | green  | `#10A36B` | `#E3F5EE` | `#34C98E` | `#1B3836` | 10.5:1 | 8.1:1 |
| 2 | orange | `#E07B39` | `#FDF0E5` | `#F0954F` | `#392F2C` | 10.8:1 | 7.4:1 |
| 3 | blue   | `#1A6FD4` | `#E8F1FC` | `#5B9DF0` | `#213145` | 11.0:1 | 6.1:1 |
| 4 | grey   | `#AAB3BF` | `#F6F7F9` | `#9AA4B1` | `#2B323B` | 10.8:1 | 6.8:1 |
| 5 | slate  | `#6F7E94` | `#EEF1F5` | `#8E9CB2` | `#29303C` | 11.1:1 | 6.2:1 |
| 6 | peach  | `#EEB692` | `#FEF7F1` | `#E8B08A` | `#383435` | 10.2:1 | 9.0:1 |
| 7 | pink   | `#D94A6A` | `#FCEAEE` | `#EE6F8C` | `#392935` | 11.4:1 | 5.9:1 |
| 8 | purple | `#7C5CD6` | `#F0ECFB` | `#9D84EA` | `#2C2D45` | 11.2:1 | 5.6:1 |

The "current task" highlight (`--color-task-current`, `--color-task-current-bg`) uses the purple pair: `#9D84EA` / `#2C2D45`.

The round-robin order is the ID order 1 → 8, the same order the light palette uses today.

## Semantic tokens (light → dark)

| Token | Light | **Dark** | Note |
|-------|-------|----------|------|
| `--color-bg-app` | `#FFFFFF` | `#0E131A` | Page background, darkest |
| `--color-bg-surface` | `#FFFFFF` | `#161C25` | Cards, panels, dialogs |
| `--color-bg-subtle` | `#F9FBFD` | `#1B222C` | |
| `--color-bg-muted` | `#F6F8FB` | `#202834` | |
| `--color-bg-sidebar` | `#FFFFFF` | `#121821` | |
| `--color-bg-overlay` | ink 45% | `rgba(0, 0, 0, 0.6)` | Modal backdrop needs to be darker on a dark page |
| `--color-border` | `#E4EAF2` | `#2A3340` | |
| `--color-border-strong` | `#CBD5E1` | `#3A4555` | |
| `--color-text-primary` | `#1F2937` | `#E6EBF2` | 14.3:1 on card surface |
| `--color-text-secondary` | `#5B6B82` | `#A3B0C2` | 7.8:1 |
| `--color-text-muted` | `#6F7E94` | `#8A97AA` | 5.8:1 |
| `--color-text-placeholder` | `#94A3B8` | `#7A879B` | 4.7:1 |
| `--color-text-on-accent` | `#FFFFFF` | `#FFFFFF` | |
| `--color-accent` | `#1A6FD4` | `#1F74D8` | White text 4.6:1; 3.7:1 against the card surface |
| `--color-accent-hover` | `#1558A8` | `#1A66C2` | Darker on hover, so white text stays readable |
| `--color-accent-soft` | `#E8F1FC` | `#213145` | |
| `--color-accent-text` | `#1558A8` | `#8CBBF5` | 6.2:1 on accent-soft |
| `--color-accent-subtle` | `#F2F7FD` | `#1A2331` | |
| `--color-accent-bright` | `#4DB8FF` | `#4DB8FF` | Unchanged; already bright |
| `--color-highlight` | `#FFC94A` | `#FFC94A` | Unchanged |
| `--color-danger` | `#C2413B` | `#F0686C` | 5.6:1 on card surface |
| `--color-danger-strong` | `#E5484D` | `#F0686C` | |
| `--color-danger-soft` | `#FCEDED` | `#392830` | |
| `--color-success` | `#10A36B` | `#34C98E` | |
| `--color-success-soft` | `#E3F5EE` | `#1B3836` | |
| `--color-success-muted` | `#7CCCAE` | `#2F7A5E` | |
| `--color-now-line` | `#E5484D` | `#F0686C` | |
| `--color-chat-bot-bg` | `#F9FBFD` | `#1B222C` | |
| `--color-chat-user-bg` | accent | accent (`#1F74D8`) | |
| `--color-illustration-sky` | `#E8F1FC` | `#213145` | Sign-in hero illustration |
| Shadows (`--shadow-*`) | ink 8–12% | black 35–50% | Shadows need to be stronger to show on dark backgrounds |

## Open points for planning

- User-chosen exact colors don't switch with the theme (spec FR-011). A very dark custom color will be hard to see in dark mode. That's accepted for now.
- `contrast.test.ts` should run its checks against both themes.
