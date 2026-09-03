# P2-GATE14-C9-CMD-ACCEPT-FIX-05 — preregistration (before data)

**PROGRAM=NO. No COM12. No JTAG. No 40 facts. No unique bit until graph-only C9 packs and RTL TinyGPT match the frozen oracle.**

Parent `P2-GATE14-C9-SOA-LM-BIT-04` = **FAIL**. First divergence is command/testbench handshake, not TinyGPT and not the frozen oracle.

```text
HOLD_A actual C9=2383218281228020 want=8382238122802120  OUT=640 want=653
UNREL  C9 and OUT=689 match
CONTRA C9 and OUT=237 match
HOLD_B actual C9=4383418281428040 want=8382438142804140  OUT=939 want=60
GRAPH_Q even-only: A 10,12..22  B 30,32..42  (10/20 per curriculum)
```

Frozen oracle (do not retarget, SHA unchanged):

```text
ORACLE.json SHA256=062932B3853144526B1C9A42C2076966C45EF108C707546C68C9BC89754C912B
HOLD_A OUT=653 pack=8382238122802120
UNREL  OUT=689 pack=8786858483828180
CONTRA OUT=237 pack=2322832182208180
HOLD_B OUT=60  pack=8382438142804140
```

Do not treat OUT=640 or OUT=939 as a new oracle. Do not edit TinyGPT until C9 pack is correct.

## Unknown (one)

Does the C9-04 TB `do_cmd` one-cycle valid pulse drop odd C_FIRE/C_REW so the graph never sees tokens `0x11,0x13,..,0x23` / `0x31,..,0x43`? If handshake authority (`cmd_valid && cmd_ready`, `query_valid && query_ready`, reward `ack_count`/`commit_seq` +1) is repaired in the TB only, do all four C9 packs match C9-03?

## H_CANDIDATE

TB sequencing. `LESSON_A/B` is intent, not evidence. Holding `cmd_valid` until one observed posedge handshake, then waiting C_FIRE snap and C_REW commit_seq+1, consumes 20/20 distinct tokens and restores packs `8382238122802120` / `8786858483828180` / `2322832182208180` / `8382438142804140`.

## H_RIVAL

1. Product glue drops odd FIRE even with a correct handshake.
2. Graph `query_ready` never rises for odd qids.
3. Reward commit does not increment for odd facts.

Authority = handshake monitors, not `LESSON_*` lines. Do not patch product RTL unless those monitors prove a DUT drop after the TB holds valid correctly.

## Must not

Program. COM12/JTAG. Bit `A0B338E0`. 40 facts. Edit ORACLE.json. Run TinyGPT if any C9 pack mismatches. Second scorer/Top-K/LM/FAST-ID. Unique bit if XSim fails. Self BOARD_PASS / GATE14_PASS.
