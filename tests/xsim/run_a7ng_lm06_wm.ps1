# lm06_wm_00 equivalence runner.
#
# One bench (tb_a7ng_lm06_wm.sv) is compiled twice. The ONLY difference between
# the arms is which working-set memory file is handed to xvlog:
#
#   ARM = ctl      rtl/lm/{weight_bram803k,act_ram128k16,snap_ram4k16}.sv   (frozen)
#   ARM = cand     rtl/native_graph/memory/a7ng_lm06_wm_{wbank,act,snap}.sv (candidate)
#
# Same module names and port lists, so the frozen arithmetic core
# rtl/lm/tiny_gpt803k_core.sv is literally the same file in both arms and is never
# edited. Frozen LM-06 sources are read-only inputs to this script.
#
#   .\run_a7ng_lm06_wm.ps1 -Arm ctl  -Nvec 9 -DoImg 1 -Tag CONTROL_frozen
#   .\run_a7ng_lm06_wm.ps1 -Arm cand -Nvec 9 -DoImg 1 -Tag CANDIDATE_armA
#   .\run_a7ng_lm06_wm.ps1 -Arm cand -Nvec 1 -DoImg 0 -Tag CANDIDATE_armB -EnforceSnap
#
# Config reaches the bench through wm00_cfg.txt because the Windows xsim.bat
# wrapper splits "NAME=value" plusargs on '='.
param(
    [ValidateSet("ctl","cand")][string]$Arm = "ctl",
    [int]$Nvec = 9,
    [int]$DoImg = 1,
    [string]$Tag = "unset",
    [switch]$EnforceSnap,
    [switch]$EnforceAct,
    [switch]$Mutant,
    [switch]$Mutant2,
    [string]$VivadoBin = "C:\2026.1\Vivado\bin"
)

$ErrorActionPreference = "Stop"
$env:PATH = "$VivadoBin;" + $env:PATH

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Raw  = Join-Path $Root "results\A7-NATIVE-GRAPH\LM06-WM-00\raw"
New-Item -ItemType Directory -Force -Path $Raw | Out-Null

$WorkName = "wm00_$Tag"
$Work = Join-Path $Root "tests\xsim\$WorkName"
if (Test-Path $Work) { Remove-Item -Recurse -Force $Work }
New-Item -ItemType Directory -Force -Path $Work | Out-Null

# Frozen arithmetic and support: identical in both arms.
$Common = @(
    "rtl\lm\a7lm06_pkg.sv",
    "rtl\lm\isqrt32.sv",
    "rtl\lm\floordiv_s48.sv",
    "rtl\lm\weight_bram_tdp8.sv",
    "rtl\lm\weight_tile803k.sv",
    "rtl\lm\tiny_gpt803k_core.sv"
)
# The working set under test: exactly one of these two sets.
if ($Arm -eq "ctl") {
    $Mem = @("rtl\lm\weight_bram803k.sv", "rtl\lm\act_ram128k16.sv", "rtl\lm\snap_ram4k16.sv")
} else {
    $Mem = @("rtl\native_graph\memory\a7ng_lm06_wm_wbank.sv",
             "rtl\native_graph\memory\a7ng_lm06_wm_act.sv",
             "rtl\native_graph\memory\a7ng_lm06_wm_snap.sv")
}
$Src = @()
foreach ($f in ($Common + $Mem)) { $Src += (Join-Path $Root $f) }
$Src += (Join-Path $Root "tests\xsim\tb_a7ng_lm06_wm.sv")

$Defs = @()
if ($Arm -eq "cand")  { $Defs += @("-d", "A7NG_WM_CAND") }
if ($EnforceSnap)     { $Defs += @("-d", "A7NG_WM_ENFORCE_SNAP") }
if ($EnforceAct)      { $Defs += @("-d", "A7NG_WM_ENFORCE_ACT") }
# Negative control only. A run with -Mutant is expected to FAIL and is never
# citable as a candidate result.
if ($Mutant)          { $Defs += @("-d", "A7NG_WM_MUTANT") }
if ($Mutant2)         { $Defs += @("-d", "A7NG_WM_MUTANT2") }

$Cfg = Join-Path $Work "wm00_cfg.txt"
$OutImg = if ($DoImg -ne 0) { Join-Path $Raw "wm00_${Tag}_after.hex" } else { "none" }
Set-Content -Path $Cfg -Encoding ascii -Value @(
    $Tag, "$Nvec", "$DoImg",
    ((Join-Path $Root "tests\xsim\a7lm06_wmem.hex") -replace '\\','/'),
    ($OutImg -replace '\\','/')
)

Push-Location $Work
try {
    "ARM=$Arm TAG=$Tag NVEC=$Nvec DOIMG=$DoImg DEFS=$($Defs -join ' ')" |
        Out-File -Encoding ascii (Join-Path $Raw "cmd_$Tag.txt")
    "START_UTC=" + (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") |
        Out-File -Encoding ascii (Join-Path $Raw "${Tag}_timestamps.txt")

    & xvlog.bat -sv --nolog @Defs @Src *> (Join-Path $Raw "xvlog_$Tag.log")
    if ($LASTEXITCODE -ne 0) { Write-Output "XVLOG_FAIL"; exit 2 }

    & xelab.bat tb_a7ng_lm06_wm -s $WorkName -timescale 1ns/1ps --nolog -O0 -mt off `
        *> (Join-Path $Raw "xelab_$Tag.log")
    if ($LASTEXITCODE -ne 0) { Write-Output "XELAB_FAIL"; exit 3 }

    $sw = [Diagnostics.Stopwatch]::StartNew()
    & xsim.bat $WorkName --runall --nolog *> (Join-Path $Raw "xsim_$Tag.log")
    $rc = $LASTEXITCODE
    $sw.Stop()

    "END_UTC=" + (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") |
        Out-File -Encoding ascii -Append (Join-Path $Raw "${Tag}_timestamps.txt")
    "ELAPSED_S=$($sw.Elapsed.TotalSeconds)" |
        Out-File -Encoding ascii -Append (Join-Path $Raw "${Tag}_timestamps.txt")

    if ($rc -ne 0) { Write-Output "XSIM_FAIL rc=$rc"; exit 4 }
    $log = Get-Content (Join-Path $Raw "xsim_$Tag.log") -Raw
    if ($log -match "A7NG_LM06_WM00_RUN_PASS") { Write-Output "WM00_OK $Tag" }
    else { Write-Output "WM00_NO_PASS $Tag"; exit 5 }
} finally {
    Pop-Location
}
