# RESULTS — U9R-FINAL-REGRESSION-00

```text
RTL_EDIT    = NO
SOC_TOP_EDIT= NO
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
BOARD_PASS  = NO
PRODUCTION_RTL = bdddbd68b048054dc0c52e87685829a590f25270
HEAD           = 40e246db922ce3d6fe35815988168c5bce9aa193
VIVADO         = 2026.1 SW Build 6511674
```

## R0 provenance

Key production hashes MATCH U9 freeze (`HASH_CROSSCHECK.txt`). Production porcelain empty.
`tests/xsim/a7lm06_wmem.hex` SHA256 `C204E559…3001E0` pinned (not in U9 keyset; not git-added).

RTL_FACT_WIRING:

```text
SOC_TOP_HAS_TYPECLASS=False
SOC_TOP_HAS_QSE=False
SOC_TOP_HAS_MIG=True
SOC_TOP_SYNTHETIC_0=True
SOC_TOP_SIM_FULL_0=True
SOC_TOP_M_GO_READY=False
TINY_GPT_DMA_GO_READY=False
AB_CORE_NATIVE_CTX_BIND=True
```

## R-matrix (this bag XSim / python)

| Group | Result | Marker / first divergence |
|---|---|---|
| R0 | PASS | 23/23 U9 key hashes MATCH |
| R1 | PASS | `U9R_R1_CONTRACTS_PASS` route 0110; PROD 65/66/67; 155 ns |
| R2 | FAIL | `QUERY_NO_SNAPSHOT` glue_st=2 S_QWAIT; qv_to_graph=0; p_sv=0; p_pend=0; cyc=2085 |
| R3 | INTEGRATION_GAP | UART FIRE decoded; soc_top has MIG, no QSE/TYPE_CLASS; not instantiated |
| R4 | FAIL | dest-like `cmd=2 s_go=0 m_done=0`; production `dma_go_ready` unwired |
| R5 | FAIL | freeze/dup PASS; `RESET_RETRAIN_RESTATES_OLD_PRIOR` pri=4 not +1 |
| R6 | FAIL | `M10_MEMBER_EVIDENCE_ABSENT` same class, different object |
| R7 | STRUCTURAL_PASS / ORACLE_GAP | encoder 12 tokens; pred_obs archived 861 ≠ 653 |
| R8 | PASS | rj_crc=1 rj_typ=1 n_cue=4 on inject |

Primary log: `xsim.log` = copy of `xsim_r2.log` (first production-path FAIL).

## Not claimed

silicon · Gate14 · BOARD_PASS · OUT=653 · LM understands TYPE_CLASS · U9S/bit · MIG PHY
