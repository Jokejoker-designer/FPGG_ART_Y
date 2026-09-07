# RESULTS — U9-FINAL-SOURCE-FREEZE-00

```text
RTL_EDIT    = NO
SOC_TOP_EDIT= NO
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
BOARD_PASS  = NO
M10         = TYPECLASS HOST_MODEL PASS (NID FAIL immutable)
HS13        = TYPE_CLASS table N=443 (not 800k full scan)
evidence    = RTL_FACT + GIT + XSIM (U8R production-path confirm)
```

## FINAL_SOURCE_COMMIT

```text
BRANCH               = grok-orch/v31-canonical-00
FINAL_SOURCE_COMMIT  = bdddbd68b048054dc0c52e87685829a590f25270
SUBJECT              = U8R: production C9 uses parent TopK; cand_* walk fixture-only.
PRODUCTION_RTL_DIFF  = empty (git diff HEAD -- rtl/ constraints/ vivado/tcl)
```

Last production RTL edit is U8R. This lake does not patch RTL.

## git status

| Path class | Result |
| --- | --- |
| `rtl/` `constraints/` `vivado/tcl/` | **CLEAN** vs HEAD |
| MIG `*.xci` | **CLEAN** vs HEAD (blob `305d8614…`) |
| MIG generated `*.xdc` (3 files) | **CRLF dirt quarantined** — not committed |
| Historical `U3Q-R3/.../xelab.log` | tracked-ignored log dirt — not production |
| Untracked ooc/xsim_work/docs | **not production source** — not git-added |

Dirty production tree STOP did **not** fire. Full porcelain is not empty (MIG CRLF + untracked evidence + this bag). That is not a production-RTL freeze failure. Do not git-add MIG.

## Blueprint §21 record

```text
TOP                      = arty_a7_ng_native_v1_ab_soc_top
PART                     = xc7a100tcsg324-1
PHYS                     = 4
WAVE                     = 16
K                        = 8
MAX_CANDS (ab_core)      = 64
VIVADO                   = 2026.1  SW Build 6511674
ROUTER_PROFILE_FINAL     = TYPE_CLASS_MASKED_CONJUNCTIVE
CAND_CAP_FINAL           = 64
DDR_QUERY_BOUND_FINAL    = 1024 bytes/query (U3 ping-pong beats=64)
LEGACY_NID_ROUTER        = P2_deep CAND_CAP=256 DDR_BOUND=4127 DISCONNECTED from U6
SYNTHETIC_CAND_GEN_PROD  = 0 (soc_top u_ab)
SYNTHETIC_CAND_GEN_FIX   = 1 (module default / sim fixture)
```

SHA sets (this measurement):

```text
XDC_SET_SHA256           = 67C18163BA5A7C26BFC33DE24E50D487D15E3B4A31D542E6452C55059E27B8B0  (17 files)
MIG_XCI_HEAD_BLOB_SHA1   = 305d86144b2a11c74cd51c27a2f0852500dbd5e0
MIG_XCI_BLOB_SHA256      = 6F17988A3274A5DBC6628AA9204F7C44E4704ACF034D3710DC5E02697ACBB127
IP_XCI_COUNT             = 1
IP_XCI_SET_SHA256        = 7A1A0E241A5395A07B5B98FC5BAB72CB6251B8FCFEBDB49FAF6373D4BA843C34
BUILD_U2_TCL_SHA256      = D5A8D235608CFAF21FA7B85417FF069CC9C1084E7753488721099A36932FA441
TCL_SET_SHA256           = F0852F7BA9E070D5CF03D4E8B920EC575014AA022D84CFD750BB359036944775  (159 files)
BLUEPRINT_V3_1_SHA256    = 2782B12D4022B99BD16CE44D5D54047F32A0F54D82D9DC414B0C619BECA9FF2D
SOURCE_MANIFEST_COUNT    = 414
```

Key production RTL SHA256: `SHA256.txt`. Full list: `SOURCE_MANIFEST.txt`. Cross-bag match: `HASH_CROSSCHECK.txt`.

## One retrieval engine (file fact + confirm XSim)

soc_top instantiates `a7ng_native_v1_ab_core` with `SYNTHETIC_CAND_GEN(1'b0)`.
Confirm XSim (U8R TB, frozen rtl, snapshot `u9freeze`):

```text
PROD id0=65 id1=66 id2=67
FIX  id0=0 id1=0 id2=0
U8R_REMOVE_SYNTHETIC_PRODUCTION_PASS
U9_FINAL_SOURCE_FREEZE_XSIM_OK
$finish 155 ns
FIRST_DIVERGENCE = none
```

Not U9R full regression. Not TYPE_CLASS→LM chain re-run (P7 already archived; pred_obs=861 MISMATCH).

## Residuals (not closed, not relabeled)

```text
SOC_WDMA_ROOT_B     = SLICE_XSIM_PASS (U8-SOC-ROOTB-WDMA-00)
                      dest dma_go_ready NOT wired in soc_top; default 1
                      OPEN_AUDIT at full SoC / silicon
native_ctx_bind     = still in a7ng_native_v1_ab_core (NID-era LM pack)
TYPE_CLASS UART exam= not the soc_top path
U7A reachability    = FAIL immutable
persist_gen_fast    = DISCONNECTED
C7_ADDR             = OBSERVE_ONLY
U2 POST_ROUTE WNS   = 0.808 on pre-U8R TOP SHA 00613B8A… — not this RTL
SEMANTIC_LM         = LM_CHECKPOINT_CONTEXT_MISMATCH
pred_obs (P7)       = 861 (not HOLD_A 653)
```

## Hard stops honored

BIT=NO PROGRAM=NO REPROGRAM_AGAIN=NO QHEAD=NO HOLD_A_ORACLE_RETARGET=NO.
No reseat of `1F0F2ABB` / `9CA2B30D` / `F24150BD` / `3A7EF204`.
No git-add of MIG or `a7lm06_wmem.hex`. No force-push.
U9S/U9I/U9P/U10 not opened.
