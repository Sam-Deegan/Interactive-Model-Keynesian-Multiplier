################################################################################
## Project: ECON42550 Macroeconomics                                          ##
## The Keynesian Multiplier: Interactive Shiny App                            ##
################################################################################

## Author:      Sam Deegan
## Affiliation: University College Dublin
## Email:       sam.deegan@ucdconnect.ie

## Usage:
##   Open app.R in RStudio and click Run App, or from this folder:
##     shiny::runApp()
##   Needs R 4.1 or later with shiny, bslib and ggplot2 installed. A hosted
##   copy runs in the browser at
##   https://sam-deegan.com/toy-models/keynesian-multiplier/
##   The stage selector builds the model up one layer at a time:
##     1  the Keynesian cross: one household, no government, no trade
##     2  taxes and government spending, and the tax rate as a stabiliser
##     3  the open economy: imports as the third leakage
##     4  high- and low-MPC households, and redistribution between them
##     5  six fiscal packages that move the same sum, at different cost
##     6  the bridge to the input-output model and the measured multipliers
##   All text (scenarios, prompts, explanations, equations, notation, the
##   Irish calibration table and the reveal) lives in B_03.
##
## Inputs:
##   R/model.R (the model) and R/toolkit.R (shared layout and helpers),
##   both sourced automatically by Shiny. www/ holds the QR code.
##
## Outputs:
##   None. The app is interactive only.
##
## Packages:
##   shiny, bslib, ggplot2.
##
## Version:
##   B_03_22_version_chr; history in CHANGELOG.md; git tag vX.Y.Z.
##
## References:
##   Keynes, J. M. (1936). The General Theory of Employment, Interest and
##     Money. Ch. 10 (the marginal propensity to consume and the multiplier).
##   Blanchard, O. (2021). Macroeconomics, 8th ed. Ch. 3 (the goods market).
##   CSO. Supply and Use and Input-Output Tables for Ireland 2022, Tables
##     2.6, 2.9 and 2.10, for the calibration and the measured multipliers.

#-------------------------------- Script Begin --------------------------------#

################################################################################
## A: Table of Contents ########################################################
################################################################################
# Note: Section C (the model) is R/model.R and section T (shared layout and
#   helpers) is R/toolkit.R, so the slides can source both alone.
#
#   B: Setup
#     B_01  Packages
#     B_02  Settings
#     B_03  Soft-coded objects
#     B_04  Paths
#   C: Model (R/model.R)
#   T: Toolkit (R/toolkit.R)
#   D: Plots
#     D_01  The Keynesian cross and the flows diagram
#     D_02  Rounds and the marginal euro
#     D_03  Packages, household types and the input-output bridge
#   E: User Interface
#   F: Server
#   G: Run

################################################################################
## B: Setup ####################################################################
################################################################################
# Note: Packages, options and every soft-coded value.

#### B_01: Packages ############################################################
# Note: Shiny, bslib for the layout, ggplot2 for the figures.

###### B_01_01: Load Packages ##################################################
# Note: All three run under shinylive.

library(shiny)
library(bslib)
library(ggplot2)

###### B_01_02: Load the Model #################################################
# Note: Shiny sources R/ itself; this covers sourcing app.R by hand.

if (!exists("C_01_05_equilibrium_fn")) {
  source(file.path("R", "model.R"))
}

###### B_01_03: Load the Toolkit ###############################################
# Note: The shared palette, plot theme, CSS and builders, section T.

if (!exists("T_01_01_palette_vec")) {
  source(file.path("R", "toolkit.R"))
}

#### B_02: Settings ############################################################
# Note: Standard options.

###### B_02_01: Global Options #################################################
# Note: No scientific notation; three digits in the console.

options(scipen = 999, digits = 3)

###### B_02_02: Seed ###########################################################
# Note: Nothing here is random; kept for consistency.

set.seed(42)

#### B_03: Soft-Coded Objects ##################################################
# Note: Calibration, stages, scenarios, controls, equations, text.

###### B_03_01: Input Defaults #################################################
# Note: Starting value of every control; Reset returns here. Amounts are in
#   euro billion. The defaults are Ireland in 2022, from the CSO Supply and
#   Use and Input-Output Tables 2022 (Tables 2.6, 2.9, 2.10) on the GNI*
#   base; B_03_19 sets out the arithmetic row by row for the stage 6 reveal.
#   tax_rate is all tax over GNI*, an average rate standing in for a marginal
#   one; imp_rate is the import content of a euro of household spending
#   times the share of a euro of income that is spent, c(1 - t); c0 and imp0
#   are the residuals that reproduce measured C and M. mpc is not in the
#   tables and comes from the consumption literature (0.5 to 0.6). The
#   two-type defaults average to the same 0.55, so stage 4 changes nothing
#   until the redistribution slider moves.

B_03_01_defaults_lst <- list(
  c0       = 19.9,  # autonomous consumption (residual: fits measured C)
  mpc      = 0.55,  # marginal propensity to consume, stages 1-3
  mpc_h    = 0.85,  # MPC of high-MPC (hand-to-mouth) households
  mpc_l    = 0.35,  # MPC of low-MPC (permanent-income) households
  omega    = 0.4,   # share of disposable income going to high-MPC households
  inv      = 44.3,  # investment: GFCF plus inventories, 2022
  gov      = 57.1,  # government spending on goods and services, 2022
  tax0     = 0,     # lump-sum taxes: the tables do not identify a lump sum
  tax_rate = 0.31,  # tax rate on income: all tax over GNI*, 2022
  exp0     = 123.7, # exports, on the GNI* basis (see B_03_19)
  imp0     = 40.2,  # autonomous imports (residual: fits measured M)
  imp_rate = 0.13,  # marginal propensity to import, 2022
  d_inv    = 0,     # change in investment (a demand shock)
  d_gov    = 0,     # change in government spending
  d_tax0   = 0,     # change in lump-sum taxes
  transfer = 0,     # budget-neutral transfer, low-MPC to high-MPC
  budget   = 10     # budget for the package comparison at stage 5
)

###### B_03_02: Number of Rounds ###############################################
# Note: Spending rounds drawn in the rounds figure.

B_03_02_n_rounds_int <- 12L

###### B_03_03: Stages #########################################################
# Note: One layer of the model each. Stage 1 is lecture 1.1, stages 2 to 5
#   the fiscal material in lecture 2.2, stage 6 the input-output bridge.

B_03_03_stages_vec <- c(
  "Stage 1: The Keynesian Cross"           = "1",
  "Stage 2: Taxes and Government Spending" = "2",
  "Stage 3: The Open Economy"              = "3",
  "Stage 4: High- and Low-MPC Households"  = "4",
  "Stage 5: Comparing Fiscal Packages"     = "5",
  "Stage 6: Bridge to the Measured Data"   = "6"
)

###### B_03_04: Scenarios ######################################################
# Note: Worked examples. Each sets a stage and overrides some defaults;
#   unlisted controls return to B_03_01. Story wording follows CONVENTIONS.md
#   sections 3 to 5; "prompt" replaces the stage's own while it is loaded.

