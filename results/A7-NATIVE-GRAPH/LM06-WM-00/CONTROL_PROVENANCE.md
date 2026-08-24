# CONTROL PROVENANCE — `lm06_wm_00`

**HLB R2 requirement:** the bit-exact CONTROL must be outputs **RECORDED FROM the frozen LM-06
before the candidate runs**. A host that computes the expected token/activation at compare time is a
next-token-on-host violation even when labelled "control".

**Compliance statement:** `python/ref/a7lm06_fixed_ref.py` (and every other host oracle in this
repository) was **not invoked at any point in this gate**. No expected token, loss, activation, fold
or weight byte was computed by a host. Every CONTROL number below was either transcribed from a
silicon recording that predates this gate, or produced by running the frozen LM-06 RTL itself and
archived with a SHA before the candidate was compiled.

---

## Tier-1 — `BOARD_RECORDED` — the authoritative control

| item | value |
|------|-------|
| Source artifact | `results/A7-LM-06/hardware_c3/ladder.json` |
| SHA256 (live, recomputed this gate) | `37A53A73ED551910F4F28E164749F86967B2B1B376B29027B859DA165E689B61` |
| SHA256 expected by `docs/contracts/A7-LM-06-CONFIRMATION.md` | `37A53A73ED551910F4F28E164749F86967B2B1B376B29027B859DA165E689B61` |
| **MATCH** | **YES** |
| Produced by bit | `build/out/arty_a7_lm06c3.bit` |
| Bit SHA256 (live, recomputed this gate) | `222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6` |
| Bit SHA256 expected by contract | `222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6` |
| **MATCH** | **YES** |
| Recorded (ladder `started_utc` → `finished_utc`) | 2026-08-18T19:18:37Z → 2026-08-18T19:24:31Z |
| This gate opened | 2026-08-22T05:28Z |
| **Recorded before the candidate ran** | **YES — by 3 days** |
| `law_id` | `lm06-signsgd-v1` |
| Port | COM12 (that historical run; **no COM12 access occurs in this gate**) |
| `hardware_pass` | `true` |
| Frozen-bit block in that ladder | LM-00…LM-05 all `match: true`, `frozen_ok: true` |

Frozen recipe (`docs/contracts/A7-LM-06-CONFIRMATION.md`, frozen 2026-08-18 **before** the board
ladder): `seed 2 / context [1] / target 32 / lr 3`, retry forbidden, host compute forbidden.

### Per-vector Tier-1 CONTROL points and where each one came from

Each row cites the exact JSON path inside `ladder.json`. All were transcribed by hand into
`tests/xsim/tb_a7ng_lm06_wm.sv` as localparams / initialised arrays; none is computed.

| CONTROL vector | recorded value | `ladder.json` path | bench symbol | axis |
|----------------|----------------|--------------------|--------------|------|
| forward token | `pred = 744` | `.one_full_status.pred`, corroborated `.expected_forward.pred` | `T1_PRED` | A4 |
| forward loss | `loss = 16` | `.one_full_status.loss`, `.expected_forward.loss` | `T1_LOSS` | A4 |
| update write count | `wr_n = 655616` | `.fold1.wr_n`, `.expected_forward.wr_n` | `T1_WRN` | A6 |
| pristine image fold | `xor32 = 5`, `add32 = 94638317` | `.fold0`, `.expected_fold0` | `T1_F0X`, `T1_F0A` | A5 |
| post-update image fold | `xor32 = 23`, `add32 = 94627297` | `.fold1`, `.expected_fold1` | `T1_F1X`, `T1_F1A` | A7 |
| 8 weight readback windows | 8 × 8 bytes at addr 0 / 131072 / 147456 / 278528 / 409600 / 540672 / 671744 / 802808 | `.upload_spots[].addr`, `.upload_spots[].got` | `t1_spot_addr`, `t1_spot_byte` | A10 |
| 4 per-layer post-update windows | 4 × 8 bytes at addr 147456 / 278528 / 409600 / 540672 | `.layer_probes[].addr`, `.layer_probes[].got` | `t1_probe_addr`, `t1_probe_byte` | A6b |
| persist digest | `bytes = 802816`, `xor32 = 23` | `.persist_flush`, `.persist_reload` | equals `T1_F1X` | A8 |
| reload fold | `xor32 = 23`, `add32 = 94627297` | `.fold_reload` | equals fold1 | A8 |
| AFTER zero-write | `wr_n` unchanged at 655616 across `.after_gate.before` / `.after_gate.after` | `.after_gate` | R3 AFTER gate | R3 |

Corroborating pre-existing recorded expectation file (not a second independent source — it carries
the same six scalars):

| file | SHA256 | mtime (UTC) | contents |
|------|--------|-------------|----------|
| `tests/xsim/a7lm06_expected.txt` | `0449A78584691718F89C978E236EA96A4BB7A1E1909B3328D5B23A32B0808FB4` | 2026-08-18T13:22:17Z | `744 / 16 / 5 / 94638317 / 23 / 94627297` |

### Tier-1 LIMIT — stated, not worked around

`ladder.json` records **exactly one input sequence**. It is the only silicon-recorded LM-06 forward /
update recipe in this repository. Therefore on the *input-vector* axis Tier-1 is **n = 1**. That is a
property of the repository, not a design choice, and it is not repaired by any host computation
(which would be an R2 violation). It caps the verdict — see `CLOSEOUT.md`.

