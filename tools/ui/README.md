# A7 Native-AI Studio

Operator console for the A7-EAM-03E-A0 encoder on Arty A7-100T. Drive training by
hand, reward and punish pairs, watch the gradient and the weight deltas, plot the
actual arithmetic, mirror the physical board, and run a held-out benchmark.

Contract: [`docs/contracts/A7-EAM-03E-UI.md`](../../docs/contracts/A7-EAM-03E-UI.md).
Read it before quoting any number from this tool — the studio is **not** evidence.

## Run

```bash
pip install pyserial          # the only third-party dependency

python tools/ui/a7_studio.py                    # twin only, no board needed
python tools/ui/a7_studio.py --port COM12       # attach the Arty A7
```

Open <http://127.0.0.1:8770/>. On start it prints whether the twin still matches
the frozen goldens; if that line says FAIL, stop and fix the twin before believing
anything on screen. `Ctrl+C` shuts down cleanly (it closes the serial port and
stops the training loop). If you background it and a port stays busy, kill by
command line rather than by the shell's PID — the Python process is a child:

```powershell
Get-CimInstance Win32_Process -Filter "Name='python.exe'" |
  Where-Object { $_.CommandLine -like '*a7_studio*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

Regression checks:

```bash
python -m python.eam.eam03e_twin                          # the 7 golden integers
python -m pytest tests/golden/test_eam03e_twin.py -q      # 10 tests
python -m pytest tests/golden/test_eam03e_bench.py -q     # 21 tests
python tools/a7eam03e_bench.py --quick                    # held-out benchmark
```

## Keyboard

The core loop is two keystrokes. This is the point of the design: an operator
labels hundreds of pairs per session, and a mouse round-trip per pair is the
dominant cost.

| Key | Action |
|-----|--------|
| `Enter` | THƯỞNG — label SAME |
| `Shift+Enter` | PHẠT — label DIFF |
| `Alt+S` | swap A and B |
| `Esc` | clear both fields |
| `Space` | start / stop the auto-train loop |
| `1` … `7` | switch tab |
| `?` | shortcut reminder |

After each step focus returns to field A with the text selected, so the next pair
is just typing. Both verdict buttons disable while a step is in flight and while
auto-train runs, so a double-click cannot inject a phantom labelled step.

## Two tracks, one screen

| Track | What it is | Authority |
|-------|------------|-----------|
| `TWIN` | `python/eam/eam03e_twin.py`, integer-exact against 7/7 xsim goldens and the A02 seed-`0x22222222` numbers | illustration only |
| `BOARD` | `arty_a7_eam03e*.bit` over UART at 115200 | the only evidence |

Every pair runs on both. The server compares `d1` and the `updated` flag and
raises a divergence banner the moment they differ, so an attached board turns the
UI into a continuous silicon-versus-twin conformance check. If the serial link
dies mid-run the auto-train loop **stops** rather than silently degrading to
twin-only, and the board chip turns red with the error.

The twin is the only source that can show `h`, gradients and weight deltas: the
20-byte reply carries `d1`, `dH`, `cue` and three flags, and the contract forbids
the host from computing the update. Nothing the twin computes is ever transmitted.

### Sync

`e_ra` has no reset in the RTL and `S_SEED` never writes it, so the first pair
after power-on reads an undefined address. Press **Resync** on the Board tab: it
reseeds both sides and burns one discarded prime pair. After that the two tracks
run in lockstep. Editing a twin weight breaks sync on purpose and `in_sync` goes
amber.

## Tabs

- **Huấn luyện** (default) — the operate surface. Two fields with live UTF-8 byte
  counters, REWARD / PUNISH, a three-way mode control (`HỌC / ĐO / ĐÓNG BĂNG` —
  the meaningless `learn=1, freeze=1` combination is not expressible), seed with a
  confirm step that names how many steps a reseed destroys, the curriculum editor,
  and the auto-train loop. Metrics show a signed Δ against the previous pair with
  the *same* strings and label, and name the strings each number came from;
  `M_L1` greys out and says so when the last SAME and DIFF pairs used different
  anchors. Below that: the `d1` chart with the `E3_MARG = 4096` gate drawn on it,
  the `M_L1` margin chart, and a sortable records table (click a row to reload
  that pair, divergent rows striped red, JSON export, pausable auto-scroll).
- **Gradient** — `h` for A against B with the 32767 saturation line, raw `g`, the
  `sign(g)` actually applied, the 32×32 `Wh` delta and the per-byte `E` delta.
  Every figure also emits a `<details>` table of its non-zero cells. Includes a
  twin-only weight editor.
- **Benchmark** — see below.
- **Bo mạch Arty A7** — port scan, connect, a real PING with a measured round
  trip, resync, and a SW/BTN/LED mirror that states whether it is live or
  modelled. Modelled switches render at reduced opacity and are labelled
  `KHÔNG ĐỌC ĐƯỢC`; inferred LEDs get a dashed outline.
- **Hiểu mô hình** — the datapath as seven keyboard-reachable stages, each with
  the real RTL expression and the quirk that lives there, plus per-byte `h`
  heatmaps.
- **Thuật toán** — `sign`, `sat8`, `|Δ|>>5`, the DIFF gate, the A0.2-L hinge, and
  the state update plotted twice: as built and as the law text describes. Curves
  come from `/api/math`, which calls the twin directly, so a plot cannot drift
  from the model.
- **Bằng chứng** — the golden comparison, the three quirks, what the host may and
  may not send, and the A0.2-L gates.

## Benchmark (`A7-SIM-BENCH v0.1`)

The only evaluation that existed before was a three-string smoke test
(`ALPHA` / `BETA.` / `OMEGA`, 32 epochs) in which train and eval shared all three
strings. It measured memorisation of three strings. The benchmark tab, and
`tools/a7eam03e_bench.py`, replace it with a held-out measurement.

```bash
python tools/a7eam03e_bench.py --quick
python tools/a7eam03e_bench.py --entities 400 --seeds 10 --epochs 6 --bootstrap 2000
python tools/a7eam03e_bench.py --vn                     # Vietnamese, multi-byte UTF-8
python tools/a7eam03e_bench.py --tsv pairs.tsv          # external dataset
```

**Task family.** The 46-byte input cap excludes the entire paraphrase / STS family
— QQP, PAWS, MRPC, STS-B and SICK are all two to three times too long and
truncation destroys the label — and places this system in the learned-string-metric
/ record-linkage literature instead. The comparable public benchmark is GeoNames
toponym matching (5M pairs, mean 22.7 chars,
<https://github.com/ruipds/Toponym-Matching>), where published baselines run from
61.5–65.2% accuracy for classical string metrics to 78.5% for gradient-boosted
feature combinations and 88.7% for a 60-dim GRU. `--tsv` loads that format; the
built-in `NAME-46-SYN` generator is a deterministic smoke-scale stand-in so the
harness runs today with no network, and it is labelled as such.

**Split.** Entity-level, by connected component of the pair graph, because a match
label is transitively an entity relation and splitting at pair level leaks a
string from a training pair into a test pair. `assert_no_leakage` fails the run if
any string appears in two splits.

**The control that decides everything** is the untrained, seed-only encoder. `E` is
a xorshift32 expansion, so an untrained encoder is already a random projection of
byte sequences and whatever `d1` does at step 0 is free. The project's claim
reduces to held-out AUC rising above it. A shuffled-label control runs alongside:
if random supervision moves AUC as much as real supervision, the effect is drift,
not learning.

**Metrics.** Tie-aware ROC-AUC via midranks (`d1` is quantised by `>> 5`, so ties
are common and trapezoidal integration would mis-score them), non-interpolated
average precision, held-out triplet accuracy with half credit on ties, tie mass,
a quantisation ceiling, saturation / negativity / effective rank, and a
length-shortcut audit. Baselines B0–B8 in pure Python: constant, length
difference, byte Jaccard, byte-histogram L1, bigram Dice, Levenshtein,
Damerau-Levenshtein, Jaro-Winkler, common suffix.

`B3_hist_l1` is the most informative baseline after the untrained control: it is
this architecture with the recurrence deleted — same alphabet, same L1, no order.
Failing to beat it means the Elman step contributed nothing.

**What it found.** Twin screen, `NAME-46-SYN`, reproducible:

- Training helps on some seeds and destroys the representation on others. At two
  epochs one seed went 0.607 → 0.836 AUC while `0x22222222` went 0.854 → 0.500
  with `d1` collapsing to a **single distinct value**.
- Past roughly 200–400 training pairs the state saturates completely: every
  coordinate pins at 32767, effective rank drops to 0–2, and `d1` becomes a
  constant. This is not weight death — only ~67 of 8192 `E` values reach ±127.
  It is quirk 2 compounding: each update grows `Wh`, which grows `acc`, which
  saturates more coordinates.
- The three-string golden test sits just **below** that collapse threshold, which
  is why it looked healthy.
- On the golden triplet, `M_L1` is **negative at 8 epochs** and positive at 16–64,
  and past 128 epochs the positive pair collapses to `d1 = 0`. So the frozen
  "32 epochs" is a waypoint on a non-monotone curve, not a converged state, and
  it is an unregistered hyperparameter. The **Độ nhạy theo số epoch** button plots
  this.
- Classical string metrics still win outright.

Screening only. It cannot close a gate and cannot declare BOARD_PASS.

## The board mirror, and what it costs

No UART command on any bitstream in this repo reports `sw` or `btn`: they are tied
into `wire unused` on every EAM top. `led` are output pins and cannot be read back
at all. So the Board tab has two modes and always says which one it is in:

- **MÔ HÌNH** — default. LED states are inferred from the reply flags and drawn
  with a dashed outline; switches are dimmed and labelled unreadable.
- **LIVE · CMD 0x2F** — requires `arty_a7_eam03e_io.bit`, a separate UI-support
  bitstream added by this rung. Same core, same law, one extra command. On that
  bit SW0 forces freeze and SW1 forces learn (a switch can request, never revoke),
  and BTN1/2/3 become reward / punish / reseed shortcuts.

```bash
vivado -mode batch -source vivado/tcl/build_a7eam03e_io.tcl
vivado -mode batch -source vivado/tcl/program_a7eam03e_io.tcl
```

**Do not build or program that bit yet.** The RTL has not been elaborated,
simulated or synthesised — Vivado was not installed on the machine that wrote it —
and A0.1-T timing is still open. A bit that fails timing returns wrong integers,
and the studio would flag a divergence that looks like a logic bug but is a setup
violation. Ratify the rung and close timing first.

## Weight editing

The 03E bitstream has **no weight-write command**. `E` (8192 INT8) and `Wh`
(1024 INT8) are generated on-chip from the seed by a xorshift32 and cannot be
loaded from the host. The Gradient tab's editor therefore writes to the twin only
and is labelled `CHỈ TWIN`. The four things the host may actually send are seed
(0x21), the learn/freeze flags (0x20 / 0x13), UTF-8 bytes (0x22) and a SAME/DIFF
label (0x23).

## Accessibility

Targets WCAG 2.2 AA. Every text token clears 4.5:1 on every surface it appears on
(`--faint` was lifted from `#6a77a3` at 3.25:1 to `#98a2c6` at 5.65:1); control
boundaries use a separate `--edge` token at ≥4.1:1 while `--line` stays decorative.
One global `:focus-visible` ring, `prefers-reduced-motion`, and a `forced-colors`
block that reverts custom-painted controls to something the OS can render.

