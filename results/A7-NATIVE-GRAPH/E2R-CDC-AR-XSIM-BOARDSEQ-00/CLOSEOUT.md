# E2R-CDC-AR-XSIM-BOARDSEQ-00 (F1h) — CLOSEOUT

**Date:** 2026-08-26  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `STATUS/E2R_F1H_DISPATCH.md`  
**Claim scope:** Observation XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**

## Verdict

| Field | Value |
|-------|-------|
| GATE | E2R-CDC-AR-XSIM-BOARDSEQ-00 (F1h) |
| TB | **PASS** |
| Hypothesis favored | **H_RIVAL** (pure silicon — clock stop / XPM silicon / SoC binding) |
| H_CANDIDATE | **Falsified** for this stimulus (staggered release does not lose the beat) |
| Product RTL edit recommended | **No** (do not open F1i CDC RTL fix from this gate) |

## Metrics (preregistered)

| Metric | s_then_m (A) | m_then_s (B) |
|--------|--------------|--------------|
| m AR handshake | YES | YES |
| `s_axi_arvalid` within 50 s_clk | YES — **16** | YES — **16** |
| `ar_empty` at first s_arv | 0 | 0 |
| `ar_empty` final (after drain) | 1 | 1 |
| Clocks | m=80 ns; s=10 ns | same |
| DUT SHA256 | `272026EC609FA51E20DF7293A28AC083DD10EAB65B151A247C65251C9392679F` | same |

AR FIFO `.rst(!(m&&s))` stays asserted until the **second** domain releases (verified by design + recovery + successful write). Same 16-cycle latency as F1f ideal control.

## Evidence quotes (`xsim_stdout.txt`)

```text
CASE_SUMMARY id=0 name=s_then_m m_accepted=1 saw_s_arv=1 s_cycles_after_m=16 ar_empty_final=1
CASE_SUMMARY id=1 name=m_then_s m_accepted=1 saw_s_arv=1 s_cycles_after_m=16 ar_empty_final=1
SUMMARY s_then_m: m_ok=1 saw=1 cyc=16 PASS=1 | m_then_s: m_ok=1 saw=1 cyc=16 PASS=1
E2R_CDC_AR_XSIM_BOARDSEQ_PASS s_then_m_cyc=16 m_then_s_cyc=16 (window=50) H_RIVAL_FAVORED
```

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame |
| `tb_e2r_cdc_ar_xsim_boardseq_00.sv` | Dual-order board-seq TB |
| `run_xsim.cmd` | xvlog / xelab (`-L xpm` + `glbl`) / xsim |
| `xsim.log` | Vivado xsim tool log |
| `xsim_stdout.txt` | Full transcript with PASS line |
| `xvlog_stdout.txt` / `xelab_stdout.txt` | Compile/elab logs |

## Interpretation

Board-like staggered reset release (s→m and m→s), with one AR only after both domains are out of reset and XPM recovery, still presents `s_axi_arvalid` in 16 s_clk — identical to F1f simultaneous-release control. Combined with F1g (`M_RST_LO=NO`, `S_RST_LO=NO`), silicon `CDC_HOLD=NO` is **not** explained by reset sequencing losing the AR beat in this RTL.

## NEXT

Continue **H_RIVAL** silicon path (clock stop / MIG ui bind / XPM silicon / SoC AR path) — **not** a CDC reset-order RTL fix. Do not program board from this gate. Optional F1i only if a new sealed unknown names a different RTL defect with a falsifier.
