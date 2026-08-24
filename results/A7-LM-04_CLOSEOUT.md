# A7-LM-04 — silicon evidence, not closed

**Status:** OPEN  
**Claim:** `ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED` **not granted**  
**LM-05:** not authorized (WNS +0.187 ns < +0.20 ns, and 04 is not closed)

Host compared only. Host did not compute board CE, next-token, or weight updates.

## Silicon (same bit as programmed)

| | |
|--|--|
| Board | Digilent Arty A7-100T JTAG `210319BE776EA` / UART `210319BE776EB` COM12 |
| Bit | `build/out/arty_a7_lm04.bit` `0716CF254D767778E792F4BAFD38EB0CF9014B731B39F21CF612D2DDE7883DB2` |
| WNS / TNS / WHS | +0.187 / 0 / +0.045 |
| LUT / FF / BRAM / DSP | 25259 (39.8%) / 30823 / **130/135 (96.3%)** / 156 |
| `law_id` | `lm05-signsgd-v1` unchanged |
| Frozen 00 | `449A330B…34783` unchanged |
| Frozen 01 | `96065A17…507B8` unchanged |
| Frozen 02 | `7CEBA854…95CC4` unchanged |
| Frozen 03 | `C98B7C85…9F23D1` unchanged |
| `mig.prj` | `914A9E4B…1AC329` identical to frozen A7-LM-01 official preset |

## Gates

| Gate | Result |
|------|--------|
| param count 100352 | PASS |
| `mig.prj` SHA | PASS |
| frozen 00/01/02/03 SHA | PASS |
| HELDOUT SHA `29d56dcc…1873ba` | PASS (frozen, not edited) |
| WNS ≥ 0, TNS = 0 | PASS (+0.187 / 0) |
| upload spots 0/1/16384/18432/83968/100344 | PASS |
| fold0 vs oracle seed 2 | PASS xor=2 add=11803320 |
| one-full `[1]→32` lr=3 | PASS pred=167 loss=16 wr=82048 xor=7 add=11822211 |
| one-full ≠ head-only | PASS (head-only is xor=253 add=11808067) |
| persist flush+DDR reload fold | PASS 100352 bytes, same fold1, under/berr/rerr=0 |
| AFTER 0 extra writes | PASS wr_n 82048→82048 |
| next-token FPGA argmax | PASS `0x3B` / status pred=167 |
| K=257 ping-pong | PASS swaps=1 overlap=31 ntile=2 counters=0 |
| K=511 ping-pong | PASS (isolated after reprogram) xor=114574343 add=4229634061 macs=65408 swaps=1 overlap=256 ntile=2 |
| K=513 ping-pong | PASS (isolated) xor=4186759747 add=4270895305 macs=65664 swaps=2 overlap=289 ntile=3 |
| requant +sat / −sat / non-sat counts | PASS case 8 (45/0/83), case 13 (0/1/127), case 0 (0/1/127), folds exact |
| held-out 3-seed median CE drop ≥ 5% | **FAIL** 256→256 all seeds, median 0 |

Evidence: `results/A7-LM-04/ladder.json`, `ladder_run1.json`, `tensor_k511.json`, `tensor_k513.json`, `tensor_c8.json`, `tensor_c13.json`, `tensor_c0.json`.

## Why K/requant needed a fresh program each time

UART `t_start_meta` was cleared on a **1-cycle** `t_done` pulse. The 2-FF CDC to `clk50` drops that pulse, so only the **first** tensor start after reset is accepted. Later `0x50`/`0x59` are silent.

K=257 / 511 / 513 and cases 8 / 13 / 0 were therefore run as **one tensor command per reprogram** of the **same** `arty_a7_lm04.bit` (SHA unchanged). Counters and folds above are from those isolated runs.

RTL now clears `t_start_meta` on the **busy falling edge** (`rtl/board/arty_a7_lm04_top.sv`). That fix is **not** in the current bit. Do not rebuild for close; a new bit would need a new one-full.

## Why held-out cannot close this contract as written

Frozen HELDOUT (seed 7, 16 pairs) draws `tgt = 48 + randint(0,15)` **independent of the prefix**. There is no mapping to learn from `board_corpus` (`[k] → 32+(k-1)`).

| Path | Result |
|------|--------|
| FPGA `0x3A` board_corpus, then FPGA last_loss on HELDOUT, seeds 2/3/5 | 256 → 256, median drop 0. Train CE on board_corpus did move (seed 3: 128→112, seed 5: 128→80), matching the oracle. |
| Oracle same recipe | same 256→256 |
| Oracle **memorize HELDOUT** 8 full steps (not used to close) | 256→192 = 25% on all three seeds |

So the 100k law can reduce CE on those 16 pairs if it is trained on them. That is **train CE on the frozen set**, not held-out generalization. The contract forbids closing on train-only CE and requires a held-out drop.

No seed degraded HELDOUT (0% ≤ 2%). PPL did not fall.

## Honest limits

- Persistent W is a BRAM working image flushed/reloaded through official AXI MIG. Compute for the 100k law is the sequential `tiny_gpt100k_core` on `clk50`, not a 128-lane 100k GEMM.
- 128-lane tensor path is the LM-02-class engine used for K and requant gates.
- AFTER was proven by a second `0x34` with AFTER on; `wr_n` did not increase.
- This is last-token / last-query attention, sign-SGD + head shift, STE LN. Not full-sequence backprop. Not an LLM.

## How to actually close (needs a director choice)

1. **Revise HELDOUT** to a learnable mapping that is not `board_corpus`, freeze a new hash, re-run 3 seeds. New contract revision, same `law_id` is OK if only the eval set changes.  
2. **Explicitly accept** “frozen 16-pair CE after FPGA train on those pairs” as the quality gate (memorization). Then run that ladder on COM12 — oracle already shows ≥5%. That is a contract wording change, not a silent pass.  
3. **Waive** the 5% held-out gate in writing because the published HELDOUT labels are independent of the prefixes.

Do **not** start A7-LM-05. Frozen 00–03 bits stay in place.
