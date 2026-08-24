# PREREGISTER — A-FAST-LM-BOARD-LANE-00

**Status:** SEALED BEFORE RUN  
**Owner:** Cursor board lane (`native_v1_existence_board_parallel_00`)  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Evidence class:** `XSIM_FAST_CAUSAL` / `PASS_NARROW`  
**Board / MIG PHY / bitstream:** **FORBIDDEN**

## ONE UNKNOWN

With `SIM_FULL=1`, no physical MIG/DDR3 model, backdoor `a7lm06_wmem.hex` only while reset/inactive, and SOA-fed live Top-8 through `a7ng_native_v1_ab_core`, does full forward produce exact FPGA `pred=664` with host winner/next-token authority zero?

## CONTROL

| Item | Value |
|------|--------|
| Core | `a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b1))` |
| Weights | `tests/xsim/a7lm06_wmem.hex` SHA `9A6BBC7AC8AF82725CAFD0B50241EE683C07FB9943C754753025F3569967D10F` |
| Wmem load | `$readmemh` only while `feed_en=0` / reset-inactive |
| SOA preload | 64 candidates, golden cues/priors per Attempt10 bench |
| Expected Top-8 | `9,11,25,27,41,43,57,59` |
| Expected pack | `64'h3b392b291b190b09` |
| Expected pred | `664` |
| AXI | Behavioral byte-memory stub — **not** `mig_native_wrap` / `ddr3_model` |

## FALSIFIER

- TB drives bind GID / pred / winner directly  
- `pred != 664` with `bind_done=1`  
- `mem_we` during exam  
- `dual_owner_err=1`  
- Host oracle at compare time  
- `SIM_FULL=0` substituted  

## PASS marker

`A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664`

## Allowed paths (board worktree only)

```text
tests/xsim/tb_a7ng_native_v1_ab_fast.sv
tests/xsim/a7ng_axi_soa_mem_stub.sv
tests/xsim/run_a7ng_native_v1_ab_fast.tcl
tests/xsim/xsim.dir.board_lane_fast/
results/A7-NATIVE-GRAPH/A-FAST-LM-BOARD-LANE-00/**
```

**Seal SHA:** compute after file write → `PREREGISTER_SEAL_SHA256.txt`
