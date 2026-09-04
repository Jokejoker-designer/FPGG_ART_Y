# Restore U4B live 20-bit C9/bind after U2R impl releases the fileset.
# U2R used HEAD glue (8-bit diagnostic pack) so SNAP remap stayed one unknown.
$ErrorActionPreference = 'Stop'
$root = 'D:\Jetking_sem4\SEM_4\arty-a7-online-lm-g14-preboard-00'
$bag  = Join-Path $root 'results\A7-NATIVE-GRAPH\GROK-ORCH-00\U4B-GLOBAL-ID-C9-WIDTH-00'
Copy-Item (Join-Path $bag 'a7ng_gate14_c9_glue.U4B.sv') (Join-Path $root 'rtl\native_graph\integrate\a7ng_gate14_c9_glue.sv') -Force
Copy-Item (Join-Path $bag 'a7ng_native_ctx_bind.U4B.sv') (Join-Path $root 'rtl\native_graph\lm\a7ng_native_ctx_bind.sv') -Force
Write-Output 'U4B_GLUE_BIND_RESTORED'
