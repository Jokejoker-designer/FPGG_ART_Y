# Parser-only score of U2 POST_ROUTE reports. No impl.
$u2 = Join-Path $PSScriptRoot '..\U2-OPTIMIZED-FULLCHIP-COFIT-00'
$util = Join-Path $u2 'report_utilization_route.rpt'
$tim = Join-Path $u2 'report_timing_summary.rpt'
$route = Join-Path $u2 'report_route_status.rpt'
$utxt = Get-Content -Raw $util
if ($utxt -notmatch '\|\s+Slice\s+\|\s+(\d+)\s+\|\s+\d+\s+\|\s+\d+\s+\|\s+(\d+)') {
  Write-Output 'U2R_PARSER_TERMINAL_FAIL no Slice Available row'
  exit 2
}
$used = [int]$Matches[1]; $tot = [int]$Matches[2]; $free = $tot - $used
if ($tot -eq 0) { Write-Output 'U2R_PARSER_TERMINAL_FAIL tot=0'; exit 3 }
$ttxt = Get-Content -Raw $tim
# Design Timing Summary numeric row
$wns='NA'; $tns='NA'; $whs='NA'; $ths='NA'
$lines = $ttxt -split "`n"
$seen=$false
foreach ($ln in $lines) {
  if ($ln -match 'Design Timing Summary') { $seen=$true }
  if ($seen -and $ln -match '^\s+([0-9]+\.[0-9]+)\s+([0-9]+\.[0-9]+)\s+\d+\s+\d+\s+([0-9]+\.[0-9]+)\s+([0-9]+\.[0-9]+)') {
    $wns=$Matches[1]; $tns=$Matches[2]; $whs=$Matches[3]; $ths=$Matches[4]; break
  }
}
$rtxt = Get-Content -Raw $route
$rte=0
if ($rtxt -match 'nets with routing errors[^\d]*(\d+)') { $rte=[int]$Matches[1] }
Write-Output "SLICE_PARSER used=$used tot=$tot free=$free"
Write-Output "TIMING WNS=$wns TNS=$tns WHS=$whs THS=$ths route_err=$rte"
if ($tot -ne 15850) { Write-Output "U2R_PARSER_TERMINAL_FAIL tot=$tot want 15850"; exit 4 }
if ($used -le 0) { Write-Output 'U2R_PARSER_TERMINAL_FAIL used'; exit 5 }
Write-Output 'U2R_PARSER_TERMINAL_PASS'
if ($free -ge 800) { Write-Output 'U2_BASELINE_PREF800_MET' } else { Write-Output "U2_BASELINE_PREF800_MISS free=$free" }
exit 0
