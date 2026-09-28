# Changelog

All notable changes to this app. Versions follow [Semantic Versioning](https://semver.org/):
MAJOR for a change to the model or its notation, MINOR for new features
(a stage, a worked example, a figure), PATCH for fixes and wording.
Each release is tagged in git as `vX.Y.Z` and shown in the app footer.

## [1.0.7] - 2026-09-28

### App
- The notes under the figures are rewritten as short plain prose: no bold
  lead-in sentences, one point per paragraph.

## [1.0.6] - 2026-09-28

### App
- Card headers in the blue used for headings, not body grey.

## [1.0.5] - 2026-09-28

### App
- Cards have no border or header rule: figures, equations and stories sit
  on the page separated by whitespace alone.

## [1.0.4] - 2026-09-28

### App
- Cards, panels, tiles and buttons are square with no shadow: they organise
  the page rather than decorate it.

## [1.0.3] - 2026-09-28

### App
- The QR code returns to the foot of the sidebar, with the name and site
  address, alongside the small one in the title bar.

## [1.0.2] - 2026-09-28

### App
- No figure carries a title or subtitle inside the image; the card header
  and the caption under it name and explain the figure (CONVENTIONS.md 6).
- Figures are drawn on a white ground, so the image sits flat in its card
  instead of showing as a tinted tile.
- The Keynesian cross is drawn at 3:2 like every other figure, not as a
  square inside a 3:2 card.

## [1.0.1] - 2026-09-28

### App
- The In Words tab lays out its three columns at fixed widths, so an
  equation no longer collapses to one term per line beside its note.
- The preset card no longer doubles the word "Stage" in front of a stage
  name that already carries it.
- The identity line on the Keynesian cross is named `E = Y` on the figure,
  in the caption and in the worked examples, in place of "45° line".

## [1.0.0] - 2026-09-28

First public release as a standalone repository.

### Model
- The Keynesian cross with a lump-sum tax, a tax rate on income and an
  import leakage, solved in closed form: `Y* = kA` with
  `k = 1 / (1 − c̄(1 − t) + m)`.
- Two household types with different MPCs, an income-weighted average MPC
  and a budget-neutral redistribution between them.
- Spending rounds as a geometric series, the injections-withdrawals
  schedules, six fiscal packages of equal size, and readouts that class a
  package as balanced, borrowed or in surplus by the change in `T − G`.
- Defaults calibrated to Ireland in 2022 from the CSO Supply and Use and
  Input-Output Tables, on the GNI* base.

### App
- Six stages that add one leakage or one comparison at a time.
- Eleven worked examples, each with a story and a prompt.
- Equations, Notation and In Words tabs that track the model at each stage.
- Figures: the Keynesian cross, injections and withdrawals, the spending
  rounds, where one euro goes, household types, the fiscal packages, and
  the bridge to the measured Irish Type I and Type II multipliers.
- Ghost curves showing the loaded worked example alongside the live sliders.
- The multiplier tile can be typed over and sets the MPC.
- A stage 6 reveal panel with the calibration arithmetic, row by row, and
  its caveats.
