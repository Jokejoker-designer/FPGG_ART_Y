$log = Join-Path $PSScriptRoot 'vivado_physical.log'
while (-not (Test-Path $log)) { Start-Sleep -Seconds 2 }
Get-Content -Path $log -Wait -Tail 5 | ForEach-Object {
  $line = $_
  if ($line -match 'PREPLACE_GATE|=== IMPLEMENT|Place 30-487|Place 30-99|BIT_OK path=|SKIP_BITSTREAM|WRITE_BITSTREAM|Exiting Vivado|GATE_FAIL|MINHEAP_BIT_00|CANDIDATE_HEAP|STOP:') {
    Write-Output $line
  }
}
