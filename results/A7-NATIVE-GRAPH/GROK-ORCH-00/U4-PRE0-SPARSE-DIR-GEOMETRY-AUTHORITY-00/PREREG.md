# PREREG — U4-PRE0-SPARSE-DIR-GEOMETRY-AUTHORITY-00

```text
GATE            = U4-PRE0-SPARSE-DIR-GEOMETRY-AUTHORITY-00
BASE            = 342b8c93227974bf78cb9e076b85974c2a327fbb
REMOTE_HEAD     = 342b8c93227974bf78cb9e076b85974c2a327fbb
QUERY_LAW       = qse-v1-lexicon-hdc-00   KEY VALUES UNCHANGED
VALIDITY_LAW    = U4A-R6 bind-state bits; NOT (key != 0)
ROUTER          = P4_4k_h64
N_TABLES        = 4
N_BUCKETS       = 4096
BUCKET_W        = 12
HEAD_CAP        = 64
CAND_CAP        = 64
ENTRY_BYTES     = 16
TABLE_BYTES     = 65536
RTL             = rtl/native_graph/memory/a7ng_sparse_dir_axi.sv
BIT             = NO
PROGRAM         = NO
COM12           = UNTOUCHED
U5              = CLOSED
GATE14_PASS     = NO
U4_MEM02        = STOPPED_BEFORE_INTEGRATION
U4_SEMANTIC     = NO  (this gate is geometry compatibility only)
```

PRIMARY_UNKNOWN:

> Can `a7ng_sparse_dir_axi` represent the exact frozen U4A-R6 / P4_4k_h64
> routing geometry and key semantics without truncation, synthetic keys,
> or absent-feature probes?

## Directory address law

```text
dir_addr = INDEX_BASE + table_id * 65536 + bucket_id * 16
bucket_id = k[11:0]     (valid=1, including key=0 → bucket 0)

T0 base = INDEX_BASE + 0x00000
T1 base = INDEX_BASE + 0x10000
T2 base = INDEX_BASE + 0x20000
T3 base = INDEX_BASE + 0x30000
```

T0→k0 T1→k1 T2→k2 T3→k3. No `k0^k1^table`.

## Pass (geometry only)

1. exact k0..k3 preserved
2. no synthetic table keys
3. 12-bit bucket identity preserved
4. four tables, disjoint directory ranges
5. valid bits control probing
6. valid=1,key=0 probes bucket 0
7. low-4-bit collision vectors no longer alias
8. candidate cap remains bounded
9. no full scan
10. existing U4-R2 AXI protocol tests still pass

STOP at first divergence. Do not call this U4 semantic PASS.
