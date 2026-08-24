# STRIDE_AUDIT — mem_schema_v1

## Authority
- NodeRecordV1 = 16 B (LE, version=1)
- EdgeRecordV1 = 32 B (LE, version=1)
- EpisodeRecordV1 = 32 B (LE, version=1)
- Package: rtl/native_graph/memory/a7ng_mem_schema_v1.sv

## Pre-fix conflicts (FALSIFIER targets) — resolved this gate
| Location | Was | Now |
|----------|-----|-----|
| a7ng_bram_hotset.sv | magic `<<3` (8 B) comment/addr | `<<4` NodeRecordV1 offset |
| tb_a7ng_hotset.sv | expected 8 B | expects 16 B |
| a7ng_episode_bank / ddr_store | magic `{idx,5'b0}` | `a7ng_episode_byte_addr` |
| a7ng_shard_fetch | magic `<<4` inline | `a7ng_node_byte_addr` |
| arty_a7_ng03_top | magic `<<4` | `a7ng_node_byte_addr` |

## Remaining non-record strides (documented, not Node/Edge/Episode)
| Location | Stride | Role |
|----------|--------|------|
| a7ng_index_bank / ddr_store index path | 16 B | Index companion rows |
| a7ng_prior_persist | 16 B AXI beats | NG-05 prior table (not schema V1 records) |
| episode_bank datapath width | 128b write into 32 B slot | lower half EpisodeRecordV1 until 2-beat writeback (stride still 32 B) |

## Grep evidence
See STRIDE_GREP.txt in this archive.
