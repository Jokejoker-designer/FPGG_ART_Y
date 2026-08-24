# AUDIT prep — bram_consolidate (implementer self-check)

**Evidence_class:** POST_ROUTE_PROXY  
**allow_loop_done_eng:** implementer proposes PASS_NARROW; auditor decides  

## Controls re-checked

| Control | Result |
|---------|--------|
| UA SoC SHA `4451AFD9…EA67F40E` | MATCH live |
| Frozen LM-06 SHA `67C37DD5…4282E3BA` | MATCH live |
| mig.prj SHA `870FA6EE…52190D` | MATCH; PortInterface=AXI; app_*=0 |
| TinyGPT-SOC LIMIT archive | present |

## Hypothesis outcome

| Hypothesis | Outcome |
|------------|---------|
| H_CANDIDATE co-fit ≤135 Prefer WNS≥0 | **SUPPORTED** — BRAM132 WNS+0.586 |
| H_CANDIDATE headroom≥132 | **NOT supported** — headroom_after=3 |
| H_RIVAL paper/pe_alive/mig edit | **did not fire** |

## Refuse checklist

| Refuse if | Fired? |
|-----------|--------|
| BOARD_PASS declared | no |
| util>135 sold as PASS | no |
| frozen overwrite | no |
| HS-22 closed from proxy | no (`hs22_closed:false`) |
| invent pe_alive | no |

## NEXT (orchestrator)

Auditor/vivado-gate VERIFY → if allow, DONE_ENG PASS_NARROW; next OPEN per LOOP_STATE. HS-22 remains OPEN until TinyGPT answer-path fit.
