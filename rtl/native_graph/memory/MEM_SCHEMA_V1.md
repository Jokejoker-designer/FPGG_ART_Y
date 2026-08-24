# MEM_SCHEMA_V1 — Authoritative DDR record layout

**Gate:** `mem_schema_v1`  
**Law id:** `a7ng-mem-schema-v1`  
**Version:** `1`  
**Endianness:** little-endian (LE) for all multi-byte fields  
**Alignment:** records packed; DDR address = `region_base + id * REC_BYTES`  
**Authority:** this file + `a7ng_mem_schema_v1.svh` + `a7ng_mem_schema_v1.h` + Python serdes  
**Map bases (document only — do not overwrite frozen LM-06 / 01R / 02M bits):** see `a7ng_pkg.sv` / `results/A7-NATIVE-GRAPH/NG-03/DDR_MAP.md`

## Sizes (pinned)

| Record | Bytes | Region base param |
|--------|------:|-------------------|
| NodeRecordV1 | **16** | `NG_DDR_NODE_BASE` |
| EdgeRecordV1 | **32** | `NG_DDR_EDGE_BASE` |
| EpisodeRecordV1 | **32** | `NG_DDR_EPISODE_BASE` |

Node stays 16 B so NG-03 single 128-bit AXI beat remains HS-13-bounded (`NG_SHARD_FETCH_B == 16`).

## NodeRecordV1 (16 B)

| Off | Type | Field |
|----:|------|-------|
| 0 | u32 | `node_id` |
| 4 | u16 | `node_type` |
| 6 | u16 | `topic_id` |
| 8 | u32 | `cue` |
| 12 | u16 | `confidence` |
| 14 | u8 | `degree_sat` (0..255 saturate) |
| 15 | u8 | `version` (=1) |

`adjacency_ptr` from BRAM_WORKING_MEMORY_SPEC §6.1 is **not** inlined in V1 compact node. Edge head lives in the index/edge banks (`NG_DDR_INDEX_BASE` / `NG_DDR_EDGE_BASE`); FPGA still owns the address (HS-14).

## EdgeRecordV1 (32 B)

| Off | Type | Field |
|----:|------|-------|
| 0 | u32 | `src_node` |
| 4 | u32 | `dst_node` |
| 8 | u16 | `relation_type` |
| 10 | u16 | `pad0` (must be 0) |
| 12 | i16 | `learned_weight` |
| 14 | i16 | `teacher_prior` |
| 16 | u16 | `positive_count` |
| 18 | u16 | `negative_count` |
| 20 | u32 | `last_update_epoch` |
| 24 | u16 | `version` (=1) |
| 26 | u16 | `flags` |
| 28 | u32 | `checksum` (0 = unused; else CRC-32/IEEE of bytes `[0..27]`) |

## EpisodeRecordV1 (32 B)

| Off | Type | Field |
|----:|------|-------|
| 0 | u32 | `episode_id` |
| 4 | u32 | `subject` |
| 8 | u32 | `relation` |
| 12 | u32 | `object` |
| 16 | u32 | `context` |
| 20 | u32 | `source_ref` |
| 24 | u32 | `answer_payload_ref` |
| 28 | u16 | `confidence` |
| 30 | u8 | `version` (=1) |
| 31 | u8 | `flags` |

## Checksum / validation policy

- Default golden and RTL traffic: `checksum == 0` (disabled).
- If non-zero on EdgeRecordV1: host/loader/RTL must reject mismatch before promote.
- Node/Episode: version byte must equal `A7NG_MEM_SCHEMA_VERSION` (1).

## Consumer rule (HS-13 / feedback P2)

No independent magic strides in RTL, Python, frontend, DDR loader, or TB.  
Import `a7ng_mem_schema_v1_pkg` / header / `mem_schema_v1.py` only.

## Out of scope this gate

TermGen, full BRAM-WM-00 integrate, `integrate_fit`, more PEs, TRAIN-V2, HNSW, LM-06 wipe.
