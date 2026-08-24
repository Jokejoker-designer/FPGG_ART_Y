# A7-EAM-03E-UI — operator studio (UI support, NOT evidence)

**Parent:** `A7-EAM-03E-A.md`
**Status:** `PATCH_DRAFT` — awaiting Anh's ratification. Nothing here may be cited in a ladder JSON.
**Law:** unchanged, `eam03e-a0-signsgd-v1`. `eam03e_core.sv` is instantiated byte-identical.
**A1:** still CLOSED. This rung adds no retrieval, no 01R, no 02M, no LM-06.

## Why this rung exists

An operator needs to drive training, reward/punish pairs, and watch the geometry
move. Two things blocked that, and neither is a UI problem:

1. The 20-byte PAIR reply carries `d1`, `dH`, `cue` and three flags. It carries
   **no** state vector, gradient or weight, and the contract forbids the host
   from computing the update. So a gradient view cannot come from the wire.
2. `sw[3:0]` and `btn[3:1]` are tied into `wire unused` on every EAM top, and
   `led[3:0]` are output pins. **No existing UART command on any bitstream in
   this repo reports switch, button or LED state.** A "mirror the board" tab is
   therefore impossible on the A0 bit as built.

This rung answers (1) with a verified host twin and (2) with one extra command on
a separate bitstream.

## Deliverables

| Path | Role | Touches frozen art? |
|------|------|---------------------|
| `python/eam/eam03e_twin.py` | integer-exact host mirror of `eam03e_core.sv` | no |
| `python/eam/eam03e_bench.py` | `A7-SIM-BENCH v0.1`: held-out split, baselines, tie-aware metrics | no |
| `tools/a7eam03e_bench.py` | benchmark runner, writes `results/A7-EAM-03E/bench/` | no |
| `tests/golden/test_eam03e_twin.py` | pins the twin to xsim + A02 numbers | no |
| `tests/golden/test_eam03e_bench.py` | pins the benchmark arithmetic and the split | no |
| `tools/ui/a7_studio.py` | stdlib HTTP/SSE server, dual-track twin+board | no |
| `tools/ui/board_link.py` | 03E serial transport | no |
| `tools/ui/static/*` | the operator UI | no |
| `rtl/eam/eam03e_io_uart.sv` | new file: A0 UART + CMD 0x2F | no |
| `rtl/board/arty_a7_eam03e_io_top.sv` | new file: top with SW/BTN synchronised | no |
| `vivado/tcl/build_a7eam03e_io.tcl` | writes `arty_a7_eam03e_io.bit` only | no |

`rtl/eam/eam03e_uart.sv`, `rtl/board/arty_a7_eam03e_top.sv`,
`vivado/tcl/build_a7eam03e.tcl` and every frozen `.bit` are untouched.
`eam03e_io_uart.sv` is a copy rather than a parameter on the A0 UART on purpose:
A0.1-T is mid-flight on timing under a frozen law, and folding a feature into the
module under test would mix a feature change into that evidence.

## Twin authority

The twin is **ILLUSTRATION ONLY**. It exists to explain, to run offline, and to
pre-screen seeds. Board numbers remain the only evidence, and AI cannot declare
BOARD_PASS.

The twin is pinned by two independent sources:

| Source | Numbers | Result |
|--------|---------|--------|
| `tests/xsim/tb_a7eam03e.sv` | 3930, 5362, 1093, 2012, 3930, 451, 1574 | **7/7 match** |
| `A7-EAM-03E-A02.md` seed `0x22222222` | d_pos 1487, d_neg 229, M_L1 −1258 | **exact match** |

Host-side gradient computation is legal inside the twin because nothing it
produces is ever transmitted. The server has no code path that writes a weight,
a gradient or an address to the board; `board_link.pack` keeps the same
forbidden-substring guard as the silicon ladder.

## Three frozen arithmetic quirks the twin had to reproduce

Quirks 1 and 2 are **confirmed by ablation**: of the four combinations of
{aligned, off-by-one} × {signed, unsigned}, only off-by-one + unsigned reproduces
the goldens, and the other three miss all seven. Fixing either is a law change.

Quirk 3 is **not** pinned by the goldens, because no golden constrains `dH`. It
follows from the same IEEE 1800 signedness rule as quirk 2 and is a **prediction**
the board can falsify in a single PAIR read: if silicon returns `dH != 0` or a
`cue` that is not `0xFFFFFFFFFFFFFFFF`, quirk 3 is wrong and the twin must be
corrected. The studio surfaces exactly that comparison.

