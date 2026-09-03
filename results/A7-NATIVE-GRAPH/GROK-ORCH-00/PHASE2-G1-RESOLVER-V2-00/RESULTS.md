# PHASE2-G1-RESOLVER-V2-00 — RESULTS

Prompt SHA-256: `DEC3A5AFE4BC65B7080A5C8D6575C99B6975648D21A9DA7BDE72550AB3FAEB96`
RTL SHA-256: `2219DA29C265D2461ED30783EBEA0F0649050B9B6E5F6EAFDB8F1C4E05F3F5F7`
Vivado: 2026.1 (SW Build 6511674). PROGRAM=NO. SoC instantiate ABSENT.

## Law

FPGA latches evidence and mints `txn={gen,seq}` (seq skips 0). Host may send only reward `[-3,+3]` and txn echo. Consume record holds subj, rel, obj, q_epoch, p_epoch, conf, contradict, signed reward, txn until `consume_valid && consume_ready`. ACK is ready/valid held. Counters saturate. Wrap uses generation bits so a stale seq-only echo cannot match a new pending id. Residual collision only after full TXN_W reuse.

## XSim

| Test | Result |
|------|--------|
| `tb_a7ng_feedback_resolver` | `FEEDBACK_RESOLVER_UNIT_XSIM_PASS fails=0` |
| `tb_resolver_counterexample` | `RESOLVER_COUNTEREXAMPLE_XSIM_PASS` |
| `tb_a7ng_feedback_resolver_v2_rand` 100000 cycles, TXN_W=4 wrap surrogate | `RESOLVER_V2_RAND_XSIM_PASS` `MISMATCH_COUNT=0` `wrap_seen=1` |

Random scoreboard (after last reset window plus directed): `issue=hs=25` directed consumes; rejects `n_orphan=11110` `n_range=5556` `n_dup=11112` `n_mode=1` `n_late=2` `n_drop=1`. DUT counters matched TB. Payload held under consume/ACK backpressure. No consume without evidence+in-range echoed reward.

Raw logs: `unit_xsim.log`, `cx_xsim.log`, `rand_xsim.log` plus xvlog/xelab.

## OOC (xc7a100tcsg324-1, 12.5 MHz, flatten rebuilt)

```text
LUT=100 (logic 100, LUTRAM=0)
FF=413
BRAM=0 DSP=0
F7=0 F8=0
control_sets=12
WNS=+72.369 TNS=0 WHS=+0.131 THS=0
```

Target `LUT<=500 FF<=500 BRAM=0 DSP=0 WNS/TNS clean`: **met**.

## Not claimed

Gate 14 PASS, Teacher-Off, resource closure, board, PROGRAM. GRAPH-PAYLOAD-NORESET remains PASS_NARROW_PHYSICAL only (free=691).