Chart series are separated by **dash pattern and marker shape**, not colour: on
this background every series colour must clear 3:1 against the panel, which forces
them into a narrow luminance band where no two can reach 3:1 from each other.
Heatmap cells carry a `+` / `−` glyph for the same reason. Each chart is
`role="img"` with an `aria-label` stating the trend, and figures with no other
on-screen presentation also emit a `<details>` data table of their non-zero cells.
SSE updates funnel into one throttled `role="status"` region — a naive live region
on the metrics would queue an announcement every 40ms during auto-training.

Not validated with a live screen reader, at 200% zoom, or in Windows High Contrast
mode. Those need a real browser and a real user.

## HTTP surface

| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/api/state` | snapshot: seed, flags, board, sync, curriculum, board_error |
| GET | `/api/events` | SSE: `step`, `divergence`, `mode`, `seed`, `training`, `bench` |
| GET | `/api/history` | last 400 records |
| GET | `/api/inspect` | full vectors for the last pair |
| GET | `/api/math` | curve samples straight from the twin |
| GET | `/api/evidence` | goldens, quirks, contract gates |
| GET | `/api/bench` | last benchmark result |
| GET | `/api/ports`, `/api/board/io` | serial ports, board IO |
| POST | `/api/step` | one pair: `{a, b, verdict: reward\|punish}` |
| POST | `/api/mode`, `/api/seed` | flags, reseed |
| POST | `/api/curriculum` | replace the pair list |
| POST | `/api/train/start`, `/api/train/stop` | auto-train loop |
| POST | `/api/board/connect`, `/api/board/disconnect`, `/api/board/resync`, `/api/board/ping` | link control |
| POST | `/api/twin/weight` | twin-only weight write |
| POST | `/api/bench/start`, `/api/bench/stop`, `/api/bench/epochs` | benchmark |
| POST | `/api/sweep/start`, `/api/sweep/stop` | twin seed sweep |

Bind to `127.0.0.1` unless you mean otherwise: there is no authentication, and
`/api/board/*` drives real hardware.

## Session logs

One JSONL record per pair in `results/A7-EAM-03E/ui_sessions/session_<ts>.jsonl`,
carrying both tracks and the `agree` field. Benchmark runs go to
`results/A7-EAM-03E/bench/`. Operator logs, not ladder results: promoting one
requires a board run under `tools/a7eam03e_a0_silicon.py`.
