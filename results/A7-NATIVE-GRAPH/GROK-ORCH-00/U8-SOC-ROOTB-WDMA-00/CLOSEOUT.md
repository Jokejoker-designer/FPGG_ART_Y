# CLOSEOUT — U8-SOC-ROOTB-WDMA-00

```text
GATE                     = U8-SOC-ROOTB-WDMA-00
BASE                     = 109b10da19a954809469d0dca334a197a521c0ba
RESULT                   = PASS
EVIDENCE_CLASS           = XSIM + RTL_FACT
FIRST_DIVERGENCE         = NONE (this run)
PRIOR_FIRST_DIVERGENCE   = WDMA_SILENT_DROP (xsim_054007_fail.backup.log)
VIOLATED_INVARIANT       = (closed on this slice) ACK ⇔ one commit
WIRE                     = a7ng_wdma_cdc.m_go_ready
RTL_EDIT                 = YES (one named wire: m_go_ready)
SOC_TOP_EDIT             = NO
FILES_CHANGED            = rtl/board/a7ng_wdma_cdc.sv
                           rtl/lm/weight_tile803k.sv (dma_go_ready default 1)
                           bag TB
SOC_WDMA_ROOT_B          = SLICE_XSIM_PASS (not full SoC; dest port unwired)
PERSIST_GEN_FAST         = DISCONNECTED
C7_ADDR                  = OBSERVE_ONLY
DUT                      = store+persist_axi_bridge | wdma_cdc+ddr_tile_dma
SOC_TOP                  = NOT instantiated
MIG                      = NOT instantiated
BIT                      = NO
PROGRAM                  = NO
QHEAD                    = NO
U8R                      = NO
HOLD_A_ORACLE_RETARGET   = NO
GATE14_PASS              = NO
BOARD_PASS               = NO
SEMANTIC_LM_CLAIM        = NO
CLASS                    = LM_CHECKPOINT_CONTEXT_MISMATCH (unchanged; not this unknown)
```

## Patch (this lake)

Named wire `m_go_ready` on `a7ng_wdma_cdc`:
`assign m_go_ready = m_rst_n && !cmd_hold_valid`.
Hold capture is `m_go && m_go_ready`. Illegal `m_go` while hold is occupied still sets `cmd_hold_overflow` (protocol sticky; payload not stored).

Tile dest (`weight_tile803k` D_GO) waits `dma_go_ready` before the one-cycle `dma_go` pulse. Port defaults to `1` so SoC top / `tiny_gpt803k_core` stay unedited (`SOC_TOP_EDIT=NO`). Dest is **not** in this xvlog snapshot.

TB dest-like producer (`dest_pulse_go`) waits `m_go_ready` on the same CDC+DMA path.

## Allowed claim

On a SoC-reachable persist slice (learned_prior_store + persist_axi_bridge,
AXI stub, dual clock, grant stall), XSim showed BRAM update ACK ⇔ commit,
store-full NAK, and FLUSH 65 beats with BRESP=AW then RELOAD identity.

On the SoC-reachable WDMA adapter (`a7ng_wdma_cdc` → `ddr_tile_dma` →
always-ready AXI slave), dest-like producer wait + `m_go_ready`:
unowned first `m_go` occupies hold and drops ready; overflow stays 0;
after grant, second waited `m_go` commits; cmd/s_go/m_done/BRESP = 2.
Mid-txn both-domain reset clears hold/overflow/DMA; one post-rst commit.

Log marker `U8_SOC_ROOTB_WDMA_PASS`. tcl `U8_SOC_ROOTB_WDMA_XSIM_OK`.

## Not claimed / not closed

`arty_a7_ng_native_v1_ab_soc_top` was not instantiated. `m_go_ready` is
**not** wired through SoC top (dest default=1 on silicon until a later
SOC_TOP_EDIT lake). persist_gen_fast is still DISCONNECTED. C7 is still
OBSERVE_ONLY. No silicon. This PASS is not a PROGRAM license.

U7A original FAIL remains immutable. P7 TYPE_CLASS chain is a different
unknown (not re-run as proof here). CASE_G still prints `under=1`
(`ddr_tile_dma` sticky); BRESP identity is an always-ready stub, not MIG.

## NEXT

Do not auto-open U8R / U9S / U9I / U9P / U10.
Do not declare BOARD_PASS or GATE14_PASS.
