# RESULTS — A-FAST-LM-BOARD-LANE-00

## Command

```powershell
$env:Path = "C:\2026.1\Vivado\bin;C:\2026.1\Vivado\bin\unwrapped\win64.o;" + $env:Path
cd D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board\tests\xsim
vivado -mode batch -notrace -source run_a7ng_native_v1_ab_fast.tcl
```

## Outcome

**FAIL** — exit code 5 (`A_FAST_LM_BOARD_LANE_NO_PASS`)

Last log lines:

```text
SOA_PRELOAD_DONE candidates=64
LM06_WMEM_BACKDOOR_DONE
SOA_OWNER_READY ok cycles=0
A_FAST_LM_BOARD_LANE_FAIL SOA_TIMEOUT bytes=256 beats=16 gv=0 ar_fires=1
```

## Ancillary (not Class A)

HS22 in same worktree: `HS22_LM06_NATIVE_CTX_FWD_XSIM_PASS pred_E0=664 pred_E1=733`
