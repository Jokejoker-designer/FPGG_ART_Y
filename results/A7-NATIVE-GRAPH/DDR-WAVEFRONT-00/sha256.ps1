$files = @(
  'rtl/native_graph/memory/a7ng_cue_wave_stage.sv',
  'rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv',
  'tests/xsim/tb_a7ng_ddr_wavefront.sv',
  'tests/xsim/tb_a7ng_ddr_wavefront_pre.sv',
  'tests/xsim/run_a7ng_ddr_wavefront.tcl',
  'rtl/native_graph/memory/a7ng_ddr_feed_pp.sv',
  'rtl/native_graph/memory/a7ng_ddr_feed_axi_bridge.sv',
  'rtl/native_graph/memory/a7ng_axi_mem_model.sv',
  'rtl/native_graph/scorer/a7ng_scorer_array.sv',
  'rtl/native_graph/scorer/a7ng_termgen_array.sv',
  'rtl/native_graph/topk/a7ng_topk.sv',
  'rtl/native_graph/pkg/a7ng_pkg.sv',
  'rtl/native_graph/memory/a7ng_mem_schema_v1.sv',
  'vivado/ip/mig_7series_0/mig_7series_0/mig.prj'
)
foreach ($f in $files) {
  if (Test-Path $f) {
    $h = (Get-FileHash -Algorithm SHA256 -Path $f).Hash
    Write-Output "$h  $f"
  } else {
    Write-Output "MISSING  $f"
  }
}
