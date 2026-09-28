# Changelog

All notable changes to this app. Versions follow [Semantic Versioning](https://semver.org/):
MAJOR for a change to the model or its notation, MINOR for new features
(a stage, a worked example, a figure), PATCH for fixes and wording.
Each release is tagged in git as `vX.Y.Z` and shown in the app footer.

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
