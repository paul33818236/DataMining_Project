# Delayed3：抗孤立尖峰的階層式變化點偵測

本專案只保留最新版 Delayed3 的程式、測試與結果。GitHub 上傳版不包含作者原始碼、原始資料及本機 R 環境；執行時需另外下載依賴。本機已有的作者原始碼與環境仍保留。

方法使用孤立尖峰修復（k = 4）、作者的線性成本、候選分數抑制，以及第 3 層釋放候選。主要比較門檻為 0.09，產生 10 個層級。

## 執行

### 首次取得 GitHub 版本

先安裝 Git 與 R。為對齊本次實驗，可使用 R 4.6.2。從專案根目錄另外取得作者程式與資料，固定在本次實驗的版本：

```powershell
git clone https://github.com/ahstat/scoth-segmentation.git upstream/scoth-segmentation
git -C upstream/scoth-segmentation checkout 0eecacf1ae892b6cf9c2c3b45f965fe50c4fba5c
New-Item -ItemType Directory -Force .runtime/r-library
```

將 R 安裝在 `.runtime/R-4.6.2`，或在下列直接執行指令中使用已安裝 R 的 `Rscript` 路徑。設定套件目錄後，安裝作者套件與實驗所需套件：

```powershell
$env:R_LIBS_USER = (Resolve-Path .runtime/r-library).Path
Rscript --vanilla experiments/setup_author_r.R .runtime/r-library
Rscript --vanilla -e 'install.packages(c("testthat", "jsonlite"), repos="https://cloud.r-project.org")'
Rscript --vanilla experiments/run_latest_tests.R
Rscript --vanilla experiments/run_latest_r.R
```

直接使用 `Rscript` 執行時請在專案根目錄操作。Windows 若遇到無效 locale，可先將 `LC_ALL`、`LC_CTYPE` 設為 `English_United States.utf8`，`LANG` 設為 `en_US.UTF-8`，再啟動 R。

上傳版只保留衍生表格與圖表，不含保存原始序列的 `.RDS`。首次執行會重新計算並產生這些本機檔案。原方法比較與完整稽核需要另行執行作者基準，或使用本機已保留的基準結果。

### 已有本機環境

在專案根目錄執行：

```powershell
powershell -File experiments/run_latest.ps1
```

重新計算並核對既有預測：

```powershell
powershell -File experiments/run_latest.ps1 -Verify
```

## 檔案位置

| 位置 | 用途 |
|---|---|
| r_extension/ | 最新方法的 5 個核心模組、5 個測試與說明 |
| experiments/run_latest_r.R | 完整 42 組資料實驗 |
| experiments/run_latest_tests.R | 最新方法測試入口 |
| experiments/validate_latest_r.R | 最新方法與原方法的合成資料比較 |
| experiments/compare_latest_author_r.R | 產生原方法與最新版比較數據 |
| experiments/time_author_latest_r.R | 兩方法的執行時間比較 |
| experiments/build_author_latest_tables.py | 產生完整比較表 |
| experiments/audit_latest.py | 核對最新程式與原始碼完整性 |
| experiments/data_folds.csv | 固定資料分組 |
| experiments/setup_author_r.R、run_author_r.ps1 | 作者原始程式的環境與執行入口 |
| results/latest_r/ | 最新預測、指標、設定、驗證與合成測試結果 |
| results/author_vs_latest_r/ | 完整比較表、數據與計時結果 |
| results/upstream_r/ | 作者原方法的實際執行紀錄與原始碼雜湊 |

## 結果與解讀

42 組資料的平均 F1：原方法 0.7556，Delayed3 為 0.7913。兩方法 FP 均為 62，FN 由 19 降至 14。

上述主比較使用標註選取最佳層級，屬描述性比較，不能解讀為無標註部署效果或外部資料的泛化保證。完整指標與比較限制請見 results/author_vs_latest_r 內的 Markdown 比較報告。
