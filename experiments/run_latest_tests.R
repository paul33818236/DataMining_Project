library(scoth)
library(dplyr)
library(testthat)
files=c("test_refined_costs.R","test_score_refinements.R","test_delayed_thresholds.R",
        "test_cached_cost.R","test_impulse_linear_cost.R")
for (file in files) {
  cat(paste0("TEST_FILE ",file,"\n"))
  source(file.path("r_extension",file))
}
cat("LATEST_TESTS_PASSED\n")
