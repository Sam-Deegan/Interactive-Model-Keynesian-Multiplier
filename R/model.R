################################################################################
## Project: ECON42550 Macroeconomics                                          ##
## The Keynesian Multiplier: Model                                            ##
################################################################################

## Author:      Sam Deegan
## Affiliation: University College Dublin
## Email:       sam.deegan@ucdconnect.ie

## Usage:
##   Sourced automatically by app.R. Can be sourced alone from a lecture
##   .qmd so slide figures come from the same model:
##     source("R/model.R")
##
## Inputs:
##   None. Every function is a pure function of a parameter list "par"
##   built by the app.
##
## Outputs:
##   C_01_* functions: propensities, the multiplier, the equilibrium, the
##   two diagrams' schedules, the rounds, the packages and the readouts.
##
## The model (Keynesian cross with a government and an import leakage):
##   C   = c0 + cbar (Y - T) + (c_h - c_l) tau        consumption
##   T   = T0 + t Y                                    taxes
##   M   = m0 + m Y                                    imports
##   Y   = C + I + G + X - M                           goods market clears
##
##   cbar = omega c_h + (1 - omega) c_l   the aggregate marginal propensity
##                                        to consume: the income-weighted
##                                        average across the two types.
##   tau  is a budget-neutral transfer from low- to high-MPC households.
##
##   Solving: Y = k A, with
##     k = 1 / (1 - cbar (1 - t) + m)
##     A = c0 - cbar T0 + (c_h - c_l) tau + I + G + X - m0
##
##   Switching features off recovers each stage's model: t = m = 0 and
##   omega = 1 give the textbook cross with k = 1 / (1 - c); m = 0 gives
##   the closed economy with a government; omega = 1 gives one household
##   type, so tau does nothing.
##
## Parameter list (par) elements:
##   c0, mpc_h, mpc_l, omega, inv, gov, tax0, tax_rate, exp0, imp0,
##   imp_rate, d_inv, d_gov, d_tax0, transfer, budget
##
## References:
##   Keynes, J. M. (1936). The General Theory of Employment, Interest and
##     Money. Ch. 10 (the marginal propensity to consume and the multiplier).
##   Blanchard, O. (2021). Macroeconomics, 8th ed. Ch. 3 (the goods market).
##   CSO. Supply and Use and Input-Output Tables for Ireland 2022, for the
##     Type I and Type II multipliers the app compares itself with.

#-------------------------------- Script Begin --------------------------------#

################################################################################
## A: Table of Contents ########################################################
################################################################################
# Note: C_01 holds the model; app.R holds sections B, D, E, F and G.
#
#   C: Model
#     C_01_01  Aggregate propensity to consume
#     C_01_02  Where one extra euro of income goes
#     C_01_03  The multiplier
#     C_01_04  Autonomous spending
#     C_01_05  Equilibrium output and its components
#     C_01_06  Planned expenditure line
#     C_01_07  Injections and withdrawals
#     C_01_08  Spending rounds
#     C_01_09  Policies of equal cost
#     C_01_10  Consumption by household type
#     C_01_11  Readouts
#     C_01_12  Problems with the calibration
#     C_01_13  How the package is financed

################################################################################
## C: Model ####################################################################
################################################################################
# Note: Pure functions. Nothing here touches Shiny.

#### C_01: Solving the Model ###################################################
# Note: Propensities, the multiplier, the equilibrium, and the rounds.
#   Amounts are in euro billion; propensities are shares of a euro.

###### C_01_01: Aggregate Propensity to Consume ################################
# Note: Income-weighted average MPC across the two consumer types. Before
#   lecture stage 4 there is one type, so omega = 1 and this returns mpc_h.

C_01_01_mpc_fn <- function(par) {
  par$omega * par$mpc_h + (1 - par$omega) * par$mpc_l
}

###### C_01_02: Marginal Euro ##################################################
# Note: Where one extra euro of income goes: tax t, saving (1 - t)(1 - cbar),
#   imports m, and the rest passed on as the next round's income.

C_01_02_leak_fn <- function(par) {
  cbar <- C_01_01_mpc_fn(par)
  tax  <- par$tax_rate
  save <- (1 - tax) * (1 - cbar)
  imp  <- par$imp_rate
  list(
    tax     = tax,
    save    = save,
    imports = imp,
    pass_on = cbar * (1 - tax) - imp,
    cbar    = cbar
  )
}

