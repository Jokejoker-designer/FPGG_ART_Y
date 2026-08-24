# CS249r / MLSysBook × Native AI — bottleneck map (K-Dense method)

**Sources:** https://github.com/harvard-edge/cs249r_book · https://mlsysbook.ai  
**Skills:** hypothesis-generation, experimental-design, scientific-critical-thinking  
**Live gate:** `LOOP_STATE.next = ddr_cue_soa_00r_axi_liveness` (FAIL `B_RREADY_DEADLOCK`)  
**Not:** Native V1 BOARD_PASS. Book principles ≠ new architecture; they **confirm** Masterplan V2.

Observation ≠ prescription. Rival hypotheses stay labeled.

---

## 1. What the book actually teaches (transferable)

**Iron Law** (Vol I Ch.11 / Vol II performance): end-to-end time splits into **data/BW + compute/throughput + fixed latency**. Adding MAC when the **data term dominates** does not move the needle.

**Roofline / arithmetic intensity** = ops per byte moved. Ridge = peak_compute / peak_BW. Below ridge = **memory-bound**; more PEs starve.

**INT8** helps *both* roofs: denser MAC *and* fewer bytes/op — only if the datapath is built for it (already true for Hamming/SignSGD INT8).

**Transformer serving:** **KV/activation working set** dominates on-chip memory, not the frozen weight file in DRAM.

**Systems-first:** start from silicon constraints, co-design; measure (Benchmarking ch.) before swapping algorithms (HNSW, extra PE).

**TinyML kits:** SRAM/scratch first, then flash/DRAM; never pretend DRAM is a register file.

These are **physics + measurement**. They do not authorize host winners (HS-01) or Arduino as the Arty product.

---

## 2. Frozen Native observations (not interpretation)

| Bottleneck | Evidence class | Rival “book-shaped” misread |
|------------|----------------|------------------------------|
| BRAM 135 vs naive 243–260 | POST_ROUTE FALSIFIED stack | “Need bigger FPGA” as first move |
| LM-06 132 = u_w/u_a/u_snap | POST_ROUTE | “802k weights in BRAM” |
| DDR seq 1.166 GB/s (LM-01) | BOARD | Treat as graph random BW |
| Graph `memory_wait` ~0.8–1.0 | MIG_XSIM_WAVEFRONT | “Ping-pong already hides DDR” |
| SOA 00R AXI hang `0x03000030` | MIG_XSIM FAIL | “SoA layout is falsified” |
| TinyGPT+UA 260>135 | FIT_LIMIT | Stack more cores |
| Encoder `M_L1<0` | SILICON | HNSW on those cues |
| HS-02 exam | NOT_EVIDENCED | UART stub = teacher-off |

---

## 3. Roofline on *this* chip (estimate, labeled)

Ridge (order-of-magnitude): if 16 Hamming PEs at 100 MHz do ~O(1) op per 8-byte cue, intensity ≪ 1 op/byte.  
DDR ~1.17e9 B/s → **memory-bound**. Textbook implication: **do not add PE**; **cut bytes/query** (SoA cue plane, survivor metadata, reuse).

LM GEMM tiles can sit nearer the ridge *if* a weight tile is reused across activations — that is why ping-pong exists. Graph 1-wide NodeRecord fetch cannot.

---

## 4. Ranked unblock (one unknown each) — “optimal” under evidence

**P0 — live LOOP (do not skip)**  
`ddr_cue_soa_00r_axi_liveness`: fix `B_RREADY_DEADLOCK` / duplicate AR.  
Book analog: a memory-bound kernel that **deadlocks** is not a roofline problem; it is a **protocol** problem. SOA **not** falsified until a live read stream finishes.

**P1 — raise arithmetic intensity (graph)**  
After AXI lives: SoA cue plane (2×64-bit cues / 128-bit beat) → 16-PE wave → metadata only for Top-K survivors.  
This is the book’s “fusion / don’t write intermediates to HBM” applied to DDR3L.  
Gate: bytes/query ↓, Top-1 **same as control**, mismatch=0. `lane_util≥80%` is **not** the DDR gate.

**P1′ — LM working set (separate unknown)**  
`lm06_wm_00` already PASS_NARROW **functional exact**, **not** BRAM-down. Next human: timed stall-allowed WM, then ladder + `report_ram_utilization`.  
Book: KV/act tiles are the on-chip term; shrinking them is independent of 802k DDR capacity.

**P2 — phase owner (after WM exact+timed)**  
GRAPH drain → LM drain, one writer/bank. Not concurrent u_a share (FALSIFIED).

**P2′ — TinyGPT on same bit**  
Only **after** LM is the sole 132-BRAM owner (no UA128). Book: don’t instantiate two working sets that both want SRAM.

**Not next:** more PE, HNSW (algorithm swap before bytes/query measured at 01R scale), zero-BRAM, ILA-as-training-scope, encoder glue, TRAIN-V2+index insert.

---

## 5. What CS249r does *not* solve

- Artix-7 **135 BRAM** physics  
- Native **HS-01** (host must not send winners)  
- Current **AXI hang** (must be measured on *this* MIG model)  
- Encoder **margin** (representation law, not TinyML compression)

INT8 is **already** the book’s precision move. Further quantization does not free `u_a` 66 tiles.

---

## 6. Optimal sentence for Cursor

Keep LOOP on **AXI liveness**. After PASS, one unknown: **SoA bytes/query vs control Top-1**. Then LM tile **P&R**, not more MAC. CS249r’s Iron Law says the same: **the data term is binding; compute is not the first lever.**
