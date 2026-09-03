# P2-GATE14-20FACT-RESIDENT-02 RESULTS

**PROGRAM=NO. RESIDENT_ONLY.** This agent does **not** declare `GATE14_PASS`, `TEACHER_OFF`, or `BOARD_PASS`.

Parent `P2-GATE14-LM-START-WIRE-01` = **PASS_NARROW_C10_G5_MATCH** (2-lesson surrogate, `cons_last=2`, C10 OUT 549/861/237). That is **not** Gate14-20.

## Return

```text
GATE=P2-GATE14-20FACT-RESIDENT-02
CLASS=FAIL_DIVERGENCE
STOP=HOLD_A OUT=733 want=549
PROGRAM=NO
RESIDENT_BIT=A0B338E0AF8836056574913B40106D2DA4DE388686067E7EDEF4D009D57F7E2B
CORPUS_20=23A4B5039CB80FECC338DF26BAB4E31EC8B314F7DBC178AD3AA572EA06963F8E
C0=34314347C00114A7
UART_SHA256=BD9EF55A603F01E3E767D2F7B0CAE768D28CFAF68F27D3C306CE9C353537922F
cframe_n=600 bytes=13250
run_40=false
TEACHER_OFF=not_claimed
GATE14_PASS=not_claimed
BOARD_PASS=not_claimed
```

COM12 opened once. JTAG `210319BE776EA` not programmed. Host: `resident_20fact.py`. Frozen corpus CONTROL only; UART objects were legal TYPE 0x01–0x0D.

## Resident C0/STATUS — EVIDENCE

`RESIDENT_OK.txt` / `exam_log.json` tag `resident_status`:

```text
c0=34314347C00114A7
mode=8
gen=3
cons=2
txn=3
addr=50333824
out=237
x=0
adig=0
bdig=68853891848
afor=1
bvis=1
dump_ckpts=0..11
CONFIG=not_lost
```

C0 MATCH. No `WAIT_NEW_TOKEN`. Starting MODE=8 / cons=2 is leftover from the 2-lesson parent, not a 20-fact freeze.

Boot on this gate (legal commands only): `TRAIN_RESET` then `TRAIN_BEGIN`.

```text
after_treset_boot  GEN 3→4  sdig=0  cons=2  mode=8
train_begin        MODE=5   GEN=4   cons=2  txn=3
```

## 20 A lessons — EVIDENCE

Each lesson: query token `T_PRE_A=0xA1` → read live C6 txn → reward(+3) with that txn echo → wait C5 consume **exactly +1** → wait C7 `busy=false` and `addr≠0` before next.

20/20 `A_lesson_ok` in `exam_log.json`:

| i | txn_used | cons0→cons | c7_addr |
|--:|---------:|------------|--------:|
| 0 | 4 | 2→3 | 50331904 |
| 1 | 5 | 3→4 | 50331904 |
| 2 | 6 | 4→5 | 50331904 |
| 3 | 7 | 5→6 | 50331904 |
| 4 | 8 | 6→7 | 50331904 |
| 5 | 9 | 7→8 | 50331904 |
| 6 | 10 | 8→9 | 50331904 |
| 7 | 11 | 9→10 | 50331904 |
| 8 | 12 | 10→11 | 50331904 |
| 9 | 13 | 11→12 | 50331904 |
| 10 | 14 | 12→13 | 50331904 |
| 11 | 15 | 13→14 | 50331904 |
| 12 | 16 | 14→15 | 50331904 |
| 13 | 17 | 15→16 | 50331904 |
| 14 | 18 | 16→17 | 50331904 |
| 15 | 19 | 17→18 | 50331904 |
| 16 | 20 | 18→19 | 50331904 |
| 17 | 21 | 19→20 | 50331904 |
| 18 | 22 | 20→21 | 50331904 |
| 19 | 23 | 21→22 | 50331904 |

```text
C5 2→22  (+1 each, no jump, no decrease)
C6 txn 4..23  (echoed; host did not invent txn)
C7 addr sticky 50331904 = 0x03000100  (NG_DDR_PRIOR_BASE+subj; WRAP_LIMIT=6)
```

This is a real 20-lesson consume path on the resident bit. It is **not** the G5 2-lesson surrogate (`cons_last=2`).

