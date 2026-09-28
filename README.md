# Interactive Model: The Keynesian Multiplier

A Shiny app for teaching the Keynesian cross and the multiplier, built up
one leakage at a time and calibrated to Ireland in 2022. Built by
[Sam Deegan](https://sam-deegan.com) for ECON42550 Macroeconomics,
University College Dublin.

**Try it in the browser (nothing to install):**
https://sam-deegan.com/toy-models/keynesian-multiplier/

Current version: **1.0.6** (see [CHANGELOG.md](CHANGELOG.md)). The version
is shown in the app footer; releases are tagged `vX.Y.Z`.

## What it does

The stage selector builds the model up one layer at a time:

| Stage | What is added |
|---|---|
| 1 | The Keynesian cross: one household, no government, no trade. The multiplier as a geometric series of spending rounds |
| 2 | Taxes and government spending: lump-sum taxes, a tax rate on income as an automatic stabiliser, the budget balance, the balanced-budget multiplier and borrowing |
| 3 | The open economy: exports as given, imports as the third leakage |
| 4 | High- and low-MPC households: the average MPC, and a budget-neutral redistribution between the two types |
| 5 | Six fiscal packages that move the same sum, at different cost to the Exchequer |
| 6 | The bridge to the input-output model: the reveal that the defaults are Ireland in 2022, and this model's k against the measured Irish Type I and Type II multipliers |

Each stage opens on a worked example (a collapse in investment, a stimulus
package, austerity, automatic stabilisers, the small open economy, a
transfer under the permanent-income benchmark, redistribution, six ways to
move the same money, matching the measured multiplier). Every slider has a
box beside it for an exact value, and every figure that moves also draws
itself at the worked example's own settings, faded, so a change is always
against something. The Equations, Notation and In Words tabs show the
model as it stands at the chosen stage and flag what that stage changed.
The multiplier tile can be typed over, and doing so sets the marginal
propensity to consume.

## Run it locally

1. Install [R](https://cran.r-project.org/) (4.1 or later) and, ideally,
   [RStudio](https://posit.co/download/rstudio-desktop/).
2. Install the three packages once:

   ```r
   install.packages(c("shiny", "bslib", "ggplot2"))
   ```

3. Open `app.R` in RStudio and click **Run App**, or from R in this folder:

   ```r
   shiny::runApp()
   ```

Equations are typeset with MathJax from a CDN, so they need an internet
connection; everything else runs offline.

## Files

```
app.R          the app: settings and text (section B), figures (D),
               interface (E), server (F)
R/model.R      the model: propensities, the multiplier, the equilibrium,
               the two diagrams, the rounds, the packages, the readouts.
               Sources on its own, so slides can reuse it.
R/toolkit.R    layout and helpers shared with the other toy-model apps
www/           logo and QR code
README.md      this file
CHANGELOG.md   version history
CONVENTIONS.md how the figures and worked examples are laid out
LICENSE        CC BY-NC-ND 4.0
```

All text on screen (worked examples, prompts, explanations, equations,
notation, the calibration table, the reveal and the fiscal notes) is in
section `B_03` of `app.R`, so it can be edited without touching the rest.

## Data

The app bundles no data files. Two sets of numbers are written into
`app.R` as a snapshot:

- The default calibration (`B_03_01`, set out row by row in `B_03_19`) is
  Ireland in 2022, from the CSO *Supply and Use and Input-Output Tables for
  Ireland 2022* (Tables 2.6, 2.9 and 2.10), on the GNI* base. GNI* is the
  CSO's own 2022 estimate.
- The measured multipliers at stage 6 (`B_03_05`) are output multipliers
  from the CSO symmetric input-output tables (domestic product flows): the
  Irish average for 1998, 2015 and 2022, and pharma and electronics, food
  products and construction for 2022, with a Type II figure for
  construction only.

Both are snapshots at the vintage stated and are not updated by the app.

## The model

The Keynesian cross is the simplest model of output determined by demand:
prices are fixed, firms produce whatever is demanded, and the central bank
does not move. It is the model behind the multiplier in Keynes's *General
Theory* (1936, chapter 10) and the opening goods-market chapter of any
intermediate textbook (Blanchard, *Macroeconomics*, chapter 3). Amounts are
in euro billion; propensities are shares of a euro.

```
Consumption:   C = c_0 + c̄ (Y − T) + (c_H − c_L) τ
Taxes:         T = T_0 + t Y
Imports:       M = m_0 + m Y
Goods market:  Y = C + I + G + X − M

Average MPC:   c̄ = ω c_H + (1 − ω) c_L
```

**Consumption** rises with disposable income `Y − T`. `c_0` is the floor
under spending; `c̄` is the marginal propensity to consume, the share of one
extra euro of disposable income that is spent. From stage 4 there are two
household types: a share `ω` of disposable income goes to high-MPC
households who spend `c_H` of a euro, the rest to low-MPC households who
spend `c_L`, and `τ` is a budget-neutral transfer from the second to the
first. Before stage 4 there is one type, so `ω = 1` and `c̄ = c`.

**Taxes** have a lump-sum part `T_0` and a part `t Y` that rises with
income. Only the second changes the multiplier.

**Imports** have an autonomous part `m_0` and a marginal propensity to
import `m`, the share of each extra euro of income that leaks abroad.
Investment `I`, government spending `G` and exports `X` are given.

Solving the four equations for output gives

```
Y* = k A
k  = 1 / (1 − c̄ (1 − t) + m)
A  = c_0 − c̄ T_0 + (c_H − c_L) τ + I + G + X − m_0
```

so equilibrium output `Y*` is the multiplier `k` times autonomous spending
`A`. Of one extra euro of income a share `q = c̄ (1 − t) − m` is passed on
as the next round's income and the rest leaks into tax, saving and
imports; the rounds sum to `ΔY = ΔA (1 + q + q² + ...) = ΔA / (1 − q)`, so
`k = 1 / (1 − q)` is one over total leakage. The fiscal multipliers follow:
`dY/dG = k`, `dY/dT_0 = −c̄ k`, the balanced-budget multiplier `(1 − c̄) k`
and the redistribution multiplier `dY/dτ = (c_H − c_L) k`. The budget
balance is `B = T − G`, and its change `ΔB = ΔT_0 + t ΔY − ΔG` includes the
tax the extra output brings in. Everything is closed form; there is no
numerical solver.

**What the six stages show with it**

- *1* The cross and the rounds. A fall in investment moves output by more
  than itself, because each round of lost income cuts consumption again;
  the `E = Y` line is the identity, not the multiplier.
- *2* Tax on its own is a leakage; spending it back is not. A balanced
  package still raises output, by `(1 − c̄) k` times the sum, while
  borrowing brings in demand from outside the flow. A higher tax rate
  flattens the expenditure line and damps booms and slumps alike.
- *3* Imports as the third leakage. At Ireland's own calibration the import
  leak is the smallest of the three, which is not what "small open economy"
  suggests.
- *4* Who holds the income. The average MPC sets `k`; the gap between the
  two MPCs is all that makes redistribution work, and a transfer to
  permanent-income households does little.
- *5* Six instruments moving the same sum. Government spending buys the
  most because the whole euro is spent; transfers and tax cuts reach output
  only after the MPC has taken its cut; two packages cost the Exchequer
  nothing and belong in a different column.
- *6* The reveal and the bridge. The defaults were Ireland in 2022, with
  `k = 1.33`. A published Type I multiplier is the direct euro plus the
  supply chain; Type II adds the induced round, which is the only mechanism
  this model has, so its `k − 1` is compared with Type II minus Type I.

**Where it departs from the textbook.** With `t = m = 0` and one household
type the model is the textbook cross with `k = 1 / (1 − c)`; each later
stage is one extra term. The two household types are the app's own device
for showing why the distribution of income matters, with `c_L` set to the
two-period permanent-income benchmark; there is no intertemporal problem
behind either MPC. The calibration uses average tax and import ratios from
a single year in place of marginal propensities, and GNI* rather than GDP
as the income base, for the reasons the stage 6 panel gives. The model has
no prices, no interest rate, no supply side and no sectors: it is a model
of one period's demand, and the bridge at stage 6 is there to say what an
input-output multiplier adds.

## References

- Keynes, J. M. (1936). *The General Theory of Employment, Interest and
  Money*. Chapter 10.
- Blanchard, O. (2021). *Macroeconomics*, 8th ed. Chapter 3.
- Central Statistics Office. *Supply and Use and Input-Output Tables for
  Ireland 2022*. Tables 2.6, 2.9 and 2.10.

## Licence

© Sam Deegan. Released under
[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/):
free to use and share for teaching with attribution; not for commercial use
or redistribution in modified form.
