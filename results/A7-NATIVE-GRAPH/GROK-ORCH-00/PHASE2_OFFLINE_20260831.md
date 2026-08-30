# Phase 2 offline (COM12 = Cursor)

CONTROL silicon frozen: SHA `439CC42D` UART `pred=664`. Do not overwrite. Do not program.

## Law (user 2026-08-31)

Old parallel bitonic Global Top-8 build is **not** reused.
New TopK on this branch = Cursor **serial** + Grok **min-heap**. Handshake must wait `busy` (multi-cycle), not 1–2 cycle merge.

## Product (unchanged)

`a7ng_cue_soa_mig_top` `u_global` = `a7ng_topk_wavefront_minheap`, `wf_cons_ready && !global_topk_busy`.
A-FAST TB already waits 4096 for `gv_count==4`.

## Fixed leftover parallel (this session)

| File | Change |
|------|--------|
| `rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv` | `u_global` min-heap; stall `wave_ready` on `!busy && !inflight && !tk_valid` |
| `tb_a7ng_native_v1_ab_mig.sv` `tb_go_h4_simfull0_00.sv` | `topk_wait` 64 → 4096 + `gv_count` |
| `tb_a7ng_ddr_wavefront.sv` `tb_a7ng_wf_global_topk_integrated.sv` | settle on `running` / merge_count, not 8/16 cycles |
| MIG / wavefront / H4 compile lists | add `a7ng_topk_wavefront_minheap.sv` |

Frozen **not** edited: `a7ng_topk.sv`, `a7ng_topk_wavefront_global.sv`.

Handshake XSim bag: `TOPK-SERIAL-MINHEAP-HS-00/` (PROGRAM=NO).

## Attempt 8 `ddr_cue_soa` MIG

`A7NG_DDR_CUE_SOA_XSIM_FAIL` DATA_MISMATCH=64. AR 832 B / 52 beats already match product A-FAST+silicon. Dedicated MIG TB preload vs PRIOR — **not** a TopK architecture fail. LOOP_STATE still OPEN on AXI liveness; SOA pattern bytes not falsified.

`graph_late_materialize_00` already XSIM_PASS. P1 soa_wavefront FF cut deferred (Cursor holds impl seat).
