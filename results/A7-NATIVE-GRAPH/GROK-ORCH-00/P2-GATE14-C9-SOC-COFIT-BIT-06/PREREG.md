# P2-GATE14-C9-SOC-COFIT-BIT-06 — preregistration

**PROGRAM=NO. No COM12. No JTAG.** Parent `P2-GATE14-C9-CMD-ACCEPT-FIX-05` = PASS_NARROW / XSim.

Frozen oracle SHA `062932B3853144526B1C9A42C2076966C45EF108C707546C68C9BC89754C912B`.
HOLD_A=653 UNREL=689 CONTRA=237 HOLD_B=60. Packs `8382238122802120` / `8786858483828180` / `2322832182208180` / `8382438142804140`.

## Unknown (one)

If SoC cofit instantiates the **same** learned_prior_graph + c9_glue that XSim PASSed (one store, one scorer, one minheap, one bind, one TinyGPT) and exam bind uses that graph TopK **not** persist FAST IDs, do HOLD_A/U/C/B still emit 653/689/237/60?

## Must not

Program. COM12. Reuse A0B338E0. Second scorer/TopK/LM. Hard-code pack/pred. Edit ORACLE. 40 facts. Self GATE14_PASS / BOARD_PASS.

## Unique bit

Only after integration XSim PASS and full-chip WNS>0, TNS=0, BRAM36≤135, CDC classed. Name contains `C9-SOC-COFIT-BIT-06`. Stop `BIT_READY_FOR_CODEX`.
