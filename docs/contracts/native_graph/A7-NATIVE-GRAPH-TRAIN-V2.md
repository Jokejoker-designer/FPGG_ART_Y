# A7-NATIVE-GRAPH-TRAIN-V2 — retraining law (frozen protocol)

**Status:** FROZEN protocol. **HARNESS archived** under `results/A7-NATIVE-GRAPH/TRAIN-V2/` (`A7NG_TRAIN_V2_HARNESS_PASS`, 2026-08-22). Not BOARD. Not §14 SoC.  
**Lane:** new results tree `results/A7-NATIVE-GRAPH/TRAIN-V2/` only.  
**Does not overwrite:** encoder 03E, NG-00…09 DONE_ENG archives, frozen 01R/02M/LM-06/A0.3 bits.  
**Authority:** this file + `BRAM_WORKING_MEMORY_SPEC.md` §37–38 + blueprint `04`/`07`/`10`/`14` + `CONTRACT_FREEZE.md`.  
**law_id:** `a7ng-train-v2` (bundle TermGen + WM + reset-learned).

Old learned state was produced by a **different law**. Continuing TRAIN on that state after changing representation, promotion, prune, or confidence **destroys attribution**.

## When to retrain

| Change | Retrain from zero? |
|--------|-------------------|
| BRAM buffer, banking, ping-pong, DDR burst, pipeline retiming | **No**, if bit-exact semantics |
| Top-K implementation, **output exact** vs old | **No** |
| Scheduler that does **not** change order/meaning of learning | **No** |
| Token / relation representation | **Yes** |
| Learning / update law | **Yes** |
| Confidence / promotion rule | **Yes** |
| Candidate → evidence → long-term knowledge | **Yes** |
| Teacher supervision format | **Yes** |
| Contextual prune that **affects** learning | **Yes** |

Plumbing (first three rows) = same `law_id`.  
Any **Yes** row ⇒ mint `A7-NATIVE-GRAPH-TRAIN-V2` and reset **learned memory only**.

Minesweeper/graph + BRAM working memory as spec’d is a **Yes** bundle → **TRAIN-V2 from zero**. Keep the old model as frozen **control**.

## What is reset / what is not

```text
OLD MODEL          frozen baseline — do not edit, do not delete
NEW TRAIN-V2       clear graph learned state
                   clear confidence
                   clear learned edges
                   clear episode bindings if semantics changed
                   KEEP firmware/RTL bitstream architecture
                   teacher = ON
                   learning = ON
```

Forbidden: delete old closeouts, overwrite old SHA-locked bits, “warm start” V2 on V1 DDR priors.

## Same curriculum first

Do **not** change law and curriculum in one experiment.

```text
OLD LAW vs NEW LAW
same 20 facts, then same 40 facts
```

Compare on the **same** bag:

```text
Top-1
Top-K recall
hard-negative FP
held-out paraphrase
candidates/query
DDR traffic
latency
reset/retrain
```

Only after that attribution is clean may the teacher “teach better” or grow the corpus.

## Scale ladder (no skip)

Each rung: teacher-on acquisition **and** teacher-off PASS on that scale before the next.

```text
20 facts  → teacher-off PASS
40 facts  → teacher-off PASS
256       → PASS
4k        → PASS
16k       → …
800k      → last, never first
```

## Blind exam (every scale)

```text
TRAIN        teacher=1  learn=1  freeze=0
FREEZE       teacher=0  external_LLM=0  learn=0  freeze=1
BLIND TEST   user query only
```

Host/teacher **must not** send in BLIND:

```text
entity=FPGA
intent=DEFINE
winner
memory address
answer
gradient  ΔW  hash  next_token  relation_path  candidate_ranking
```

## Two independent from-zero runs

After V2 law is frozen:

```text
Run A:  RESET → train mapping A  → freeze → blind
RESET learned state (architecture stays)
Run B:  train mapping B  → freeze → blind
```

PASS only if B forgets A and acquires B (knowledge in **learned state**, not ROM).

## Gates (do not start V2 while these are open)

1. `ng02r_flow` PASS (conservation, ready/valid).  
2. New `law_id` published (one unknown: the law).  
3. Old model SHA / DDR dump / closeout archived as **CONTROL**.  
4. 20-fact corpus frozen **identical** for CONTROL vs V2.  
5. Then `results/A7-NATIVE-GRAPH/TRAIN-V2/run_a/` and `run_b/`.

AI does not declare BOARD_PASS. Harness teacher-off ≠ V2 board exam.
