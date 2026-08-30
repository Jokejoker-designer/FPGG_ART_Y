# SLICE-OPT-00 — UART/CDC slim to free slices (pred=664 law frozen)

**Date:** 2026-08-30  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**Authority:** resource-architecture, READ-ONLY except this file.  
**Next bag (not this file):** `results/A7-NATIVE-GRAPH/GROK-ORCH-00/SLICE-OPT-BIT-00/`  
**PROGRAM:** **NO**. COM12 not armed. Do not write a program TCL that opens `open_hw_manager`.

---

## 0. Control (do not overwrite, do not delete)

| Field | Value |
|-------|--------|
| Control bag | `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GLOBAL-TOPK-MINHEAP-BIT-01/` |
| Bit | `arty_a7_ng_native_v1_grok_orch_minheap_01.bit` |
| SHA256 | `439CC42D9BA0B3780C384C47E6E7F0A886269929E3ED3667471F064A8A222A8D` |
| UART law | `NATIVE_V1_EXIST_ROW,pred=664` `POISON=0` `PACK=TOPK=3B392B291B190B09` |
| Design state | Physopt postRoute, `xc7a100tcsg324-1` |
| WNS / TNS | +0.416 / 0 @ 12.5 MHz (80 ns) |

**Never overwrite** `minheap_01.bit`. New bitstream (when a later worker builds) lands only in `SLICE-OPT-BIT-00/`.

Source SHA freeze from BIT-01 (P0 may change **TOP only**):