**C7 honesty:** the host treated `C5+1` + `busy=false` + `addr≠0` as MIG ACK. Addr did **not** walk 20 distinct AXI locations. UART log `busy_seen=False` on all 20 `LESSON_OK` lines — STATUS samples never caught `busy=1`. Do not read the table as 20 unique DDR writes or as a captured MIG busy pulse.

## FLUSH → BRAM_KILL → RELOAD → FREEZE A — EVIDENCE

`exam_log.json` tags `after_flush_a` / `after_kill_a` / `after_reload_a` / `freeze_a`:

```text
freeze_a
  MODE=8
  GEN=4  (!=0)
  cons=22
  txn=23
  addr=50331904
  pack=4267489577458535177 = 0x3B392B291B190B09
  out=0  lmdn=0  lmst=0
  x=0
  adig=0
  bdig=16777217 = 0x01000001
  afor=1 bvis=1
  dump_ckpts=0..11
```

Live C0–C11 on the freeze dump. C9 stayed the **existence graph pack**, not G5 persist FAST IDs `0x0706050403010002`.

`adig=0` with `afor=1` is sticky from the prior 2-lesson session. Numeric `ADIG≠BDIG` (0 vs 16777217) is **not** a 20-fact mapping-A digest proof.

## First exam — STOP_DIVERGENCE — EVIDENCE

Legal `EXAM_QUERY` token `T_HOLD_A=0xA2`. No host idx/delta/address/cue/topk/answer/MODE.

```text
exam_HOLD_A  (second sample, LMDN rose)
  MODE=8
  LMDN=1 LMST=1
  OUT=733   want G5 HOLD_A=549
  pack=0x3B392B291B190B09
  x=0
  GEN=4 cons=22 txn=23
  C0 still 34314347C00114A7
```

Host `Divergence`: `HOLD_A OUT=733 want=549`. Stopped. Files written:

- `STOP.txt`
- `gate14_20fact_result.json` `CLASS=FAIL_DIVERGENCE`
- `uart_raw_stop.bin` / `uart_raw_stop.txt`
- `UART_CFRAME_SHA_stop.txt` (SHA re-hashed on close: match)

## Not run (by stop rule)

UNREL, CONTRA, TRAIN_RESET-forget-A, mapping B (20× PRE_B), FLUSH/KILL/RELOAD/FREEZE B, blind HOLD_B, 40-fact, reprogram.

Do not back-fill those rows. Do not call this Gate14-20.

## Classification (keep separate)

| Claim | Label |
|-------|--------|
| Resident C0 live, config not lost | EVIDENCE |
| 20× PRE_A consume C5 2→22, live C6 txn echo 4..23 | EVIDENCE |
| FREEZE A MODE=8 GEN=4 live C0–C11 x=0 | EVIDENCE |
| HOLD_A C10 OUT=733 ≠ registered 549 | EVIDENCE |
| 2-lesson G5 OUT 549/861/237 with cons=2 | EVIDENCE (parent bag) |
| 20-lesson priors change TinyGPT ctx vs 2-lesson oracle | ENGINEERING_INFERENCE (H_RIVAL 4) |
| C7 20 distinct MIG addresses | FALSE_OR_OVERCLAIM (addr sticky) |
| ADIG≠BDIG proves 20-fact mapping A | FALSE_OR_OVERCLAIM (ADIG=0 sticky) |
| 2-lesson surrogate = 20 facts | FALSE_OR_OVERCLAIM |
| GATE14_PASS / TEACHER_OFF / BOARD_PASS | not claimed |

H_CANDIDATE (20× PRE_A wraps CONTROL and exam matches 549/861/237) is **falsified** on this resident bit at the first HOLD_A exam.

H_RIVAL 4 is the standing explanation: 20 rewards are not the 2-lesson G5 working set; C10 moved to 733.

## Must not (still)

- Relax oracle to 733 and retry.
- Reprogram the unique bit `A0B338E0…` (`program_count=1` on parent).
- Run 40 facts on this stop.
- Send host idx/delta/address/cue/topk/answer.
- Self-claim BOARD_PASS.

## Next (Codex/human, not this close)

Need a **new token** if the next unknown is a different exam law, a persist-ID C9 path, or a from-zero 20-fact bit. This bag is closed `FAIL_DIVERGENCE`. PROGRAM remains NO unless a human token names a new bit.