B_03_04_scenarios_lst <- list(
  slump = list(
    label  = "A Collapse in Investment",
    stage  = "1",
    values = list(d_inv = -20),
    story  = paste(
      "Firms cut investment (I) by €20bn, so autonomous spending (A) falls by",
      "the full €20bn and the planned-expenditure line drops by that much",
      "without changing its slope. It meets the 45° line further to the left:",
      "income (Y) on the horizontal axis and planned expenditure on the",
      "vertical fall together, and both fall by more than €20bn. The 45° line",
      "is only the set of points where planned expenditure equals output, so",
      "the crossing is equilibrium output (Y*), a resting point rather than a",
      "level anyone chose; the multiplier is the ratio of ΔY to the €20bn, not",
      "a slope on the diagram. How far it goes is set by the marginal",
      "propensity to consume (c): each round cuts consumption (C) by c times",
      "the income lost in the round before, and the rounds sum to",
      "k = 1/(1 − c) times the shock."
    ),
    prompt = paste(
      "Read the rounds figure from left to right. The first bar is the €20bn",
      "itself; every bar after it is the one before times the MPC. Lower the",
      "MPC to 0.4: how much of the fall in output survives?"
    )
  ),
  stimulus = list(
    label  = "A Stimulus Package",
    stage  = "2",
    values = list(d_gov = 20),
    story  = paste(
      "The government raises its spending on goods and services (G) by €20bn",
      "and leaves tax policy alone, so the whole package is borrowed. The",
      "planned-expenditure line shifts up by €20bn at every level of income,",
      "and the crossing point slides out along the 45° line: output (Y) and",
      "planned expenditure both rise, by more than €20bn. Two leakages now",
      "decide how much more — households save (1 − c) of each euro of",
      "disposable income, and the tax rate on income (t = 0.31) takes 31 cents",
      "of every euro before they see it — so the multiplier is",
      "k = 1/(1 − c(1 − t)). Watch the budget balance (B = T − G): the deficit",
      "comes to less than €20bn, because the extra output brings extra tax",
      "with it."
    ),
    prompt = paste(
      "Compare the multiplier with the one at stage 1. Then raise the tax",
      "rate to 0.45: the stimulus buys less output, but look at what happens",
      "to the budget balance."
    )
  ),
  tax_leak = list(
    label  = "Tax on Its Own Is a Leakage",
    stage  = "2",
    values = list(d_tax0 = 20),
    story  = paste(
      "Lump-sum taxes (T<sub>0</sub>) rise by €20bn and the government spends",
      "none of it. Disposable income falls by the full €20bn, but consumption",
      "(C) falls only by c times that, because households absorb the rest by",
      "saving less: the planned-expenditure line therefore drops by c × €20bn,",
      "not by €20bn. On the cross both axes fall together — output (Y) slides",
      "left and planned expenditure with it — to a new crossing on the 45°",
      "line. That factor of c is why the tax multiplier is −ck rather than −k;",
      "the budget balance (B) improves, because the euro has left the",
      "circular flow and been parked."
    ),
    prompt = paste(
      "Output falls, and the budget tile shows a surplus: money has been",
      "taken out of the flow and parked. Now hold this €20bn tax rise and",
      "load the next scenario, where the government spends it. The fall you",
      "are looking at now is exactly what that spending has to undo."
    )
  ),
  balanced = list(
    label  = "Spending the Tax Back: the Balanced Budget",
    stage  = "2",
    values = list(d_gov = 20, d_tax0 = 20),
    story  = paste(
      "The same €20bn rise in lump-sum taxes (ΔT<sub>0</sub>), but now the",
      "government spends every cent of it (ΔG = €20bn). The spending enters",
      "planned expenditure at its full €20bn while the tax withdraws only",
      "c × €20bn, so the line still shifts up and the cross's crossing point",
      "moves right: output (Y) and planned expenditure rise together, even",
      "though not a euro has been borrowed. The size of the rise is",
      "(1 − c)k times €20bn; set the tax rate (t) and the marginal propensity",
      "to import (m) to zero and (1 − c)k is exactly one, so €20bn of spending",
      "buys €20bn of output and no more. The balance (B) then improves rather",
      "than breaking even, because the higher output pays extra tax on top of",
      "the €20bn legislated for."
    ),
    prompt = paste(
      "The balanced-budget multiplier is (1 − c&#772;)k, so ΔY is positive",
      "even though not a euro has been borrowed. Set the tax rate and the",
      "import share to zero and it becomes exactly one: €20bn of spending",
      "buys €20bn of output, no more and no less. Why exactly one? And note",
      "the ΔB tile: with a tax rate in place this package does not merely",
      "break even, it improves the balance, because the extra output brings",
      "in extra tax on top of the €20bn that was legislated for."
    )
  ),
  deficit = list(
    label  = "Borrowing: Demand from Outside the Flow",
    stage  = "2",
    values = list(d_gov = 20),
    story  = paste(
      "The same €20bn of government spending (ΔG), with the tax rise taken",
      "away again: the gap is borrowed, which brings purchasing power into",
      "the circular flow that the flow did not itself generate. The whole",
      "€20bn now shifts the planned-expenditure line up, so on the cross",
      "output (Y) and planned expenditure move out together by k × €20bn",
      "instead of the balanced package's (1 − c)k × €20bn; the difference",
      "between the two crossings is what the borrowing bought. The budget",
      "tile says what it cost, and it costs less than €20bn because the tax",
      "rate (t) claws part of the extra output back. Who lends decides what",
      "the extra demand really is: a foreign lender makes it external, like",
      "an export, while a domestic saver makes it a transfer inside the flow,",
      "and the model assumes that saver had no other use for the money."
    ),
    prompt = paste(
      "Compare ΔY here with the balanced-budget scenario: the extra output",
      "is what the borrowing bought. Read the budget tile for what it cost.",
      "Then notice that the deficit is smaller than the €20bn spent, because",
      "the extra output pays some of the bill back in tax."
    )
  ),
  austerity = list(
    label  = "Austerity: Spending Cuts and Tax Rises",
    stage  = "2",
    values = list(d_gov = -10, d_tax0 = 10),
    story  = paste(
      "A €20bn consolidation split evenly, as in Ireland after 2008:",
      "government spending (G) cut by €10bn and lump-sum taxes",
      "(T<sub>0</sub>) raised by €10bn. Both push the planned-expenditure",
      "line down, but by different amounts — the spending cut removes the",
      "full €10bn, the tax rise only c × €10bn — and the cross's crossing",
      "point slides left, so output (Y) and planned expenditure fall together",
      "by k times the combined shift. The split therefore matters as much as",
      "the total: a euro taken off spending does more damage than a euro",
      "added to tax, because households absorb part of a tax rise by saving",
      "less. The budget balance (B) improves by less than €20bn either way,",
      "since the lost output takes tax revenue with it."
    ),
    prompt = paste(
      "Put the whole €20bn on the spending side, then the whole of it on",
      "taxes. Which does less damage to output, and why? The budget",
      "improves by less than €20bn either way: why?"
    )
  ),
  stabiliser = list(
    label  = "Automatic Stabilisers",
    stage  = "2",
    values = list(d_inv = -20, tax_rate = 0.45),
    story  = paste(
      "The same collapse in investment (ΔI = −€20bn), but in an economy where",
      "the tax rate on income (t) is 0.45 rather than Ireland's measured",
      "0.31. Nobody decides anything: a higher t flattens the",
      "planned-expenditure line, so when the line drops by €20bn it meets the",
      "45° line closer to where it started, and output (Y) and planned",
      "expenditure both fall by less than they did at the lower rate. The",
      "multiplier k = 1/(1 − c(1 − t)) falls from 1.6 to 1.4, and it does so",
      "symmetrically: the leakage that damps this recession would damp a boom",
      "by the same fraction. That symmetry is the price of the insurance."
    ),
    prompt = paste(
      "Move the tax rate between 0 and 0.5 and watch the fall in output. At",
      "this stage, with imports still assumed away, t = 0 gives a multiplier",
      "of 2.2, Ireland's 0.31 gives 1.6 and this scenario's 0.45 gives 1.4.",
      "This is insurance, not stimulus: what does it cost in a boom?"
    )
  ),
  small_open = list(
    label  = "The Small Open Economy",
    stage  = "3",
    values = list(d_gov = 20, imp_rate = 0.3),
    story  = paste(
      "Stages 1 and 2 assumed the border away; stage 3 lets imports",
      "(M = m<sub>0</sub> + mY) rise with income, adding a third leakage to",
      "the same €20bn of government spending (ΔG). The marginal propensity to",
      "import (m) is set to 0.30 here, well above Ireland's measured 0.13, so",
      "the planned-expenditure line is much flatter: it still shifts up by",
      "€20bn, but it meets the 45° line almost at once, and output (Y) and",
      "planned expenditure rise together by barely more than the €20bn spent.",
      "The multiplier is now k = 1/(1 − c(1 − t) + m), about 1.1. Put m back",
      "to 0.13 and the same €20bn buys markedly more — and the marginal-euro",
      "bar shows that at Ireland's own calibration the import leak is the",
      "smallest of the three, which is not what the phrase small open economy",
      "leads you to expect."
    ),
    prompt = paste(
      "Stages 1 and 2 assumed net exports away entirely. Now that they are",
      "here, which leakage does most of the work? Put the import share back",
      "to 0.13: the faded line the figure leaves behind is this example at",
      "m = 0.30, so the gap between the two is the whole of the answer.",
      "Stage 6 checks this multiplier against the",
      "measured Irish ones, and says where these numbers came from."
    )
  ),
  pih = list(
    label  = "A Transfer to Households (the PIH Benchmark)",
    stage  = "4",
    values = list(d_tax0 = -20, mpc_h = 0.9, mpc_l = 0.5, omega = 0.3),
    story  = paste(
      "The government hands €20bn back to households as a cut in lump-sum",
      "taxes (ΔT<sub>0</sub> = −€20bn). Households are two types from this",
      "stage on: a share ω = 0.3 of disposable income goes to high-MPC",
      "households who spend c<sub>H</sub> = 0.9 of a euro, the rest to",
      "permanent-income households who spend only c<sub>L</sub> = 0.5 — the",
      "two-period benchmark on the sample paper, where a windfall raises",
      "consumption today by half of it. The windfall therefore lifts the",
      "planned-expenditure line by c&#772; × €20bn rather than €20bn, where",
      "c&#772; = ωc<sub>H</sub> + (1 − ω)c<sub>L</sub> is the average MPC, and",
      "on the cross output (Y) and planned expenditure rise together by k",
      "times that — much less than €20bn of government spending would have",
      "moved them. Set ω to zero, so every household smooths, and the rise",
      "shrinks again: that is the sense in which the permanent-income",
      "hypothesis makes temporary fiscal policy weak."
    ),
    prompt = paste(
      "Set the income share of high-MPC households to 0, so that every",
      "household is a permanent-income consumer. What is the multiplier on a",
      "transfer now? This is the sense in which the PIH says temporary",
      "fiscal policy is weak."
    )
  ),
  redistribute = list(
    label  = "Redistribution to High-MPC Households",
    stage  = "4",
    values = list(transfer = 20, mpc_h = 0.9, mpc_l = 0.5, omega = 0.3),
    story  = paste(
      "€20bn is taken from low-MPC households and handed to high-MPC",
      "households (τ = €20bn). The Exchequer spends nothing and borrows",
      "nothing, so the budget balance (B) does not move, but the euro has",
      "changed hands to someone who spends more of it: autonomous spending",
      "(A) rises by (c<sub>H</sub> − c<sub>L</sub>)τ, the",
      "planned-expenditure line shifts up by that much, and on the cross",
      "output (Y) and planned expenditure rise together by k times it. Only",
      "the gap between c<sub>H</sub> = 0.9 and c<sub>L</sub> = 0.5 does any",
      "work here. Set the two equal and the shift vanishes, because the",
      "average MPC (c&#772;) — and so the multiplier k — never depended on who",
      "held the income in the first place."
    ),
    prompt = paste(
      "Set the two MPCs equal and watch the effect vanish: the whole result",
      "rests on the gap between them. Then ask what the model leaves out —",
      "what does taking €20bn from savers do to investment?"
    )
  ),
  packages = list(
    label  = "Six Ways to Move the Same Money",
    stage  = "5",
    values = list(budget = 10, mpc_h = 0.9, mpc_l = 0.5, omega = 0.3),
    story  = paste(
      "The same €10bn is moved six ways, so the instrument rather than the",
      "amount is what changes. The figure puts the policy on the horizontal",
      "axis and the change in output (ΔY) on the vertical: government",
      "spending (G) buys the most, because the state spends the whole euro",
      "and the full multiplier k applies to it, while a cut in lump-sum taxes",
      "(T<sub>0</sub>) or an untargeted transfer reaches output only after",
      "the average MPC (c&#772;) has taken its cut, and a transfer aimed at",
      "high-MPC households is scaled by c<sub>H</sub> = 0.9 instead. The last",
      "two bars are coloured apart because they are financed inside the",
      "package: the balanced-budget pair moves (1 − c&#772;)k and the",
      "redistribution (c<sub>H</sub> − c<sub>L</sub>)k, and both cost the",
      "Exchequer nothing. Output per euro of budget cost ranks the first",
      "four; it cannot rank the last two, because no amount of output divided",
      "by a cost of zero is a number."
    ),
    prompt = paste(
      "Compare the four deficit-financed packages with each other first:",
      "they cost the same, so output ranks them. Then look at the two green",
      "ones on their own terms, because no amount of output divided by a",
      "budget cost of zero is a number. Now raise the low MPC to 0.8: which",
      "policies gain, and which lose their advantage?"
    )
  ),
  bridge = list(
    label  = "Matching the Measured Multiplier",
    stage  = "6",
    values = list(imp_rate = 0.19, d_gov = 10),
    story  = paste(
      "The marginal propensity to import (m) is nudged from Ireland's",
      "measured 0.13 up to 0.19, which lands this model's multiplier on",
      "k = 1.24 — the figure the CSO input-output tables show for the Irish",
      "average in 2022 — against €10bn of government spending (ΔG).",
      "The two numbers are not the same object. A published Type I",
      "multiplier is the direct euro of demand plus the supply chain behind",
      "it, and a Type II adds the induced round in which the wages earned",
      "along that chain are spent again; this model has no supply chain at",
      "all, so the whole of its k − 1 is that induced round and nothing else.",
      "The bridge figure puts the policy on the horizontal axis and the",
      "multiplier, split into those three pieces, on the vertical, so the",
      "comparison to make is green against green: put m back to 0.13 and k",
      "rises to 1.33, which says this model's induced round is a little",
      "bigger than the tables'."
    ),
    prompt = paste(
      "k now sits on the measured average of 1.24. Put the import share back",
      "to Ireland's own 0.13 and k rises to 1.33: this model says the",
      "induced round is slightly bigger than the tables do. Which of the two",
      "would you trust, and why is construction's measured figure so high?"
    )
  )
)

###### B_03_05: Measured Multipliers ###########################################
# Note: Published Irish output multipliers for stage 6, from the CSO
#   symmetric input-output tables (domestic product flows). Type I is the
#   direct euro plus the supply chain; Type II adds the induced round, the
#   only piece this model shares, so the figure shows Type II - Type I on
#   its own. type_ii is NA where the tables publish none.

B_03_05_measured_df <- data.frame(
  label   = c("Pharma and Electronics, 2022", "Irish Average, 2015",
              "Irish Average, 2022", "Irish Average, 1998",
              "Food Products, 2022", "Construction, 2022"),
  type_i  = c(1.04, 1.23, 1.24, 1.39, 1.68, 1.75),
  type_ii = c(NA_real_, NA_real_, NA_real_, NA_real_, NA_real_, 2.09),
  stringsAsFactors = FALSE
)

###### B_03_06: Bridge Notes ###################################################
# Note: Four paragraphs under the stage 6 figure, naming the three pieces
#   every bar is cut into.

B_03_06_bridge_lst <- list(
  paste(
    "<strong>Read the figure as three pieces, not two kinds of bar.</strong>",
    "Every bar starts with the direct euro of demand itself. An input-output",
    "multiplier then adds the SUPPLY CHAIN — the cement, haulage and",
    "professional services a euro of construction demand pulls in — and, if",
    "it is a Type II multiplier, the INDUCED round on top of that: the wages",
    "earned along the chain being spent again. Type I is the first two",
    "pieces; Type II is all three. The difference between them is the green",
    "segment, and it is labelled rather than left to be subtracted."
  ),
  paste(
    "<strong>The induced round is the only shared part.</strong> This",
    "model has no supply chain in it at all: it never asks what a euro of",
    "demand is spent ON, only whose income it becomes. Its whole multiplier",
    "is the direct euro plus induced rounds, which is why its bar has a green",
    "segment and no blue one. The Keynesian multiplier is not a rival",
    "estimate of an input-output multiplier; it is an estimate of one",
    "component of one."
  ),
  paste(
    "<strong>Which is what makes the comparison sharp.</strong> Ireland's",
    "published Type II figure for construction adds 0.34 on top of a Type I",
    "of 1.75 — an induced round worth about a fifth of the direct euro. Set",
    "the leakages in this model so that k − 1 is near that, and the two",
    "descriptions of the same economy agree; set them so that it is not, and",
    "at least one of them is wrong about how much income leaks away."
  ),
  paste(
    "<strong>Both are held down by the same leakage.</strong> Ireland's",
    "average measured multiplier fell from about 1.39 in 1998 to 1.24 in",
    "2022, as production became more import-intensive. That is the import",
    "share on the left, showing up in the data."
  )
)

###### B_03_07: Diagram Height #################################################
# Note: Height of the Keynesian cross and the flows diagram in the browser.

B_03_07_diagram_height_chr <- "440px"

###### B_03_08: Rounds Height ##################################################
# Note: Height of the spending-rounds figure in the browser.

B_03_08_rounds_height_chr <- "380px"

###### B_03_09: Marginal Euro Height ###########################################
# Note: Height of the stacked bar showing where one euro goes.

B_03_09_euro_height_chr <- "160px"

