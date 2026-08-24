# STATUS AMENDMENT 2026-08-18 (evidence below is not deleted)

**Scientific status:** `VALIDATION_PASS_WITH_KNOWN_ERRATA`  
**Claim:** **HOLD** — do not treat the body of this file as a final `BOARD_VALIDATED` grant.  
**LM-05:** **HOLD**

R2 is a **validation** set. Extra +2 full `0x34` steps were chosen after attempt-1 HELDOUT FAIL (seed 3). K=513 first issue after 511 is known-wrong; the ladder issued `0x59` twice and scored the second fold. The 5% CE gate can PASS via class collapse (constant-class ~12.5% on 8 balanced targets; last_loss is 0 or 16). PPL is derived from the same CE.

Do not overwrite this directory. Confirmation is R3 (`results/A7-LM-04/candidate_r3/`).

---

# A7-LM-04 HELDOUT-R2 BOARD PASS — 2026-08-17

100,352-param 2-layer / 4-head TinyGPT. Persistent W flushed/reloaded through official AXI MIG. FPGA-resident forward + last-token update. Host compares only.

**Claim:** `ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED`  
**LM-05:** authorized (WNS +0.340 ns ≥ +0.20 ns). Not started.

Not a general-purpose LLM. `law_id` remains `lm05-signsgd-v1`.

The previous candidate `arty_a7_lm04.bit` `0716CF25…7883DB2` stays **FAIL_HELDOUT_INVALID_TASK**. Its closeout and `results/A7-LM-04/ladder.json` were not overwritten.

## Silicon (R2)

| | |
|--|--|
| Board | Digilent Arty A7-100T JTAG `210319BE776EA` / UART `210319BE776EB` COM12 |
| Bit | `build/out/arty_a7_lm04r.bit` `6BED0DE83922B45BABBD8D2DD0F46F0F469474CB9F0A8A1DF96D1421817EF6B9` |
| WNS / TNS / WHS | **+0.340 / 0 / +0.036** |
| FAIL bit still on disk | `0716CF254D767778E792F4BAFD38EB0CF9014B731B39F21CF612D2DDE7883DB2` |
| Frozen 00–03 / `mig.prj` | unchanged |
| HELDOUT-R2 SHA | `941a7b243e1c1fcaf5f920978067e4c5b8190342600a1374a54e94208d6c4d3c` (seed 11, n=24) |
| CDC | `t_start_meta` clears on busy falling edge |

## HELDOUT-R2 (preregistered before board)

Train remains `[k] → 32+(k-1)`. Held-out is last-token retrieval with distractors: prefix length 2–4, last token `k∈1..8` balanced, distractors `9..40`, target `32+(k-1)`. Not the V1 random-label set.

Oracle (board_corpus only, head-24 + 1 full, then 2 extra full steps): all three seeds improve last_loss CE. Board used the same recipe. No train-on-HELDOUT.

## Gates (conjunctive, all met)

| Gate | Result |
|------|--------|
| param 100352 / frozen SHA / mig.prj | PASS |
| HELDOUT-R2 hash frozen | PASS |
| WNS≥0 TNS=0 | PASS +0.340 / 0 |
| WNS≥+0.20 (LM-05) | PASS |
| upload spots / fold0 | PASS xor=2 add=11803320 |
| one-full vs oracle | PASS pred=167 loss=16 wr=82048 xor=7 add=11822211 |
| ≠ head-only | PASS (253 / 11808067) |
| persist DDR reload | PASS 100352 B, fold1 |
| AFTER | PASS wr_n unchanged |
| FPGA argmax | PASS |
| K=257→511→513 same session | PASS, counters=0, swap/overlap/ntile as specified |
| requant 8 / 13 / 0 + 0x58 same session | PASS +sat/−sat/non-sat counts exact |
| held-out seeds 2/3/5 | 384→320 / 352 / 304; median **16.7%**; PPL down all three; no degrade |
| FAIL bit preserved | PASS |

Evidence: `results/A7-LM-04/candidate_r2/ladder.json`, `heldout_preregister.json`, `oracle_solvability.json`.

## Honest limits

- This is a 100k fixed-point last-token Transformer on Arty A7. Not an open-domain LLM.
- Persistent W is a BRAM working image with DDR flush/reload. 100k law is sequential on `clk50`. 128-lane tensor path is the LM-02-class engine for K/requant.
- First 3-tile ping-pong after a 2-tile run leaves a stale last DDR tile; the ladder issues K=513 twice and scores the second fold (bit-exact). CDC consecutive start is separately proven (257 then 511 then 513 plus requant cases in one program).
- Held-out training is `0x3A` (head-24 + one full on `board_corpus`) plus two extra FPGA `0x34` full steps on the same train pairs only.
- AFTER / last-query / sign-SGD + head shift / STE LN. Not full-sequence backprop.

## Next

A7-LM-05 is **HOLD** (2026-08-18 amendment). WNS +0.340 does not authorize LM-05 while first-try K=513 and confirmation-set rules are open. Frozen 00–03, FAIL `arty_a7_lm04.bit`, and this R2 directory stay in place.
