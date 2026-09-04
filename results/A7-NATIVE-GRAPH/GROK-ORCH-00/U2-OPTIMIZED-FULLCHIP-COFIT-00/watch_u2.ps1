# Silent until terminal/action. Poll U2 Vivado log.
param(
  [Parameter(Mandatory=$true)][int]$PidToWatch,
  [Parameter(Mandatory=$true)][string]$LogPath
)
$ErrorActionPreference = 'Continue'
$lastWake = ''
function Emit($kind, $msg) {
  $line = "${kind}: $msg"
  if ($line -ne $script:lastWake) {
    $script:lastWake = $line
    Write-Output $line
  }
}
while ($true) {
  $alive = $false
  try { $p = Get-Process -Id $PidToWatch -ErrorAction Stop; if ($p) { $alive = $true } } catch { $alive = $false }
  $txt = ''
  if (Test-Path $LogPath) {
    try { $txt = Get-Content -LiteralPath $LogPath -Raw -ErrorAction SilentlyContinue } catch { $txt = '' }
  }
  if ($txt -match 'U2_OPTIMIZED_FULLCHIP_COFIT_IMPL_PASS') {
    Emit 'DONE' 'U2_OPTIMIZED_FULLCHIP_COFIT_IMPL_PASS'
    exit 0
  }
  if ($txt -match 'U2_OPTIMIZED_FULLCHIP_COFIT_FAIL') {
    Emit 'FAILED' 'U2_OPTIMIZED_FULLCHIP_COFIT_FAIL'
    exit 1
  }
  if ($txt -match 'GATE_FAIL') {
    $m = [regex]::Match($txt, 'GATE_FAIL[^\r\n]*')
    Emit 'FAILED' $m.Value
    exit 1
  }
  if ($txt -match 'ERROR:\s+\[Synth') {
    $m = [regex]::Match($txt, 'ERROR:\s+\[Synth[^\r\n]*')
    Emit 'FAILED' $m.Value
    exit 1
  }
  if ($txt -match 'ERROR:\s+\[Common') {
    $m = [regex]::Match($txt, 'ERROR:\s+\[Common[^\r\n]*')
    Emit 'FAILED' $m.Value
    exit 1
  }
  if (-not $alive) {
    Start-Sleep -Seconds 3
    $txt2 = ''
    if (Test-Path $LogPath) { try { $txt2 = Get-Content -LiteralPath $LogPath -Raw -ErrorAction SilentlyContinue } catch { $txt2 = '' } }
    if ($txt2 -match 'U2_OPTIMIZED_FULLCHIP_COFIT_IMPL_PASS') { Emit 'DONE' 'U2_OPTIMIZED_FULLCHIP_COFIT_IMPL_PASS'; exit 0 }
    if ($txt2 -match 'U2_OPTIMIZED_FULLCHIP_COFIT_FAIL') { Emit 'FAILED' 'U2_OPTIMIZED_FULLCHIP_COFIT_FAIL'; exit 1 }
    Emit 'FAILED' "vivado pid $PidToWatch exited without U2 pass marker"
    exit 1
  }
  Start-Sleep -Seconds 30
}