###### C_01_03: The Multiplier #################################################
# Note: k = 1 / (1 - cbar (1 - t) + m): one over the share of a euro that
#   leaks out. Keynes (1936) ch. 10 with t = m = 0; Blanchard ch. 3 with t.

C_01_03_multiplier_fn <- function(par) {
  leak <- C_01_02_leak_fn(par)
  1 / (1 - leak$pass_on)
}

###### C_01_04: Autonomous Spending ############################################
# Note: Everything that does not depend on income. "delta" adds the policy
#   change on top of the baseline, so the same function serves both runs.

C_01_04_autonomous_fn <- function(par, delta = TRUE) {
  cbar <- C_01_01_mpc_fn(par)
  base <- par$c0 - cbar * par$tax0 + par$inv + par$gov + par$exp0 - par$imp0
  if (!delta) return(base)
  base + par$d_inv + par$d_gov - cbar * par$d_tax0 +
    (par$mpc_h - par$mpc_l) * par$transfer
}

###### C_01_05: Equilibrium ####################################################
# Note: Output and its components, for one run of the model. "delta = FALSE"
#   gives the baseline before the policy change.

C_01_05_equilibrium_fn <- function(par, delta = TRUE) {
  cbar <- C_01_01_mpc_fn(par)
  k    <- C_01_03_multiplier_fn(par)
  a    <- C_01_04_autonomous_fn(par, delta = delta)
  y    <- k * a

  gov <- par$gov + if (delta) par$d_gov else 0
  inv <- par$inv + if (delta) par$d_inv else 0
  tx0 <- par$tax0 + if (delta) par$d_tax0 else 0
  tau <- if (delta) par$transfer else 0

  tax <- tx0 + par$tax_rate * y
  imp <- par$imp0 + par$imp_rate * y
  con <- par$c0 + cbar * (y - tax) + (par$mpc_h - par$mpc_l) * tau
  sav <- (y - tax) - con

  list(
    y          = y,
    autonomous = a,
    multiplier = k,
    cbar       = cbar,
    consume    = con,
    save       = sav,
    tax        = tax,
    imports    = imp,
    invest     = inv,
    govt       = gov,
    exports    = par$exp0,
    budget     = tax - gov,
    trade      = par$exp0 - imp
  )
}

###### C_01_06: Planned Expenditure Line #######################################
# Note: Planned expenditure at each level of income: the AE line of the
#   Keynesian cross. The E = Y line is the identity.

C_01_06_ae_line_fn <- function(par, y_grid, delta = TRUE) {
  cbar <- C_01_01_mpc_fn(par)
  a    <- C_01_04_autonomous_fn(par, delta = delta)
  data.frame(y = y_grid, ae = a + (cbar * (1 - par$tax_rate) -
                                     par$imp_rate) * y_grid)
}

###### C_01_07: Injections and Withdrawals #####################################
# Note: The other way to draw equilibrium. Withdrawals S + T + M rise with
#   income; injections I + G + X do not. They cross where the cross does.

C_01_07_flows_fn <- function(par, y_grid, delta = TRUE) {
  cbar <- C_01_01_mpc_fn(par)
  tx0  <- par$tax0 + if (delta) par$d_tax0 else 0
  gov  <- par$gov + if (delta) par$d_gov else 0
  inv  <- par$inv + if (delta) par$d_inv else 0
  tau  <- if (delta) par$transfer else 0

  tax <- tx0 + par$tax_rate * y_grid
  con <- par$c0 + cbar * (y_grid - tax) + (par$mpc_h - par$mpc_l) * tau
  data.frame(
    y           = y_grid,
    withdrawals = ((y_grid - tax) - con) + tax + par$imp0 +
                    par$imp_rate * y_grid,
    injections  = inv + gov + par$exp0
  )
}

###### C_01_08: Spending Rounds ################################################
# Note: The multiplier as a geometric series. Round 1 is the injection;
#   each round after it is the last times the share passed on.

C_01_08_rounds_fn <- function(par, n_rounds) {
  leak <- C_01_02_leak_fn(par)
  cbar <- leak$cbar
  shock <- par$d_inv + par$d_gov - cbar * par$d_tax0 +
    (par$mpc_h - par$mpc_l) * par$transfer

  q     <- leak$pass_on
  round <- seq_len(n_rounds)
  spend <- shock * q^(round - 1)

  data.frame(
    round      = round,
    spend      = spend,
    cumulative = cumsum(spend),
    leaked     = cumsum(spend) * (1 - q) / q * q,
    total      = if (abs(1 - q) < 1e-12) NA_real_ else shock / (1 - q)
  )
}

