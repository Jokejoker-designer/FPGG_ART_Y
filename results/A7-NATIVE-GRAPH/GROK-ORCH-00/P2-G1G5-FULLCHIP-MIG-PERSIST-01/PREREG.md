# P2-G1G5-FULLCHIP-MIG-PERSIST-01 — preregistration (before data)

**PROGRAM=NO.** No COM12 / JTAG / board / Gate14 close / Teacher-Off / BOARD_PASS.  
Preserve COFIT-00 bit `2E18B144…225C4` and all parent bags.

## One unknown

Can the COFIT LUTRAM persist mock (`ddr_mem[0:31]`) be replaced by an FPGA-owned AXI/MIG record path on the existing dedicated prior region `NG_DDR_PRIOR_BASE`, using the existing SoC owner mux (boot / WMEM / SOA / graph CDC / WDMA), such that:

1. persist **write complete / C7 ready** only after AXI **BRESP==OKAY**;
2. persist **reload beat** only after **RVALID && RLAST && RRESP==OKAY**;
3. G4 seven cells stay bit-exact with **BRAM kill** and **DDR model retained**;
4. freeze issues **no AW**;
5. GEN0 / wrap rules unchanged (persist SHA lock);
6. backpressure + BRESP/RRESP/RLAST inject do not violate conservation or address ownership, and never dual-drive graph/LM DMA;

then rerun AFAST249 + G1–G5 unit markers and meet COFIT-00 full-chip P&R gates — **without** editing MIG generated RTL / law / WMEM / G1–G4 persist / G5 glue?

## Must not

- Edit `mig_7series_0` generated `.v` / `.xci` contents.
- Edit `a7ng_persist_gen_fast.sv` (G4 SHA `D1BF0340…`).
- Edit G1 / G2 / G3 / G5 glue / TinyGPT / WMEM / law.
- Instantiate second TinyGPT, `causal_learn_fast`, or bitonic global TopK.
- Program the board. Overwrite bit `2E18B144…`.

## Region (existing map, not a new magic base)

| Region | Base | Owner |
|--------|------|-------|
| WMEM | `DDR_WBASE=0x0010_0000` | LM tile DMA |
| Node/SOA | `NG_DDR_NODE_BASE=0x0100_0000` | graph CDC |
| Cue64 | `NG_DDR_CUE64_BASE=0x0110_0000` | graph |
| **Persist slots 0..31** | **`NG_DDR_PRIOR_BASE=0x0300_0000` + `addr*16`** | persist AXI |
| Episode | `0x0400_0000` | unused this SoC |
| Index | `0x0500_0000` | unused this SoC |

C7 commit beat uses slot **31** (persist dump uses 0..16 only).

## Physical gates (same as COFIT-00)

route errors 0. WNS≥0 TNS=0 WHS≥0 THS=0. BRAM36-eq≤135. DSP≤240.  
free<256 RISK. free<64 FAIL. Bit only if all PASS. Unique name. PROGRAM=NO.
