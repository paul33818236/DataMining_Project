# Delayed3: Hierarchical Changepoint Detection with Isolated-Spike Repair

This repository contains the latest Delayed3 implementation, tests, and experimental results. The GitHub version excludes the original authors' source code, raw datasets, and local R runtime. Download these dependencies separately before running the experiments. Existing local copies are retained.

Delayed3 combines isolated-spike repair (`k = 4`), the authors' linear cost, candidate-score suppression, and candidate release starting at level 3. The main comparison uses a threshold of `0.09` and produces 10 nonzero levels.

For a detailed explanation, see [Original Method vs. Delayed3](原方法與改良方法差異說明.md).

## Running the Experiments

### First Setup After Downloading from GitHub

Install Git and R. R 4.6.2 was used for the recorded experiments. From the project root, download the authors' code and datasets and check out the version used in this study:

```powershell
git clone https://github.com/ahstat/scoth-segmentation.git upstream/scoth-segmentation
git -C upstream/scoth-segmentation checkout 0eecacf1ae892b6cf9c2c3b45f965fe50c4fba5c
New-Item -ItemType Directory -Force .runtime/r-library
```

Install R at `.runtime/R-4.6.2` to use the provided PowerShell wrappers. Alternatively, use the `Rscript` executable from your existing R installation for the direct commands below. Set the package library, then install the authors' package and the additional packages required for the experiments:

```powershell
$env:R_LIBS_USER = (Resolve-Path .runtime/r-library).Path
Rscript --vanilla experiments/setup_author_r.R .runtime/r-library
Rscript --vanilla -e 'install.packages(c("testthat", "jsonlite"), repos="https://cloud.r-project.org")'
Rscript --vanilla experiments/run_latest_tests.R
Rscript --vanilla experiments/run_latest_r.R
```

Run direct `Rscript` commands from the project root. On Windows, if R reports an invalid locale, set `LC_ALL` and `LC_CTYPE` to `English_United States.utf8` and `LANG` to `en_US.UTF-8` before starting R.

The GitHub version includes derived tables and figures but excludes `.RDS` files containing copies of the original series. The first run recomputes and generates these local files. Reproducing the baseline comparison and full audit requires running the authors' baseline separately or using baseline outputs already retained locally.

### Using the Existing Local Environment

From the project root, run:

```powershell
powershell -File experiments/run_latest.ps1
```

To recompute and check predictions against existing saved cases:

```powershell
powershell -File experiments/run_latest.ps1 -Verify
```

## Project Files

| Path | Purpose |
|---|---|
| `r_extension/` | Five core modules, five test files, and module documentation |
| `experiments/run_latest_r.R` | Full experiment on all 42 datasets |
| `experiments/run_latest_tests.R` | Test entry point for the latest method |
| `experiments/validate_latest_r.R` | Synthetic-data comparison with the original method |
| `experiments/compare_latest_author_r.R` | Generate baseline-versus-Delayed3 comparison data |
| `experiments/time_author_latest_r.R` | Runtime comparison |
| `experiments/build_author_latest_tables.py` | Generate the comprehensive comparison tables |
| `experiments/audit_latest.py` | Check implementation hashes and upstream source integrity |
| `experiments/data_folds.csv` | Fixed dataset grouping for cross-validation |
| `experiments/setup_author_r.R`, `experiments/run_author_r.ps1` | Set up and run the authors' original R implementation |
| `results/latest_r/` | Latest metrics, configuration, verification, and synthetic-test results; local runs also save predictions |
| `results/author_vs_latest_r/` | Comparison tables, figures, and timing results |
| `results/upstream_r/` | Selected baseline summaries and source-integrity records; additional execution records are retained locally |

## Results and Interpretation

Across 42 datasets, mean F1 is **0.7556** for the original linear method and **0.7913** for Delayed3. Both methods produce 62 false positives in total; false negatives decrease from 19 to 14.

The main comparison uses ground-truth labels to select the best level for each dataset. These are descriptive results, not estimates of performance with label-free level selection or on unseen external data. The source-group bootstrap 95% interval for the mean F1 difference is `[-0.0069, 0.0805]`, which includes zero; a consistent statistically significant improvement has not been established.

See the [method comparison](原方法與改良方法差異說明.md) for the English explanation and limitations, and the [comprehensive comparison tables](results/author_vs_latest_r/comparison_tables.md) for all dataset-level results. The existing detailed tables and chart labels are in Traditional Chinese.
