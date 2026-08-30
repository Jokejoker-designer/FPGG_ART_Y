$log = Join-Path $PSScriptRoot 'vivado_physical.log'
while (-not (Test-Path $log)) { Start-Sleep -Seconds 2 }
Get-Content -Path $log -Wait -Tail 8 | ForEach-Object {
  $line = $_
  if ($line -match 'STOP:|GATE_FAIL|BIT_OK|SKIP_BITSTREAM|SYNTH GO-DGO-WAITBUSY|IMPLEMENT GO-DGO-WAITBUSY|GO_DGO_WAITBUSY|PREPLACE_GATE|TIMING_PARSE|GO_DGO_PULSE|CANDIDATE_TILE|REFUSE:|Exiting Vivado') {
    Write-Output $line
  }
}
