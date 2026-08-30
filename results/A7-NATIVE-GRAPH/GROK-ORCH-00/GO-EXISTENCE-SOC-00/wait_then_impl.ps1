# Wait for a foreign Vivado (close664 INTEGRATE) then run THIS tree's existence impl.
# PROGRAM=NO. Does not open_hw_manager. Does not steal JTAG.
$ErrorActionPreference = 'Continue'
$bag = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $bag 'waiter.log'
function W([string]$m) {
  $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $m
  Add-Content -Path $log -Value $line -ErrorAction SilentlyContinue
}
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\GrokOrchGoExistenceWaiter00', [ref]$created)
if (-not $created) {
  W ("DUPLICATE_WAITER exit pid={0}" -f $PID)
  exit 0
}
$PID | Set-Content -Path (Join-Path $bag 'waiter.pid')
W ("WAIT_THEN_IMPL start PROGRAM=NO self_pid={0}" -f $PID)
$busy = 175800
while (Get-Process -Id $busy -ErrorAction SilentlyContinue) {
  W "WAIT foreign vivado pid=$busy"
  Start-Sleep -Seconds 30
}
W 'foreign pid gone; wait remaining vivado.exe'
while (Get-Process -Name vivado -ErrorAction SilentlyContinue) {
  $ids = (Get-Process -Name vivado | Select-Object -ExpandProperty Id) -join ','
  W "WAIT remaining vivado pids=$ids"
  Start-Sleep -Seconds 30
}
Start-Sleep -Seconds 20
W 'license presumed free; launch grok-orch existence impl'
$env:XILINXD_LICENSE_FILE = 'D:\Xilinx\licenses\vivado_basic.lic'
$bat = Join-Path $bag 'run_go_existence_soc_00.bat'
& cmd.exe /c $bat
$code = $LASTEXITCODE
W "vivado batch exit=$code PROGRAM=NO"
exit $code