| # | Site | Reading | Consequence |
|---|------|---------|-------------|
| 1 | `S_EISS` / `S_ELAT` | `e_ra` is latched at the end of `S_EISS` while `e_q` still holds the previous address, so `e_lat[j] = E[b][j−1]` and `e_lat[0]` is a stale read of `E[b_prev][31]` | `E[b][31]` is never consumed by the forward pass. `S_SEED` does not reset `e_ra`, so a reseed inherits the previous pair's address; the first pair after power-on reads X in xsim, which is why the TB primes. The update path reads correctly because `S_ELAT2` is a wait state. |
| 2 | `S_HWR` | `acc + {{8{e[7]}}, e, 8'd0}` — a SV concatenation is unsigned, so the add is unsigned and `>>>` degrades to a logical shift | **`h` is never negative and pins at 32767.** 30–31 of 32 coordinates saturate. This is the mechanism behind the A0.2-L "DIFF collapse", not a metric footnote. |
| 3 | `S_PACC` | `(psum ± concat) > 32'sd0` mixes an unsigned concat with a signed zero, so the compare is unsigned and means `!= 0` | `cue` is all-ones and `dH` reads 0. **`dH` is unusable on this bitstream.** No frozen golden depends on `dH`, so A0.1-T is unaffected. |

## Held-out benchmark findings (twin screen, reproducible)

`A7-SIM-BENCH v0.1` (`python/eam/eam03e_bench.py`, `tools/a7eam03e_bench.py`)
replaces the three-string smoke test with an entity-split held-out measurement,
baselines, and an untrained-encoder control. Four findings from it bear directly
on A0.1-T and A0.2-L. All are twin numbers and none closes a gate.

**1. Online training past a few hundred pairs destroys the representation.** On
`NAME-46-SYN` with ~320 training pairs, every coordinate of `h` pins at 32767,
effective rank falls to 0–2, `d1` collapses to a single distinct value, and AUC
falls to exactly 0.500. This is **not** weight death: only ~67 of 8192 `E` values
and ~16 of 1024 `Wh` values reach ±127. It is quirk 2 compounding — each update
grows `Wh`, which grows `acc`, which saturates more coordinates, which destroys
the differences `d1` is built from. Measured onset is between 200 and 400 update
transactions.

**2. The frozen three-string golden test sits just below that threshold.** It runs
32 epochs × 2 pairs = 64 update transactions. That is why it looks healthy.

**3. The 32-epoch budget is an unregistered hyperparameter on a non-monotone
curve.** Sweeping the golden triplet at seed `0x11111111`:

| epochs | 4 | 8 | 16 | 32 | 64 | 128 | 256 |
|---|---|---|---|---|---|---|---|
| `M_L1` | +1108 | **−2448** | +3787 | +919 | +918 | +5694 | +5694 |
| `d1_pos` | 4428 | 5382 | 851 | 1093 | 1094 | **0** | **0** |

`M_L1` is negative at 8 epochs, positive at 16–64, and from 128 epochs the
positive pair collapses onto a single point (`d1_pos = 0`), which makes `M_L1`
look excellent for the wrong reason. Any gate on the sign of `M_L1` therefore also
gates the epoch budget, and the budget is not currently registered anywhere.

**4. Training helps on some seeds and destroys others, and classical string
metrics still win.** At two epochs, seed `0x7A9BE636` went AUC 0.607 → 0.836
(ΔAUC +0.230) while `0x22222222` went 0.854 → 0.500 (ΔAUC −0.354, `d1` collapsed
to one level). On the same held-out split, byte-histogram L1 scored 0.83–0.94 and
Jaro-Winkler 0.79. So the current state is the one the project's own contract
already names — plasticity without discriminative geometry — now with held-out
numbers, baselines and a shuffled-label control instead of three strings.

Screening verdict from the harness: `DOES_NOT_WORK`, driven by the worst-seed
rule. That is the harness applying the contract's own gate, not a board result.

### Consequence for A0.2-L that should reach the board before L1 opens

Gate 3 of the A0.2-L per-seed gate is `M_cos_post > 0`. With quirk 2 in place,
`h ≥ 0` and nearly every coordinate is pinned at 32767, so the cosine between any
two vectors is close to 1 and `M_cos` only moves by about ±0.01 (twin numbers:
+0.0145 at seed `0x11111111`, −0.0120 at `0x22222222`, −0.0018 at `0xA7E03EA1`).
A gate on the sign of a quantity that small is not a robust gate. Decide whether
quirk 2 is a law defect to version out before spending silicon on L1.

