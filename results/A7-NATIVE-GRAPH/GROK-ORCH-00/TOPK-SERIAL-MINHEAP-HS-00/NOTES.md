# TOPK-SERIAL-MINHEAP-HS-00

PROGRAM=NO. COM12=Cursor. CONTROL silicon SHA `439CC42D` frozen. Do not program.

Old parallel bitonic Global Top-8 (1–2 cycle merge) is **not** reused.
New branch law: Cursor serial + Grok min-heap (`HEAP_CMP_LANES=1`, busy until ordered commit).

## Product (already)

`a7ng_cue_soa_mig_top` `u_global` = min-heap, `wf_cons_ready && !global_topk_busy`.

## Fixed this gate

| Item | Old (parallel leftover) | Now |
|------|-------------------------|-----|
| `a7ng_ddr_wavefront_top` `u_global` | bitonic, `busy_o()` open | min-heap, stall `wave_ready` on busy/inflight |
| A-FAST MIG / H4 `topk_wait` | 64 | 4096 + `gv_count` |
| Integrated / ddr_wavefront settle | 16 / 8 cycles | wait `running` / merge_count |
| compile lists | missing minheap.sv | added |

Frozen files **not** edited: `a7ng_topk.sv`, `a7ng_topk_wavefront_global.sv`.
`tb_a7ng_wf_global_topk.sv` still tests the frozen bitonic unit.

## Attempt 8 ddr_cue_soa MIG

`A7NG_DDR_CUE_SOA_XSIM_FAIL` DATA_MISMATCH=64. Bytes/beats 832/52 already match product. Separate from this handshake gate.

## XSim (2026-08-31, PROGRAM=NO)

`TOPK_MINHEAP_BUSY_HS_XSIM_PASS fails=0`

- stall-producer: merges=4 gv=4 busy=0, 82 cycles after last fire
- parallel-fire-drop: merges=1 — old bitonic 1–2 cycle fire **FALSIFIED** for min-heap
- `DDR_WAVEFRONT_MINHEAP_XELAB_OK`

`a7ng_ddr_wavefront_top.sv` SHA256 `4A16B07A3F9487057EFA7D3FF1B77416685693E350727E31F4525156A2F0D564`
minheap SHA256 still `C197E419…` (untouched).
