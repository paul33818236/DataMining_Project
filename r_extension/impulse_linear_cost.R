# Equivalent cost-interface form of the validated repair + linear pipeline.
# Repair is fixed once for the whole offline series, not recomputed per segment.
source("r_extension/refined_costs.R")
make_impulse_linear_cost = function(x, k = 4) {
  original = x
  repaired = repair_isolated_impulses(x, k = k)
  original_linear = if (is.data.frame(x)) scoth:::c_reg_cusum_L2_multivariate else scoth:::c_reg_cusum_L2
  cost = function(x, s = 1, e = if (is.data.frame(x)) nrow(x)+1 else length(x)+1) {
    stopifnot(identical(x, original))
    original_linear(repaired, s, e)
  }
  attr(cost, "repaired_series") = repaired
  cost
}