###### B_03_10: Package Height #################################################
# Note: Height of the stage 5 and stage 6 comparison figures.

B_03_10_package_height_chr <- "420px"

###### B_03_11: Controls #######################################################
# Note: One entry per numeric control: label (HTML), slider range and step,
#   and the stage from which it appears. Each gets a slider and a box.

B_03_11_controls_lst <- list(
  c0       = list(label = "Autonomous Consumption (c<sub>0</sub>)",
                  min = 0, max = 60, step = 5, from = 1),
  mpc      = list(label = "Marginal Propensity to Consume (c)",
                  min = 0, max = 0.95, step = 0.05, from = 1),
  inv      = list(label = "Investment (I)",
                  min = 0, max = 120, step = 5, from = 1),
  gov      = list(label = "Government Spending (G)",
                  min = 0, max = 160, step = 5, from = 2),
  d_inv    = list(label = "Change in Investment (ΔI)",
                  min = -40, max = 40, step = 5, from = 1),
  d_gov    = list(label = "Change in Government Spending (ΔG)",
                  min = -40, max = 40, step = 5, from = 2),
  tax0     = list(label = "Lump-Sum Taxes (T<sub>0</sub>)",
                  min = 0, max = 80, step = 5, from = 2),
  tax_rate = list(label = "Tax Rate on Income (t)",
                  min = 0, max = 0.6, step = 0.05, from = 2),
  d_tax0   = list(label = "Change in Lump-Sum Taxes (ΔT<sub>0</sub>)",
                  min = -40, max = 40, step = 5, from = 2),
  exp0     = list(label = "Exports (X)",
                  min = 0, max = 160, step = 5, from = 3),
  imp0     = list(label = "Autonomous Imports (m<sub>0</sub>)",
                  min = 0, max = 60, step = 5, from = 3),
  imp_rate = list(label = "Marginal Propensity to Import (m)",
                  min = 0, max = 0.6, step = 0.05, from = 3),
  mpc_h    = list(label = "MPC of High-MPC Households (c<sub>H</sub>)",
                  min = 0.05, max = 1, step = 0.05, from = 4),
  mpc_l    = list(label = "MPC of Low-MPC Households (c<sub>L</sub>)",
                  min = 0, max = 0.95, step = 0.05, from = 4),
  omega    = list(label = "Income Share of High-MPC Households (ω)",
                  min = 0, max = 1, step = 0.05, from = 4),
  transfer = list(label = "Redistribution to High-MPC Households (τ)",
                  min = -40, max = 40, step = 5, from = 4),
  budget   = list(label = "Budget for the Package (€bn)",
                  min = 1, max = 40, step = 1, from = 5)
)

###### B_03_12: Parameter Explanations #########################################
# Note: What each control is and what raising it does. Shown as a hover
#   tooltip on every control, and under a scenario for its key parameters.

B_03_12_help_lst <- list(
  c0 = paste(
    "Consumption that does not depend on income at all: the floor under",
    "spending. Shifts the expenditure line up without tilting it."
  ),
  mpc = paste(
    "A slope: of one extra euro of disposable income, c is spent and",
    "(1 − c) is saved. It is the single most important number in the model,",
    "because it sets how much of each round survives into the next. It is",
    "also the one number here that the Irish tables cannot measure: they",
    "record what was spent, never what would have been spent out of one",
    "more euro. The default 0.55 comes from the consumption literature."
  ),
  inv = "Firms' spending on capital. Taken as given here, not explained.",
  gov = paste(
    "Government purchases of goods and services. Unlike a transfer, the",
    "whole euro is spent, which is why its multiplier is the largest."
  ),
  d_inv = paste(
    "A change in investment: the demand shock. Traces the rounds without",
    "any policy being involved."
  ),
  d_gov = paste(
    "A change in government spending, financed by borrowing unless you also",
    "move taxes. Borrowed spending adds demand the circular flow did not",
    "generate; watch the budget tile to see how much is being borrowed."
  ),
  tax0 = paste(
    "Taxes that do not vary with income. A rise cuts disposable income",
    "one-for-one, but cuts consumption only by c times as much. Set to zero",
    "here: the Irish tables give a total tax take, not a lump-sum part."
  ),
  tax_rate = paste(
    "The share of each extra euro of income taken in tax. On its own it is",
    "a leakage: the euro leaves the flow and the next round is smaller,",
    "which lowers the multiplier to 1/(1 − c(1 − t)) — and that is",
    "exactly why it stabilises the economy automatically. It stops being",
    "a leakage to the extent the government spends the money back."
  ),
  d_tax0 = paste(
    "A change in lump-sum taxes. Negative is a tax cut or a transfer to",
    "households. Move it with government spending to build a balanced",
    "package; leave it at zero and the spending is borrowed."
  ),
  exp0 = "Foreign demand for home output. Taken as given.",
  imp0 = "Imports that do not vary with income.",
  imp_rate = paste(
    "The share of each extra euro of INCOME spent on imports: the third",
    "leakage. Smaller than the import content of spending, because only",
    "part of a euro of income is spent at all. The Irish tables put the",
    "import content of a euro of household spending at about 0.35, direct",
    "plus supply chain, which works out at 0.13 per euro of income."
  ),
  mpc_h = paste(
    "The MPC of households that spend what they receive: the credit",
    "constrained and the hand-to-mouth. Close to one in the micro evidence."
  ),
  mpc_l = paste(
    "The MPC of households that smooth consumption over a lifetime. The",
    "permanent-income benchmark on the sample paper gives one half out of a",
    "two-period windfall, and less over a longer horizon."
  ),
  omega = paste(
    "The share of disposable income going to high-MPC households. It",
    "decides how much the average MPC is pulled towards c<sub>H</sub>."
  ),
  transfer = paste(
    "A transfer from low-MPC to high-MPC households. It costs the Exchequer",
    "nothing, so any effect on output comes purely from who holds the euro."
  ),
  budget = "The size of the fiscal package being compared, in euro billion."
)

###### B_03_13: Prompts ########################################################
# Note: One "what to try" prompt per stage, shown above the figures.

B_03_13_prompts_lst <- list(
  "1" = paste(
    "Set a change in investment of −20 and read the rounds figure. The",
    "first bar is the shock; each one after it is the last times the MPC.",
    "Why does the total settle at 1/(1 − c) times the shock rather than",
    "growing for ever?"
  ),
  "2" = paste(
    "Do these three in order and watch the budget tile each time. Raise",
    "lump-sum taxes by 20 on their own: output falls, because the tax is a",
    "pure leakage. Now add 20 to government spending as well: output rises,",
    "although every euro spent has been taxed back — that is the",
    "balanced-budget multiplier. Now take the tax rise away and leave the",
    "spending: output rises further, and the difference is what borrowing",
    "bought. The three panels below say why."
  ),
  "3" = paste(
    "Stages 1 and 2 assumed net exports away. Raise the marginal propensity",
    "to import from Ireland's 0.13 towards 0.35 and watch the multiplier",
    "fall towards one. Look at the marginal-euro bar: which leakage is",
    "largest at Ireland's own calibration, and does that surprise you?"
  ),
  "4" = paste(
    "The two MPCs average to the same 0.55 as before, so the multiplier is",
    "unchanged. Now move the redistribution slider: output changes although",
    "the government has spent nothing and borrowed nothing."
  ),
  "5" = paste(
    "The four navy packages each add the same amount to the deficit, so",
    "output alone ranks them: explain that order from the MPCs. The two",
    "green ones are financed within the package and cost the Exchequer",
    "nothing, so they belong in a different column, not further down the",
    "same one."
  ),
  "6" = paste(
    "Read the panel below first: the numbers you have been moving for five",
    "stages are Ireland in 2022. Then hit Reset, so every slider is back on",
    "its measured value, and compare this model's k with the multipliers the",
    "Irish input-output tables actually publish. The two are not the same",
    "object, and knowing why is the point."
  )
)

###### B_03_14: The Model, Stage by Stage ######################################
# Note: Every equation in the equations panel, in four groups. "versions"
#   maps the stage where a version first applies to its LaTeX; "notes" says
#   what that version adds. Stages follow the header's list.

