# A7-EAM-02M — Multi-Cue Episodic Binding

**Status:** **FROZEN / BOARD_PASS**.  
**Frozen claim:** FPGA-native post-bitstream multi-cue episodic binding and teacher-off exact recall.  
**Not in the claim:** semantic, generalization, unseen paraphrase, LM-06 hidden.  
**Board bit:** `build/out/arty_a7_eam02m.bit` SHA `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696`. WNS +0.788 / WHS +0.026. LUT 1704, FF 2332, BRAM 52, DSP 0.  
**Close:** `results/A7-EAM-02M/CLOSEOUT.md` + `ladder_02m.json`.  
**Law:** `eam02m-bind-v1`  
**Depends on:** frozen **A7-EAM-01R** (`eam01r-mih-v1`, `HIT_MAX=8`, `MARGIN_MIN=4`). Instantiates `eam01r_core` as a black box.  
**Does not depend on:** LM-06 hidden, Q0/Q1/Q2, DDR, wordpiece.

## Why this lane exists

A7-EAM-02H closed a specific assumption:

```
LM-06 last-token / pooled hidden  →  cheap 64-bit hash  →  semantic episodic key
```

`Q1P_NOGO`. The 128-D stream was trained for next-byte prediction, not paraphrase geometry.  
`L0_last` still separates same-k vs diff-k — the network has a representation for **its** task. That task is not EAM semantics.

02M does **not** try to fix that. It asks a smaller, native EAM question:

> Can one episode carry several distinct 64-bit cues, and after teacher-off can **either** cue recall **the same** episode?

This is **multi-cue binding**, not paraphrase generalization.

```
Episode #37
 ├─ cue A   "FPGA nào đang dùng?"
 ├─ cue B   "Board hiện tại dùng chip gì?"
 └─ value   xc7a100t
```

After teacher-off, probe A or probe B must return episode 37 **and** the same value.  
An unseen paraphrase of A is **not** required to hit. That claim belongs to 03E.

## Split of labor (frozen)

```
             ┌──────────── A7-LM-06 ────────────┐
text/bytes → │ language / prediction path       │   FROZEN — do not retune
             └──────────────────────────────────┘

64-bit cues → 01R MIH router (frozen) → cue record
                    ↓ token = episode_id
              02M episode table → value
```

| Block | Owns | Must not |
|-------|------|----------|
| 01R | Hamming NN on **cues**, index nominates only | Declare HIT from a bucket; be retuned |
| 02M episode table | `episode_id → {value_token, vec, cue_n}` | Invent a second router |
| Host | OPEN payload (value) + BIND/PROBE cues | Winner address, precomputed Hamming, projection weights |
| LM-06 / Q1 | nothing in this lane | Be glued, hashed, or silent-tuned |

## What this is not

- Not semantic generalization. Two bound strings are **exact cues**, not a Hamming ball of meaning.
- Not “PARA pairs get close.” Unseen rewordings **miss** unless 03E later maps them onto a bound cue.
- Not two independent 01R MAPs that happen to share a host-chosen token. FPGA **allocates** `episode_id` and BIND must not resend the value.
- Not Q2 / HDML / kNN-LM. Those papers do not close 02M.

## Geometry

| Item | Value |
|------|--------|
| Episodes | 256 (`episode_id` 8-bit = 01R `token` field of a **cue** record) |
| Cues | ≤ 4096 (01R record store). Typical 02M test: 2–4 per episode |
| Cue key | 64-bit. Host key **or** FPGA fold of UTF-8 bytes (`eam02m-fold-v1`) |
| Value | 8-bit `value_token` + 128-bit `vec` (observed, 00B DCE lesson) |
| Router | frozen 01R: `d1 ≤ 8` and `margin ≥ 4` |
| Pairwise cue gap | TB/silicon cues **d_H ≥ 24** so an exact unique cue cannot fail `MARGIN_MIN` |

01R `token` on a cue record **is the episode_id**, never the payload token.  
Payload lives only in the episode table. A probe that returns the same `value_token` but a **different** `episode_id` is a fail (two independent associations, not one episode).

## Fold (optional text path)

Law `eam02m-fold-v1`. **Not learned. Not semantic. 0 DSP.**

```
IV = 64'h0EA1020D02A70001
acc = IV
for each byte b:
    acc ^= {56'0, b}
    acc  = rotl(acc, 1)
    acc ^= rotl(acc, 8)
    acc += {48'0, b, 8'hA7}
```

Two different UTF-8 strings produce two different keys with overwhelming probability and typically sit near d≈32. 02M **binds both**. It does not need them close.

Tokenizer stays UTF-8 bytes. No wordpiece in this lane.

## Protocol (host → FPGA)

Frame: `A5 cmd n payload xor` (same 00B/01R envelope). Reply 20 bytes `5A … xor`.

