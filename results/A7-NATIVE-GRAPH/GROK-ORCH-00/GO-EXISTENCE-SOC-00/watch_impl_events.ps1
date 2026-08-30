# Stream existence impl log; print only gate/progress lines.
$log = Join-Path $PSScriptRoot 'vivado_physical.log'
while (-not (Test-Path $log)) { Start-Sleep -Seconds 2 }
Get-Content -Path $log -Wait -Tail 15 | ForEach-Object {
  $line = $_
  if ($line -match 'STOP:|GATE_FAIL|BIT_OK|SKIP_BITSTREAM|SYNTH GO-EXISTENCE|IMPLEMENT GO-EXISTENCE|WRITE_BITSTREAM|PREPLACE_GATE|TIMING_PARSE|GO_EXISTENCE_SOC_00_|CANDIDATE_|REFUSE:|ERROR:|Exiting Vivado') {
    Write-Output $line
  }
}