B_03_14_equations_lst <- list(

  # --- The model's equations --------------------------------------------------
  list(
    group = "model", label = "Consumption",
    versions = list(
      "1" = "C = c_0 + c\\,Y",
      "2" = "C = c_0 + c\\,(Y - T)",
      "4" = paste0("C = c_0 + \\bar{c}\\,(Y - T) + ",
                   "(c_H - c_L)\\,\\tau")
    ),
    notes = list(
      "1" = paste("Households spend a fixed fraction c of income, whatever",
                  "else is going on."),
      "2" = "What households spend out of is income after tax.",
      "4" = paste("Two types with different MPCs. The average MPC",
                  "c&#772; drives the multiplier; the gap between the two",
                  "is what makes redistribution work.")
    )
  ),
  list(
    group = "model", label = "Taxes",
    versions = list("2" = "T = T_0 + t\\,Y"),
    notes = list(
      "2" = paste("A lump-sum part and a part that rises with income. Only",
                  "the second changes the multiplier.")
    )
  ),
  list(
    group = "model", label = "Imports",
    versions = list("3" = "M = m_0 + m\\,Y"),
    notes = list(
      "3" = "Imports rise with income, so they leak demand abroad."
    )
  ),
  list(
    group = "model", label = "Goods Market",
    versions = list(
      "1" = "Y = C + I",
      "2" = "Y = C + I + G",
      "3" = "Y = C + I + G + X - M"
    ),
    notes = list(
      "1" = paste("Output is whatever is demanded. This is the assumption",
                  "the whole model rests on."),
      "2" = "The government buys goods too.",
      "3" = paste("Net exports, assumed away until now, finally appear. In",
                  "a small open economy they are the largest correction the",
                  "model receives.")
    )
  ),

  # --- Assumptions ------------------------------------------------------------
  list(
    group = "assumption", label = "Prices",
    versions = list("1" = "P \\text{ fixed; output is demand-determined}"),
    notes = list(
      "1" = paste("Firms meet demand at the going price. The short run is",
                  "short enough that this is not silly, and lecture 2.3",
                  "asks what makes prices sticky.")
    )
  ),
  list(
    group = "assumption", label = "Closed Economy",
    versions = list(
      "1" = "X = M = 0",
      "3" = "X \\text{ given},\\ M = m_0 + m\\,Y"
    ),
    notes = list(
      "1" = paste("Nothing crosses the border. Harmless for a continent,",
                  "badly wrong for Ireland, and stage 3 drops it."),
      "3" = "Exports are exogenous; imports leak with income."
    )
  ),
  list(
    group = "assumption", label = "Given",
    versions = list(
      "1" = "I \\text{ exogenous}",
      "3" = "I,\\ G,\\ X \\text{ exogenous}"
    ),
    notes = list(
      "1" = paste("Investment is a number, not a decision. Lecture 2.1",
                  "replaces it with a firm's valuation problem."),
      "3" = "Government spending and exports are set outside the model."
    )
  ),
  list(
    group = "assumption", label = "No Monetary Response",
    versions = list("1" = "i \\text{ fixed}"),
    notes = list(
      "1" = paste("The central bank does not move. In the IS-MP-PC model it",
                  "does, and the multiplier is then much smaller — except at",
                  "the lower bound, where this assumption is close to right.")
    )
  ),
  list(
    group = "assumption", label = "Spending Out of Current Income",
    versions = list(
      "1" = "C \\text{ depends on } Y \\text{ today}",
      "4" = "\\text{a share } \\omega \\text{ is hand-to-mouth}"
    ),
    notes = list(
      "1" = paste("The permanent-income hypothesis says households look at",
                  "lifetime resources instead, which would make c small."),
      "4" = paste("A compromise: some households are constrained and spend",
                  "what arrives, the rest smooth.")
    )
  ),
  list(
    group = "assumption", label = "One Good",
    versions = list(
      "1" = "\\text{output is a single good}",
      "6" = "\\text{no input-output structure}"
    ),
    notes = list(
      "1" = paste("There are no sectors and no supply chains: a euro of",
                  "demand is a euro of demand, wherever it lands."),
      "6" = paste("This is what the input-output tables add, and why a",
                  "measured multiplier differs by sector while this one",
                  "cannot.")
    )
  ),
  list(
    group = "assumption", label = "Stability",
    versions = list("1" = "0 < \\bar{c}(1 - t) - m < 1"),
    notes = list(
      "1" = paste("Each round must be smaller than the last, or the sum",
                  "never settles.")
    )
  ),

  # --- Solved forms -----------------------------------------------------------
  list(
    group = "solved", label = "The Multiplier",
    versions = list(
      "1" = "k = \\frac{1}{1 - c}",
      "2" = "k = \\frac{1}{1 - c(1 - t)}",
      "3" = "k = \\frac{1}{1 - c(1 - t) + m}",
      "4" = "k = \\frac{1}{1 - \\bar{c}(1 - t) + m}"
    ),
    notes = list(
      "1" = "One over the share of a euro that leaks into saving.",
      "2" = "Tax is now a leakage too, so the multiplier falls.",
      "3" = "Imports are the third leakage.",
      "4" = paste("Only the average MPC matters for k. Who holds the income",
                  "matters for how much is spent, not for the multiplier",
                  "on it.")
    )
  ),
  list(
    group = "solved", label = "Equilibrium Output",
    versions = list("1" = "Y^* = k\\,A"),
    notes = list(
      "1" = "The multiplier times autonomous spending."
    )
  ),
  list(
    group = "solved", label = "Autonomous Spending",
    versions = list(
      "1" = "A = c_0 + I",
      "2" = "A = c_0 - c\\,T_0 + I + G",
      "3" = "A = c_0 - c\\,T_0 + I + G + X - m_0",
      "4" = paste0("A = c_0 - \\bar{c}\\,T_0 + (c_H - c_L)\\tau",
                   " + I + G + X - m_0")
    ),
    notes = list(
      "1" = "Everything that does not depend on income.",
      "2" = paste("A lump-sum tax enters multiplied by c, not one-for-one:",
                  "households absorb part of it by saving less."),
      "3" = "Autonomous imports are demand that leaves at once.",
      "4" = "A budget-neutral transfer shifts autonomous spending."
    )
  ),
  list(
    group = "solved", label = "Spending Multiplier",
    versions = list("2" = "\\frac{dY}{dG} = k"),
    notes = list(
      "2" = "The state spends the whole euro, so the full k applies."
    )
  ),
  list(
    group = "solved", label = "Tax Multiplier",
    versions = list(
      "2" = "\\frac{dY}{dT_0} = -c\\,k",
      "4" = "\\frac{dY}{dT_0} = -\\bar{c}\\,k"
    ),
    notes = list(
      "2" = paste("Smaller than the spending multiplier in absolute value,",
                  "because the first round is c, not 1."),
      "4" = "The average MPC does the filtering."
    )
  ),
  list(
    group = "solved", label = "Balanced-Budget Multiplier",
    versions = list("2" = "\\frac{dY}{dG}\\Big|_{dG = dT_0} = (1 - c)\\,k"),
    notes = list(
      "2" = paste("Spending and taxing the same euro still raises output,",
                  "because the spending enters the flow at its full value",
                  "while the tax only cuts spending by c times as much. With",
                  "no tax rate and no imports, k = 1/(1 − c) and this is",
                  "exactly one: €1 of spending buys €1 of output. Tax is a",
                  "leakage only to the extent it is NOT spent back.")
    )
  ),
  list(
    group = "solved", label = "Redistribution Multiplier",
    versions = list("4" = "\\frac{dY}{d\\tau} = (c_H - c_L)\\,k"),
    notes = list(
      "4" = paste("Nothing is borrowed and nothing is spent. Output moves",
                  "only because the euro changed hands.")
    )
  ),

  # --- Descriptors ------------------------------------------------------------
  list(
    group = "descriptor", label = "Average MPC",
    versions = list("4" = "\\bar{c} = \\omega c_H + (1 - \\omega) c_L"),
    notes = list(
      "4" = "The income-weighted average across the two types."
    )
  ),
  list(
    group = "descriptor", label = "Share Passed On",
    versions = list(
      "1" = "q = c",
      "2" = "q = c(1 - t)",
      "3" = "q = c(1 - t) - m",
      "4" = "q = \\bar{c}(1 - t) - m"
    ),
    notes = list(
      "1" = "What one euro of income becomes in the next round.",
      "2" = "Tax is taken before households decide anything.",
      "3" = "And part of what they spend goes abroad.",
      "4" = "The average MPC again."
    )
  ),
  list(
    group = "descriptor", label = "The Rounds",
    versions = list(
      "1" = paste0("\\Delta Y = \\Delta A\\,(1 + q + q^2 + \\cdots)",
                   " = \\frac{\\Delta A}{1 - q}")
    ),
    notes = list(
      "1" = paste("The multiplier is a geometric series, which is why",
                  "k = 1/(1 − q). The rounds figure is this sum, drawn.")
    )
  ),
  list(
    group = "descriptor", label = "Total Leakage",
    versions = list("1" = "1 - q = \\tfrac{1}{k}"),
    notes = list(
      "1" = "Saving, plus tax, plus imports. The multiplier is its inverse."
    )
  ),
  list(
    group = "descriptor", label = "Budget Balance",
    versions = list("2" = "B = T - G = T_0 + t\\,Y - G"),
    notes = list(
      "2" = paste("What the Exchequer takes out of the flow less what it",
                  "puts back. A euro of tax is a leakage only while B is",
                  "rising: spend it and it re-enters the flow as G.")
    )
  ),
  list(
    group = "descriptor", label = "Financing the Gap",
    versions = list(
      "2" = paste0("\\Delta B = \\Delta T_0 + t\\,\\Delta Y - \\Delta G")
    ),
    notes = list(
      "2" = paste("A package that widens the deficit brings in spending the",
                  "flow did not generate — genuinely external if the lender",
                  "is abroad, a transfer within the flow if the lender is a",
                  "domestic saver. Note the t ΔY term: output rises, tax",
                  "revenue rises with it, and the package part-pays for",
                  "itself, so the deficit is smaller than ΔG − ΔT₀.")
    )
  ),
  list(
    group = "descriptor", label = "Type I Multiplier",
    versions = list("6" = paste0("k^{I}_j = \\sum_i \\big[(I - A)^{-1}",
                                 "\\big]_{ij}")),
    notes = list(
      "6" = paste("The input-output multiplier for sector j: the column sum",
                  "of the Leontief inverse. It counts the supply chain, and",
                  "has no household round in it at all.")
    )
  ),
  list(
    group = "descriptor", label = "Type II Multiplier",
    versions = list("6" = "k^{II}_j > k^{I}_j"),
    notes = list(
      "6" = paste("The same calculation with households added as a row and",
                  "a column, so wages earned along the chain are spent",
                  "again. That added round is this model's mechanism.")
    )
  )
)

###### B_03_15: Equation Group Titles ##########################################
# Note: Group headings in the equations tabs.

B_03_15_groups_vec <- c(
  model      = "Model Equations",
  assumption = "Assumptions",
  solved     = "Solved Forms",
  descriptor = "Descriptors"
)

###### B_03_16: Notation Key ###################################################
# Note: Notation tab. Groups: var, par, flw (flows and policy instruments),
#   with the stage each symbol first appears in.

B_03_16_notation_lst <- list(
  list(grp = "var", sym = "Y", txt = "output (income)", from = 1),
  list(grp = "var", sym = "Y^*", txt = "equilibrium output", from = 1),
  list(grp = "var", sym = "E", txt = "planned expenditure, C + I + G + X - M",
       from = 1),
  list(grp = "var", sym = "C", txt = "consumption", from = 1),
  list(grp = "var", sym = "S", txt = "saving", from = 1),
  list(grp = "var", sym = "A", txt = "autonomous spending", from = 1),
  list(grp = "par", sym = "c_0", txt = "autonomous consumption", from = 1),
  list(grp = "par", sym = "c", txt = "marginal propensity to consume",
       from = 1),
  list(grp = "par", sym = "k", txt = "the multiplier", from = 1),
  list(grp = "par", sym = "q", txt = "share of a euro passed on", from = 1),
  list(grp = "flw", sym = "I", txt = "investment", from = 1),
  list(grp = "flw", sym = "\\Delta I", txt = "change in investment", from = 1),
  list(grp = "var", sym = "T", txt = "taxes", from = 2),
  list(grp = "par", sym = "T_0", txt = "lump-sum taxes", from = 2),
  list(grp = "par", sym = "t", txt = "tax rate on income", from = 2),
  list(grp = "var", sym = "B", txt = "budget balance, T − G", from = 2),
  list(grp = "flw", sym = "G", txt = "government spending", from = 2),
  list(grp = "flw", sym = "\\Delta G",
       txt = "change in government spending", from = 2),
  list(grp = "flw", sym = "\\Delta T_0",
       txt = "change in lump-sum taxes", from = 2),
  list(grp = "var", sym = "M", txt = "imports", from = 3),
  list(grp = "par", sym = "m_0", txt = "autonomous imports", from = 3),
  list(grp = "par", sym = "m", txt = "marginal propensity to import",
       from = 3),
  list(grp = "flw", sym = "X", txt = "exports", from = 3),
  list(grp = "par", sym = "c_H", txt = "MPC of high-MPC households", from = 4),
  list(grp = "par", sym = "c_L", txt = "MPC of low-MPC households", from = 4),
  list(grp = "par", sym = "\\bar{c}", txt = "average MPC", from = 4),
  list(grp = "par", sym = "\\omega",
       txt = "income share of high-MPC households", from = 4),
  list(grp = "flw", sym = "\\tau",
       txt = "redistribution to high-MPC households", from = 4),
  list(grp = "par", sym = "A_{ij}", txt = "matrix of input coefficients",
       from = 6),
  list(grp = "par", sym = "(I - A)^{-1}", txt = "the Leontief inverse",
       from = 6),
  list(grp = "par", sym = "k^{I}_j", txt = "Type I multiplier of sector j",
       from = 6),
  list(grp = "par", sym = "k^{II}_j", txt = "Type II multiplier of sector j",
       from = 6)
)

###### B_03_17: Notation Columns ###############################################
# Note: How the notation tab is split into columns.

B_03_17_nota_cols_lst <- list(
  "Variables"        = "var",
  "Parameters"       = "par",
  "Policy and Flows" = "flw"
)

###### B_03_18: Recalculation Delay ############################################
# Note: Milliseconds to wait before recalculating, so a burst of changes is
#   handled in one go.

B_03_18_debounce_ms_int <- 250L

###### B_03_19: The Irish Calibration ##########################################
# Note: Where every default in B_03_01 came from, one row per parameter, for
#   the stage 6 reveal. "source" is the arithmetic on the CSO 2022 tables.

B_03_19_calib_df <- data.frame(
  param = c(
    "Marginal propensity to consume, c",
    "Tax rate on income, t",
    "Marginal propensity to import, m",
    "Government spending, G",
    "Investment, I",
    "Exports, X",
    "Autonomous imports, m<sub>0</sub>",
    "Autonomous consumption, c<sub>0</sub>",
    "Lump-sum taxes, T<sub>0</sub>",
    "Equilibrium output, Y*"
  ),
  value = c("0.55", "0.31", "0.13", "&euro;57.1bn", "&euro;44.3bn",
            "&euro;123.7bn", "&euro;40.2bn", "&euro;19.9bn", "&euro;0bn",
            "&euro;272.9bn"),
  source = c(
    paste("<strong>Not from the tables.</strong> A supply-use table records",
          "what was spent, never what would have been spent out of one more",
          "euro. Taken from the consumption literature: the annual marginal",
          "propensity to consume out of transitory income, 0.5 to 0.6."),
    paste("All tax in the tables &mdash; taxes on products &euro;13.4bn,",
          "other taxes on production &euro;1.1bn, income tax &euro;31.3bn,",
          "social contributions &euro;16.0bn, corporation tax &euro;22.6bn,",
          "&euro;84.5bn in all &mdash; over GNI* of &euro;272.9bn. An",
          "<strong>average</strong> rate standing in for a marginal one."),
    paste("Import content of &euro;1 of household spending = 0.35: direct",
          "imports &euro;22.9bn / &euro;123.5bn = 0.185, plus 0.163 embodied",
          "in the Irish products households buy, from the Leontief inverse",
          "of the same tables. Multiplied by c(1 &minus; t) = 0.38, the",
          "share of a euro of <em>income</em> that is spent at all."),
    paste("Government final consumption, 2022: &euro;51.1bn of Irish",
          "products (cso_govt_amt) plus &euro;6.0bn imported directly."),
    paste("Gross fixed capital formation &euro;43.1bn (cso_gfcf_amt) plus",
          "&euro;1.2bn of inventories (cso_inventory_amt), 2022."),
    paste("The external term on the GNI* basis: what is left of foreign",
          "demand after its own imported inputs and after the profits and",
          "depreciation of foreign-owned firms that GNI* excludes. Gross",
          "exports were &euro;644.2bn, of which &euro;276.3bn was imported",
          "inputs. This is a residual, not a published figure."),
    paste("The residual that makes M = m<sub>0</sub> + mY come out at",
          "&euro;75.7bn: the imports serving Irish domestic demand",
          "(&euro;43.0bn for consumption, &euro;16.1bn for government,",
          "&euro;16.6bn for investment), direct plus supply chain."),
    paste("The residual that makes the model reproduce measured household",
          "consumption of &euro;123.5bn (cso_hh_amt plus its direct imports",
          "and product taxes) given c = 0.55."),
    paste("Zero. The tables give a total tax take; they do not identify a",
          "part that is independent of income, so nothing is invented here."),
    paste("Modified gross national income, GNI*, 2022. This is the one",
          "number in the table that is not in these tables: it is a CSO",
          "headline aggregate, used here because Irish GDP is not a usable",
          "income base &mdash; see the first note underneath.")
  ),
  stringsAsFactors = FALSE
)

