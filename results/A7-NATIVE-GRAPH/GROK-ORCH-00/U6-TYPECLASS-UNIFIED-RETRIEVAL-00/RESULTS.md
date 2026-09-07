# RESULTS — U6-TYPECLASS-UNIFIED-RETRIEVAL-00

```text
XSIM = U6_TYPECLASS_UNIFIED_RETRIEVAL_PASS
OOC  = synth 0 errors; 10 ns estimate WNS=-4.103 ns (heap path; not full-chip fit)
```

Frozen:

```text
TYPECLASS_TABLE_SHA256   = B5958D4ADBE96F1D4432915E767BA2C4806594DBB291BBFFBEC95FE588E436C2
CLASS_ID_MAPPING_SHA256  = CEA2B9710D4D5F229BC341DF790E557B20F023F98161464C6C79BEADAE6BD68B
TC_N                     = 443
CLASS_ID                 = 16'd1 .. 16'd443  (not from NID)
CANDIDATE_OWNER          = a7ng_typeclass_scan
LEGACY_NID               = DISCONNECTED
```

Independent host gold vs XSim (CUT A–G):

| query | n | top0 CLASS_ID | sc0 |
|-------|---|---------------|-----|
| chiller | 29 | 57 | 8 |
| water chiller | 10 | 58 | 16 |
| leak chiller | 4 | 68 | 16 |
| payroll/soccer/adv/piano | 0 | pad 0x00FFFFF0 | 0 |
| install chiller | 3 | 65 | 16 |
| air condenser | 10 | 87 | 16 |
| leak check | 47 | 17 | 8 |
| supply duct | 10 | 254 | 16 (ids 256+ in Top-K) |

Protocol: empty Q_BOUND → 0 real CLASS_ID; exact-K=8 (iid=1,rid=3) includes CLASS_ID>255; scan/heap stalls still match; mid-scan reset and S_SCW reset recover; cap8 leak_check ovf=1 emit=8 trunc=39.

Poison A (decoy NID 0x00ABCDEF) does not enter Top-K.
Poison B (CLASS_ID 57 eid→99) drops 57; Top-K becomes 58..65.

OOC xc7a100t (do not conclude SoC fit):

| LUT | FF | BRAM | DSP | WNS@10ns | TNS |
|-----|----|------|-----|----------|-----|
| 5916 | 1134 | 0 | 0 | **-4.103 ns** | -3561.980 ns |

Instance cells: QSE 2854, heap 5115, scan 375, mat 118, scorer 217.
Catalog ROM mapped as LUT (512x*), not BRAM. Two copies (scan+mat).
Failing OOC path is production minheap `h[7].s → h[0].id CE` (19 levels, 13.817 ns data). Not a typeclass-scan exclusive path.

Delta vs T2 scanner-only OOC: LUT 137→5916, FF 126→1134 (QSE+heap dominate).
Cycles/query estimate ≈ TC_N + ~6×n_cands + drain ≈ 450–750 at 1 class/cycle scan.

Host semantic counters = 0. No QSE change. No Q-head. No NID cap sweep.
