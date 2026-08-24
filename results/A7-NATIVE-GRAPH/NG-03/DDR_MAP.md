# NG-03 DDR map (FPGA-owned — HS-14)

Board: Arty A7-100T Digilent AXI MIG (28-bit byte address on `s_axi_*`)

| Region | Base (byte) | Stride | Owner | Notes |
|--------|-------------|--------|-------|-------|
| Node/topic compact records | `0x0100_0000` | **16 B** (NodeRecordV1) | FPGA `a7ng_shard_fetch` | `addr = a7ng_node_byte_addr(BASE, id)` |
| Edge table (reserved) | `0x0200_0000` | **32 B** (EdgeRecordV1) | FPGA | `mem_schema_v1` |
| Learned priors (NG-05) | `0x0300_0000` | 64 B table | FPGA `a7ng_prior_persist` | flush/reload; host cannot write weights |
| Episode bank (MEM-01) | `0x0400_0000` | **32 B** (EpisodeRecordV1) | FPGA `a7ng_episode_bank` | `a7ng_episode_byte_addr` |
| Index lines (MEM-02) | `0x0500_0000` | 16 B companion | FPGA `a7ng_index_bank` | not Node/Edge/EpisodeRecordV1 |
| LM weight image | legacy LM map | — | LM lane | do not overlap; graph stays ≥ `0x0100_0000` |

## Fetch law

- Miss → **one** 128-bit AXI beat (16 B), not full-graph scan (HS-13).
- Host never supplies winning DDR address.
- BRAM hotset depth = 256 direct-mapped.

## Evidence so far

| Gate | Result | Class |
|------|--------|-------|
| Hotset XSim | `A7NG03_HOTSET_XSIM_PASS` | EVIDENCE |
| Shard+AXI model XSim | `A7NG03_SHARD_XSIM_PASS` (32 B / 3 cands, 1 hit 2 miss) | EVIDENCE |
| MIG board bit | pending | NEEDS_EXPERIMENT |