###### B_03_20: The Reveal #####################################################
# Note: The panel at stage 6. "lede" is the payoff line; "notes" are the
#   caveats, above all what an average ratio can and cannot stand in for.

B_03_20_reveal_lst <- list(
  head = "These Were Ireland's Own Numbers",
  lede = paste(
    "Nothing on the sliders was invented. Every leakage you have been",
    "moving for five stages, and every level you have been moving it",
    "against, is the Irish economy in 2022, taken from the CSO Supply and",
    "Use and Input-Output Tables for that year &mdash; the same file the",
    "input-output app draws on. At those values Ireland's multiplier is",
    "<strong>k = 1.33</strong>: a euro of demand becomes about &euro;1.33",
    "of output, because 31 cents of every euro of income goes in tax, 31",
    "cents is not spent, and 13 cents goes abroad."
  ),
  notes = c(
    paste("<strong>Why GNI* and not GDP.</strong> Irish GDP in 2022 was",
          "&euro;507.5bn, of which household consumption was 24 per cent and",
          "net exports 56 per cent. No textbook consumption function fits",
          "that: with any household MPC you would need autonomous",
          "consumption of about &minus;&euro;215bn to reproduce the measured",
          "level of C. The reason is that most of Irish GDP is profit and",
          "depreciation accruing to foreign-owned firms and never becomes",
          "anyone's income to spend. GNI* takes that out, and on the GNI*",
          "base the accounts behave like a normal economy: C is 45 per cent,",
          "G 21, I 16 and the external balance 18."),
    paste("<strong>Average is not marginal.</strong> t and m here are",
          "<em>average</em> ratios from a single year &mdash; total tax over",
          "income, import content per euro of spending. The model needs",
          "<em>marginal</em> propensities: what happens to the NEXT euro.",
          "They coincide only if the ratios are flat in income, which they",
          "are not: Ireland's tax system is progressive, so the marginal",
          "rate is above 0.31, and import content rises with income. Treat",
          "them as the best available proxies, not as measurements."),
    paste("<strong>The MPC is not in the data at all.</strong> A supply-use",
          "table is a photograph of one year's spending. It can tell you",
          "what households spent; it cannot tell you what they would have",
          "spent out of one more euro. c = 0.55 is a number from the",
          "consumption literature, and c<sub>0</sub> is then whatever it",
          "takes to hit the measured level of consumption. If you think the",
          "MPC is 0.7, change it &mdash; and watch what it does to k."),
    paste("<strong>What the budget tile is and is not.</strong> G here is",
          "government purchases of goods and services only. Transfers,",
          "public investment, interest and non-tax revenue are outside the",
          "model, so T &minus; G at the defaults (about +&euro;27bn) is a",
          "purchases balance, not the general government balance &mdash;",
          "Ireland ran a surplus of roughly &euro;8bn in 2022. The tile's",
          "<em>change</em>, which is what the fiscal scenarios turn on, is",
          "exactly right whatever the level."),
    paste("<strong>And &ldquo;saved&rdquo; means &ldquo;not spent&rdquo;.",
          "</strong> The saving slice of the marginal-euro bar is every euro",
          "of income that does not come back as demand: household saving,",
          "but also income retained by firms and income that never reaches",
          "an Irish household. In an economy like Ireland's that second part",
          "is the larger one."),
    paste("<strong>Source.</strong> CSO, Supply and Use and Input-Output",
          "Tables for Ireland 2022, Tables 2.9, 2.10 and 2.6, as shipped",
          "with the input-output app in",
          "<code>_apps/io-multiplier/data/io_products.csv</code>. GNI* is",
          "the CSO's own 2022 estimate. Everything else above is arithmetic",
          "on those columns, set out row by row in the table.")
  )
)

###### B_03_21: The Fiscal Mechanics ###########################################
# Note: Three paragraphs on tax, the balanced budget and borrowing, shown
#   under the readouts from stage 2 beside the budget tile.

B_03_21_fiscal_lst <- list(
  paste(
    "<strong>On its own, tax is a leakage.</strong> Every euro the",
    "Exchequer takes at each round is a euro that does not become someone",
    "else's income in the next one. That is the whole of why the tax rate",
    "sits inside the multiplier as k = 1/(1 &minus; c(1 &minus; t)): raise",
    "t and each round is smaller than the last by more, so the series that",
    "the rounds figure draws dies out faster. Raise lump-sum taxes on their",
    "own and output falls by c&#772;k times the rise &mdash; and the budget",
    "balance tile moves into surplus, which is the leakage, sitting there."
  ),
  paste(
    "<strong>It stops being a leakage to the extent the government spends",
    "it back.</strong> Raise G and T<sub>0</sub> by the same amount and",
    "output still RISES. The spending enters the flow at its full value;",
    "the tax only reduces spending by c&#772; times the amount, because",
    "households absorb part of the tax by saving less. What is left over is",
    "the balanced-budget multiplier, (1 &minus; c&#772;)k, and in the bare",
    "model &mdash; no tax rate, no imports &mdash; it is exactly one: a euro",
    "taxed and spent buys a euro of output. Nothing has been borrowed."
  ),
  paste(
    "<strong>A deficit brings in demand from outside the flow.</strong> If",
    "G exceeds T the difference is borrowed, and borrowing is spending the",
    "circular flow did not itself generate. Where it comes from matters. If",
    "the lender is abroad, the euro is genuinely external demand, doing the",
    "same work as an export. If the lender is a domestic saver, it is a",
    "transfer within the flow, and the model is quietly assuming that saver",
    "had no other use for the money &mdash; an assumption that is fine when",
    "there is spare capacity and idle saving, and much less fine when there",
    "is not. Read the budget tile beside &Delta;Y: it names the package",
    "balanced, borrowed or in surplus, and the borrowing is always less",
    "than &Delta;G &minus; &Delta;T<sub>0</sub>, because the extra output",
    "pays part of the bill back in tax."
  )
)

###### B_03_22: Version ########################################################
# Note: Semantic version, shown in the footer; CHANGELOG.md has the history.

B_03_22_version_chr <- "1.0.0"

###### B_03_23: Source Repository ##############################################
# Note: The GitHub repo, linked from the footer.

B_03_23_repo_chr <- paste0("https://github.com/Sam-Deegan/",
                        "Interactive-Model-Keynesian-Multiplier")

#### B_04: Paths ###############################################################
# Note: The QR code only.

###### B_04_01: QR Code Source #################################################
# Note: The QR image: www/ if present, else the toolkit's own copy.

B_04_01_qr_src_chr <- T_07_04_qr_fn()

################################################################################
## D: Plots ####################################################################
################################################################################
# Note: Builders only; each returns a ggplot for the server to draw. The
#   palette, theme and formatters come from the toolkit. See CONVENTIONS.md 6.

#### D_01: The Cross and the Flows #############################################
# Note: The two standard ways of drawing the same equilibrium.

###### D_01_01: Keynesian Cross ################################################
# Note: The 45 degree line, planned expenditure before and after the change,
#   and the two equilibria. The identity E = Y takes no ghost.

D_01_01_cross_fn <- function(par, ref = NULL) {
  base  <- C_01_05_equilibrium_fn(par, delta = FALSE)
  new   <- C_01_05_equilibrium_fn(par, delta = TRUE)
  moved <- abs(new$y - base$y) > 1e-9

  ghost_on <- !T_02_03b_ghost_off_fn(par, ref)
  ref_eq   <- if (ghost_on) C_01_05_equilibrium_fn(ref, delta = TRUE) else NULL

  # One line takes the plain name; two are the same object at two moments
  lab_now_chr <- if (moved) "After the change" else "Planned expenditure"
  lab_was_chr <- "Before the change"

  # Wide enough to hold the ghost's crossing as well
  y_max  <- max(base$y, new$y, if (ghost_on) ref_eq$y else 0, 1) * 1.45
  y_grid <- seq(0, y_max, length.out = 201)
  ae_b   <- C_01_06_ae_line_fn(par, y_grid, delta = FALSE)
  ae_n   <- C_01_06_ae_line_fn(par, y_grid, delta = TRUE)

  # Ghost first, so the live schedule and equilibrium sit on top
  ghost_lyr <- if (!ghost_on) NULL else list(
    T_02_03a_ghost_line_fn(
      C_01_06_ae_line_fn(ref, y_grid, delta = TRUE),
      aes(x = y, y = ae),
      colour = T_01_02_series_vec[["main"]], linewidth = 1.1),
    T_02_03a_ghost_point_fn(ref_eq$y, ref_eq$y,
                            T_01_02_series_vec[["main"]])
  )

  # Same range on both axes, so the identity is drawn at 45 degrees
  lim_vec <- c(0, y_max)
  q_num   <- C_01_02_leak_fn(par)$pass_on
  a_num   <- C_01_04_autonomous_fn(par, delta = TRUE)
  # Width of the schedule's name in data units
  w_num   <- nchar("Planned expenditure") * 0.55 * 3.2 / 95 * y_max

  # Both equilibria named only where they are far enough apart to read
  split_lgl <- moved && abs(new$y - base$y) > 0.08 * y_max
  mark_at   <- if (split_lgl) c(base$y, new$y) else new$y
  mark_lab  <- if (split_lgl) {
    expression(Y[0]^"*", Y[1]^"*")
  } else {
    expression(Y^"*")
  }

  # Dashed leaders from both axes to the crossing; see CONVENTIONS.md 6
  lead_lyr <- lapply(mark_at, function(y_num) {
    list(
      annotate("segment", x = 0, xend = y_num, y = y_num, yend = y_num,
               linetype = "dashed", linewidth = 0.45,
               colour = T_01_01_palette_vec[["ink"]]),
      annotate("segment", x = y_num, xend = y_num, y = 0, yend = y_num,
               linetype = "dashed", linewidth = 0.45,
               colour = T_01_01_palette_vec[["ink"]])
    )
  })

  p <- ggplot() +
    T_02_02_zero_fn() +
    lead_lyr +
    ghost_lyr +
    geom_line(aes(x = y_grid, y = y_grid),
              colour = T_01_02_series_vec[["reference"]], linewidth = 0.6)

  if (moved) {
    p <- p +
      geom_line(data = ae_b, aes(x = y, y = ae, colour = lab_was_chr),
                linewidth = 0.9, linetype = "22") +
      T_02_03_point_fn(base$y, base$y, T_01_02_series_vec[["compare"]], 2.8)
  }

  p <- p +
    geom_line(data = ae_n, aes(x = y, y = ae, colour = lab_now_chr),
              linewidth = 1.1) +
    T_02_03_point_fn(new$y, new$y) +
    scale_colour_manual(values = setNames(
      c(T_01_02_series_vec[["main"]], T_01_02_series_vec[["compare"]]),
      c(lab_now_chr, lab_was_chr)
    )) +
    scale_x_continuous(breaks = mark_at, labels = mark_lab) +
    coord_cartesian(xlim = lim_vec, ylim = lim_vec, expand = FALSE) +
    # Names clear their lines across the name's own width
    annotate("text", x = y_max * 0.93, y = y_max * 0.965, hjust = 1,
             vjust = 0.5, size = 3.2, label = "45° line",
             colour = T_01_02_series_vec[["reference"]]) +
    annotate("text", x = y_max * 0.98,
             y = min(a_num + q_num * (y_max * 0.98 - w_num),
                     y_max * 0.98 - w_num) - 0.045 * y_max,
             hjust = 1, vjust = 0.5, size = 3.2,
             label = "Planned expenditure",
             colour = T_01_02_series_vec[["main"]]) +
    labs(
      # Short: the panel is square and a folded title is clipped
      title = paste0("The Keynesian Cross: Y* = ", T_02_04_eur_fn(new$y)),
      x = expression(bold("Output (" * Y * "), EUR billion")),
      y = expression(bold("Planned expenditure (" * E * "), EUR billion")),
      caption = paste0(
        "The 45° line is the identity E = Y, every point where planned ",
        "expenditure equals output — not the multiplier. Equilibrium ",
        "output Y* is where the expenditure line meets it: to the left of ",
        "it planned expenditure is above output, so output is rising. ",
        "Slope of the expenditure line: q = ",
        T_02_05_num_fn(q_num),
        " — the fraction of a euro of income passed on."
      )
    ) +
    T_02_01_theme_fn(grid = "none") +
    theme(aspect.ratio = 1)

  if (moved) {
    p <- p + annotate(
      "segment", x = base$y, xend = new$y,
      y = y_max * 0.06, yend = y_max * 0.06,
      colour = T_01_02_series_vec[["main"]], linewidth = 0.9,
      arrow = arrow(length = unit(0.16, "cm"), ends = "last")
    ) + annotate(
      "label", x = (base$y + new$y) / 2, y = y_max * 0.125,
      label = paste0("ΔY = ", T_02_04_eur_fn(new$y - base$y)),
      colour = T_01_02_series_vec[["main"]], size = 4, fontface = "bold",
      fill = T_01_01_palette_vec[["wash"]], label.size = 0,
      label.padding = unit(0.12, "lines")
    )
  }
  p
}

