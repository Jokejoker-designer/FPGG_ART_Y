# RESULTS — LM06-BRAM-PHYS-AUDIT-00

**Gate:** `LM06-BRAM-PHYS-AUDIT-00`  
**Type:** `READ_ONLY_RESEARCH`  
**Main loop:** untouched (`ddr_cue_soa_00r_axi_liveness`; Codex lock not modified)  
**Closeout class:** `AUDIT_COMPLETE_NO_PARITY_TILE_GAIN`  
**DCP:** `build/out/a7lm06_post_route.dcp`  
**DCP SHA256:** `CE6A6AD7FCDD9BC4D602CBD1D4B679FDE56C551A65AC8D0400418F0A5CDA6022`

ONE UNKNOWN: What physically causes LM06's 132-RAMB36 footprint, and does any logical bank contain unused parity/tail/aspect capacity that could remove at least ONE physical RAMB36 without changing numerical law or access semantics?

---

## FACT

1. Enumerated **132** `RAMB36E1` on frozen post-route DCP (matches prior Q0 ownership).
2. Owner split: `u_a=66`, `u_w=64`, `u_snap=2`.
3. Mode/width census: TDP×96 (`rw=1`), SDP×34 (`rw=72`), TDP×2 (`rw=9`).
4. **ECC off** on all 132 (`EN_ECC_READ=0`, `EN_ECC_WRITE=0`).
5. **17 SDP cells** (`*_reg_0` / `u_a/mem_reg_0`): DIP/DOP carry `wr_data`/`q` bits `[64:71]` → **FULL_X72_PAYLOAD** (parity used as payload).
6. **17 SDP cells** (`*_reg_1` / `u_a/mem_reg_1`): `DIADI` carries `[72:103]`; **all DIP tied `<const1>`**; DO `[72:103]` without DOP payload → **WIDTH_BOUND** + tag `PARITY_UNUSED_NO_TILE_GAIN` + `TAIL_FRAGMENT_32b_IN_X72_SHELL`.
7. Logical SDP word width implied by connectivity: **104 bits** = 72 + 32 across the pair.
8. **96 TDP `rw=1` cells**: DIP not used as payload (const/unconnected); single DI bit signal on probed `u_a` slice; shared address/clock nets across `u_core/u_a` slices → **BIT_SLICED_PORT_BOUND**.
9. `u_snap/mem_reg_0`: width 9 with `DIPADIP[0]`/`DOPBDOP[0]` in `rdata[8]` → **PARITY_USED** (x9 aspect).
10. `estimated_removable_tiles = 0` for every logical bank (no N→N−k remapping executed).
11. Artifacts: `BRAM_PHYSICAL.tsv`, `LOGICAL_BANKS.tsv`, `BRAM_CONTROL_GROUPS.tsv`, pin probes, this RESULTS, CLOSEOUT, loss decomposition.

---

## INFERENCE

1. Dominant footprint cause is **port-bound bit-sliced TDP inference** (96/132 tiles), not unused parity on x72 banks.
2. Second structure is **104-bit SDP channels** split as full-x72 + 32-bit fragment in an x72 shell (34 tiles) — a **width/tail** issue, not a “free 12.5% parity” issue.
3. Filling unused DIP on bit-slices or on `*_reg_1` with metadata would change stored bits but **would not, by itself, delete a RAMB36**.
4. Theoretical 12.5% parity capacity is **not** available as a tile-reduction lever on FULL_X72 tiles (already consumed) and is **not tile-removable** on WIDTH_BOUND / BIT_SLICED classes without redesign.
5. Any future BRAM cut that could remove ≥1 tile likely requires **re-inference / retile / overlay / narrower banking**, i.e. access-geometry change — outside this audit’s READ_ONLY scope.

---

## NEEDS_EXPERIMENT

| ID | Proposal | Falsifier |
|----|----------|-----------|
| E1 | Retile 104-bit SDP as native 2×52 or 36+36+32 mapping that drops one physical tile per channel **without** changing DDR/weight law | Post-route tile count not reduced, or bit-exact fail |
| E2 | Re-infer `u_a`/`u_w` TDP bit-slices as wider True Dual Port words (e.g. x9/x18) reducing slice count | Tile count flat or WNS/ports explode |
| E3 | Overlay / phase-share (doctrine `bram_owner_00`) — not parity | Lifetime overlap or second writer |
| E4 | Meta-only DIP on one WIDTH_BOUND or bit-slice bank (no tile claim) | Only if goal is LUT/FF meta move — **not** tile PASS |

None of E1–E4 were run. Human picks at most **one**.

---

## Mandatory check answers

| # | Check | Result |
|---|-------|--------|
| 1 | All 34 SDP x72 use parity as payload? | **No** — 17 yes (FULL_X72); 17 no (DIP const / WIDTH_BOUND). Documented. |
| 2 | 96 TDP w=1 are bit slices? | **Yes** where probed — shared ADDR/CLK + 1-bit DI; naming `mem_reg_b_s` consistent. |
| 3 | Can parity packing reduce physical tile count for any bank? | **Not evidenced** — all `estimated_removable_tiles=0`. |
| 4 | Tail/aspect vs parity separated? | **Yes** — §B WIDTH_BOUND/tail vs §A FULL_X72 vs §C port-bound. |
| 5 | Port/banking fixes tile count? | **Yes** — 96 TDP bit-slices classified `BIT_SLICED_PORT_BOUND`. |

---

## Metrics summary (per owner)

| Owner | physical_tiles | limiting_dimension | removable |
|-------|---------------:|--------------------|----------:|
| `u_a` | 66 | port (64) + width (2) | 0 |
| `u_w` | 64 | port (32) + width+banking (32) | 0 |
| `u_snap` | 2 | aspect | 0 |

`peak_live_bits`: **not reported** (no lifetime trace in this gate’s inputs).

---

## Hard-stop compliance

- No RTL / bitstream / dense pack / quantize / ladder open / `LOOP_STATE.next` change / Attempt 10 interference.
- No BOARD_PASS. No implementation PASS. No claimed BRAM reduction.
