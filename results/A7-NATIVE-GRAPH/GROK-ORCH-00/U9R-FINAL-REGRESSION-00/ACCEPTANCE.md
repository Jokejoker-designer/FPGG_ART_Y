# ACCEPTANCE — U9R-FINAL-REGRESSION-00

```text
AUDITOR     = gstack-acceptance-auditor (qa-only; report-only; no RTL/TB/CLOSEOUT patch)
GATE        = U9R-FINAL-REGRESSION-00
BAG         = results/A7-NATIVE-GRAPH/GROK-ORCH-00/U9R-FINAL-REGRESSION-00
AUTHORITY   = .agents/skills/gstack-acceptance-auditor/SKILL.md
              + PLAN.md R0–R9 + PROMPT_GROK_U9R.md + CLOSE_NATIVE_V1_DAG P10
              + PREREG/LOCK + CLOSEOUT/RESULTS + raw xsim*.log + SHA256 + RTL/TB
VERDICT     = FAIL
OVERCLAIM   = false
FRAUD       = false
LOGIC_BUG   = false
FIRST_DIV   = QUERY_NO_SNAPSHOT
READY_FOR_FINAL_SYNTH = NO
NEXT        = C03_QUERY_PENDING_SNAPSHOT_SOURCE (auditor does not open it)
```

Evidence > chat memory. This file does not change CLOSEOUT, RESULTS, RTL, or TB.
TRUTH > PROGRESS. Stop at first divergence. Do not auto-open U9S/U9I/U9P/U10.
Do not declare BOARD_PASS or GATE14_PASS.

## Authority / hard stops

| Token | Observed |
|---|---|
| BIT | NO. `vivado.log` command line is `vivado.exe -mode batch -notrace -source run_xsim.tcl`. No `write_bitstream`. |
| PROGRAM | NO. No `open_hw` / `program_device`. |
| REPROGRAM_AGAIN | NO |
| QHEAD | NO (R1/R7 logs; ORACLE_COMPATIBILITY.md) |
| HOLD_A_ORACLE_RETARGET | NO. pred_obs archived 861; HOLD_A stays 653. |
| reseat `1F0F2ABB` / `9CA2B30D` / `F24150BD` / `3A7EF204` | no bit in bag |
| U9S / U9I / U9P / U10 | LOCK/PREREG/CLOSEOUT = NO; auditor does not open them |
| BOARD_PASS / GATE14_PASS | CLOSEOUT = NO; no log marker |
| MIG / `a7lm06_wmem.hex` git-add | NO. wmem hashed `C204E559…3001E0` as `U9=NOT_IN_U9_KEYSET`. Full porcelain has historical MIG `*.xdc` CRLF + untracked this bag. |
| force-push / history rewrite | U9 freeze `bdddbd68` retained; HEAD docs `40e246db` |
| RTL_EDIT / SOC_TOP_EDIT | NO (LOCK + RESULTS) |
| Semantic LM | `LM_CHECKPOINT_CONTEXT_MISMATCH` |

Cycle watchdog, not ns overflow. R2 `WATCH_CYC=4096`; first trip is snap timeout tmo=2048 at `cyc=2085`, `$finish` 20955 ns.

## Fail-closed inputs

| Artifact | Status |
|---|---|
| `xsim.log` | present. Copy of `xsim_r2.log`. XSim 2026.1 SW Build 6511674. Start Mon Sep 7 09:41:13 2026. |
| PASS marker vs log | CLOSEOUT `RESULT=FAIL` **matches**. Marker `FIRST_DIVERGENCE QUERY_NO_SNAPSHOT` **present**. No `U9R_R2_QUERY_REWARD_PASS`. Fail-closed PASS-without-marker does **not** apply. |
| `SHA256.txt` | present. 23 production hashes labeled `U9=MATCH` equal U9 `SOURCE_MANIFEST.txt` (not only the 17-file U9 `SHA256.txt` subset). TBs and `run_xsim.tcl` hashed. |
| xvlog / xelab | per-group `xvlog_r*.log` / `xelab_r*.log`. R2 xvlog analyzes pkg, scorer, store, minheap, learned_prior_graph, id20_pack, c9_glue, g1g5_cofit, `tb_u9r_r2.sv`. No soc_top, no MIG. |

## First divergence (this lake)

Verbatim `xsim.log` / `xsim_r2.log`:

```text
R2_BOOT pbusy=0 qv_to_graph=0 p_qr=1 cyc=34
GLUE_FIRE tok0=00 map=03 mode=5 want_lm=0
GLUE_QISS qid=03 qr=1
R2_AFTER_FIRE glue_st=2 qv=1 qr=1 psv=0 ppend=0 qv_to_graph=0
R2_WAIT_SNAP tmo=2048 psv=0 ppend=0 glue_st=2 qv_to_graph=0
FIRST_DIVERGENCE QUERY_NO_SNAPSHOT SYNTHETIC_CAND_GEN=0: graph never sees query; S_QWAIT has no snap cyc=2085 qv_to_graph=0 p_qr=1 p_sv=0 p_pend=0 glue_st=2
$finish called at time : 20955 ns : File ".../tb_u9r_r2.sv" Line 70
```

RTL invariant (frozen `a7ng_g1g5_cofit.sv`):

```text
assign qv_to_graph = SYNTHETIC_CAND_GEN ? p_qv : 1'b0;
assign p_qr        = SYNTHETIC_CAND_GEN ? graph_qr : 1'b1;
```

`a7ng_learned_prior_graph` still owns `snap_valid_o` / `pending_o`. Glue `S_QWAIT=2` waits on `p_snap_v_i`. With `SYNTHETIC_CAND_GEN=0`, query never reaches the graph, so snapshot/pending stay 0. Violated invariant: production query/reward liveness after U8R mux.

`tb_u9r_r2.sv` instantiates `a7ng_g1g5_cofit #(.SYNTHETIC_CAND_GEN(1'b0))` only (not soc_top). That is enough to prove the production-parameter hole. It is not a full-SoC PASS and CLOSEOUT does not call it one.

## R-matrix (independent vs logs)

| Group | CLOSEOUT/RESULTS | Log marker | Auditor |
|---|---|---|---|
| R0 | PASS 23/23 MATCH | `SHA256.txt` vs U9 `SOURCE_MANIFEST.txt` | hashes recorded MATCH; live Get-FileHash not re-run here |
| R1 | PASS | `U9R_R1_CONTRACTS_PASS` route probe=0110; PROD 65/66/67; FIX idle; `qv_to_graph=0`; 155 ns | slice PASS. Heap golden is **pinned display**, not a 110s re-run — disclosed |
| R2 | FAIL | `FIRST_DIVERGENCE QUERY_NO_SNAPSHOT` | **first divergence** |
| R3 | INTEGRATION_GAP | `U9R_R3_INTEGRATION_GAP`; DUT `uart_cmd_rx+cmd_map (NOT soc_top)` | xsim exit 0 is expected gap, not Master PASS. `R_MATRIX.txt` `r3 XSIM_OK` is orchestrator pass_pat, not FULL_SOC PASS |
| R4 | FAIL | `FIRST_DIVERGENCE WDMA_DONE_COUNT expect 2 cyc=8004`; `cmd=2 s_go=0 m_done=0 b_ok=0` | CDC slice, not soc_top dest. Production dest unwired (RTL fact) |
| R5 | FAIL | `FIRST_DIVERGENCE RESET_RETRAIN_RESTATES_OLD_PRIOR pri=4 not from-zero +1 cyc=396` | freeze/dup PASS then restamp. xsim `EXCEPTION_ACCESS_VIOLATION` (`hs_err_pid36096`) **after** the marker; FAIL still evidenced |
| R6 | FAIL | `FIRST_DIVERGENCE M10_MEMBER_EVIDENCE_ABSENT`; python rc=7 | HOST_MODEL. `member_lookup=False` matches encoder: `member_ptr_o` unused in tok stream |
| R7 | STRUCTURAL_PASS / ORACLE_GAP | `U9R_R7_STRUCTURAL_PASS_ORACLE_GAP`; ntok=12; stream `1 1 0 0 1 1 0 1 1 1 1 0`; CLASS_ID not serialized | encoder only. `pred_obs=861` archived from U8-UNIFIED `xsim.log` (`PRED_OBS core=861`); not retargeted |
| R8 | PASS | `U9R_R8_NEGATIVE_PASS` `rj_crc=1 rj_typ=1 n_cue=4` | harness catch; not production host-leakage=0 proof. Disclosed |
| R9 | FAIL + READY_FOR_FINAL_SYNTH=NO | METRICS/CLOSEOUT | matches matrix |

Later FAILS (R4/R5/R6) are residuals, not a rewrite of first divergence.

## RTL facts (read, not TB literals)