###### D_01_02: Injections and Withdrawals #####################################
# Note: The same equilibrium drawn as leakages against injections. Both
#   schedules and the crossing are ghosted.

D_01_02_flows_fn <- function(par, ref = NULL) {
  new      <- C_01_05_equilibrium_fn(par, delta = TRUE)
  ghost_on <- !T_02_03b_ghost_off_fn(par, ref)
  ref_eq   <- if (ghost_on) C_01_05_equilibrium_fn(ref, delta = TRUE) else NULL

  y_max  <- max(new$y, if (ghost_on) ref_eq$y else 0, 1) * 1.45
  y_grid <- seq(0, y_max, length.out = 201)
  flows  <- C_01_07_flows_fn(par, y_grid, delta = TRUE)

  ghost_lyr <- if (!ghost_on) NULL else {
    g <- C_01_07_flows_fn(ref, y_grid, delta = TRUE)
    list(
      T_02_03a_ghost_line_fn(
        data.frame(y = g$y, value = g$withdrawals), aes(x = y, y = value),
        colour = T_01_02_series_vec[["main"]], linewidth = 1.1),
      T_02_03a_ghost_line_fn(
        data.frame(y = g$y, value = g$injections), aes(x = y, y = value),
        colour = T_01_02_series_vec[["compare"]], linewidth = 1.1),
      T_02_03a_ghost_point_fn(
        ref_eq$y, ref_eq$invest + ref_eq$govt + ref_eq$exports)
    )
  }

  long <- rbind(
    data.frame(y = flows$y, value = flows$withdrawals,
               line = "Withdrawals (S + T + M)"),
    data.frame(y = flows$y, value = flows$injections,
               line = "Injections (I + G + X)")
  )

  ggplot(long, aes(x = y, y = value, colour = line)) +
    T_02_02_zero_fn() +
    T_02_02_rest_fn(v = new$y) +
    ghost_lyr +
    geom_line(linewidth = 1.1) +
    T_02_03_point_fn(new$y, new$invest + new$govt + new$exports) +
    scale_colour_manual(values = c(
      "Withdrawals (S + T + M)" = T_01_02_series_vec[["main"]],
      "Injections (I + G + X)"  = T_01_02_series_vec[["compare"]]
    )) +
    T_02_02_mark_x_fn(new$y, expression(Y^"*")) +
    coord_cartesian(xlim = c(0, y_max)) +
    labs(
      title = "Injections (I + G + X) Meet Withdrawals (S + T + M)",
      x = expression(bold("Output (" * Y * "), EUR billion")),
      y = expression(bold("Injections and withdrawals, EUR billion")),
      caption = paste(
        "Withdrawals rise with income; injections do not. Where they cross,",
        "at equilibrium output Y*, nothing is pushing output either way."
      )
    ) +
    T_02_01_theme_fn()
}

#### D_02: Rounds and the Marginal Euro ########################################
# Note: The multiplier taken apart: over time, and per euro.

###### D_02_01: Spending Rounds ################################################
# Note: Each round's spending as a bar, the running total as a step, and the
#   limit k times the injection as a dotted rest line. Only the step is ghosted.

D_02_01_rounds_fn <- function(par, n_rounds, ref = NULL) {
  rounds <- C_01_08_rounds_fn(par, n_rounds)
  if (all(abs(rounds$spend) < 1e-12)) {
    return(T_02_02_placeholder_fn(paste(
      "Set a change in spending, taxes or the",
      "\nredistribution to start the rounds.")))
  }

  # The limit is a resting point: dotted, symbol on the right axis
  total <- rounds$total[1]

  # Ghost staircase as an explicit path, two points per round
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    g <- C_01_08_rounds_fn(ref, n_rounds)
    T_02_03a_ghost_path_fn(
      data.frame(x = c(rbind(g$round - 0.5, g$round + 0.5)),
                 y = rep(g$cumulative, each = 2)),
      aes(x = x, y = y), colour = T_01_02_series_vec[["main"]])
  }

  ggplot(rounds) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    T_02_02_rest_fn(h = total) +
    geom_col(aes(x = round, y = spend, fill = "Spending in This Round"),
             width = 0.65) +
    ghost_lyr +
    geom_step(aes(x = round - 0.5, y = cumulative,
                  colour = "Running Total"), linewidth = 1) +
    scale_fill_manual(values = c(
      "Spending in This Round" = T_01_02_series_vec[["band"]])) +
    scale_colour_manual(values = c(
      "Running Total" = T_01_02_series_vec[["main"]])) +
    scale_x_continuous(breaks = seq_len(n_rounds)) +
    T_02_02_mark_y_fn(total, expression(k %.% Delta * A)) +
    labs(
      title = "The Multiplier (k), One Round at a Time",
      x = expression(bold("Spending round")),
      y = expression(bold("Extra spending, EUR billion")),
      caption = paste0("Each round is the one before times q = ",
                       T_02_05_num_fn(C_01_02_leak_fn(par)$pass_on),
                       ". The running total settles at k × ΔA.")
    ) +
    T_02_01_theme_fn()
}

###### D_02_02: Where One Euro Goes ############################################
# Note: One stacked bar splitting a euro of extra income into its four uses.
#   The share consumed at home is the accent green; the leakages the ramp.

D_02_02_euro_fn <- function(par) {
  leak  <- C_01_02_leak_fn(par)
  parts <- data.frame(
    part = factor(
      c("Consumed at Home", "Saved", "Taken in Tax",
        "Spent on Imports"),
      levels = c("Consumed at Home", "Saved", "Taken in Tax",
                 "Spent on Imports")
    ),
    share = c(max(leak$pass_on, 0), max(leak$save, 0), max(leak$tax, 0),
              max(leak$imports, 0))
  )
  parts$share <- parts$share / sum(parts$share)
  parts <- droplevels(parts[parts$share > 1e-9, , drop = FALSE])
  parts$label <- ifelse(parts$share > 0.06,
                        paste0(round(parts$share * 100), "c"), "")

  ggplot(parts, aes(x = 1, y = share, fill = part)) +
    geom_col(width = 0.55, position = position_stack(reverse = TRUE)) +
    geom_text(aes(label = label),
              position = position_stack(vjust = 0.5, reverse = TRUE),
              colour = T_01_01_palette_vec[["ground"]], fontface = "bold",
              size = 4.2) +
    coord_flip() +
    scale_fill_manual(values = c(
      "Consumed at Home" = T_01_01_palette_vec[["green"]],
      "Saved"                       = T_01_01_palette_vec[["navy"]],
      "Taken in Tax"                = T_01_01_palette_vec[["blue"]],
      "Spent on Imports"            = T_01_01_palette_vec[["muted"]]
    )) +
    scale_y_continuous(labels = function(x) paste0(round(x * 100), "c")) +
    labs(x = NULL,
         y = expression(bold("Share of one euro of extra income (cent)")),
         caption = paste(
           "Four uses of a euro of extra income. Only the part consumed at",
           "home comes back as somebody else's income, so only it starts",
           "the next round; the other three leave the circular flow.")) +
    T_02_01_theme_fn(grid = "none") +
    theme(
      axis.text.y  = element_blank(),
      axis.ticks.y = element_blank()
    ) +
    guides(fill = guide_legend(nrow = 2, byrow = TRUE))
}

#### D_03: Packages, Types and the Bridge ######################################
# Note: The figures that only appear at the later stages.

###### D_03_01: Fiscal Packages ################################################
# Note: Output bought by each instrument, for the same sum moved. The two
#   that cost the Exchequer nothing are in the accent green. No ghost.

