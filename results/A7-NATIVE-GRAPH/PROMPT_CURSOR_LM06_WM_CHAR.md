# DÁN NGUYÊN — STOP cache RTL; characterize u_a only

```text
## SYSTEM — CORRECTION, then STOP after closeout

Repo: D:\Jetking_sem4\SEM_4\arty-a7-online-lm
Board: Arty A7-100T  210319BE776EA  COM12

You are a7-ng-orchestrator. Parent writes STATUS only.
If an implementer Task is already running lm06_wm_00 cache/LRU/line-cache RTL: STOP it.
Do not dispatch a second implementer on the same gate id.

READ:
results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json
results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/00_CURRENT_AUTHORITY.md
DDR-WAVEFRONT-00/AUDIT_ddr_wavefront_00_hlb.md §7 R1–R5

First line:
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=lm06_wm_00
SCI_METHOD: CHAR only. No cache RTL. No PREREG amend. Evidence_class=LM06_WM_CHAR_XSIM
HUMAN_CORRECTION: true

====================================================================
WHAT WAS WRONG (do not continue that thinking)
====================================================================

You mixed persist digest + u_w prior + u_a tiling + LRU + line cache + backing
store + ping-pong + snap enforce + PREREG amendments. That is many unknowns.

FALSE / TOO STRONG:
  "two addresses + one write per cycle => 2-deep ping-pong always sufficient"
That is instantaneous port demand, NOT temporal working set, NOT prefetch
distance, NOT DDR latency hiding. A,B then C,D then A,B thrashes a 2-slot
cache if refill latency > 1 cycle.

Do NOT require same-cycle refill/writeback "to preserve bit-exact timing".
LM06-WM equivalence (later) is FUNCTIONAL: same data/fold/persist, cycles MAY differ.
Stall on miss is a ladder COST, not a WM-00 correctness failure.

Full backing array + residency tags ≠ BRAM reduction. Only synth/P&R
report_ram_utilization proves physical bound.

Do NOT amend the same PREREGISTER again. Characterization results of this
run must NOT rewrite this run's recipe.

Do NOT claim SIM_FULL=0 vs SIM_FULL=1 formal equivalence unless a file-backed
A/B artifact exists. You MAY cite prior LM-06 tiled W as:
  "bounded u_w operation is supported by prior LM06 evidence <path/SHA>"

====================================================================
THIS SESSION — ONE UNKNOWN (characterization)
====================================================================

UNKNOWN: what is the u_a (and u_snap) ACCESS PATTERN on the frozen/reference
LM-06 control run?

NOT this session:
  eviction/LRU/line-cache candidate RTL
  ping-pong depth chosen from port count
  BRAM ladder 96/64/48/32
  bram_owner_00
  TinyGPT SoC
  COM12
  TRAIN-V2
  HNSW
  HS-02 exam

If LOOP_STATE still says lm06_wm_00: KEEP that id. Close it as
CHAR / LIMIT-not-equivalence. Do NOT silently retitle to a cache PASS.
Do NOT open a new gate id unless human says so after STOP.

Instrument the existing / frozen-control path (no new memory semantics):

  u_a read addresses, u_a write addresses
  tile_id per access (declare tile_words in PREREG ONCE — do not sweep sizes in RTL)
  distinct tiles/cycle
  reuse-distance histogram (offline OK)
  tile-switch count
  dirty words/tile if cheap
  phase boundaries
  sequential-run length

Offline, AFTER the run, you MAY compute hypothetical miss/refill/writeback
tables for tile sizes {128,256,512,1K,2K,4K} and resident {2,4,8,16}.
Those tables are ENGINEERING_INFERENCE for a FUTURE prereg of LM06-WM-00
equivalence — not a PASS of this gate.

Optional infrastructure (not a reason to redesign u_a):
  flush/reload 802,816 B identity vs CONTROL FILE captured from frozen
  LM-06 bitstream BEFORE the candidate. No host-computed token/logit.

If no adequate recorded CONTROL exists: FAIL or LIMIT. Do not synthesize CONTROL.

====================================================================
PASS / FAIL / STOP
====================================================================

PASS_NARROW (CHAR): histograms + switch counts archived; no cache RTL claimed;
  CONTROL SHA cited; frozen bits MATCH; R1–R5 acknowledged;
  Evidence_class=LM06_WM_CHAR_XSIM
  Closeout MUST say: equivalence NOT proven; ladder NOT opened.

LIMIT: wall-clock / no CONTROL file / cannot instrument without semantic change.

FAIL: implemented eviction and called it WM-00 PASS.

Then: verify trio + HLB on THIS closeout only. STOP.
Do not tick lm06_wm ladder. Do not auto-run QUEUED gates.

Archive: results/A7-NATIVE-GRAPH/LM06-WM-00/  (CHAR closeout)
         or LM06-WM-CHAR-00/ if you must split files — still one LOOP id.

NEXT after STOP (human later, new PREREG, one tile size + one NLIVE):
  LM06-WM equivalence: real BRAM-resident set + DDR/backing + stall/ready
  functional exact, cycles may differ
  THEN physical ladder + report_ram_utilization

END
```
