Write-Host '=== PROCESSES ==='
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match 'vivado|hw_server|unwrapped|xsdb|xsim' } | Format-Table Id,ProcessName,StartTime -AutoSize
if (-not $?) { Write-Host 'NO_MATCH_OR_NONE' }
Write-Host '=== COM ==='
[System.IO.Ports.SerialPort]::GetPortNames() | ForEach-Object { Write-Host $_ }
Write-Host '=== HASH ==='
$files = @(
  'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\rtl\board\arty_a7_ng_native_v1_ab_soc_top.sv',
  'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\rtl\native_graph\memory\a7ng_cue_soa_mig_top.sv',
  'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\rtl\native_graph\topk\a7ng_topk_wavefront_minheap.sv',
  'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\rtl\native_graph\lm\a7ng_native_ctx_bind.sv',
  'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\rtl\lm\tiny_gpt803k_core.sv',
  'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\rtl\native_graph\memory\a7ng_ddr_wavefront_top.sv'
)
foreach ($f in $files) {
  $h = (Get-FileHash -Algorithm SHA256 $f).Hash
  Write-Host ((Split-Path $f -Leaf) + ' ' + $h)
}