## New UART command (only on `arty_a7_eam03e_io.bit`)

PING identity stays `3A0`; the host distinguishes the builds by probing 0x2F and
falling back when it answers `0x8E`.

| CMD | Payload | Action | Reply kind |
|-----|---------|--------|------------|
| `0x2F` | none | report board IO, then clear the sticky button byte | `0xAF` |

`0xAF` layout:

| Offset | Field |
|--------|-------|
| 2 | `{5'b0, upd, freeze_eff, learn_eff}` |
| 3 | `{4'b0, sw[3:0]}` |
| 4 | `{4'b0, btn[3:0]}` |
| 5 | `{4'b0, led[3:0]}` |
| 6 | `{4'b0, btn_sticky[3:1], 1'b0}` — rising edges since the last 0x2F |
| 7 | `sw_changes` — wrapping count of switch transitions |
| 8, 9 | ASCII `I`, `O` |
| 10 | `{7'b0, core_idle}` |
| 11, 12 | `d1` low, high |
| 14, 15, 16, 18 | `nA`, `nB`, `seed_used[7:0]`, flags — as in `0xA3` |

Switch semantics on this bit. A switch may **request**, never revoke:

```
learn_eff  = learn_r  || sw[1]
freeze_eff = freeze_r || sw[0]
```

`freeze` still wins over `learn` inside the core, so SW0 up is always safe: it
stops learning and cannot start it. SW2, SW3 are report-only. BTN0 stays the
power-on reset. BTN1..3 are reported as sticky edges and the UI binds them to
reward / punish / reseed; the RTL gives them no datapath meaning.

There is no debounce module in this repo, only the two-FF `sync_bits`, so one
mechanical press can raise several sticky edges. The UI treats a sticky bit as a
one-shot request, never as a count.

## Not verified

Stated plainly, because it changes how this must be used:

- `eam03e_io_uart.sv` and `arty_a7_eam03e_io_top.sv` **parse and elaborate clean**
  but have **not been simulated or synthesised**. An earlier revision of this
  contract claimed Vivado was absent from this machine; that was a search error.
  Vivado 2026.1 is installed at `C:\2026.1\Vivado\bin\vivado.bat`.

  Evidence, 2026-08-20, license `D:\Xilinx\licenses\vivado_basic.lic`:

  ```
  xvlog -sv rtl/eam/a7eam03e_pkg.sv rtl/eam/eam03e_core.sv \
            rtl/eam/eam03e_io_uart.sv rtl/board/arty_a7_eam03e_io_top.sv \
            rtl/board/sync_bits.sv rtl/board/uart_rx.sv rtl/board/uart_tx.sv
  xelab -L work work.arty_a7_eam03e_io_top -s io_top_elab
  ```

  Both exit 0. `xelab` reports `Built simulation snapshot io_top_elab` with no
  width or port-connection warnings. This proves the module hierarchy and port
  widths are consistent; it proves nothing about behaviour.
- No xsim testbench covers `0x2F`.
- Utilisation and timing for this bit are unknown. It inherits the same
  `S_DIST → d1_acc` critical path as A0.1-T, which was `WNS −0.119, TNS −0.407`
  before the `S_DADD` pipeline patch and has not been re-run.

**Therefore:** do not build or program `arty_a7_eam03e_io.bit` until A0.1-T
timing closes. A bit that fails timing can return wrong integers, and the studio
would then report a twin↔board divergence that looks like a logic bug but is a
setup violation. Until then the Board tab runs in `MÔ HÌNH` mode and says so on
screen.

## Forbidden in this rung

- citing any twin number, sweep row or UI session log as silicon evidence
- declaring BOARD_PASS, or any `*_PASS` claim, from the studio
- editing `eam03e_core.sv`, `eam03e_uart.sv`, `arty_a7_eam03e_top.sv`, or any frozen `.bit`
- adding a weight-write, gradient-write or address command to reach the UI's
  weight editor — that editor is twin-only by design
- treating `dH` or `cue` as a retrieval signal (quirk 3)
- using the seed sweep to pick a seed and then calling the seed robustness gate closed

## Evidence written by the studio

Session logs go to `results/A7-EAM-03E/ui_sessions/session_<ts>.jsonl`, one
record per pair, each carrying both tracks and an `agree` field. These are
operator logs. Promoting one to a ladder result requires a board run under
`tools/a7eam03e_a0_silicon.py`, not this UI.
