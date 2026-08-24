# A7-EAM-03E logic audit — 2026-08-19 (Cursor)

Authority: `HANDOFF.md` + `A7-EAM-03E-A.md` / `-A01.md` / `-A02.md`.  
Scope: encoder lane only. Not LM-06. Not 01R/02M glue. Not BOARD_PASS.

## Verdict

A0.1-T **law is consistent** with `eam03e-a0-signsgd-v1`. Plasticity goldens are internally consistent on **32-step xsim**. Timing is **not** closed (WNS −0.119 on `d1_acc`). Seed `0x22222222` inversion is a **TRAIN law** failure (gated DIFF + two independent PAIR updates), not a pipeline bug. A1 stays closed.

## Evidence classes

| ID | Class | Finding |
|----|--------|---------|
| F1 | FACT | Live `rtl/eam/eam03e_core.sv` SHA256 matched snapshot `a01t_eupd/eam03e_core.sv` before this session’s S_DIST patch (`717025A88F…5B04EE`). |
| F2 | FACT | `build/out/arty_a7_eam03e.bit` SHA256 `ADD9E462…1C2262` = a01t_eupd. DSP 0, LUT 7653, FF 7157. WNS −0.119 / TNS −0.407 @ 100 MHz. Destination `d1_acc_reg[12]/D`. |
| F3 | FACT | xsim TB (`tb_a7eam03e.sv`) trains **32** SAME+DIFF steps. Goldens 3930/5362 → 1093/2012 → 3930 → 451/1574. |
| F4 | FACT | Host `a7eam03e_a0_silicon.py` used **STEPS=24**. A0 silicon swap 1986/983 (`ladder_a0.json` / `silicon.md`) is the 24-step protocol, not an xsim golden change. |
| F5 | FACT | SAME: `gA=hA−hB`, `gB=hB−hA`. DIFF: update only if `d1_acc < E3_MARG` (4096), else `g=0`. Broadcast `E[b][i] -= sat8 sign(g)`. Matches contract §update law. |
| F6 | FACT | `Wh` last-step uses **gB** and `hprev` after encoding B only. Matches “last-step SignSGD”, not full BPTT. |
| F7 | FACT | Seed `0x22222222`: SAME 2135→1487, DIFF 1679→229, `M=−1258`. Host gate `seed2_same_shrink` does **not** require `d1_diff > d1_same`. |
| F8 | FACT | PING ident `3A`/`A0` (`0x33 0x41 0x30`). UART envelope `A5 cmd n payload xor`, reply 20×`5A`. No 01R MAP/PROBE. |
| F9 | INFERENCE | DIFF collapse with `d1` already below 4096 means repulsion is active and still loses to SAME pull + shared-byte E updates. Triplet hinge (`A7-EAM-03E-A02.md`) is the right **next law**, after T close. |
| F10 | INFERENCE | Registering `ad` then adding (`S_DIST`/`S_DADD`) preserves term order i=0..31; commutative saturation saturates the same running u16. Golden should hold if xsim confirms. |
| F11 | CODE_QUALITY | `gsel_r` and `hprev_j_r` are written, never read (EUPD pipeline leftovers). |
| F12 | CODE_QUALITY | Empty B used to enter `S_DIST` without clearing `d1_acc` (stale from prior pair). Not on golden strings. Patch clears on empty-B. |
| F13 | UNKNOWN | a01t_eupd silicon vs 32-step goldens: **not run** (board disconnected). |
| F14 | UNKNOWN | Post-S_DIST WNS: **not routed yet**. |

## Law vs geometry (why A0.2 exists)

Independent PAIR steps:

```
step k:  TRAIN(A,P,SAME) then TRAIN(A,N,DIFF)
DIFF update iff d1(A,N) < 4096
```

If DIFF starts far, repulsion never fires. Shared bytes (`A` in ALPHA/BETA/OMEGA) still move under SAME. Seed 0x22222222 starts **inside** the margin and still inverts → missing **combined** repulsion, not a silent `m` tweak.

Do **not** retune `E3_MARG` per seed. Do **not** open A1.

## UART / host

- BUF `0x22` slot+len+bytes, `n≤46`, `MAXP=48` fits `E3_TMAX`.
- PAIR `0x23` uses buffered A/B; host `measure()` BUF then PAIR. Host does not send hash/grad/weights.
- Freeze `0x13` then PAIR: `do_upd = learn && !freeze` → EVAL. Correct.
- Ident stays `3A A0` until A0.2-L ships `3A A2`.

## Timing next (this patch)

Critical path after eupd: `i_reg → abs16 → >>5 → sat-add → d1_acc` (10.135 ns).  
Allowed T change: register `ad`, add next cycle. **Not** a law change.

## Frozen / do not

| Item | Rule |
|------|------|
| `arty_a7_eam02m.bit` | FROZEN SHA `DB3BC58A…CFE696` |
| LM-00..05 bits | FROZEN |
| a01t_eupd snapshot + bit | keep; new T attempt is live RTL |
| A1 | CLOSED |
| Cosine in TRAIN | forbidden until L3, which is not opened |

## Tests run this session

| Command | Result |
|---------|--------|
| SHA256 live vs snapshot (pre-patch) | match `717025A88F…5B04EE` |
| SHA256 live after S_DIST patch | `F8221477803E…9ADEA5` |
| SHA256 current bit | `ADD9E462…1C2262` |
| Mesh `GET /api/v1/mesh/summary` | ok, grok-build **online** |
| Mesh broadcast | `bcast-ac9ae3af0439` delivered n=9 |
| Workspace handoff | `handoff-ef18463b836e` cursor-peer → grok-builder |
| Workspace message | `msg-61662eecd8e1` seq 176 |
| xsim after S_DIST | **not run** — Vivado/xsim not on PATH this shell |
| grok `--resume` `-p` | **hung** ~7 min, CPU frozen, no TCP; killed. Use Grok TUI paste of `GROK_PROMPT_CURSOR_ACK.md` |