| Fact | Independent read |
|---|---|
| `SOC_TOP_HAS_MIG=True` | `arty_a7_ng_native_v1_ab_soc_top.sv` instantiates `mig_native_wrap u_mig` |
| `SOC_TOP_HAS_TYPECLASS=False` | no typeclass / encoder / `a7ng_typeclass_soc_chain` in soc_top |
| `SOC_TOP_HAS_QSE=False` | no `a7ng_query_struct_extract` in soc_top |
| `SOC_TOP_SYNTHETIC_0=True` | `u_ab` `.SYNTHETIC_CAND_GEN(1'b0)` |
| `SOC_TOP_SIM_FULL_0=True` | `u_ab` `.SIM_FULL(1'b0)` |
| `SOC_TOP_M_GO_READY=False` | `a7ng_wdma_cdc u_wdma_cdc` has no `.m_go_ready` connection |
| `TINY_GPT_DMA_GO_READY=False` | `tiny_gpt803k_core` instantiates `weight_tile803k` without `.dma_go_ready`; port defaults `1'b1` |
| `AB_CORE_NATIVE_CTX_BIND=True` | `a7ng_native_v1_ab_core.sv:259` `a7ng_native_ctx_bind u_bind` |

## Hunt

### FAIL hidden as PASS
No. CLOSEOUT `RESULT=FAIL`, `REGRESSION_RESULT=FAIL`, `MARKER=(none; FAIL)`, METRICS `"result":"FAIL"`. Primary log has `FIRST_DIVERGENCE`. R3 `XSIM_OK` is INTEGRATION_GAP by design (`pass_pat=U9R_R3_INTEGRATION_GAP`).

### Overclaim
false. CLOSEOUT does **not** claim silicon, Gate14, BOARD_PASS, OUT=653, “LM understands TYPE_CLASS”, soc_top instantiated, or production WDMA ACK⇔commit. R4 scope line: `CDC_SLICE dest-like producer; not production tile through soc_top`. R7 full-forward not re-run. R1 heap not re-run. Allowed-claim text is within the logs.

### Fraud
false. TBs do not inspect CLASS_ID to pick reward. R5 stimulus is store `upd_rew`. R6 is a documented class-predicate host model that **fails**. R3 prints RTL facts as strings; those facts were re-read in RTL and match. R8 injects `host_cue_i` and requires `n_host_cue` to move (glue `if (host_cue_i != 64'd0) n_host_cue_o <= n_host_cue_o + 1`); zero constants were not used as proof.

### Logic bug (CLASS_ID as token / bind-as-TYPE_CLASS-stream)
false **on the TYPE_CLASS encoder path under test**. `a7ng_lm_ctx_encoder_v1.sv` writes `{eid,iid,rid,xid}`; R7 TB rejects tok∈{65,66,67}. `member_ptr` is materialized and dropped.

Production residual (already INTEGRATION_GAP, not a hidden TYPE_CLASS PASS): `a7ng_native_ctx_bind.sv` still does `pack_comb[8*i +: 8] = global_id_i[i][7:0]`. That is the live ab_core LM pack, **not** the TYPE_CLASS encoder stream, and CLOSEOUT names it `NATIVE_CTX_BIND_STILL_PRODUCTION_LM_PACK`. Do not invent CLASS_ID as NID. Do not treat 65/66/67 mux IDs as an LM-understands claim.

### Host counters
R8 after inject: `n_cue=4 n_win=0 n_w=0`. That is the negative harness, not a normal-run host-leak PASS.

## Provenance

```text
PRODUCTION_RTL = bdddbd68b048054dc0c52e87685829a590f25270
HEAD           = 40e246db922ce3d6fe35815988168c5bce9aa193
BRANCH         = grok-orch/v31-canonical-00
GIT_STATUS_PRODUCTION = empty
```

Key SHA cross-check vs U9 freeze `SOURCE_MANIFEST.txt` (identical 64-hex): soc_top `0AECC1F1…`, ab_core `EE3443DF…`, g1g5 `1762CE02…`, wdma_cdc `9BE3A8CD…`, weight_tile `8D602D10…`, native_ctx_bind `72A23A57…`, encoder `BBD95F7F…`, typeclass_table `9ADD454C…`, uart_cmd_rx `7CA553B5…`, cmd_map `20BF43EF…`, tiny_gpt `75706E2C…`, c9_glue `A0555B07…`.

## What this lake is not

- Not BOARD_PASS, not GATE14_PASS, not silicon.
- Not license to U9S/U9I/U9P/U10.
- Not a patch ticket. Missing UART→QSE→TYPE_CLASS in soc_top and dest `dma_go_ready` remain C02/C04 residuals.
- Semantic LM stays `LM_CHECKPOINT_CONTEXT_MISMATCH`. 861 ≠ 653 is oracle compatibility, not a transport bug to rewind U8-R3.

## Smallest next experiment (hint only; auditor does not implement)

C03: when `SYNTHETIC_CAND_GEN=0`, pending/snapshot must come from the live parent query/Top-K completion path, not from the disabled cand graph. Do **not** patch frozen RTL in this bag to flip FAIL→PASS. Do not reseat frozen bits. Manager owns C00–C13 dispatch.
