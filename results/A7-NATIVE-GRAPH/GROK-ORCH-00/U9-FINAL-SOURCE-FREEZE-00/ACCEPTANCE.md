# ACCEPTANCE — U9-FINAL-SOURCE-FREEZE-00

```text
AUDITOR     = gstack-acceptance-auditor (qa-only; report-only; no RTL/TB/CLOSEOUT patch)
GATE        = U9-FINAL-SOURCE-FREEZE-00
BAG         = results/A7-NATIVE-GRAPH/GROK-ORCH-00/U9-FINAL-SOURCE-FREEZE-00
AUTHORITY   = skill SKILL.md + a7-fpga-gate + a7-native-graph-gate
              + PREREG/LOCK + CLOSEOUT/RESULTS + raw xsim.log + RTL/TB + git worktree
VERDICT     = PASS
OVERCLAIM   = false
FRAUD       = false
LOGIC_BUG   = false
FIRST_DIV   = NONE
SCOPE       = docs/manifest freeze + U8R production-path confirm XSim
              NOT silicon, NOT U9R suite, NOT full-SoC WDMA, NOT unique bit
```

Evidence > chat memory. This file does not change CLOSEOUT, RESULTS, RTL, or TB.

## Authority / hard stops

| Token | Observed |
|---|---|
| BIT | NO. `vivado.jou` is `source run_xsim.tcl -notrace` only. No `write_bitstream`, `open_hw`, `program_device` in bag. |
| PROGRAM | NO |
| REPROGRAM_AGAIN | NO |
| QHEAD | NO |
| HOLD_A_ORACLE_RETARGET | NO (no OUT 653/689/237/60; pred_obs cited as prior P7=861 MISMATCH) |
| reseat `1F0F2ABB` / `9CA2B30D` / `F24150BD` / `3A7EF204` | no bit in bag |
| U9S / U9I / U9P / U10 | CLOSEOUT NEXT = `U9R-FINAL-REGRESSION-00`; forbids auto-open. Auditor does not open them. |
| BOARD_PASS / GATE14_PASS | CLOSEOUT = NO; log has no such marker |
| force-push | worktree `logs/HEAD` is linear `bdddbd68` → `4ca071e` (docs commit). Not a reset of U8R. |
| MIG / `a7lm06_wmem.hex` git-add | `GIT_STATUS_FULL.txt` still shows three generated MIG `*.xdc` as `M`; not staged in that snapshot. COMMITMSG forbids add. |

Semantic LM class remains `LM_CHECKPOINT_CONTEXT_MISMATCH`. Cycle watchdog is not this unknown (`$finish` 155 ns, ~16 cycles @ 10 ns).

## Fail-closed inputs

| Artifact | Status |
|---|---|
| `xsim.log` | present; XSim 2026.1 SW Build 6511674; start Mon Sep 7 08:09:08 2026; `$finish` 155 ns at TB line 108 |
| Confirm marker vs log | `U8R_REMOVE_SYNTHETIC_PRODUCTION_PASS` **present**. `PROD id0=65 id1=66 id2=67`. `FIX id0=0 id1=0 id2=0`. No `FIRST_DIVERGENCE`. |
| Freeze wrapper marker | `U9_FINAL_SOURCE_FREEZE_XSIM_OK` is in `vivado.log` after xsim exit (tcl `puts` in `run_xsim.tcl`). **Not** inside `xsim.log`. CLOSEOUT splits `CONFIRM_XSIM` vs `MARKER`. RESULTS quotes both in one xsim block — presentation only; not a silicon claim. |
| `SHA256.txt` | present (soc_top, ab_core, g1g5, wdma_cdc, store, persist bridge, ddr_tile_dma, weight_tile, typeclass chain, ctx_fwd, ctx_bind, XCI, XDC, U2 tcl, bag TB/tcl) |
| xvlog / xelab | bag `xvlog.log` analyzes pkg, scorer, resolver, context_delta, store, minheap, learned_prior_graph, id20_pack, c9_glue, **g1g5_cofit**, bag TB. Snapshot `u9freeze`. **No soc_top, no MIG, no typeclass_soc_chain, no native_ctx_bind, no LM.** xelab: two pre-existing unconnected-port warnings on `a7ng_learned_prior_graph`. |

