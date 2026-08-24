# VERIFY_ONLY: bram_consolidate (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** **PASS_NARROW** (confirm) — measured shared pool BRAM **132/135** Prefer WNS=+0.586; co-fit proj **132** collapses additive **260**; frozen **MATCH**; **HS-22 OPEN**  
**Not claimed:** HS-22 closed, full TinyGPT+UA SoC, BOARD_PASS, Digilent MIG DDR spill, XSim functional pass, soft Prefer≤130  
**XSim marker:** **ABSENT** (	ests/xsim/native_graph missing; no A7NG_*_XSIM_PASS)  
**Evidence class:** POST_ROUTE_PROXY (implementer); XSim N/A  
**ts_utc:** 2026-08-22T02:46:46Z

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | implementer PASS_NARROW; consol BRAM132 WNS+0.586; CONTROL additive 260; frozen MATCH claimed |
| UNKNOWN | Independent confirm: capacity honesty? frozen MATCH? HS-22 inflate / BOARD_PASS / invent XSim? |
| H_CANDIDATE | Re-read util/timing → 132≤135 Prefer WNS≥0; live rehash MATCH; hs22_closed=false; stay PASS_NARROW |
| H_RIVAL | Sell util>135 as PASS; claim headroom≥132; close HS-22 from proxy; invent A7NG_*_XSIM_PASS; overwrite frozen |
| FALSIFIER | BRAM≠132; WNS<0; any frozen MATCH=False; hs22_closed=true; BOARD_PASS; XSim marker without TB |
| UNIT | post-route util/timing + live SHA (≠ clock cycles / query bags) |
| CONTROL | UA 4451AFD9…; frozen LM-06 67C37DD5… + 01R/02M/A0.3; mig.prj 870FA6EE… AXI |
| METRICS | bram_tiles, wns/tns, cofit_proj, additive, headroom_after, frozen_match, hs22_closed, board_pass |

## Re-derived checks

| Check | Measured | Verdict |
|-------|----------|---------|
| consol_util.rpt Block RAM Tile | **132 / 135** (97.78%) | MATCH gate |
| consol_util.rpt RAMB36E1 / RAMB18 | **132 / 0** | MATCH |
| consol_util.rpt DSP | **0** | MATCH (proxy glue; no TinyGPT MAC) |
| consol_util.rpt Slice LUTs / FF | **141 / 23** | FF MATCH; LUT cell-count **153** (=LUT1..6 prim sum) vs Slice LUTs **141** after combine — **MINOR** label only |
| consol_timing.rpt Setup WNS/TNS | **0.586 / 0.000** | MATCH |
| consol_timing.rpt Hold WHS/THS | **0.069 / 0.000** | MATCH |
| Additive CONTROL (TinyGPT-SOC) | **128 + 132 = 260** vs **135** | LIMIT retained |
| Co-fit projection (WM share) | **max(128,132)=132 ≤ 135** | **HONEST** ENGINEERING_INFERENCE + measured pool |
| Headroom after / Prefer≤130 | **3** / soft Prefer **not met** | documented; device hard ≤135 OK |
| Consol .bit live SHA | 83A438B5…A7D3AEF | **MATCH** |
| CONTROL UA / repair live SHA | 4451AFD9…EA67F40E | **MATCH** |
| Frozen LM-06 / 01R / 02M / A0.3 | all MATCH | **MATCH** (HS-20) |
| ivado/ip/.../mig.prj live SHA | 870FA6EE…52190D; PortInterface AXI; app_*=0 | **MATCH** untouched |
| XSim TB / A7NG_*_XSIM_PASS | ABSENT | not invented |
| BOARD_PASS / HS-22 closed | false / OPEN | **REFUSED inflate** |
| RTL / golden / frozen bits edited this verify | No (read-only + verify artifacts) | PASS |

## Capacity-claims honesty

1. **Measured** shared pool tiles = **132 ≤ 135** Prefer WNS≥0 — **supported** by consol_util.rpt + consol_timing.rpt.  
2. **Co-fit proj** = shared max(UA128, TinyGPT132) = **132** collapsing additive **260** — labeled ENGINEERING_INFERENCE; not sold as full TinyGPT+UA SoC P&R.  
3. **Headroom ≥132 free tiles** — **not claimed** (headroom_after=3).  
4. Soft Prefer ≤130 — **honestly not met**.  
5. HS-22 / answer-path / pe_alive / DSP TinyGPT — **OPEN / ABSENT** on this proxy.

## Artifacts consulted (read-only)

- GATE_bram_consolidate.md, LIMIT_bram_consolidate.md, NOTE_bram_consolidate.md
- FIT_BUDGET_BRAM_CONSOL.json, METRICS.json, VERDICT.txt, SHA256.txt, rozen_sha_control.txt
- consol_util.rpt, consol_timing.rpt, consol_util_hier.rpt, ivado_consol.log
- Live rehash → rozen_sha_verify.txt (this verify)

## Explicit non-claims

- No XSim functional proof for consol / TinyGPT-on-SoC  
- No HS-22 silicon LM-on-answer-path closed  
- No full TinyGPT+UA+DSP co-implemented bitstream  
- No BOARD_PASS / Native V1  
- No LOOP_STATE flip by this verifier (orchestrator / evidence-auditor)
