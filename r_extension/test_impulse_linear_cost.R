library(scoth)
library(dplyr)
library(testthat)
source("r_extension/impulse_linear_cost.R")
test_that("cost-interface implementation exactly matches validated preprocessing pipeline", {
  data = load_kpis("upstream/scoth-segmentation/public-data")
  for (name in c("well_log", "apple")) {
    frame = data$kpis[[which(data$dataset_name == name)]]
    x = if (ncol(frame) == 1) frame[,1] else frame
    cost = make_impulse_linear_cost(x, 4)
    z = attr(cost, "repaired_series")
    original = if (is.data.frame(x)) scoth:::c_reg_cusum_L2_multivariate else scoth:::c_reg_cusum_L2
    a = scoth_scoring_func(x, cost, FALSE)
    b = scoth_scoring_func(z, original, FALSE)
    expect_equal(a, b, tolerance = 0)
    first = scoth_recursive_partitions(.09, 10, a$changepoint_gain, a$cost_initial, x, cost)
    second = scoth_recursive_partitions(.09, 10, b$changepoint_gain, b$cost_initial, z, original)
    expect_equal(first$partitions, second$partitions, tolerance = 0)
  }
})
