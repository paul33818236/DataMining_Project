# Execute the author's unmodified experiments/main.R using project-local R.
# Run from any directory: powershell -File experiments/run_author_r.ps1
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$rExecutable = Join-Path $projectRoot '.runtime/R-4.6.2/bin/Rscript.exe'
$rLibrary = Join-Path $projectRoot '.runtime/r-library'
$runFolder = Join-Path $projectRoot 'results/upstream_r'
$upstreamFolder = Join-Path $projectRoot 'upstream/scoth-segmentation'
if (-not (Test-Path -LiteralPath $rExecutable)) { throw 'Install the project-local R runtime first.' }
if (-not (Test-Path -LiteralPath $rLibrary)) { throw 'Run setup_author_r.R first.' }
New-Item -ItemType Directory -Force -Path $runFolder | Out-Null
$env:LC_ALL = 'English_United States.utf8'
$env:LC_CTYPE = 'English_United States.utf8'
$env:LANG = 'en_US.UTF-8'
$env:R_LIBS_USER = $rLibrary
Push-Location -LiteralPath $upstreamFolder
try {
    (Get-Date).ToUniversalTime().ToString('o') | Set-Content (Join-Path $runFolder 'start_utc.txt')
    & $rExecutable --vanilla 'experiments/main.R' *> (Join-Path $runFolder 'main.log')
    $pipelineExit = $LASTEXITCODE
    $pipelineExit | Set-Content (Join-Path $runFolder 'exit_code.txt')
    (Get-Date).ToUniversalTime().ToString('o') | Set-Content (Join-Path $runFolder 'end_utc.txt')
    Get-Content (Join-Path $runFolder 'main.log') -Tail 24
    if ($pipelineExit -ne 0) { throw "Author main.R exited with code $pipelineExit" }
} finally {
    Pop-Location
}
