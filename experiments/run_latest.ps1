# Run from any directory; all paths are resolved relative to this project.
param([switch]$Verify)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$rExecutable = Join-Path $projectRoot '.runtime/R-4.6.2/bin/Rscript.exe'
$env:LC_ALL = 'English_United States.utf8'
$env:LC_CTYPE = 'English_United States.utf8'
$env:LANG = 'en_US.UTF-8'
$env:R_LIBS_USER = Join-Path $projectRoot '.runtime/r-library'
Push-Location -LiteralPath $projectRoot
try {
    New-Item -ItemType Directory -Force 'results/latest_r' | Out-Null
    $rArguments = @('--vanilla', 'experiments/run_latest_r.R')
    if ($Verify) { $rArguments += '--verify' }
    & $rExecutable @rArguments *> 'results/latest_r/run.log'
    $runExit = $LASTEXITCODE
    $runExit | Set-Content 'results/latest_r/exit_code.txt'
    Get-Content 'results/latest_r/run.log' -Tail 10
    if ($runExit -ne 0) { throw "Latest R experiment failed: $runExit" }
} finally {
    Pop-Location
}
