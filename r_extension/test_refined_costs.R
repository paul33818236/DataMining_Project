library(scoth)
library(dplyr)
library(testthat)
source("r_extension/refined_costs.R")
test_that("isolated impulse repair protects short plateaus and unchanged signals", {
  set.seed(15)
  x = rnorm(300, sd = .2)
  x[100:102] = x[100:102]+4
  expect_equal(repair_isolated_impulses(x, 4)[100:102], x[100:102])
  spike = x; spike[200] = spike[200]+20
  repaired = repair_isolated_impulses(spike, 4)
  expect_equal(repaired[200], (spike[199]+spike[201])/2)
  expect_equal(repair_isolated_impulses(rep(3, 100)), rep(3, 100))
  linear = seq_len(100)*4
  expect_equal(repair_isolated_impulses(linear), linear)
  integer_series = as.integer(c(rep(10000000, 20), 200000000, rep(10000000, 20)))
  expect_equal(repair_isolated_impulses(integer_series),
               repair_isolated_impulses(as.numeric(integer_series)))
  expect_true(all(is.finite(repair_isolated_impulses(integer_series))))
})
