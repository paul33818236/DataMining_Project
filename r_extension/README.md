# 最新版 R 擴充：Delayed3

| 檔案 | 功能 |
|---|---|
| refined_costs.R | 估計噪音並修復孤立尖峰 |
| impulse_linear_cost.R | 將修復後序列交給作者的線性成本函數 |
| score_refinements.R | 抑制距離過近的候選分數 |
| delayed_thresholds.R | 前兩層抑制近鄰候選，第 3 層開始釋放，保持階層切點包含關係 |
| cached_cost.R | 快取相同區間的成本，減少重複計算 |
| test_*.R | 對應上述五個模組的測試 |

最新版參數：k = 4、release_level = 3、min_distance = 3、10 個層級，主要比較門檻為 0.09。

請透過 experiments/run_latest.ps1 執行。測試入口為 experiments/run_latest_tests.R。執行需要專案 .runtime 中的 R 與套件，以及 upstream/scoth-segmentation 中保留的作者原始碼。