What Tier-1 *does* give at n = 1 is **20 independent recorded comparison points** spread across the
whole working set: 8 weight windows before the update, 4 per-layer windows after it, 2 whole-image
folds, 3 forward/update scalars, the persist digest, the reload fold and the AFTER gate. A
restructure that perturbed any tile in the W, activation or snapshot working set would have to
survive all 20.

---

## Tier-2 — `XSIM_RTL_RECORDED` — replication control, lower class

To answer the pseudoreplication falsifier F7 without committing the R2 falsifier F4, additional
CONTROL vectors were produced by **running the frozen LM-06 RTL itself** and archiving the output
before the candidate was compiled.

| property | value |
|----------|-------|
| Control generator | the frozen RTL, unmodified — `rtl/lm/{a7lm06_pkg,isqrt32,floordiv_s48,weight_bram803k,weight_bram_tdp8,weight_tile803k,act_ram128k16,snap_ram4k16,tiny_gpt803k_core}.sv` |
| Bench | `tests/xsim/tb_a7ng_lm06_wm.sv` — the **same file** drives the candidate arm |
| Evidence class | `XSIM_RTL_RECORDED` — **strictly below** Tier-1, never reported as board evidence |
| Replication | N = 9 input sequences, UNIT = one input sequence (forward + update + fold) |
| Faithfulness anchor | sequence 0 **is** the Tier-1 recipe, so the Tier-2 generator is validated against silicon inside the same run |

Vector table (fixed in bench source before the control run, so it cannot be tuned afterwards):

| v | ntok | tokens | tgt | lr | note |
|--:|-----:|--------|----:|---:|------|
| 0 | 1 | `[1]` | 32 | 3 | **Tier-1 frozen recipe** — must run first, recorded fold0 needs a pristine image |
| 1 | 1 | `[7]` | 100 | 1 | different token, different target, minimum lr |
| 2 | 2 | `[1,7]` | 5 | 3 | context length 2 |
| 3 | 3 | `[3,9,17]` | 200 | 2 | context length 3 |
| 4 | 1 | `[255]` | 1023 | 4 | max token byte, max target class, max lr |
| 5 | 4 | `[0,1,2,3]` | 64 | 1 | token 0 included |
| 6 | 2 | `[128,64]` | 512 | 3 | high token ids |
| 7 | 5 | `[11,22,33,44,55]` | 777 | 2 | context length 5 |
| 8 | 8 | `[1..8]` | 32 | 3 | full 8-token pack, recipe target/lr at longer context |

Sequences are **chained**: each `start_train` mutates the weight image, so sequence *k* runs on the
image produced by sequence *k−1*. The fold after each sequence is therefore a running digest over
the whole 802,816-byte image and any divergence at any sequence propagates and is caught.

Ordering discipline, enforced and recorded:

```text
control run  ->  archive control log + control image + SHA256 + timestamps
             ->  ONLY THEN compile the candidate
             ->  candidate run
             ->  compare
```

Timestamps are in `raw/control_timestamps.txt` and `raw/candidate_timestamps.txt`. If a candidate
log timestamp precedes the control archive timestamp the gate is void.

---

## Tier-3 — pre-existing recorded artifact, corroboration only

| file | SHA256 | mtime (UTC) | role |
|------|--------|-------------|------|
| `tests/xsim/a7lm06_after.hex` | `81865273AD2025DA86A7415267E36CBACD3ADD17D051AFEEE8AEDE05864DE271` | 2026-08-18T17:38:38Z | post-training full weight image dumped by the pre-existing frozen bench `tb_a7lm06_core.sv`, i.e. recorded 4 days before this gate |
| `tests/xsim/a7lm06_wmem.hex` | `9A6BBC7AC8AF82725CAFD0B50241EE683C07FB9943C754753025F3569967D10F` | 2026-08-18T13:22:18Z | the initial weight image, identical input to **both** arms (axis A1) |

`a7lm06_after.hex` is **not overwritten** by this gate: both arms write to distinct filenames
(`raw/wm00_control_after.hex`, `raw/wm00_candidate_after.hex`).

Note on its scope: it was produced by the pre-existing bench, which runs the Tier-1 recipe only, so
it corroborates the single-sequence image and not the 9-sequence chain.

---

## Prior evidence bearing on this unknown — cited, not re-claimed

`weight_tile803k` with `SIM_FULL = 0` is already a **bounded, evict-and-refill, single-region W
working set**: one 131,072-byte region resident, dirty flush on miss, refill from DDR over the
official Digilent AXI MIG. The C3 silicon run executed that structure and produced folds
`5 / 94638317` and `23 / 94627297` — identical to the flat `SIM_FULL = 1` monolith recorded in
`a7lm06_expected.txt`.

That is a pre-existing **board-class** existence proof that a bounded W working set is bit-exact
with the flat reference. This gate **cites** it as prior evidence and does **not** claim it as its
own result. It is also why `NLIVE_W` was withdrawn as a measurement target in PREREGISTER amendment
A1(a): re-deriving a board-proven result at simulation fidelity would add nothing.

---

## What is NOT a control here

```text
python/ref/a7lm06_fixed_ref.py        NOT INVOKED  (host oracle - would be an R2 violation)
any host-computed next token          ABSENT
any host-computed activation or fold  ABSENT
any host-selected winning address     ABSENT
mig_board stall rows                  NOT USED (quarantined, pre-metric cumulative counters)
ddr_wavefront_00 512 B carry-in       NOT USED to size any LM tile (auditor MAJOR-2, falsifier F6)
```
