$log = Join-Path $PSScriptRoot 'vivado_physical.log'
while (-not (Test-Path $log)) { Start-Sleep -Seconds 2 }
Get-Content -Path $log -Wait -Tail 8 | ForEach-Object {
  $line = $_
  if ($line -match 'STOP:|GATE_FAIL|BIT_OK|SKIP_BITSTREAM|SYNTH GO-H2PACK|IMPLEMENT GO-H2PACK|GO_H2PACK|CANDIDATE_|PREPLACE_GATE|TIMING_PARSE|REFUSE:|Exiting Vivado|WRITE_BITSTREAM') {
    Write-Output $line
  }
}
