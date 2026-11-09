library(scoth)
library(dplyr)
library(testthat)
source("r_extension/impulse_linear_cost.R")
source("r_extension/cached_cost.R")
test_that("memoization preserves original R scores and selected levels exactly", {
  set.seed(32)
  x = c(rnorm(20), rnorm(20, 4), 30, rnorm(20, 4))
  for (cost in list(scoth:::c_reg_cusum_L2, make_impulse_linear_cost(x, 4))) {
    cached = cache_segment_cost(x, cost)
    a = scoth_scoring_func(x, cost, FALSE)
    b = scoth_scoring_func(x, cached, FALSE)
    expect_equal(a, b, tolerance = 0)
    l1 = scoth_recursive_partitions(.1, 10, a$changepoint_gain, a$cost_initial, x, cost)
    l2 = scoth_recursive_partitions(.1, 10, b$changepoint_gain, b$cost_initial, x, cached)
    expect_equal(l1$partitions, l2$partitions, tolerance = 0)
  }
})
