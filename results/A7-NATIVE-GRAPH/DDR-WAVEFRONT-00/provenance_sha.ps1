$dir = 'results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00'
$mine = @(
  'PREREGISTER.md',
  'RESULTS.md',
  'CLOSEOUT.md',
  'FROZEN_VERIFY.md',
  'PROVENANCE_a7-ng-memory-arch.md',
  'SHA256.txt',
  'ddr_wavefront_xsim.prj',
  'xvlog_ddr_wavefront.log',
  'xelab_ddr_wavefront.log',
  'xsim_ddr_wavefront.log',
  'xsim_preflight_synth_axi.log',
  'run_console.txt'
)
foreach ($f in $mine) {
  $p = Join-Path $dir $f
  if (Test-Path $p) {
    $h = (Get-FileHash -Algorithm SHA256 -Path $p).Hash
    Write-Output "$h  $f"
  } else {
    Write-Output "MISSING  $f"
  }
}