## HEAD / FINAL_SOURCE_COMMIT (git worktree, not bag HEAD.txt)

Worktree gitdir: `D:/Jetking_sem4/SEM_4/arty-a7-online-lm/.git/worktrees/arty-a7-online-lm-g14-preboard-00`.

```text
bag HEAD.txt              = bdddbd68b048054dc0c52e87685829a590f25270
bag HEAD_COMMIT subject   = U8R: production C9 uses parent TopK; cand_* walk fixture-only.
live refs/heads/grok-orch/v31-canonical-00 = 4ca071e7927aa4ceb6b9868eb17630ffa985eaf0
logs/HEAD last            = bdddbd68 → 4ca071e  commit: U9: final source freeze docs. PRODUCTION_RTL=bdddbd68. BIT=NO.
```

`FINAL_SOURCE_COMMIT=bdddbd68` is the last **production RTL** commit (U8R). Live branch HEAD is the later **docs** commit `4ca071e`. Bag `HEAD.txt` is a snapshot taken before that docs commit. That is not a production-RTL dirty-tree STOP and not a force-push. It is also not a claim that `git rev-parse HEAD` is still `bdddbd68` at audit time.

P7b WDMA named-wire commit `3b3aebef` is **before** U8R `bdddbd68`. Live `a7ng_wdma_cdc.sv` has `m_go_ready`. SHA `9BE3A8CD…744485` matches U8-SOC-ROOTB bag.

## git status (bag snapshot)

`GIT_STATUS_PRODUCTION.txt` empty ⇒ `git status --porcelain` on `rtl/` `constraints/` `vivado/tcl/` was empty at capture.

`GIT_STATUS_FULL.txt` modified:

- `results/.../U3Q-R3-STRUCTURED-QUERY-FEATURE-00/xelab.log` (tracked-ignored log; not production RTL)
- three generated MIG `*.xdc` (quarantined; `MIG_QUARANTINE.txt` class=`CRLF_LINE_ENDINGS_ONLY_NOT_XCI_CONTENT`)
- untracked evidence / CLI / this bag (at capture)

No `rtl/` `constraints/` `vivado/tcl/` paths in the modified list. Blueprint §21 “No dirty working tree” is **full porcelain not empty**. This lake’s locked PREREG unknown is production paths clean + MIG generated dirt quarantined, matching U0 quarantine practice and the owner ban on `git add` MIG. Dirty-tree STOP for production RTL **did not fire** on the captured porcelain.

## SHA / manifest

Cross-bag `HASH_CROSSCHECK.txt` matches files this auditor read:

| File | This bag SHA256.txt | Independent check |
|---|---|---|
| `arty_a7_ng_native_v1_ab_soc_top.sv` | `0AECC1F1…9A38DC` | = U8R SHA256.txt; SOURCE_MANIFEST line 43 |
| `a7ng_native_v1_ab_core.sv` | `EE3443DF…F7558E36` | = U8R SHA256.txt |
| `a7ng_g1g5_cofit.sv` | `1762CE02…B14AE17` | = U8R SHA256.txt |
| `a7ng_wdma_cdc.sv` | `9BE3A8CD…744485` | = U8-SOC-ROOTB SHA256.txt |
| `a7ng_typeclass_soc_chain.sv` | `ACD0818C…34BC49E6` | = U8-UNIFIED-SOC SHA256.txt |
| `a7ng_lm_ctx_fwd_v1.sv` | `63E32A9B…C52ABF4C` | = U8-UNIFIED-SOC SHA256.txt |
| `typeclass_table.svh` | SOURCE_MANIFEST `9ADD454C…9D9DDC` | = U6-TYPECLASS SHA256.txt |
| MIG XCI blob SHA1 | `305d8614…0dbd5e0` | = U0 RESULTS/METRICS |

