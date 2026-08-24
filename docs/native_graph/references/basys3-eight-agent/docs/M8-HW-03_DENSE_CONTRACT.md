# M8-HW-03 — dense 8×8 / 64-cell simultaneous plasticity

**Status:** BOARD PASS 2026-08-14 (`results/M8-HW-03/run_002`).  
**Depends on:** M8-HW-02 closed and frozen (`M8-HW-02-BOARD-PASS-20260814`).  
**Do not** overwrite bitstream SHA-256 `74F989937CAB99B02E43313E33243DA5B0BC562646548797F150F5FA3CB9F05B`.  
**New image name:** `build/out/basys3_eight_agent_m8hw03.bit`

M8-HW-02 proved *behavior* (two one-hot sessions, 64-cell observability).  
M8-HW-03 must prove *architecture*: all 64 plastic lanes fire in **one** TRAIN transaction.

Still **not** conversation.

---

## Law

Bit `1` = `+1`, bit `0` = `−1`.

```text
ΔW[d][s] = LR × teacher_pm1[d] × stimulus_pm1[s]
```

`LR = 8` (same magnitude as the boarded STDP `TRACE_INCREMENT>>LEARNING_SHIFT`).  
Diagonal **is** plastic in dense mode (unlike the one-hot STDP path).  
Neutral start remains: `W[d][d]=0`, else `64`.

Because every product is `±8`, a single dense TRAIN from the neutral matrix must change **64/64** cells (none sit on the clip rail).

`00000000` as a *bit pattern* is **not** “teacher off” — that encoding is all `−1` and would still update 64 cells.  
Teacher disconnected means `learn=0` and `teacher_to_core=0` (no write).

---

## Hardware counter

RTL latches `W_before[64]`, applies 64 parallel updates, compares `W_after`, and reports:

```text
changed_cell_count ∈ 0..64
```

Host heatmaps are supporting pictures, not the pass oracle.

---

## Controls

| Test | Stimulus | Teacher | Expect |
|------|----------|---------|--------|
| Dense-A | `10110100` = `0xB4` | `01101011` = `0x6B` | 64/64 change |
| Dense-B | invert A = `0x4B` | `0x6B` | 64/64 change |
| Freeze | Dense-A | Dense-A | 0/64 change |
| Teacher disabled | Dense-A | disconnected | 0/64; no learned mapping |

Patterns are **host/TB only**. Illegal in `rtl/`.

---

## Board sequence (one program)

```text
PROGRAM m8hw03.bit once
RESET → DUMP snapshot=BEFORE
LOAD DENSE SAMPLE
EXACTLY ONE TRAIN TRANSACTION → DENSE_TRAIN_EVENT
DUMP snapshot=AFTER_ONE
FPGA Δ == Python Δ  and  64/64 exact
FREEZE, teacher disconnected, 32 infer ticks
DUMP snapshot=FREEZE
AFTER_ONE == FREEZE bit-exact
```

Do not train 256/512/1024 ticks. One transaction is the claim.

---

## UART

| Kind | Role |
|------|------|
| `A5 60` | host → FPGA dense sample: stim, teacher, lr |
| `A5 5F` cmd `0x02` | RESET |
| `A5 5F` cmd `0x03` | DUMP 16 pages |
| `A5 5F` cmd `0x04` | one dense TRAIN |
| `A5 5F` cmd `0x05` | freeze + 32 infer |
| `A5 61` | `DENSE_TRAIN_EVENT`: stim, teacher, changed_cell_count, learn, freeze |
| `A5 5D` | weight pages (unchanged layout) |

Switches: **SW11 ON**, **SW12 ON** (dense path), **SW10 OFF**. LED15 locked.

---

## Conjunctive PASS

```text
M8_HW_03_PASS =
  SAME NEW BITSTREAM
  AND DENSE STIMULUS AND DENSE TEACHER
  AND BEFORE_MATRIX_COMPLETE AND AFTER_MATRIX_COMPLETE
  AND changed_cell_count == 64
  AND FPGA_delta == Python_delta
  AND 64/64 weight values exact
  AND teacher disconnected outside TRAIN
  AND FREEZE changes 0/64
  AND post-route timing PASS
  AND replay verdict == live verdict
```

Only then:

```text
64_SYNAPSES_SIMULTANEOUSLY_ACTIVE
FULL_PARALLEL_PLASTICITY
BOARD_VALIDATED
```

63 or fewer is **FAIL**. No partial pass.

Next after this file closes: **M8-HW-03R**, not conversation.
