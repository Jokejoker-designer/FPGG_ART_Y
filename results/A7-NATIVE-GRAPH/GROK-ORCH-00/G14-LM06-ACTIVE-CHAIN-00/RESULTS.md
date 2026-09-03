# RESULTS — G14-LM06-ACTIVE-CHAIN-00 (Gate L)

```text
G14_LM06_ACTIVE_CHAIN        = LM_ACTIVE_CHAIN_PROVEN
FIRST_DIVERGENCE             = NONE
C9                           = 8382238122802120  (HOLD_A L0 exact)
BIND                         = captured_pack == C9; ctx_we n=8
LM_START                     = glue.lm_start + bind.start_fwd  (L2)
LM_COMPUTE                   = busy=1 st left IDLE max_st=29  (L3)
LM_DONE                      = core_done this request; pred latched  (L5)
OUT_SOURCE                   = c10_out == core_pred == 653  (L6)
HOST_NEXT_TOKEN              = 0
HOST_WEIGHT_WRITE            = 0
XSIM                         = PASS  SIM_FULL=1
READY_TO_PROGRAM             = NO
PROGRAM                      = NO
GATE14_PASS                  = NO
LM06_BOARD                   = not_claimed
```

No FPGA program. No new bit. No RTL edit.

---

## Causal table (`XSIM`)

| signal | producer | consumer | phase | value |
|--------|----------|----------|-------|-------|
| c9_topk | glue←graph TopK | bind global_id | L0 | `8382238122802120` |
| captured_pack | bind S_IDLE | ctx_pack | L1 | same C9 |
| ctx_we / ctx_n | bind S_CTX | tiny_gpt tok[] | L1 | we=1 n=8 |
| lm_start | glue S_QWAIT | bind.start_i | L2 | pulse |
| start_fwd | bind S_START | tiny_gpt | L2 | pulse; busy 0→1 st 0→1 |
| core_busy / st | tiny_gpt | bind | L3 | busy=1 max_st=29 |
| tile addr_a | weight_tile SIM_FULL BRAM | MAC | L4 | activity (XSim BRAM, not DDR) |
| core_done / pred | tiny_gpt ST_ARG | bind pred_r | L5 | pred=653 |
| c10_out | glue <= bind.pred | UART | L6 | 653 = core_pred |
| n_host_* | tied-0 glue | TB | L7 | all 0 |

`exam_lm_used_o` / `lmst` sticky **not** used as proof.

---

## Perturbation (same frozen A state, freeze=1)

| query | C9 | ctx_pack | core_pred | OUT |
|-------|----|----------|-----------|-----|
| HOLD_A | `8382238122802120` | same | 653 | 653 |
| UNREL  | `8786858483828180` | same | 689 | 689 |

C9 change ⇒ ctx change ⇒ pred/OUT change. Oracle not retargeted.

---

## Honesty

- XSim `SIM_FULL=1`: weights from sim BRAM, `stall=0`. Dest/DDR WDMA is **not** this evidence class.
- Silicon bind path in `ab_core` is the same modules; BOARD LM chain still **not_claimed**.

Remaining Gate14 gaps: BOARD teacher-off / reset-retrain if checklist requires silicon, parallelism/memory metrics, 800k / no-hidden-scan.