D_03_01_package_fn <- function(par, budget) {
  pol <- C_01_09_policies_fn(par, budget)
  pol$policy <- factor(pol$policy, levels = rev(pol$policy))

  # Each bar states its own budget cost
  pol$cost_lab <- ifelse(pol$cost > 0,
                         paste0("Adds ", T_02_04_eur_fn(budget),
                                " to the Deficit"),
                         "Financed Within the Package")
  pol$label <- paste0(T_02_04_eur_fn(pol$effect, 1), "   ",
                      ifelse(pol$cost > 0,
                             paste0("costs ", T_02_04_eur_fn(pol$cost, 0)),
                             "no net cost"))

  ggplot(pol, aes(x = policy, y = effect, fill = cost_lab)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    geom_col(width = 0.65) +
    geom_text(aes(label = label),
              hjust = ifelse(pol$effect >= 0, -0.08, 1.08), size = 3.8,
              colour = T_01_01_palette_vec[["navy"]]) +
    coord_flip(ylim = c(0, max(pol$effect) * 1.55)) +
    scale_fill_manual(values = stats::setNames(
      c(T_01_01_palette_vec[["navy"]], T_01_01_palette_vec[["green"]]),
      c(paste0("Adds ", T_02_04_eur_fn(budget), " to the Deficit"),
        "Financed Within the Package")
    )) +
    labs(
      title = paste0("Fiscal Packages: Six Ways to Move ",
                     T_02_04_eur_fn(budget)),
      x = NULL,
      y = expression(bold("Change in output (" * Delta * Y *
                            "), EUR billion")),
      fill = NULL,
      caption = paste(
        "The same sum, spent six ways. The four navy packages each add the",
        "whole sum to the deficit; the two green ones pay for themselves",
        "inside the package, so they buy less output but cost nothing. Do",
        "not rank these on output alone, and do not rank them on output per",
        "euro of budget either: for the green two that ratio divides by",
        "zero. Transfers and tax cuts reach output only after the MPC has",
        "taken its cut, which is why a euro handed out never buys as much",
        "as a euro spent."
      )
    ) +
    T_02_01_theme_fn()
}

###### D_03_02: Household Types ################################################
# Note: Income and consumption of each type, so the class can see where the
#   extra spending comes from. No ghost.

D_03_02_types_fn <- function(par) {
  eq  <- C_01_05_equilibrium_fn(par, delta = TRUE)
  tps <- C_01_10_types_fn(par, eq)

  long <- rbind(
    data.frame(type = tps$type, measure = "Disposable Income",
               value = tps$income),
    data.frame(type = tps$type, measure = "Consumption",
               value = tps$consume)
  )
  long$measure <- factor(long$measure,
                         levels = c("Disposable Income", "Consumption"))

  ggplot(long, aes(x = type, y = value, fill = measure)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    geom_col(position = position_dodge(width = 0.7), width = 0.62) +
    geom_text(aes(label = T_02_04_eur_fn(value)),
              position = position_dodge(width = 0.7), vjust = -0.4,
              size = 3.8, colour = T_01_01_palette_vec[["navy"]]) +
    scale_fill_manual(values = c(
      "Disposable Income" = T_01_02_series_vec[["band"]],
      "Consumption"       = T_01_02_series_vec[["main"]]
    )) +
    scale_y_continuous(expand = expansion(mult = c(0.05, 0.12))) +
    labs(
      title = "Household Types: Who Holds the Income, and Who Spends It",
      x = NULL,
      y = expression(bold("Income and consumption, EUR billion")),
      caption = paste0(
        "MPCs: high-MPC households ", T_02_05_num_fn(par$mpc_h),
        ", low-MPC households ", T_02_05_num_fn(par$mpc_l),
        ". Average ", T_02_05_num_fn(C_01_01_mpc_fn(par)), "."
      )
    ) +
    T_02_01_theme_fn()
}

###### D_03_03: Bridge to the Measured Multipliers #############################
# Note: This model's k against the published Irish multipliers, every bar cut
#   into the direct euro, the supply chain (Type I) and the induced round
#   (Type II minus Type I). This model's bar has no supply-chain piece.

D_03_03_bridge_fn <- function(par, measured) {
  k <- C_01_03_multiplier_fn(par)

  # One row per case; no Type II figure means the bar stops at Type I
  rows <- rbind(
    data.frame(
      label   = measured$label,
      direct  = 1,
      supply  = measured$type_i - 1,
      induced = ifelse(is.na(measured$type_ii), 0,
                       measured$type_ii - measured$type_i),
      total   = ifelse(is.na(measured$type_ii), measured$type_i,
                       measured$type_ii),
      stringsAsFactors = FALSE
    ),
    data.frame(label = "This Model, as Set", direct = 1, supply = 0,
               induced = k - 1, total = k, stringsAsFactors = FALSE)
  )
  rows <- rows[order(rows$total), ]
  rows$label <- factor(rows$label, levels = rows$label)

  parts <- c(direct = "The Direct Euro", supply = "Supply Chain (Type I)",
             induced = "Induced Round (Type II adds this)")
  long <- rbind(
    data.frame(label = rows$label, part = parts[["direct"]],
               value = rows$direct),
    data.frame(label = rows$label, part = parts[["supply"]],
               value = rows$supply),
    data.frame(label = rows$label, part = parts[["induced"]],
               value = rows$induced)
  )
  long$part <- factor(long$part, levels = unname(parts))

  # End label: the total and the induced round, which is negative when k < 1
  rows$tag <- ifelse(
    abs(rows$induced) > 1e-9,
    paste0(T_02_05_num_fn(rows$total), "   induced ",
           ifelse(rows$induced > 0, "+", "−"),
           T_02_05_num_fn(abs(rows$induced))),
    T_02_05_num_fn(rows$total)
  )
  rows$tag_at <- rows$direct + pmax(rows$supply, 0) + pmax(rows$induced, 0)

  ggplot(long, aes(x = label, y = value, fill = part)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    T_02_02_rest_fn(h = 1) +
    geom_col(width = 0.62, position = position_stack(reverse = TRUE)) +
    geom_text(data = rows, aes(x = label, y = tag_at, label = tag),
              inherit.aes = FALSE, hjust = -0.06, size = 3.9,
              colour = T_01_01_palette_vec[["navy"]]) +
    coord_flip(ylim = c(min(0, min(rows$induced)) * 1.05,
                        max(rows$tag_at) * 1.30)) +
    scale_fill_manual(values = stats::setNames(
      c(T_01_01_palette_vec[["navy"]], T_01_01_palette_vec[["light"]],
        T_01_01_palette_vec[["green"]]),
      unname(parts)
    )) +
    T_02_02_mark_y_fn(1, expression(k == 1)) +
    labs(
      title = paste0("The Induced Round: This Model's k − 1 = ",
                     T_02_05_num_fn(k - 1)),
      x = NULL,
      y = expression(bold("Output multiplier (" * k *
                            "), split into its rounds")),
      caption = paste(
        "Measured figures are output multipliers from the CSO symmetric",
        "input-output tables, as used in the input-output app. Type I is the",
        "direct euro plus the supply chain; Type II adds the induced round in",
        "green, which is the same mechanism as the rounds figure above. The",
        "tables publish a Type II figure for construction only, so it is the",
        "only measured bar with a green segment."
      )
    ) +
    T_02_01_theme_fn() +
    theme(plot.title.position = "plot", plot.caption.position = "plot")
}

################################################################################
## E: User Interface ###########################################################
################################################################################
# Note: The sidebar of controls and the page itself. Theme, CSS and the
#   builders come from the toolkit.

#### E_01: Sidebar #############################################################
# Note: Stage selector, scenario menu and story, then the controls.

###### E_01_01: Control Shorthand ##############################################
# Note: Saves passing the same three lists at every call.

E_01_01_ctl_fn <- function(id) {
  T_03_01_control_fn(id, B_03_11_controls_lst, B_03_12_help_lst,
                     B_03_01_defaults_lst)
}

###### E_01_02: Sidebar ########################################################
# Note: conditionalPanel reveals controls as the stages add layers.

E_01_02_sidebar_lst <- sidebar(
  width = 380,
  radioButtons("stage", "Stage of the Model",
               choices = B_03_03_stages_vec, selected = "1"),
  T_03_05_note_fn(paste(
    "Each stage adds one piece to the model and leaves the rest",
    "alone. Start at the top; the equations panel marks what is new.")),
  accordion(
    open = c("The Change"),
    accordion_panel(
      "The Change",
      E_01_01_ctl_fn("d_inv"),
      conditionalPanel("parseFloat(input.stage) >= 2",
                       E_01_01_ctl_fn("d_gov"),
                       E_01_01_ctl_fn("d_tax0")),
      conditionalPanel("parseFloat(input.stage) >= 4",
                       E_01_01_ctl_fn("transfer")),
      conditionalPanel("parseFloat(input.stage) == 5",
                       E_01_01_ctl_fn("budget"))
    ),
    accordion_panel(
      "Households",
      conditionalPanel("parseFloat(input.stage) < 4",
                       E_01_01_ctl_fn("mpc")),
      conditionalPanel("parseFloat(input.stage) >= 4",
                       E_01_01_ctl_fn("mpc_h"),
                       E_01_01_ctl_fn("mpc_l"),
                       E_01_01_ctl_fn("omega")),
      E_01_01_ctl_fn("c0")
    ),
    accordion_panel(
      "The Rest of the Economy",
      tags$h6("Firms"),
      E_01_01_ctl_fn("inv"),
      conditionalPanel(
        "parseFloat(input.stage) >= 2",
        tags$h6("Government"),
        E_01_01_ctl_fn("gov"),
        E_01_01_ctl_fn("tax0"),
        E_01_01_ctl_fn("tax_rate")
      ),
      conditionalPanel(
        "parseFloat(input.stage) >= 3",
        tags$h6("The Rest of the World"),
        E_01_01_ctl_fn("exp0"),
        E_01_01_ctl_fn("imp0"),
        E_01_01_ctl_fn("imp_rate")
      )
    )
  ),
  actionButton("reset", "Reset Everything",
               class = "btn-outline-secondary btn-sm w-100")
)

###### E_01_03: Worked-Example Presets #########################################
# Note: Scenario cards in the main window, filtered to the stage on screen;
#   the machinery is T_05_04 to T_05_07. The stage names already say "Stage".

E_01_03_presets_lst <- T_05_04_presets_fn(
  B_03_04_scenarios_lst, B_03_03_stages_vec, stage_word = ""
)

#### E_02: Main Panel ##########################################################
# Note: Equations, prompt, readouts, then the figures for this stage.

###### E_02_01: Reveal Styling #################################################
# Note: The only CSS this app adds to the toolkit's: the stage 6 reveal card
#   and the calibration table under it.

E_02_01_reveal_css_lst <- tags$style(HTML("
  .reveal-card { border-left: 4px solid #61B77C; }
  .reveal-lede { font-size: 1.02rem; line-height: 1.5; color: #04204C;
    margin-bottom: 0.8rem; }
  .calib-table { width: 100%; border-collapse: collapse;
    font-size: 0.84rem; margin: 0.4rem 0 0.9rem 0; }
  .calib-table th { text-align: left; color: #04204C; font-weight: 700;
    border-bottom: 2px solid #D8E0E6; padding: 0.3rem 0.5rem; }
  .calib-table td { border-bottom: 1px solid #EDF1F4;
    padding: 0.32rem 0.5rem; vertical-align: top; }
  .calib-table td.calib-val { font-weight: 700; color: #0056A4;
    white-space: nowrap; }
  .calib-wrap { overflow-x: auto; }
  .reveal-note { font-size: 0.88rem; margin-bottom: 0.5rem; }
"))

###### E_02_02: Page ###########################################################
# Note: The full UI object passed to shinyApp().

E_02_02_app_ui_lst <- tagList(
  T_07_08b_nav_fn(),
  page_sidebar(
  title        = T_07_09_title_fn("The Keynesian Multiplier",
                                  B_04_01_qr_src_chr),
  window_title = paste("The Keynesian Multiplier ·", T_07_01_author_chr),
  fillable     = FALSE,
  theme        = T_07_05_theme_fn(),
  sidebar      = E_01_02_sidebar_lst,
  T_07_08_head_fn(),
  tags$head(
    E_02_01_reveal_css_lst,
    tags$style(HTML(T_05_07_preset_css_chr)),
    tags$script(HTML(T_05_05_preset_js_chr))
  ),
  navset_card_tab(
    title = textOutput("eq_title", inline = TRUE),
    nav_panel("Equations", uiOutput("eq_model")),
    nav_panel("Notation", uiOutput("eq_notation")),
    nav_panel("In Words", uiOutput("eq_explain"))
  ),
  E_01_03_presets_lst,
  uiOutput("prompt"),
  uiOutput("problems"),
  tags$div(class = "stat-caption",
           HTML(paste("Readouts. They follow the sliders, and the",
                      "multiplier can be typed over: doing so sets the",
                      "marginal propensity to consume."))),
  uiOutput("tiles"),
  conditionalPanel(
    "parseFloat(input.stage) >= 2",
    card(
      card_header("Tax, Spending and the Budget"),
      uiOutput("fiscal")
    )
  ),
  layout_columns(
    col_widths = breakpoints(sm = 12, xl = c(6, 6)),
    T_07_07c_figcard_fn("cross", "The Keynesian Cross",
                          B_03_07_diagram_height_chr),
    T_07_07c_figcard_fn("flows", "Injections and Withdrawals",
                          B_03_07_diagram_height_chr)
  ),
  layout_columns(
    col_widths = breakpoints(sm = 12, xl = c(7, 5)),
    T_07_07c_figcard_fn("rounds", "The Spending Rounds",
                          B_03_08_rounds_height_chr),
    card(
      card_header("Where One Extra Euro of Income Goes"),
      plotOutput("euro", height = B_03_09_euro_height_chr),
      tags$div(class = "stat-caption",
               "The green share is what survives into the next round.",
               "One over the rest is the multiplier.")
    )
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 4",
    T_07_07c_figcard_fn("types", "High- and Low-MPC Households",
                          B_03_08_rounds_height_chr)
  ),
  conditionalPanel(
    "parseFloat(input.stage) == 5",
    T_07_07c_figcard_fn("packages", "Six Ways to Move the Same Money",
                          B_03_10_package_height_chr)
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 6",
    card(
      class = "reveal-card",
      card_header(B_03_20_reveal_lst$head),
      uiOutput("reveal")
    ),
    card(
      card_header("From This Model to the Measured Irish Multipliers"),
      plotOutput("bridge", height = B_03_10_package_height_chr),
      uiOutput("bridge_notes")
    )
  ),
  T_07_11_footer_fn(paste0("Version ", B_03_22_version_chr, "."),
                    repo = B_03_23_repo_chr)
))

################################################################################
## F: Server ###################################################################
################################################################################
# Note: Builds parameters for the chosen stage, solves the model, draws.

#### F_01: Server Function #####################################################
# Note: Two plain builders that return HTML, then the server itself.

###### F_01_01: Financing Note #################################################
# Note: The line under the budget-balance tile: the level says whether the
#   state is in surplus, the change whether this package is paid for.

F_01_01_finance_fn <- function(d) {
  fin  <- d$d_finance
  here <- if (d$budget >= 0) "In surplus" else "In deficit"
  said <- switch(
    fin$kind,
    none     = "No package loaded yet",
    balanced = "This package is balanced: it pays for itself",
    deficit  = paste0("This package borrows ",
                      T_02_04_eur_fn(fin$borrowing, 1)),
    surplus  = paste0("This package takes ",
                      T_02_04_eur_fn(fin$d_balance, 1), " out of the flow")
  )
  paste0(here, ". ", said)
}

###### F_01_02: The Reveal Panel ###############################################
# Note: Builds the stage 6 reveal from B_03_19 and B_03_20: the opening
#   line, the parameter table, then the caveats. Not reactive.

F_01_02_reveal_fn <- function(reveal, calib) {
  rows <- lapply(seq_len(nrow(calib)), function(i) {
    tags$tr(
      tags$td(HTML(calib$param[i])),
      tags$td(class = "calib-val", HTML(calib$value[i])),
      tags$td(HTML(calib$source[i]))
    )
  })

  tags$div(
    tags$div(class = "reveal-lede", HTML(reveal$lede)),
    tags$div(
      class = "calib-wrap",
      tags$table(
        class = "calib-table",
        tags$thead(tags$tr(tags$th("Parameter"), tags$th("Value"),
                           tags$th("Where it comes from"))),
        tags$tbody(rows)
      )
    ),
    lapply(reveal$notes, function(x) tags$p(class = "reveal-note", HTML(x)))
  )
}

###### F_01_03: Server #########################################################
# Note: Local objects are plain snake_case.

F_01_03_app_server_fn <- function(input, output, session) {

  # --- Figure captions --------------------------------------------------------
  # Captions print under the figure rather than inside the device

  T_07_07d_cap_fn(output)

  # --- Stage as a number ------------------------------------------------------
  stage_num <- reactive(as.numeric(input$stage))

  # --- Controls ---------------------------------------------------------------
  val <- function(id) T_03_04_val_fn(input, id)
  T_03_02_sync_fn(input, session, B_03_11_controls_lst)

  set_control <- function(id, value) {
    T_03_03_set_fn(session, B_03_11_controls_lst, id, value)
  }

  # --- Worked-example presets -------------------------------------------------
  # One observer per preset; the ids are stable across stages
  scenario <- reactiveVal(names(B_03_04_scenarios_lst)[[1L]])

  # Guarded lookup of the loaded scenario, NULL when none
  scn_now <- reactive({
    k <- scenario()
    if (is.null(k) || !k %in% names(B_03_04_scenarios_lst)) NULL
    else B_03_04_scenarios_lst[[k]]
  })

  set_scenario_fn <- function(key) {
    scenario(if (is.null(key)) "custom" else key)
    session$sendCustomMessage("dgPreset", if (is.null(key)) "" else key)
    invisible(NULL)
  }

  load_preset_fn <- function(key) {
    if (is.null(key) || !key %in% names(B_03_04_scenarios_lst)) {
      return(invisible(NULL))
    }
    scn  <- B_03_04_scenarios_lst[[key]]
    set_scenario_fn(key)
    vals <- utils::modifyList(B_03_01_defaults_lst, scn$values)
    for (id in names(B_03_11_controls_lst)) set_control(id, vals[[id]])
    invisible(NULL)
  }

  lapply(names(B_03_04_scenarios_lst), function(key) {
    observeEvent(input[[paste0("preset_", key)]],
                 load_preset_fn(key), ignoreInit = TRUE)
  })

  # First scenario of a stage, or NULL
  first_preset_fn <- function(stage) {
    hits <- names(B_03_04_scenarios_lst)[vapply(
      B_03_04_scenarios_lst, function(x) identical(x$stage, stage), TRUE)]
    if (length(hits) == 0L) NULL else hits[[1L]]
  }

  # Every stage opens on its first worked example
  observeEvent(input$stage, {
    first <- first_preset_fn(input$stage)
    if (!is.null(first)) {
      load_preset_fn(first)
      return()
    }
    set_scenario_fn(NULL)
  })

  output$preset_title <- renderUI({
    T_05_06_preset_title_fn(scn_now(), input$stage, B_03_03_stages_vec,
                            stage_word = "")
  })

  # --- Reset ------------------------------------------------------------------
  observeEvent(input$reset, {
    for (id in names(B_03_11_controls_lst)) {
      set_control(id, B_03_01_defaults_lst[[id]])
    }
    set_scenario_fn(NULL)
  })

  # --- Parameters in force at this stage --------------------------------------
  # Hidden controls are switched off by the stage gates. A pure function of
  # values and stage, so it also runs over the worked example for the ghost
  assemble_fn <- function(v, s) {
    two_type <- s >= 4
    open_ec  <- s >= 3
    list(
      c0       = v$c0,
      mpc_h    = if (two_type) v$mpc_h else v$mpc,
      mpc_l    = if (two_type) v$mpc_l else v$mpc,
      omega    = if (two_type) v$omega else 1,
      inv      = v$inv,
      gov      = if (s >= 2) v$gov else 0,
      tax0     = if (s >= 2) v$tax0 else 0,
      tax_rate = if (s >= 2) v$tax_rate else 0,
      exp0     = if (open_ec) v$exp0 else 0,
      imp0     = if (open_ec) v$imp0 else 0,
      imp_rate = if (open_ec) v$imp_rate else 0,
      d_inv    = v$d_inv,
      d_gov    = if (s >= 2) v$d_gov else 0,
      d_tax0   = if (s >= 2) v$d_tax0 else 0,
      transfer = if (two_type) v$transfer else 0,
      budget   = v$budget
    )
  }

  par_raw <- reactive({
    req(!is.null(input$mpc))
    vals <- stats::setNames(lapply(names(B_03_01_defaults_lst), val),
                            names(B_03_01_defaults_lst))
    # A box not yet drawn reads NULL; the default stands in
    vals <- utils::modifyList(B_03_01_defaults_lst,
                              vals[!vapply(vals, is.null, TRUE)])
    assemble_fn(vals, stage_num())
  })

  par_now  <- debounce(par_raw, B_03_18_debounce_ms_int)
  diag_now <- reactive(C_01_11_diagnostics_fn(par_now()))
  ok_now   <- reactive(length(diag_now()$problems) == 0)

  # --- The ghost: the figure at the worked example's own settings -------------
  # The reference is the loaded example's values, else the defaults
  ref_vals <- reactive({
    key <- scenario()
    if (is.null(key) || !key %in% names(B_03_04_scenarios_lst)) {
      return(B_03_01_defaults_lst)
    }
    utils::modifyList(B_03_01_defaults_lst,
                      B_03_04_scenarios_lst[[key]]$values)
  })

  # Same assembler as the live run
  ref_par <- reactive(assemble_fn(ref_vals(), stage_num()))

  # NULL when the reference matches the sliders or does not solve
  ghost_par <- reactive({
    ref <- ref_par()
    if (T_02_03b_ghost_off_fn(par_now(), ref)) return(NULL)
    if (length(C_01_12_problems_fn(ref)) > 0) return(NULL)
    ref
  })

  # --- Scenario story ---------------------------------------------------------
  output$scenario_story <- renderUI({
    T_05_02_story_fn(scn_now(), B_03_11_controls_lst, B_03_12_help_lst)
  })

  # --- The model so far: equations, notation and explanations tabs -----------
  output$eq_title <- renderText({
    T_05_04_stage_name_fn(B_03_03_stages_vec, input$stage)
  })

  eq_items <- reactive({
    T_06_03_items_fn(B_03_14_equations_lst, stage_num())
  })

  output$eq_model <- renderUI({
    T_06_04_model_fn(eq_items(), B_03_15_groups_vec,
                     "These appear as the later stages add to the model.")
  })

  output$eq_notation <- renderUI({
    T_06_05_notation_fn(B_03_16_notation_lst, stage_num(),
                        B_03_17_nota_cols_lst, first_stage = 1)
  })

  output$eq_explain <- renderUI({
    T_06_06_explain_fn(eq_items(), B_03_15_groups_vec)
  })

  # --- Prompt and problems ----------------------------------------------------
  output$prompt <- renderUI({
    T_07_12_prompt_fn(scn_now(), input$stage, B_03_13_prompts_lst)
  })

  output$problems <- renderUI(T_07_13_problems_fn(diag_now()$problems))

  # --- Readouts ---------------------------------------------------------------
  # Typing over k sets the MPC; ro_pushed marks the server's own updates
  ro_pushed <- new.env()

  output$tiles <- renderUI({
    d <- diag_now()
    s <- stage_num()
    T_04_03_row_fn(
      T_04_02_typed_fn("ro_k", "The multiplier, k", d$multiplier,
                       "Type a value to set the MPC"),
      T_04_01_tile_fn("Equilibrium output, Y*", T_02_04_eur_fn(d$y_new),
                      paste0("Before the change: ",
                             T_02_04_eur_fn(d$y_base))),
      T_04_01_tile_fn(
        "Change in output, ΔY", T_02_04_eur_fn(d$d_y, 1),
        paste0("From ΔA = ", T_02_04_eur_fn(d$d_a, 1)),
        class = if (d$d_y >= 0) "good" else "bad"
      ),
      T_04_01_tile_fn(
        "Leakage per euro", paste0(round((1 - 1 / d$multiplier) * 100), "c"),
        if (s >= 3) "Saving, tax and imports" else
          if (s >= 2) "Saving and tax" else "Saving alone"
      ),
      if (s >= 2) {
        T_04_01_tile_fn(
          "Budget balance, T &minus; G", T_02_04_eur_fn(d$budget, 1),
          F_01_01_finance_fn(d),
          class = if (d$d_finance$kind == "deficit") "bad" else
            if (d$d_finance$kind == "none") "" else "good"
        )
      },
      if (s >= 2) {
        T_04_01_tile_fn(
          "Change in the balance, &Delta;B",
          T_02_04_eur_fn(d$d_budget, 1),
          paste0("&Delta;T = ", T_02_04_eur_fn(d$d_tax, 1),
                 " against &Delta;G = ", T_02_04_eur_fn(d$d_gov, 1)),
          class = if (d$d_budget >= -1e-9) "good" else "bad"
        )
      },
      if (s >= 3) {
        T_04_01_tile_fn(
          "Trade balance", T_02_04_eur_fn(d$trade, 1),
          if (d$trade >= 0) "Surplus" else "Deficit",
          class = if (d$trade >= 0) "good" else "bad"
        )
      },
      if (s >= 4) {
        T_04_01_tile_fn("Average MPC, c&#772;", T_02_05_num_fn(d$cbar),
                        "Income-weighted across the two types")
      }
    )
  })

  observe({
    k <- diag_now()$multiplier
    if (!is.finite(k)) return()
    ro_pushed$ro_k <- utils::tail(c(ro_pushed$ro_k, round(k, 3)), 3)
    updateNumericInput(session, "ro_k", value = round(k, 3))
  })

  observeEvent(input$ro_k, {
    k <- input$ro_k
    if (is.null(k) || is.na(k) || k <= 0) return()
    if (any(abs(c(ro_pushed$ro_k, Inf) - k) < 1e-6)) return()
    p <- par_now()
    q <- 1 - 1 / k
    c_new <- (q + p$imp_rate) / (1 - p$tax_rate)
    if (!is.finite(c_new)) return()
    if (stage_num() >= 4) {
      # Move both types together, keeping the gap between them
      gap <- p$mpc_h - p$mpc_l
      set_control("mpc_l", min(max(c_new - p$omega * gap, 0), 0.95))
      set_control("mpc_h", min(max(c_new + (1 - p$omega) * gap, 0.05), 1))
    } else {
      set_control("mpc", min(max(c_new, 0), 0.95))
    }
  }, ignoreInit = TRUE)

  # --- Figures ----------------------------------------------------------------
  output$cross <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_01_01_cross_fn(par_now(), ref = ghost_par())
  }) })

  output$flows <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_01_02_flows_fn(par_now(), ref = ghost_par())
  }) })

  output$rounds <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_02_01_rounds_fn(par_now(), B_03_02_n_rounds_int, ref = ghost_par())
  }) })

  output$euro <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_02_02_euro_fn(par_now())
  }) })

  output$types <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 4)
    D_03_02_types_fn(par_now())
  }) })

  output$packages <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() == 5)
    D_03_01_package_fn(par_now(), par_now()$budget)
  }) })

  output$bridge <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 6)
    D_03_03_bridge_fn(par_now(), B_03_05_measured_df)
  }) })

  output$bridge_notes <- renderUI({
    req(stage_num() >= 6)
    tags$div(class = "narrative",
             tags$div(class = "nar-head", "What the Gap Is"),
             lapply(B_03_06_bridge_lst, function(x) tags$p(HTML(x))))
  })

  # --- Fiscal mechanics and the reveal ----------------------------------------
  output$fiscal <- renderUI({
    req(stage_num() >= 2)
    tags$div(lapply(B_03_21_fiscal_lst,
                    function(x) tags$p(class = "reveal-note", HTML(x))))
  })

  output$reveal <- renderUI({
    req(stage_num() >= 6)
    F_01_02_reveal_fn(B_03_20_reveal_lst, B_03_19_calib_df)
  })
}

################################################################################
## G: Run ######################################################################
################################################################################
# Note: Launch.

#### G_01: Launch ##############################################################
# Note: Returns the app object.

###### G_01_01: The App ########################################################
# Note: UI from E, server from F.

G_01_01_app_lst <- shinyApp(E_02_02_app_ui_lst, F_01_03_app_server_fn)

G_01_01_app_lst
