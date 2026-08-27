# E2R-WMEM-PRELOAD-00 CLOSEOUT — PASS

**Verdict:** **PASS** (XSim DDR verify + firewall RTL)  
**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board`

## Metrics

| Check | Result |
|-------|--------|
| bytes written | **802816** |
| DDR readback vs `a7lm06_wmem.hex` | **0 mismatches** |
| base | `0x0010_0000` (`DDR_WBASE`) |
| source SHA256 | `9A6BBC7AC8AF82725CAFD0B50241EE683C07FB9943C754753025F3569967D10F` |
| marker | `E2R_WMEM_PRELOAD_XSIM_PASS` |
| firewall RTL | `core_rst_n = calib ∧ soa ∧ wmem` in `arty_a7_ng_native_v1_ab_soc_top.sv` |
| Program | **NO** |

## Notes

- Gate 2 store for verify: sim `$readmemh` into FPGA-owned AXI master (`a7ng_ddr_wmem_boot`) — **not** silicon evidence.
- Silicon fill remains **T2-SPI** (Gate 4 prerequisite). Synth path writes zeros until SPI master lands.

## Artifacts

- `xsim.log`, `xvlog.log`, `xelab.log`, `PREREGISTER.md`
- RTL: `rtl/board/a7ng_ddr_wmem_boot.sv`, top firewall wiring

**Next:** Gate 3 `E2R-TELEMETRY-00`
