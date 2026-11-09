library(scoth)
library(dplyr)
library(testthat)
source("r_extension/delayed_thresholds.R")
set.seed(315)
x=c(rnorm(40),rnorm(40,4),rnorm(40))
cost=scoth:::c_reg_cusum_L2
scored=scoth_scoring_func(x,cost,FALSE)
test_that("release at level 1 exactly recovers the author's Algorithm 2",{
  original=scoth_recursive_partitions(.05,10,scored$changepoint_gain,scored$cost_initial,x,cost)
  delayed=scoth_delayed_partitions(.05,10,scored$changepoint_gain,scored$cost_initial,x,cost,1)
  expect_equal(original,delayed,tolerance=0)
})
test_that("release schedules preserve every previously selected cut",{
  for (release in c(2L,3L)) {
    result=scoth_delayed_partitions(.05,10,scored$changepoint_gain,scored$cost_initial,x,cost,release)
    for (i in 2:10) expect_true(all(result$partitions[[i-1]]$s %in% result$partitions[[i]]$s))
  }
})
test_that("empty predictions are represented without invalid empty intervals",{
  result=scoth_delayed_partitions(1,10,scored$changepoint_gain,scored$cost_initial,x,cost,2)
  expect_true(all(vapply(result$partitions,nrow,0L)==1L))
})