###### C_01_09: Policies of Equal Cost #########################################
# Note: What one euro of budget buys, by instrument. The redistribution costs
#   the Exchequer nothing, which is the point of the last row.

C_01_09_policies_fn <- function(par, budget) {
  cbar <- C_01_01_mpc_fn(par)
  k    <- C_01_03_multiplier_fn(par)

  data.frame(
    policy = c("Government Spending", "Transfer to All Households",
               "Transfer to High-MPC Households", "Cut in Lump-Sum Taxes",
               "Balanced Budget (Spend and Tax)",
               "Redistribution to High-MPC Households"),
    effect = c(k, cbar * k, par$mpc_h * k, cbar * k, (1 - cbar) * k,
               (par$mpc_h - par$mpc_l) * k) * budget,
    cost   = c(budget, budget, budget, budget, 0, 0),
    stringsAsFactors = FALSE
  )
}

###### C_01_10: Consumption by Type ############################################
# Note: Splits consumption between the two types, so the class can see which
#   households the extra spending actually comes from.

C_01_10_types_fn <- function(par, eq) {
  yd  <- eq$y - eq$tax
  tau <- par$transfer

  data.frame(
    type    = c("High-MPC Households", "Low-MPC Households"),
    share   = c(par$omega, 1 - par$omega),
    mpc     = c(par$mpc_h, par$mpc_l),
    income  = c(par$omega * yd + tau, (1 - par$omega) * yd - tau),
    consume = c(par$mpc_h * (par$omega * yd + tau),
                par$mpc_l * ((1 - par$omega) * yd - tau)),
    stringsAsFactors = FALSE
  )
}

###### C_01_11: Readouts #######################################################
# Note: The numbers in the tiles above the figures. Budget entries are the
#   level of T - G and the change the package causes, which includes t dY.

C_01_11_diagnostics_fn <- function(par) {
  leak <- C_01_02_leak_fn(par)
  base <- C_01_05_equilibrium_fn(par, delta = FALSE)
  new  <- C_01_05_equilibrium_fn(par, delta = TRUE)

  list(
    multiplier  = new$multiplier,
    cbar        = leak$cbar,
    leakage     = 1 - leak$pass_on,
    y_base      = base$y,
    y_new       = new$y,
    d_y         = new$y - base$y,
    d_a         = new$autonomous - base$autonomous,
    budget      = new$budget,
    budget_base = base$budget,
    d_budget    = new$budget - base$budget,
    d_tax       = new$tax - base$tax,
    d_gov       = new$govt - base$govt,
    d_finance   = C_01_13_finance_fn(par, base, new),
    trade       = new$trade,
    gov_mult    = new$multiplier,
    tax_mult    = -leak$cbar * new$multiplier,
    bb_mult     = (1 - leak$cbar) * new$multiplier,
    problems    = C_01_12_problems_fn(par)
  )
}

###### C_01_12: Problems with the Calibration ##################################
# Note: Warnings shown above the figures when the numbers stop making sense.

C_01_12_problems_fn <- function(par) {
  leak <- C_01_02_leak_fn(par)
  out  <- character(0)

  if (leak$pass_on <= 0) {
    out <- c(out, paste(
      "Nothing is passed on: leakages take the whole of every extra euro,",
      "so the multiplier is one or less and there are no further rounds.",
      "Lower the import share or the tax rate."
    ))
  }
  if (leak$pass_on >= 1) {
    out <- c(out, paste(
      "More than a euro is passed on from each euro of income, so the",
      "rounds never die out and the multiplier is infinite. Lower the",
      "marginal propensity to consume."
    ))
  }
  if (C_01_05_equilibrium_fn(par)$y <= 0) {
    out <- c(out, paste(
      "Equilibrium output is zero or negative. Autonomous spending has been",
      "cut too far."
    ))
  }
  out
}

###### C_01_13: How the Package Is Financed ####################################
# Note: Classes the package by the change in T - G, not the instruments.
#   "none" is no policy change at all. tol is in euro billion.

C_01_13_finance_fn <- function(par, base, new, tol = 0.05) {
  d_bal <- new$budget - base$budget
  moved <- any(abs(c(par$d_gov, par$d_tax0, par$d_inv, par$transfer)) > 1e-9)

  kind <- if (!moved) {
    "none"
  } else if (abs(d_bal) <= tol) {
    "balanced"
  } else if (d_bal < 0) {
    "deficit"
  } else {
    "surplus"
  }

  list(kind = kind, d_balance = d_bal, borrowing = max(-d_bal, 0))
}