| CMD | Name | Payload | FPGA does |
|-----|------|---------|-----------|
| `0x01` | PING | — | ident `M2M` (`4D 32 4D`) |
| `0x04` | SOFT_RST | — | clear episodes, 01R epoch++, teacher-on |
| `0x05` | CLR_STAT | — | counters only |
| `0x07` / `0x08` | HIT_MAX / MARGIN | 1 byte | pass-through; defaults 8 / 4 |
| `0x10` | OPEN | `vec[16] \|\| value_token` | allocate episode, `cue_n=0`, return `episode_id` |
| `0x11` | BIND | `episode_id \|\| key[8]` | attach cue; do **not** require value again |
| `0x12` | PROBE | `key[8]` | 01R → episode → value |
| `0x13` | TEACHER_OFF | — | further OPEN/BIND → NACK |
| `0x14` | BIND_TXT | `episode_id \|\| n \|\| bytes[n]` | fold then BIND |
| `0x15` | PROBE_TXT | `n \|\| bytes[n]` | fold then PROBE |

`n ≤ 46`. MAXP = 48.

Raw 01R MAP/PROBE (`0x02`/`0x03`) are **not** exposed on the 02M UART. Host cannot fake a bind by writing two records with a guessed token.

### BIND algorithm (FPGA)

1. Reject if teacher-off, bad `episode_id`, or `!valid`.
2. **Probe first** (`do_map=0`). If 01R HIT → `BIND_COLLIDE` (cue already in an accepted ball). Do not steal another episode. Do not bump `cue_n`.
3. Else MAP (`do_map=1`) with `token=episode_id`, `vec=episode.vec`, `key=cue`.
4. Wait 01R **idle** (MAP returns `result_valid` before index writes finish).
5. `cue_n += 1`.

Host never sends a record address, way, or winner id.

### Reply `0x92` PROBE (and OPEN/BIND cousins)

| Byte | Field |
|------|--------|
| 2 | `{teacher_off, collide, idle, is_res, hit}` |
| 3 | `value_token` (probe hit) |
| 4 | `hamming` |
| 5 | `second` / nack code |
| 14 | `episode_id` |
| 15 | `cue_n` |

NACK kind `0x9E`. Codes: `1` teacher-off, `2` full, `3` bad episode, `4` collide, `5` empty text.

## Teacher-off

After `0x13`, the store is query-only. This is the 02M analogue of HOLD: **do not bind on the probe set**.

## Pass / fail (pre-registered)

A close requires **all**:

1. OPEN then BIND cue A, BIND cue B (pairwise d≥24) → `episode_id` identical, `cue_n=2`.
2. TEACHER_OFF.
3. PROBE A and PROBE B: HIT, **same** `episode_id`, same `value_token`, `d=0` on exact cues.
4. 1-bit flip of cue A: HIT, same episode (`d=1`, 01R theorem). Unrelated far key: MISS.
5. Second episode, two cues: no cross-talk (wrong `episode_id` = fail).
6. BIND after teacher-off: NACK `1`. PROBE still works.
7. Same key rebound: `BIND_COLLIDE`, `cue_n` unchanged.
8. Host trace contains no way / BRAM / precomputed winner.

Text path (silicon): BIND_TXT / PROBE_TXT of two **different** UTF-8 strings (the Vietnamese pair is allowed as **labels**, not as a semantic claim) must behave as (1)–(3).

**Forbidden claim:** “unseen paraphrase retrieved.” That is 03E.

## Erratum (known protocol quirk, not a functional blocker)

NACK after teacher-off **may leave stale `hit=1`** from the previous PROBE reply.  
Protocol authority is **`kind=0x9E` and `nack_code=1`**, not the hit flag.  
The silicon ladder already keys on kind+code. Fix in a later 02M.1 bit if the UART is retouched; do **not** retune 01R to “fix” this.

## Resource / bit

New bit `build/out/arty_a7_eam02m.bit` only.  
Never write `arty_a7_lm*.bit`, `arty_a7_eam00b.bit`, `arty_a7_eam00g.bit`, `arty_a7_eam01r.bit`, `arty_a7_eam02q.bit`.

Budget: 01R (~56 BRAM36-eq) + 256×~145-bit episode table (≤2 BRAM36) + fold LUTs. 0 DSP. 100 MHz.

## Forbidden

- Modify `eam01r_core.sv` / 01R defaults to “make bind easier.”
- Glue LM-06 or Q1 into the cue.
- Silent-tune Q1 seed / HOLD / HIT_MAX for 02M evidence.
- Call 02M a semantic encoder.
- Open Q2 because 02M works.

## Sibling

**A7-EAM-03E** — dedicated episodic encoder (bytes → 64-bit cue) trained on SAME/DIFF.  
02M remains useful if 03E fails.

## Deliverables

- this contract
- `rtl/eam/a7eam02m_pkg.sv`, `eam02m_core.sv`, `eam02m_uart.sv`
- `rtl/board/arty_a7_eam02m_top.sv`
- `tests/xsim/tb_a7eam02m.sv` + `run_a7eam02m.tcl`
- `tools/a7eam02m_silicon.py`
- `results/A7-EAM-02M/`
