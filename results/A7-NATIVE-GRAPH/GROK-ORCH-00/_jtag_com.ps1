Write-Host 'COM:'
[System.IO.Ports.SerialPort]::GetPortNames() | ForEach-Object { Write-Host $_ }
Write-Host 'PNP:'
Get-PnpDevice -PresentOnly | Where-Object { $_.FriendlyName -match 'Serial|FTDI|Digilent|USB Serial|JTAG' } | ForEach-Object {
  Write-Host ($_.Status + ' | ' + $_.FriendlyName + ' | ' + $_.InstanceId)
}
Write-Host 'BIT:'
Get-FileHash -Algorithm SHA256 'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\results\A7-NATIVE-GRAPH\GROK-ORCH-00\SLICE-OPT-BIT-00\arty_a7_ng_native_v1_grok_orch_slice_opt_00.bit' | ForEach-Object { Write-Host $_.Hash }
