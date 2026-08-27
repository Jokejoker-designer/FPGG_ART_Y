# E2R-CDC-AR-XSIM-00 (F1f) — CLOSEOUT

**Date:** 2026-08-26  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Claim scope:** Observation XSim only — **not** existence, **not** `BOARD_PASS`

## Verdict

| Field | Value |
|-------|-------|
| GATE | E2R-CDC-AR-XSIM-00 (F1f) |
| TB | **PASS** |
| Hypothesis favored | **H_RIVAL** (silicon-only clocking/reset sequencing) |
| H_CANDIDATE | Not supported by this sim (RTL does present `s_axi_arvalid`) |
| Product RTL edited | **No** |

## Metrics (preregistered)

| Metric | Result |
|--------|--------|
| m AR handshake | YES (`M_AR_ACCEPT` T=6040 ns, `ar_wr_en=1`) |
| `s_axi_arvalid` within 50 s_clk | YES — **16** s_clk after m accept (window=50) |
| First `!ar_empty` / `s_arv` | T=6195 ns; `ar_rd_en=1`; `s_axi_araddr=0001000` |
| Clocks | m=80 ns (12.5 MHz); s=10 ns (100 MHz) |
| DUT SHA256 | `272026EC609FA51E20DF7293A28AC083DD10EAB65B151A247C65251C9392679F` |

## Evidence quotes (`xsim_stdout.txt` / `xsim.log`)

```text
M_AR_DRIVE T=5960000 addr=0001000
M_AR_ACCEPT T=6040000 ar_wr_en=1 ar_full=0 ar_empty=1
S_ARVALID T=6195000 s_cycles_after_m=16 ar_empty=0 ar_rd_en=1 addr=0001000
SUMMARY m_accepted=1 saw_s_arv=1 s_cycles_after_m=16 ar_empty_final=1 dbg_ne=0 dbg_hold=0
E2R_CDC_AR_XSIM_PASS s_cycles_after_m=16 (window=50) H_RIVAL_FAVORED
```

Wall-clock CDC delay m-accept → first s valid ≈ 155 ns (~CDC_SYNC_STAGES + FWFT), independent of the s_clk counter start.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame |
| `tb_e2r_cdc_ar_xsim_00.sv` | Isolated DUT TB |
| `run_xsim.cmd` | xvlog / xelab (`-L xpm` + `glbl`) / xsim |
| `xsim.log` | Vivado xsim tool log |
| `xsim_stdout.txt` | Full transcript with PASS line |
| `xvlog_stdout.txt` / `xelab_stdout.txt` | Compile/elab logs |

## Interpretation

Isolated F1e/F1c `a7ng_axi_read_cdc` **does** forward one m-side AR beat to `s_axi_arvalid` under ideal dual-clock / dual-reset stimulus. Silicon F1a–F1e `CDC_HOLD=NO` is therefore **not** explained by a pure RTL “FIFO loses the beat” bug under this stimulus → favor **H_RIVAL** (board reset/clock sequencing, or surrounding SoC binding).

## NEXT

**F1g** — silicon reset/clock sequencing investigation (do not change CDC RTL based on this gate alone). Board program only when COM12 / JTAG available; this gate did not touch COM12.
