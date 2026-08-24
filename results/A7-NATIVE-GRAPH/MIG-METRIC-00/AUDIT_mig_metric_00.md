# AUDIT — mig_metric_00 (VERIFY_ONLY)

**Auditor:** a7-evidence-auditor  
**Mode:** VERIFY_ONLY  
**Result:** **PASS**  
**allow_loop_done_eng:** **true**  
**Evidence_class:** MIG_XSIM (not BOARD)  
**Marker:** `A7NG_MIG_METRIC_XSIM_PASS`  
**ts_utc:** 2026-08-22T04:05:00Z  

MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue). Encoder lane parked; this audit does not touch encoder.

## Verdict line

`AUDIT: 2 FINDINGS` — technical MIG_XSIM unknown **PASS**; session-process findings do **not** refuse `allow_loop_done_eng`.

## Dispatch provenance (refuse checks)

| Check | Result |
|-------|--------|
| Last implementer `DISPATCH_LOG` line `gate` == `mig_metric_00` | **PASS** (line: a7-ng-memory-arch PASS → CLOSEOUT.md) |
| Last implementer `agent` == `a7-ng-memory-arch` | **PASS** (`run_blueprint_loop.py` map + log) |
| `Evidence_class` == `MIG_XSIM` | **PASS** |
| No DROP-as-loss claim | **PASS** (`r_backpressure_cycles` / NOT lost-data DROP) |
| No COM12 as part of this gate | **PASS** (XSim archive only; falsifier REFUSED) |
| STOP / no `mig_board` auto-unlock | **PASS** (`LOOP_STATE.next=STOP`, `forbid_auto_mig_board=true`) |

## Re-derived headline numbers (from `xsim_mig_metric.log`)

| Cell | axi_read_bytes | axi_read_bursts | axi_read_beats | integrity |
|------|---------------:|----------------:|---------------:|-----------|
| (1,1) | 1024 | 64 | 64 | data/rresp/rlast=0; exp/rcv/cons=64/64/64 |
| (4,8) | 1024 | 16 | 64 | same CLEAN |

Stall sanity: `(1,1) 1554/1618=0.960445`; `(4,8) 80/144=0.555556` — matches `MIG_METRIC_ROW`.

SHA256 recomputed MATCH: bridge `D07A9742…`, mig.prj `870FA6EE…` PortInterface=AXI, pp `1FB685BD…`, mig_top `F91EA825…`, tb `7097EDDB…`.

H_RIVAL (cumulative 2048/80 sold as per-cell) **FALSIFIED** by per-run second cell 1024/16.  
Failed first run archived: `run_console.txt` → `A7NG_MIG_METRIC_XSIM_FAIL` (extra burst + RID/data mismatches) before AR-pipe fix + `run_console2` / `xsim_mig_metric.log` PASS.

## Findings

```
[MAJOR] LOOP_STATE flipped DONE_ENG before auditor; mig_board/COM12 interleaved earlier
  where     : STATUS/LOOP_STATE.json mig_metric_00; DISPATCH_LOG mig_board line before mig_metric PASS
  claim      : session override STOP / no COM12 / mig_board BLOCKED until metric CLOSEOUT
  evidence   : mig_board PASS_NARROW + board_probe.json programmed=true uart COM12 appears in DISPATCH_LOG before mig_metric_00 implementer PASS; LOOP already DONE_ENG+allow when auditor started
  why it matters: a reader could treat session as metric-first; COM12 program happened on a different gate out of declared order
  fix        : keep mig_board BLOCKED/next=STOP; do not auto-dispatch; cite BOARD archive as separate prior gate; this audit does not unlock mig_board
```

```
[MINOR] CLOSEOUT omits archived FAIL run
  where     : MIG-METRIC-00/CLOSEOUT.md vs run_console.txt
  claim      : clean PASS deltas only
  evidence   : run_console.txt shows A7NG_MIG_METRIC_XSIM_FAIL fails=2 (1088B/17 bursts) before AR-pipe fix; GATE mentions fix; CLOSEOUT does not
  why it matters: forbidden-route checklist wants failed experiments visible in closeout
  fix        : one-line CLOSEOUT cite of FAIL→PASS iteration (optional; archive already on disk)
```

## Non-findings (checked clean)

- No BOARD_PASS / Native V1 claim  
- No invent GB/s  
- No mig.prj hand-edit  
- Frozen LM/01R/02M/A0.3 not in this gate’s change set  
- DROP not sold as lost data  
- Evidence_class not mixed with BOARD for metric rows  

## STOP note (session override)

**allow_loop_done_eng = true** for `mig_metric_00` only.  
**Do not** set `next=mig_board`. **Do not** auto-start `mig_board`. Parent closeout only.

## NOT VERIFIED

- Full RTL diff review of AR-pipe change vs “feed/search law unchanged” claim (accepted GATE framing; bytes/bursts match preregister)  
- Independent re-run of XSim in this auditor turn (log + SHA recompute only)  
- mig_board silicon claims (out of scope; remains BLOCKED for auto-dispatch)
