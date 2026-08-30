# Stream waiter.log, skip periodic WAIT lines.
$log = Join-Path $PSScriptRoot 'waiter.log'
while (-not (Test-Path $log)) { Start-Sleep -Seconds 2 }
Get-Content -Path $log -Wait -Tail 5 | ForEach-Object {
  $line = $_
  if ($line -notmatch 'WAIT foreign|WAIT remaining') {
    Write-Output $line
  }
}
