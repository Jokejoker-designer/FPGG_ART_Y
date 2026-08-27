# AUDIT_XSIM — A-FAST-LM-BOARD-LANE-00

**Auditor:** `a7-ng-xsim-verify` (VERIFY_ONLY)  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Date:** 2026-08-24  
**Evidence class:** `XSIM_FAST_CAUSAL` / `PASS_NARROW`  
**Verdict:** **PASS**

---

## Scope

Confirm preregistered XSim fast-causal lane: SOA-fed Top-8 → ctx capture → LM forward → `pred=664`, without TB injection of bind/pred/winner, using `SIM_FULL=1`, AXI behavioral stub, and backdoor wmem only.

## Artifacts inspected

| Artifact | Path |
|----------|------|
| Testbench | `tests/xsim/tb_a7ng_native_v1_ab_fast.sv` |
| Run script | `tests/xsim/run_a7ng_native_v1_ab_fast.tcl` |
| Live log | `tests/xsim/xsim.log` |
| Archived log | `results/A7-NATIVE-GRAPH/A-FAST-LM-BOARD-LANE-00/xsim_fast.log` |
| RTL fix | `rtl/native_graph/memory/a7ng_cue_soa_wavefront.sv` |
| Preregister | `results/A7-NATIVE-GRAPH/A-FAST-LM-BOARD-LANE-00/PREREGISTER.md` |

## Log markers (primary: `tests/xsim/xsim.log`)

| Check | Expected | Observed | Status |
|-------|----------|----------|--------|
| Pass marker | `A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664` | line 731 | **PASS** |
| SOA pattern | `SOA_PATTERN_PASS burst=16 out=8` | line 36 | **PASS** |
| Data integrity | `SOA_DATA_MISMATCH=0` | line 37 | **PASS** |
| Capture | `CAPTURE_OK pack=3b392b291b190b09` | line 49 | **PASS** |
| Fail markers | none | none (`FAIL`/`ERROR` absent) | **PASS** |
| Sim exit | `$finish` at tb line 439 | line 732, elapsed ~6m40s | **PASS** |

Archived `xsim_fast.log` contains the same pass marker and SOA/CAPTURE markers (lines 22–23, 35, 717).

## SOA phase detail

```
SOA_DELTA axi_read_bytes=832 axi_read_beats=52 bursts=4 gv=4 topk_updates=4
SOA_PLANE id=16 cue=32 prior=4 delivered=64 waves=4
SOA_TOP1 id=9 score=165 (expect id=9 score=165)
SOA_GLOBAL_TOP8[0..7] id=9,11,25,27,41,43,57,59 score=165 (all match preregister)
NEG_CHECK pred=0 start_fwd_beats=0 do_lm=0   (pre-LM isolation)
```

832 bytes / 52 beats / 4 gv batches match preregister `SOA_BYTES_PER_QUERY` / burst=16 / outstanding=8.

## Structural TB checks (no Top-8 / bind / pred injection)

| Requirement | Evidence |
|-------------|----------|
| `SIM_FULL=1` | DUT instantiated `#(.SIM_FULL(1'b1), ...)` (tb line 108) |
| AXI stub, no MIG/DDR3 | `a7ng_axi_soa_mem_stub u_mem` (tb line 55); not in xvlog src list |
| Backdoor wmem only | `$readmemh("a7lm06_wmem.hex", dut.u_core.u_w.FULL.u_full.mem)` before release (tb line 294); `LM06_WMEM_BACKDOOR_DONE` in log |
| TB does not drive bind/pred/topk | `bind_done_o(bind_done)`, `pred_o(pred)`, `topk_id_o(topk_id)` are **inputs to TB** (observed only). No assignments to `pred`, `bind_done`, or `topk_id[*]` from TB. Log prints `STRUCTURAL TB_DOES_NOT_DRIVE_BIND_OR_TOP8_INJECTION` |
| Host authority zero at compare | Pass branch requires `dual_ticks === 0 && mem_we_exam === 0 && st_beats === 32'd1` before emitting pass (tb lines 434–435); pass printed → all satisfied |
| LM enable is causal, not cheat | `do_lm=1` asserted only after SOA_PATTERN_PASS + NEG_CHECK + CAPTURE_OK (tb lines 385–414) |

TB **does** assert `do_lm`, `start`, `poison`/`poison_id`, and SOA plane preload via stub `poke128` — all preregister-allowed stimulus, not winner/pred injection.

## RTL fix — field-split rec0/rec1 (`a7ng_cue_soa_wavefront.sv`)

**Problem (documented):** 128b distributed-RAM wave pack caused rec0 node-id lag `(pi-1)` in XSim.

**Fix:** Separate per-field ping-pong banks:

```systemverilog
logic [31:0] r0_nid [WAVE]; logic [63:0] r0_cue [WAVE]; logic [7:0] r0_prior [WAVE];
logic [31:0] r1_nid [WAVE]; logic [63:0] r1_cue [WAVE]; logic [7:0] r1_prior [WAVE];
```

Fill alternates `r0_*` / `r1_*` on SOA_DRAIN pack (lines 424–445); drain mux selects bank via `drain_sel` (lines 197–204). Post-fix log shows `SOA_DATA_MISMATCH=0` and correct global Top-8 ids — fix is **causally consistent** with pass.

## Run script hygiene

`run_a7ng_native_v1_ab_fast.tcl`:

- Compiles full native_graph + LM06 stack + stub + tb
- Archives sim stdout to `results/.../xsim_fast.log`
- Exits non-zero unless `*A_FAST_LM_BOARD_LANE_XSIM_PASS*` present

## Falsifiers (preregister) — not triggered

- TB driving bind GID / pred / winner directly → **not observed**
- `pred != 664` with `bind_done=1` → **not observed** (`pred=664`, pass emitted)
- `mem_we` during exam → **not observed** (`mem_we_exam === 0` required for pass)
- `dual_owner_err=1` → **not observed** (`dual_ticks === 0` required)
- `SIM_FULL=0` → **not observed**

## Limitations (explicit)

- **XSim only** — not board/MIG PHY/bitstream evidence.
- **PASS_NARROW** — single preregistered query/cue set, 64 candidates, one wmem hex bag.
- LM phase ran ~18.2M sim cycles (heartbeat lines in log); wall time ~6m40s on logged host.

---

## Verdict

**PASS** — All preregistered XSim markers confirmed. SOA plane, capture pack, and LM forward `pred=664` are evidenced without TB forcing Top-8/bind/pred. Field-split rec0/rec1 wavefront fix is present and consistent with zero SOA data mismatch.