| File | SHA256 | P0 |
|------|--------|----|
| `rtl/board/a7ng_wdma_cdc.sv` | `5AF2FBDA5E9D2E0F1527BD9E89D6935CDC7722BD775DCE0870683C215A06539D` | **lock** |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` | `EA82899B3117F0AE63CFFF1B21B54D9C26E8B8F7263808728363E0028ECD02AC` | **edit (new SHA)** |
| `rtl/lm/tiny_gpt803k_core.sv` | `29D230FCC23247F49DD58E081607314C1CC4F8C8B4ECBD422E2FA75412290C9E` | **lock** |
| `rtl/native_graph/lm/a7ng_native_ctx_bind.sv` | `C5F57AD1F0A81BB998234BC885EACA5EC7A4F19279E1EDBFDC5DADE163FC94CC` | **lock** |
| `rtl/lm/weight_tile803k.sv` | `06F62A3A71E00B2A8F8B6D7277488544ABD1556B03F6FE88165E24EC6A4CB430` | **lock** |
| `rtl/native_graph/memory/a7ng_cue_soa_mig_top.sv` | `4DBA8E7881521DD2401E6833FE72B9F1B0AEE1DB803612B86970B48E24A27602` | **lock** |
| `rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv` | `C197E41948716BEFCD50ABBC558BCEE09CE63BAA1AD61DBC0AF070AEE224DDC0` | **lock** |

`.poison_i(1'b0)` stays. Do not edit `a7ng_topk.sv`, minheap law, `tiny_gpt803k_core.sv`, scorer, termgen, MIG `mig.prj`, bind.

---

## 1. What is actually full (FACT, post-route)

Device `xc7a100tcsg324-1` — BIT-01 `report_utilization_route.rpt`:

| Resource | Used | Avail | Util |
|----------|-----:|------:|-----:|
| **Slice** | **15850** | **15850** | **100%** |
| Slice LUT | 51361 | 63400 | 81.01% |
| LUT as Logic | 48617 | 63400 | 76.68% |
| LUT as Memory | 2744 | 19000 | 14.44% |
| FF | 57912 | 126800 | 45.67% |
| RAMB36 | 103 | 135 | 76.30% |
| DSP48E1 | 19 | 240 | 7.92% |
| Unique control sets | 2499 | 15850 | 15.77% |
| F7 / F8 mux | 5184 / 1774 | | |

Packing (same report, §2 Slice Logic Distribution):

```text
Register driven from within the Slice     12780
Register driven from outside the Slice    45132
  LUT in front of the register is unused  17740
  LUT in front of the register is used    27392
```

**Diagnosis:** LUT 81% is not the ceiling. **Every slice is occupied.** 45132 FF sit outside their LUT; 17740 of those have a dead LUT in front. That is packing waste (control sets + `ASYNC_REG` 2-FF CDC chains + UART unique-case CE), not extra algorithm.

BIT-00 = **same RTL**, no `opt_design -control_set_merge` → synth LUT 59238 (93.44%), unique CE **2565**, Place **30-487** (CLASSIFICATION: 13446 slices needed / 13012 available at fail), **NO_BIT**. BIT-01 needed `opt_design -control_set_merge -sweep -propconst` to close place. P0 must shrink the **debug CDC+UART** so the next bag is not one packing-directive away from 30-487.

---

## 2. Classification of every major block

Classes:

- **ALGORITHM** — do not touch this gate. Required for `pred=664` / `PACK=TOPK=3B392B291B190B09` / `poison_i=0` / MIG+WDMA grant.
- **JUNK** — safe to slim/delete without changing that law. Observe-only UART, ATOM hex, F1* probe CDC.
- **HYBRID** — contains real query datapath **and** oversized telemetry. Not P0. Later one-unknown only.

LUT/FF from BIT-01 `report_utilization_route_hier.rpt` (Physopt postRoute). Hier LUT can include cross-hierarchy combining; treat as **order-of-magnitude**, not a DSE score.

### 2.1 ALGORITHM (do not touch)

| Instance | Module | LUT | FF | BRAM | DSP | Why frozen |
|----------|--------|----:|---:|-----:|----:|------------|
| `u_ab/u_core` | `tiny_gpt803k_core` | 18690 | 25152 | 96 | 19 | LM path; pred decimal |
| `u_ab/u_soa/u_tg` | `a7ng_termgen_array` 16×~657 | 10522 | 7585 | 0 | 0 | 16-lane termgen |
| `u_ab/u_soa/u_core/u_scorer` | `a7ng_scorer_array` 16 lane | 8732 | 1792 | 0 | 0 | 16-lane scorer |
| `u_ab/u_soa/u_core/u_frontier` | `a7ng_frontier_buckets` | 269 | 64 | 0 | 0 | NG-02 frontier |
| `u_ab/u_soa/u_core/u_topk` | `a7ng_topk` stub | 4 | 385 | 0 | 0 | leftover bitonic stub; **do not edit `a7ng_topk.sv`** |
| `u_ab/u_soa/u_global` | `a7ng_topk_wavefront_minheap` | **2760** | 1324 | 0 | 0 | minheap law |
| `u_ab/u_bind` | `a7ng_native_ctx_bind` | 33 | 103 | 0 | 0 | bind / `ctx_pack` |
| `u_ab/u_soa/u_br` | `a7ng_ddr_soa_axi_bridge` | 160 | 529 | 0 | 0 | SOA AXI |
| `u_mig` | `mig_native_wrap` | 4844 | 4027 | 0 | 0 | official Digilent AXI MIG |
| `u_axi_cdc` | `a7ng_axi_read_cdc` | 118 | 351 | 2 | 0 | functional AR/R CDC |
| `u_wdma` | `ddr_tile_dma` | 144 | 79 | 0 | 0 | tile DMA |
| `u_wdma_cdc` | `a7ng_wdma_cdc` | 187 | 631 | 5 | 0 | functional WDMA CDC |
| `u_boot` | `a7ng_ddr_soa_boot` | 638 | 190 | 0 | 0 | SOA DDR boot |
| `u_wmem_boot` | `a7ng_ddr_wmem_boot` | 169 | 361 | 0 | 0 | WMEM boot |
| `u_boot_core_sync` | `sync_bits` WIDTH=3 | (flat) | | | | `wmem_done/boot_done/calib` → `core_rst_n` |
| `u_b0_166` | `sync_bits` WIDTH=1 | (flat) | | | | MIG btn reset |
| `u_wdma_rel_sync` | `sync_bits` WIDTH=3 | (flat) | | | | **grant law** (`cmd_empty`, DMA idle, AR quiet) |

Grant-path taps that look like F1 debug but are **ALGORITHM** (do not unplug):

| Signal | Use |
|--------|-----|
| `dbg_tile_miss` | `wdma_owner_grant` set: `(wdma_owner \|\| dbg_tile_miss) && !soa_running` |
| `wdma_dbg_st` | `wdma_dma_idle_ui = (wdma_dbg_st == 3'd0)` |
| `wdma_owner`, `wdma_owner_grant`, `r_path_idle` | grant hold/release |
| `wdma_cmd_empty_ui`, `wdma_arr_quiet_ui` | grant release |
| `.poison_i(1'b0)` | H2 pack law |

Keep CDC: `u_h2_pack_sync` (64), `u_h2_topk_sync` (64), `u_h2_poison_sync` (1), slim `u_stat_sync` for `pred[9:0]`, slim CORE_DONE bit, `u_wmem_sync`, `u_tx`.

Algorithm LUT envelope (sum of frozen hier rows, not a new claim):

```text
tiny_gpt 18690 + termgen 10522 + ng02_core 9007 + minheap 2760
+ bind 33 + soa_bridge 160 + MIG 4844 + axi_cdc 118
+ wdma 144 + wdma_cdc 187 + boot 638 + wmem_boot 169
+ wavefront LUT 2954 (HYBRID body, still frozen in P0)
≈ 50.2k LUT of 51.4k chip
```

P0 cannot and must not hunt LUT inside that 50k.

### 2.2 JUNK (P0 target)

Observe-only. Deleting them cannot change TinyGPT / 16-lane termgen / 16-lane scorer / minheap / MIG / bind / `poison_i=0`.

#### UART 70-heartbeat unique-case (keep 7)

`hb_char` / `hb_len` / `hb_next` / `have_pending` / `sent_mask[70:0]` in `arty_a7_ng_native_v1_ab_soc_top.sv`. BIT-01 UART dump is 70 lines; law is four tokens. The other 63 lines are E2R F1* archaeology.

**KEEP ASCII (do not rename — capture scripts match these bytes):**

| sel | Line |
|----:|------|
| 0 | `BOOT` |
| 2 | `WMEM_OK` |
| 32 | `TOPK=3B392B291B190B09` |
| 34 | `PACK=3B392B291B190B09` |
| 35 | `POISON=0` |
| 54 | `CORE_DONE` |
| 55 | `NATIVE_V1_EXIST_ROW,pred=664` |

**DROP sel 1,3–31,33,36–53,56–70** (MIG_OK, SOA_OK, CORE_START, OWNER_RDY, Q_GO, SOA_RUN, AR/R ladder, D3/E1/E3, F1g–F1B2, ATOM0/ATOM1, W_STALL, PHASE, PRED_NZ, ACCEPT, FWD, LM, BIND_BUSY, …).

`sent_mask` shrinks 71 → 7. `msg_sel` can go back to 3 bits. Nested `unique case` of ~64 constant strings + hex nibble muxes is the UART LUT/F7 farm (hier often **combines** those LUTs into `u_atom*_sync` / `u_h2_*` rows — that is why a WIDTH=32 `sync_bits` shows 71 LUT).

#### ATOM0/ATOM1 32-bit CDC

| Instance | WIDTH | Hier LUT | Hier FF | Signals |
|----------|------:|---------:|--------:|---------|
| `u_atom0_sync` | 32 | 71 | 64 | `atom0_q` |
| `u_atom1_sync` | 32 | 55 | 64 | `atom1_q` |
| `u_atom_flag_sync` | 3 | 70 | 6 | `atom_giveup`, `atom1_valid`, `atom0_valid` |
| `u_atom_sdone_latch_core` | 1 | flat | | `latched_sdone_f1t` |
| `u_atom_sdone_sticky_core` | 1 | flat | | `wdma_dbg_sdone` |

Plus core FSM `atom_st` / `atom_now` / `AST_IDLE|HAVE0|DONE`. Probe-only (comment: `E2R-ATOMIC-SDONE-PROBE-00`). UART `ATOM0=0000059C` / `ATOM1=0000059D` is not the 664 law.

#### F1L–F1V (+ F1B2, F1g, F1j, D3, E1, E3) probe CDC farm

All `sync_bits` WIDTH 1..8 in the SoC top whose only sink is UART / Pmod JA / ATOM. ~40 instances. Named in hier: `u_f1n_phase_sync` 64 LUT / 16 FF; the rest flattened into the ~226 LUT gap (chip 51361 − named children ≈ 226).

#### `u_stat_sync` WIDTH=47 vs 32

```sv
sync_bits #(.WIDTH(47)) u_stat_sync (
  .async_in({axi_bytes[18:0], pred, sticky_bind, boot_done_core, calib_core}),
  .sync_out({axi_b_100[18:0], pred_100, bind_100, boot_100, calib_100})
);
```

Concat is **32 bits** (`19 + 10 + 1 + 1 + 1`). WIDTH=47 zero-extends **15 constant bits** of `ASYNC_REG` 2-FF. `axi_bytes[18:0]` is then only `unused_tie`. P0: WIDTH = `pred[9:0] + sticky_bind + sticky_core_done` (11). **Do not unconnect** `axi_read_bytes_o` at `u_ab` (would DCE SOA counters — second unknown).

#### Other junk on top

| Item | Note |
|------|------|
| Pmod JA `ja_q[7:0]` `(* IOB="TRUE" *)` | feeds `sgo_lat_100`, `w_stall_100`, … — F1 observe. Tie `ja_q <= 8'd0` or KEEP-only (`core_live`, `bind`). |
| `(* DONT_TOUCH = "TRUE" *) sticky_cdc_sarv/sarr/sarf/hold` | packing poison for E3 UART. Delete with E3. |
| `u_lm_sync` | `LM` heartbeat only |
| `u_led_sync` WIDTH=4 | optional; LEDs can reuse KEEP-synced bits |
| ui sticky always_ff (E1/E3/F1j/F1r latches) | probe-only once UART drops them |
| core sticky F1l–F1v latches | probe-only; see §5 |

### 2.3 HYBRID (not P0)

| Instance | LUT | FF | Split |
|----------|----:|---:|-------|
| `u_ab/u_soa/u_soa` `a7ng_cue_soa_wavefront` | **2954** | **14249** | body 2696 LUT / 10068 FF; `u_pf` plane 258 LUT / **4181** FF |

Wave records (16×128b) + 3-plane fetch are **ALGORITHM**. The 32-bit telemetry (`cycles_o`, `waves_o`, `cand_*`, `bytes_*`, stall counters, …) is junk-adjacent. **Do not prune wavefront in P0.** Later gate, one unknown, after P0 BIT_OK.

`u_post_sync` WIDTH=12 (77 LUT / 24 FF) is HYBRID: keep `sticky_topk`, `sticky_pack`; drop the other 10 bits in P0 (that slice of this instance **is** P0 junk).

`u_h2_pack_sync` 139 LUT / 128 FF and `u_h2_topk_sync` 181 LUT / 128 FF are **KEEP** (law UART). Do not slim WIDTH.

---

## 3. Junk vs algorithm LUT table (P0 ledger)

| Class | Block | LUT (hier) | FF (hier) | P0 action |
|-------|--------|-----------:|----------:|-----------|
| ALGORITHM | TinyGPT | 18690 | 25152 | freeze |
| ALGORITHM | 16-lane termgen | 10522 | 7585 | freeze |
| ALGORITHM | ng02_core (scorer 8732 + frontier 269 + stub 4) | 9007 | 2278 | freeze |
| ALGORITHM | minheap `u_global` | 2760 | 1324 | freeze |
| ALGORITHM | bind | 33 | 103 | freeze |
| ALGORITHM | SOA AXI bridge | 160 | 529 | freeze |
| ALGORITHM | MIG | 4844 | 4027 | freeze |
| ALGORITHM | axi_cdc + wdma + wdma_cdc | 449 | 1061 | freeze |
| ALGORITHM | boot + wmem_boot | 807 | 551 | freeze |
| ALGORITHM | grant CDC (`u_wdma_rel_sync`, `u_boot_core_sync`, `u_b0_166`) | flat | | freeze |
| HYBRID | soa_wavefront (+ plane) | 2954 | **14249** | freeze this gate |
| KEEP (law UART) | `u_h2_topk_sync` + `u_h2_pack_sync` + `u_h2_poison_sync` | 181+139+flat | 128+128+2 | keep WIDTH |
| KEEP | `u_tx` | 98 | 23 | keep engine; slim ROM |
| JUNK | ATOM0/1/flag CDC | 71+55+70 = **196** | 64+64+6 = **134** | delete |
| JUNK | `u_f1n_phase_sync` | 64 | 16 | delete |
| JUNK | flattened F1*/D3/E1/E3/F1g/F1j/ATOM-core CDC (~35 inst) | **~226** gap | (ASYNC_REG 2×WIDTH) | delete |
| JUNK | `u_stat_sync` extra 15+19 bits | part of 85 | part of 24 | slim 47→11 |
| JUNK | `u_post_sync` 10 of 12 bits | part of 77 | part of 24 | slim 12→2 |
| JUNK | UART unique-case sel 1,3–31,33,36–70 | combined into rows above + F7/F8 | `sent_mask[70:0]` | drop 64 messages |
| JUNK | Pmod JA IOB | ~0 logic | 8 | tie 0 |

**P0 expected mechanism:** fewer `ASYNC_REG` 2-FF chains + fewer unique CEs + a 7-way UART ROM instead of 71-way → **slices free**, even if raw LUT only drops ~0.5–1.5 k. Do not score P0 as “LUT 81→75”. Score P0 as:

```text
Slice used < 15850   (headroom, not 100%)
WNS ≥ 0  TNS = 0
Unique CE ≤ BIT-01 2499  (expect drop)
SOURCE SHA: all ALGORITHM files MATCH BIT-01
UART KEEP tokens MATCH control law
PROGRAM=NO
```

---

## 4. Ordered one-unknown gates

One RTL/impl unknown per bag. Do not merge P0 with wavefront FF prune, TinyGPT BRAM, scorer lane-cut, or QoR directives as the **question**.

### P0 — `UART_SLIM` (this plan; next worker = `SLICE-OPT-BIT-00`)

**Unknown:** does deleting observe-only UART + F1*/ATOM CDC in **`arty_a7_ng_native_v1_ab_soc_top.sv` only** free slices while the KEEP UART tokens still encode the BIT-01 law?

Keep UART: `BOOT` / `WMEM_OK` / `POISON=` / `TOPK=` / `PACK=` / `NATIVE_V1_EXIST_ROW,pred=` / `CORE_DONE`.

Drop ATOM hex and F1* probes.

Reuse BIT-01 impl recipe (`opt_design -control_set_merge` allowed as **packing**, not as the unknown). New bit path only under `SLICE-OPT-BIT-00/`. PROGRAM=NO.

### P1 — optional remaining debug CE (only if P0 still 100% slice or 30-487)

**Unknown:** after P0 RTL, do leftover debug CEs still dominate packing?

Allowed: merge remaining debug CE (`opt_design -control_set_merge` already in recipe; optionally share one `rst_n`/`CE` on leftover KEEP CDC). **Not** allowed: edit minheap / TinyGPT / scorer / termgen. Do not start P1 until P0 post-route numbers exist.

### Explicitly not a gate here

| Idea | Why not |
|------|---------|
| Ungated DIFF / EAM H5 | Encoder lane; unrelated |
| Wavefront 14k FF telemetry trim | HYBRID; second unknown |
| `a7ng_topk.sv` / minheap comparator | law |
| Lane-cut scorer/termgen | algorithm |
| `ram_style` on line buffers | topology change, no evidence |
| Overwrite BIT-01 | forbidden |

---

## 5. P0 patch list — signal names to gate off

**File (only):** `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv`  
**Do not edit:** `a7ng_topk.sv`, `a7ng_topk_wavefront_minheap.sv`, `tiny_gpt803k_core.sv`, scorer/termgen, `a7ng_wdma_cdc.sv`, `ddr_tile_dma.sv`, MIG, bind, `a7ng_cue_soa_mig_top.sv`.

If a listed signal is an **output** of a frozen child, stop **sampling/syncing/printing** it. Leave the child port connected or open as today; do not SHA-drift child files. Exception: do **not** stop using grant-path taps in §2.1.

### 5.1 Delete these `sync_bits` instances (gate off)

| Instance | WIDTH | `async_in` signals to stop crossing |
|----------|------:|-------------------------------------|
| `u_atom0_sync` | 32 | `atom0_q` |
| `u_atom1_sync` | 32 | `atom1_q` |
| `u_atom_flag_sync` | 3 | `atom_giveup`, `atom1_valid`, `atom0_valid` |
| `u_atom_sdone_latch_core` | 1 | `latched_sdone_f1t` |
| `u_atom_sdone_sticky_core` | 1 | `wdma_dbg_sdone` |
| `u_f1m_probe_sync` | 3 | `sticky_core_busy`, `sticky_wdma_done`, `sticky_wdma_busy` |
| `u_f1n_wstall_sync` | 1 | `sticky_w_stall` |
| `u_f1n_phase_valid_sync` | 1 | `sticky_core_busy` |
| `u_f1n_phase_sync` | 8 | `latched_phase` |
| `u_f1o_tile_miss_sync` | 1 | `sticky_tile_miss` |
| `u_f1o_tile_dst_valid_sync` | 1 | `sticky_core_busy` |
| `u_f1o_tile_dst_sync` | 3 | `latched_tile_dst` |
| `u_f1p_tile_bst_valid_sync` | 1 | `sticky_core_busy` |
| `u_f1p_tile_bst_sync` | 4 | `latched_tile_bst` |
| `u_f1q_tile_req_valid_sync` | 1 | `sticky_core_busy` |
| `u_f1q_tile_dma_sync` | 3 | `latched_tile_dma_own`, `latched_tile_dma_busy`, `latched_tile_req` |
| `u_f1r_dma_src_sync` | 3 | `latched_wdma_owner_ui`, `latched_wdma_busy_f1r`, `latched_s_dma_busy` |
| `u_f1t_done_probe_sync` | 3 | `latched_busy_hold_f1t`, `latched_mdone_f1t`, `latched_sdone_f1t` |
| `u_f1u_fsm_probe_sync` | 4 | `latched_sgo_f1u`, `latched_dma_st_f1u` |
| `u_f1v_owner_grant_sync` | 4 | `latched_mgo_f1v`, `latched_rpath_idle_f1v`, `latched_wdma_grant_f1v`, `latched_wdma_own_f1v` |
| `u_f1b2_cmd_probe_sync` | 5 | `wdma_dbg_cmd_rd`, `wdma_dbg_cmd_empty_mgo`, `wdma_dbg_cmd_st[1:0]`, `wdma_dbg_sbusy_pend` |
| `u_f1j_ar_fifo_ne_sync` | 1 | `sticky_ar_fifo_ne` |
| `u_core_rst_100_sync` | 1 | `core_rst_n_q` (F1g `M_RST_LO`) |
| `u_ui_rst_100_sync` | 1 | `ui_rst_n_q` (F1g `S_RST_LO`) |
| `u_core_busy_ui_sync` | 1 | `core_busy` (only used to latch F1r/F1t/F1u) |
| `u_qgo_ui_sync` | 1 | `sticky_qgo` (only used to arm ui probe stickies) |
| `u_d3_sync` | 7 | `sticky_cdc_ne`, `sticky_migrv`, `sticky_outst`, `sticky_rid_bad`, `sticky_rid_ok`, `sticky_rready1`, `sticky_rvseen` |
| `u_e1_sync` | 4 | `sticky_muxcdc`, `sticky_cdcar`, `sticky_ownwdma`, `sticky_migar` |
| `u_e3_marf_sync` | 1 | `sticky_cdc_marf` |
| `u_e3_sync` | 4 | `sticky_cdc_hold`, `sticky_cdc_sarf`, `sticky_cdc_sarr`, `sticky_cdc_sarv` |
| `u_lm_sync` | 1 | `sticky_lm` |

`u_f1l_probe_sync` WIDTH=3 `{sticky_core_done, sticky_pred_nz, sticky_bind_busy}` → **replace with WIDTH=1** `sticky_core_done` → `core_done_100` (KEEP `CORE_DONE`). Drop `pred_nz_100`, `bind_busy_100`.

### 5.2 Slim, do not delete

| Instance | Now | P0 |
|----------|-----|----|
| `u_stat_sync` | WIDTH=47 `{axi_bytes[18:0], pred, sticky_bind, boot_done_core, calib_core}` | WIDTH=11 `{pred[9:0], sticky_bind}` **or** `{pred[9:0], sticky_core_done}` if bind is already in another KEEP CDC. `axi_b_100` / `boot_100` / `calib_100` UART-only → drop. Keep local `axi_bytes` wire for `unused_tie` so SOA counters do not DCE. |
| `u_post_sync` | WIDTH=12 `{sticky_fwd, sticky_pack, sticky_accept, sticky_topk, sticky_soaq, sticky_ridle, sticky_rbusy, sticky_rbeat, sticky_ar, sticky_soarun, sticky_qgo, sticky_owner}` | WIDTH=2 `{sticky_pack, sticky_topk}` |
| `u_led_sync` | WIDTH=4 | delete or drive LEDs from KEEP-synced `wmem_100` / `bind_100` |
| `u_h2_pack_sync` / `u_h2_topk_sync` / `u_h2_poison_sync` | 64 / 64 / 1 | **keep** |
| `u_wmem_sync` | 1 `wmem_done` | **keep** (`WMEM_OK`) |
| `u_tx` | UART engine | **keep** |

### 5.3 Core-domain FFs / wires to stop updating (gate off)

Delete ATOM FSM and these sticky/latch updates in the `core_clk` `always_ff` (keep `sticky_topk`, `topk_pack_lat`, `sticky_pack`, `ctx_pack_lat`, `poison_lat<=0`, `sticky_bind`, `sticky_core_done`, `qs`, `start_q`):

```text
sticky_owner, sticky_qgo, sticky_soarun, sticky_ar, sticky_rbeat,
sticky_rbusy, sticky_ridle, sticky_soaq, sticky_accept, sticky_fwd, sticky_lm,
sticky_bind_busy, sticky_pred_nz,
sticky_wdma_busy, sticky_wdma_done, sticky_core_busy,
sticky_w_stall, latched_phase,
sticky_tile_miss, latched_tile_dst, latched_tile_bst, latched_tile_req,
latched_tile_dma_busy, latched_tile_dma_own,
latched_wdma_busy_f1r, latched_mdone_f1t, latched_busy_hold_f1t,
latched_wdma_own_f1v, latched_wdma_grant_f1v, latched_rpath_idle_f1v, latched_mgo_f1v,
sticky_rvseen, sticky_rready1, sticky_rid_ok, sticky_rid_bad, sticky_outst,
sticky_cdc_ne, sticky_cdc_marf, last_arid, ar_outst_cnt,
atom0_q, atom1_q, atom0_valid, atom1_valid, atom_giveup, atom_st, atom_now
```

`latched_sdone_f1t` / `latched_dma_st_f1u` / `latched_sgo_f1u` / `latched_s_dma_busy` / `latched_wdma_owner_ui` live in **ui_clk** probe `always_ff` — delete that whole probe block. **Keep** the grant `always_ff` for `wdma_owner_grant` and `wdma_arr_outst`.

### 5.4 UART-only taps on frozen modules (stop reading; do not edit child)

Gate off (no CDC, no UART, no ATOM, no JA):

```text
wdma_dbg_sdone, wdma_dbg_mdone, wdma_dbg_busy_hold,
wdma_dbg_sgo, wdma_dbg_mgo,
wdma_dbg_sbusy_pend, wdma_dbg_cmd_empty_mgo, wdma_dbg_cmd_rd, wdma_dbg_cmd_st,
dbg_tile_bst, dbg_tile_dst, dbg_tile_req_s1,
w_stall,          // UART/ATOM only; not grant
phase,            // UART PHASE=HH only
bind_busy,        // UART BIND_BUSY only
cdc_ar_empty, cdc_ar_ne, cdc_ar_hold,   // F1j / E3 UART
cdc_arvalid, cdc_arready,               // E1/E3 UART (mux still uses functional AR)
```

**Do not gate off:** `wdma_dbg_st` (grant idle), `dbg_tile_miss` (grant), `wdma_owner`, `r_path_idle`, `wdma_owner_grant`.

### 5.5 UART ROM / sequencer

- Delete `hb_char`/`hb_len`/`hb_next`/`have_pending` arms for every **non-KEEP** `sel`.
- `sent_mask` width = number of KEEP lines (7).
- Collapse `hb_next` to: `BOOT` → `WMEM_OK` (`wmem_100`) → `TOPK=` (`topk_100`) → `PACK=` (`pack_100`) → `POISON=` (`poison` CDC, gated on `bind_100` as today) → `CORE_DONE` (`core_done_100`) → `NATIVE_V1_EXIST_ROW,pred=` (`pred_100 != 0 && bind_100`).
- Remove F1w 7'd64 alias comment path (MGO no longer exists).
- Pmod `ja_q`: drive `8'd0` (or KEEP-only). Drop `sgo_lat_100` etc. from the concat.
- Remove `DONT_TOUCH` on E3 stickies (those signals go away).

### 5.6 KEEP CDC / ports (do not gate off)

```text
u_boot_core_sync.{wmem_done, boot_done, calib}
u_b0_166.btn[0]
u_wdma_rel_sync.{wdma_cmd_empty_ui, wdma_dma_idle_ui, wdma_arr_quiet_ui}
u_wmem_sync.wmem_done
u_h2_pack_sync.ctx_pack_lat
u_h2_topk_sync.topk_pack_lat
u_h2_poison_sync.poison_lat
u_stat_sync.pred          (EXIST_ROW)
sticky_bind               (pred_ready / POISON gate)
sticky_core_done          (CORE_DONE)
.poison_i(1'b0)
u_axi_cdc, u_wdma_cdc, u_mig, u_boot, u_wmem_boot, u_wdma, u_ab, u_tx
```

---

## 6. SLICE-OPT-BIT-00 bag rules (for the implementer, not this file)

```text
results/A7-NATIVE-GRAPH/GROK-ORCH-00/SLICE-OPT-BIT-00/
  build_slice_opt_bit_00.tcl    # PROGRAM=NO, no open_hw_manager
  TOKEN.md                      # wait-human; do not consume BIT-01 token
  report_utilization_route.rpt
  report_utilization_route_hier.rpt
  e2r_metrics.txt
```

- Copy BIT-01 TCL **refusals** (wrong worktree, leftover SHA, frozen lm/eam names).
- `out_bit` must **not** be `...minheap_01.bit`. Suggested: `arty_a7_ng_native_v1_grok_orch_slice_opt_00.bit`.
- Lock ALGORITHM SHAs to BIT-01 table in §0. After the SoC-top edit, print **new** TOP SHA and lock that in the new TCL.
- Same `opt_design -control_set_merge` is allowed (not the unknown).
- Capture script: grep KEEP tokens only. Do not require ATOM/F1 lines.
- **PROGRAM=NO** until a later human token names `gate=SLICE-OPT-BIT-00` and the new SHA. BIT-01 token is spent and must not be reused.

Pass / fail (AI still does not stamp BOARD_PASS):

| Result | Meaning |
|--------|---------|
| Place 30-487 | P0 FAIL packing — then P1 CE, still no algorithm edit |
| Slice < 15850, WNS≥0, SHA locks hold | P0 BIT_OK (impl). UART law not yet silicon |
| UART (later token) KEEP tokens MATCH BIT-01 law | existence preserved |
| `PACK=FF…` or `pred≠664` | law broken — revert SoC top; do not “fix” minheap/TinyGPT |

---

## 7. Expected UART after P0 (law)

```text
BOOT
WMEM_OK
TOPK=3B392B291B190B09
PACK=3B392B291B190B09
POISON=0
CORE_DONE
NATIVE_V1_EXIST_ROW,pred=664
```

Order may follow `hb_next` priority; bytes of each KEEP line must match BIT-01. Dropping `MIG_OK`/`SOA_OK` is intentional (P0 keep list). Do not add them back in the same gate.

---

## 8. Decision

Slice 100% on BIT-01 is **debug CDC + UART unique-case + ASYNC_REG packing**, not “need a smaller GPT”. P0 is the cheapest legal cut that cannot change `pred=664`. P1 is optional CE mop-up. Wavefront 14k FF stays HYBRID until a later named gate.

```text
CONTROL_BIT=GLOBAL-TOPK-MINHEAP-BIT-01
CONTROL_SHA=439CC42D9BA0B3780C384C47E6E7F0A886269929E3ED3667471F064A8A222A8D
NEXT=SLICE-OPT-BIT-00 UART_SLIM
PROGRAM=NO
OVERWRITE_MINHEAP_01=FORBIDDEN
```
