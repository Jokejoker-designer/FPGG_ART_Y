# PREREGISTER — native_v1_ab_integrate_accept_00

**Status:** SEALED BEFORE CANDIDATE RTL  
**Owner:** Grok Project C `019ffa1c-a65c-71e0-8521-7d285e7c2ffd` (transferred from Cursor; clean start)  
**Type:** integration / acceptance-readiness  
**Iron-law:** **none** — not an optimization gate  
**Evidence target:** `XSIM + MIG_XSIM + POST_ROUTE + HARNESS_DRY_RUN`  
**Board / COM12 / bitstream / BOARD_PASS:** **FORBIDDEN**

| Field | Value |
|-------|-------|
| Gate ID | `native_v1_ab_integrate_accept_00` |
| Prerequisite | Project A contract v0; Project B TopK→bind audit ACCEPTED |
| Encoder | PARKED (H5 ungated DIFF twin only — not glue) |

## ONE UNKNOWN

Can one lineage-locked A+B candidate replace Project B local-wave fixtures with frozen live SOA/MIG producer, drive accepted bind + frozen TinyGPT, and post-route on `xc7a100tcsg324-1`, leaving only an explicit BOARD/800k punch-list?

## H_CANDIDATE / H_RIVAL / FALSIFIER

As `PROMPT_CURSOR_PROJECT_C_AB_INTEGRATE.md`. Any TB drive of local/global Top-8, bind IDs, pack, pred, winner, next-token → FAIL.

## Frozen SHA (must MATCH)

| Item | SHA256 |
|------|--------|
| SOA MIG top | `B4FBF8A64E828E28EB3C0470B4C224629687551B62A1961D89A0B470A0297C23` |
| SOA wavefront | `322995D6D053AEEF995687F8F6A6CE2E89FC50B4DFDB8875EC29FE1215C0FF28` |
| plane engine | `689C56D7CEA6CBDE8DCC376394026AEEBC736708CC73C7BD712D738B336EA6D5` |
| Global reducer | `D6D6882BD4C5505246C9B24CB95CEF66BE3BC1F0881545AEDCEC302B01C14B7B` |
| bind | `5CDBCC47E5D0CC0A4977EA916D4698E453B2EABBE5263FEAE627864F380D7803` |
| TinyGPT | `B8F485E5A98903A56C23BADEB30CD84451E728F42E64296343086E6D51351880` |
| snap candidate | `C578AF0B31FE3A193BD1322F40FE0091764AA73514C80A54F14DE4280A6A08EB` |
| A contract | `F5843C60ABAE1662B9EC85C76801EF775E558DC3DBD3C02D1043E092EB6C663C` |
| B audit | `421BADECFF8BDAA9E0891C3A31693A405D4EAF6C3E44AF3F85DB274D415FAC05` |

## CONTROL query

64 candidates, cues identical to Attempt10/SOA bench. Expect 4 AR, 52 beats, 832 B, planes 16/32/4, Global Top-8 `9,11,25,27,41,43,57,59` @165, pack `3b392b291b190b09`, TinyGPT `pred=664` after one `start_fwd`. 800k = **NOT_MEASURED**.

## Verdicts (fixed)

| Class | Rule |
|-------|------|
| `PASS_NARROW_ACCEPTANCE_READY` | live-producer causal chain + safety + SIM_FULL=0 snap-sub P&R BRAM≤135 WNS/WHS≥0 TNS/THS=0 + harness dry-run; BOARD/800k listed OPEN |
| `FAIL` | any falsifier or missing load-bearing artifact |

## Allowed new paths

`rtl/native_graph/integrate/*native_v1_ab*` · `tests/xsim/*native_v1_ab*` · `vivado/tcl/*native_v1_ab*` · this result dir · mailbox.

No edits to Attempt10, A/B artifacts, MIG IP, frozen bits, `LOOP_STATE.json`.
