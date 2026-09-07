# RESULTS — U8-R3-TYPECLASS-TOPK-TO-LM-00

Marker: `U8_R3_TYPECLASS_TOPK_TO_LM_PASS`
XSim 2026.1 start Mon Sep 7 08:44:58 2026; exit 08:46:50.
Sim time: 280342605 ns. XSim wall ~110 s. Vivado: `U8_R3_XSIM_OK`.
Encoder SHA matches U8-R2 (`bbd95f7f…8292aa`). Encoder RTL not edited.

## Ranking (U7 DUT)

Install-chiller poke `eid=1 iid=1 ev=1 iv=1`, freeze, no train.
Heap from `topk_class_id_o` (`sc_idi = {16'd0, cid_q}`; pads `0xFFF0+`).

```text
HEAP cid=65 66 67 65520 65521 65522 65523 65524
```

Pads `0xFFF0+` are not CLASS_ID 1..443. Host did not supply CLASS_ID.

## Encoder V1

```text
ntok=12 rec=3 skip=5
stream = 1 1 0 0  1 1 0 1  1 1 1 0
```

Rank-order `[eid,iid,rid,xid]`. CLASS_ID / low8 / member-NID not in the stream.

## LM-06 chain

| Event | Count |
|---|---|
| ctx_we (eirx beats) | 2 |
| ctx_we_beats | 2 |
| start_fwd pulses | 1 |
| start_fwd_beats | 2 (H4 overlap; one busy rise) |
| core_busy rise | 1 |
| core_done | 1 |

CTX stream matches encoder. `a7ng_native_ctx_bind` not instantiated.

## Host

```text
n_host_tok  = 0
n_host_w    = 0
n_host_win  = 0
n_host_addr = 0
rank n_host_or = 0
mem_we_exam = 0
```

## Pred (observation only)

`core_pred = glue_pred = 861`. FPGA-owned. Not HOLD_A. Not OUT=653. Not a semantic TYPE_CLASS claim.

## Not claimed

LM understands TYPE_CLASS · silicon · Gate14 · Q-head · OUT=653
