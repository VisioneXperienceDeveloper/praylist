# Praylist UI — Brilliant

The editable source lives in the Brilliant project `Scratch`, under `Praylist UI`.
It is intentionally consolidated into two canvases:

- `Design System`: semantic light/dark variables and shared components.
- `Playground`: all 14 product screens plus dark-theme proofs, composed from shared component instances.

## Design system

The `praylist` system defines theme modes (`light`, `dark`), density modes
(`comfortable`, `compact`), and accessibility modes (`standard`, `high-contrast`,
`large-text`). Semantic tokens cover surfaces, text, primary actions, outlines,
errors, typography, radius, spacing, and CTA shadow.

Shared components include primary/secondary buttons, icon button, selected/idle
segments, Pray card, settings row, text field, and stat tile. Playground screens
reference these component masters across canvases.

## Playground screens

1. Main Notebook
2. Daily Prayer
3. Achievement Record
4. History — Achievements
5. History — Calendar
6. Settings
7. Reminder Settings
8. Category Management
9. Category Editor
10. Onboarding — Categories
11. Onboarding — First Pray
12. Language
13. Help
14. Privacy

Consolidated previews are stored in `consolidated/`. Simulator evidence and the
cross-check report are stored in `audit-simulator/`.