Auditor did not recompute live `Get-FileHash`; hashes are cross-bag identity plus RTL_FACT greps below.

`SOURCE_MANIFEST.txt` has **415** lines, not METRICS/RESULTS `source_manifest_count=414`. `vivado/tcl/` occupies lines 252–411 = **160** files, not RESULTS `TCL_SET_SHA256 (159 files)`. Count fields are off-by-one. The listed hashes themselves are not thereby falsified. Not a hidden FAIL.

U0 recorded XCI content SHA256 `9FBB119A…` is disclosed as unreproduced from the same blob; freeze authority is blob SHA1 `305d8614…`. Honest, not an XCI edit.

## RTL_FACT — one production retrieval engine

`rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` instantiates:

```text
a7ng_native_v1_ab_core #(
  ...
  .SYNTHETIC_CAND_GEN(1'b0)
) u_ab (
```

`a7ng_g1g5_cofit` default parameter remains `1'b1` (fixture). Production mux:

```text
assign qv_to_graph = SYNTHETIC_CAND_GEN ? p_qv : 1'b0;
// SYNTHETIC_CAND_GEN=0 → c9_id = graph_id_i (parent), not cand walk p_id
```

Confirm XSim DUT is **g1g5 slice**, not soc_top. xvlog list and TB match. TB prints `SOC_TOP SYNTHETIC_CAND_GEN=0 (file fact; this TB is g1g5 slice)`. CLOSEOUT `TOP=arty_a7_ng_native_v1_ab_soc_top` is the blueprint record, not an instantiated-sim claim. Hunt “SoC top instantiated when it was not” = **not claimed**.

## Confirm XSim (verbatim xsim.log body)

```text
PROD id0=65 id1=66 id2=67
FIX  id0=0 id1=0 id2=0
SOC_TOP SYNTHETIC_CAND_GEN=0 (file fact; this TB is g1g5 slice)
FIXTURE default SYNTHETIC_CAND_GEN=1 kept
BIT=NO PROGRAM=NO QHEAD=NO
U8R_REMOVE_SYNTHETIC_PRODUCTION_PASS
$finish called at time : 155 ns
```

This is a **new** run (08:09:08, snapshot `u9freeze`), not a copy of U8R `xsim.log` (07:22:09, snapshot `u8r`). TB in this bag is the same U8R TB (HASH_CROSSCHECK byte-identical `AC1EF49C…`). Expected 65/66/67 come from TB-driven `graph_id_i=65+i`, which is the production mux check, not CLASS_ID inspection.

`vivado.log` tail: `U9_FINAL_SOURCE_FREEZE_XSIM_OK`.

## Hunt

| Hunt | Result |
|---|---|
| FAIL hidden as PASS | **no.** Confirm marker in `xsim.log`. No `FIRST_DIVERGENCE`. Wrapper marker in `vivado.log`. |
| silicon / Gate14 / Q-head / NLU / OUT=653 / “LM understands TYPE_CLASS” | not claimed. `GATE14_PASS=NO` `BOARD_PASS=NO` `SEMANTIC_LM_CLAIM=NO` `CLASS=LM_CHECKPOINT_CONTEXT_MISMATCH` |
| SoC top instantiated when it was not | **not claimed.** xvlog has no `arty_a7_ng_native_v1_ab_soc_top`. |
| WDMA ACK=commit when only store XSim ran | **not this lake.** Carry-forward `SOC_WDMA_ROOT_B=SLICE_XSIM_PASS` + dest unwired OPEN_AUDIT. Matches U8-SOC-ROOTB ACCEPTANCE (re-audit PASS). soc_top `u_wdma_cdc` has **no** `m_go_ready` port connection (grep empty). |
| TB inspects CLASS_ID to pick reward | no CLASS_ID / reward path in this TB |
| Host builds learn key / host counters | `n_host_*` left open; not scored |
| CLASS_ID as LM token / first-member / NID bind as TYPE_CLASS stream | this TB/snapshot does not run bind or TYPE_CLASS chain. Residual: `a7ng_native_v1_ab_core` still instantiates `a7ng_native_ctx_bind` and feeds `ctx_pack_o` (global_id `[7:0]`) to TinyGPT. CLOSEOUT lists it as not closed. `a7ng_lm_ctx_fwd_v1` comment: does not pack CLASS_ID. P7 chain is a different DUT (`a7ng_typeclass_soc_chain`). |
| BIT/PROGRAM/QHEAD performed | no |
| History rewrite | prior U8-SOC fail retained in that bag. U9 docs commit `4ca071e` is forward, not a rewrite of `bdddbd68`. DAG/GSTACK already printed `P9 PASS` as implementer pointer; this file is the independent confirm. |

