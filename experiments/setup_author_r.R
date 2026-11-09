# Installs declared Imports, then the ORIGINAL upstream scoth package.
# Run from the project root; runtime and library stay project-local.
options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 600)
args = commandArgs(trailingOnly = TRUE)
lib = normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
.libPaths(c(lib, .libPaths()))
description = read.dcf("upstream/scoth-segmentation/DESCRIPTION")
deps = trimws(strsplit(description[1, "Imports"], ",")[[1]])
deps = sub("[[:space:]]*\\(.*\\)", "", deps)
missing = setdiff(deps, rownames(installed.packages()))
if (length(missing)) install.packages(missing, lib = lib, type = "binary")
stopifnot(all(deps %in% rownames(installed.packages())))
install.packages("upstream/scoth-segmentation", repos = NULL, type = "source", lib = lib)
library(scoth)
dir.create("results/upstream_r", recursive = TRUE, showWarnings = FALSE)
capture.output(sessionInfo(), file = "results/upstream_r/setup_sessionInfo.txt")
write.csv(as.data.frame(installed.packages()[, c("Package", "Version", "LibPath")]),
          "results/upstream_r/installed_packages.csv", row.names = FALSE)
cat("AUTHOR_PACKAGE_INSTALLED\n")
