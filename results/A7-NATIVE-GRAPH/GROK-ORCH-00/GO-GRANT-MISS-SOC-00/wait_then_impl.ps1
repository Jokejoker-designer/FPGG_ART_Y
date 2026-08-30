# Wait until no vivado.exe (Cursor impl / our listen does not use vivado).
# Then synth/impl standby bit. PROGRAM=NO. No open_hw_manager.
$ErrorActionPreference = 'Continue'
$bag = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $bag 'waiter.log'
function W([string]$m) {
  $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $m
  Add-Content -Path $log -Value $line -ErrorAction SilentlyContinue
}
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\GrokOrchGrantMissWaiter00', [ref]$created)
if (-not $created) { W ("DUPLICATE_WAITER exit pid={0}" -f $PID); exit 0 }
$PID | Set-Content (Join-Path $bag 'waiter.pid')
W ("WAIT_THEN_IMPL start PROGRAM=NO self_pid={0}" -f $PID)
while (Get-Process -Name vivado -ErrorAction SilentlyContinue) {
  $ids = (Get-Process -Name vivado | Select-Object -ExpandProperty Id) -join ','
  W "WAIT remaining vivado pids=$ids"
  Start-Sleep -Seconds 30
}
Start-Sleep -Seconds 15
W 'license presumed free; launch grant-miss impl PROGRAM=NO'
$env:XILINXD_LICENSE_FILE = 'D:\Xilinx\licenses\vivado_basic.lic'
& cmd.exe /c (Join-Path $bag 'run_go_grant_miss_soc_00.bat')
W ("vivado batch exit={0} PROGRAM=NO" -f $LASTEXITCODE)
exit $LASTEXITCODE