## Residuals (do not flip PASS → OVERCLAIM)

Recorded by CLOSEOUT/RESULTS and confirmed:

1. Full-SoC WDMA dest `dma_go_ready` still default 1 / unwired in soc_top. `SOC_WDMA_ROOT_B` remains slice, not silicon.
2. `native_ctx_bind` still in `ab_core`; 8-bit `global_id` pack is still the soc_top LM ctx path. Semantic class stays `LM_CHECKPOINT_CONTEXT_MISMATCH`. pred_obs P7 = 861, not HOLD_A 653.
3. TYPE_CLASS UART exam is not the soc_top path.
4. U7A reachability FAIL immutable. `persist_gen_fast` DISCONNECTED. C7 OBSERVE_ONLY.
5. U2 POST_ROUTE WNS is on pre-U8R TOP SHA `00613B8A…`, not this RTL (`0AECC1F1…`).
6. This XSim is **not** U9R full regression.
7. Manifest line-count fields 414/159 disagree with the file (415/160). Amend counts later; do not relabel the freeze.

HS13 `TC_N = 443` is a file fact in `typeclass_table.svh`. M10 TYPECLASS HOST_MODEL PASS / NID FAIL immutable matches U5Q-M10-TYPECLASS-SCALE vs U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE.

## Verdict

**PASS.** `overclaim=false` `fraud=false` `logic_bug=false`.

Production `rtl/` `constraints/` `vivado/tcl` were clean vs U8R `bdddbd68` on the captured porcelain. Key SHA256 match predecessor bags. soc_top `SYNTHETIC_CAND_GEN=0` is RTL_FACT. Confirm XSim reproduced parent IDs 65/66/67 vs fixture idle 0 with marker `U8R_REMOVE_SYNTHETIC_PRODUCTION_PASS`. MIG XCI blob SHA1 unchanged; generated XDC quarantined. No bitstream.

This PASS is a **docs/manifest freeze**, not BOARD_PASS, not GATE14_PASS, not U9R, not a PROGRAM license.

Do not auto-open U9S / U9I / U9P / U10. Do not reseat `1F0F2ABB` / `9CA2B30D` / `F24150BD` / `3A7EF204`. Do not git-add MIG or `a7lm06_wmem.hex`. Semantic LM stays `LM_CHECKPOINT_CONTEXT_MISMATCH`.

## Fix hint (not this lake; auditor does not patch)

Next DAG node is `U9R-FINAL-REGRESSION-00` only. Wire CDC `m_go_ready` to dest `dma_go_ready` is a later `SOC_TOP_EDIT` lake. `native_ctx_bind` removal from `ab_core` is not this freeze. If bag `HEAD.txt` is amended, record live `4ca071e` as the freeze-docs commit and keep `FINAL_SOURCE_COMMIT=bdddbd68` as last production RTL. Correct SOURCE_MANIFEST count 415 / tcl 160 on a docs-only pass if desired.
