$log = Join-Path $PSScriptRoot 'xsim.log'
while (-not (Test-Path $log)) { Start-Sleep -Seconds 2 }
Get-Content -Path $log -Wait -Tail 5 | ForEach-Object {
  $line = $_
  if ($line -match 'A_FAST_LM_BOARD_LANE|pred=664|FAIL|GO_AFAST') {
    Write-Output $line
  }
}
