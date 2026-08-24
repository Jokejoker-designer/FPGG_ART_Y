# A7-EAM-03E Phase S — long-horizon stability (2026-08-20)

Law under test: `eam03e-a0-signsgd-v1`, unchanged. No fix applied.
Evidence class: **REFERENCE MODEL** (host twin), not XSim, not board.
The twin is integer-exact against the frozen A0.1-T goldens; `golden_check`
is asserted before the sweep starts and refuses to run otherwise.

## Verdict

`STABILITY_FAIL` on 11 of 11 pre-registered seeds. Collapse reproduced 11/11.

| Gate | Result |
|------|--------|
| AUC_post > AUC_init | FAIL 11/11 |
| AUC does not return to ~0.5 | FAIL 11/11 (final AUC exactly 0.500000) |
| effective_rank noncollapsed (>= 8) | FAIL 11/11 (final rank 0) |
| saturation far below total | FAIL 11/11 (final 1.000) |
| unique_d1_count > 1 | FAIL 11/11 (final 1) |
| no acc runaway | PASS 11/11 (see below — and this is the interesting part) |

Do not read the last row as good news. It is the row that falsifies the
assumed cause.

## The stated hypothesis is wrong

The task mandate states the collapse is "recurrent scale runaway: Wh/acc grows,
h saturates, effective rank collapses". Measured over 10,000 updates:

| Quantity | Update 0 | Update 10000 | Verdict |
|----------|---------:|-------------:|---------|
| `Wh_l1` (seed 0x11111111) | 64696 | 64596 | flat, ‑0.15% |
| `max_abs_Wh` | 128 | 128 | constant, at the seed range, from birth |
| `Wh_rail_count` / 1024 | 8 | 9 | no growth |
| `max_abs_acc` | 34,219,930 | 31,631,795 | **decreases** |
| `fraction_acc_wrapped` | 0.000 | 0.000 | never wraps |

Across all 11 seeds `Wh_l1` moves by at most 0.4% and `max_abs_Wh` never leaves
128. `max_abs_acc` peaks around 3.4e7, which is 1.6% of the 2^31 wrap threshold.

**H1 (recurrent scale runaway) is FALSIFIED.** Nothing runs away. Consequently
the mandate's prescribed remedies S1 (reduce Wh update rate), S2 (bound Wh) and
S3 (Wh decay) all target a mechanism that does not occur. Applying them would
be treating the wrong cause and any apparent improvement would be incidental.

## What actually happens

`negativity_rate` is exactly `0.0` at every checkpoint of every seed: 110
measurements, no exceptions. The state can never be negative. That is the tell.

`rtl/eam/eam03e_core.sv:229` is the state update:

```systemverilog
h[k] <= e3_sat16((acc[k] + {{8{e_lat[k][7]}}, e_lat[k], 8'd0}) >>> E3_SH);
```

`e_lat` is `logic signed [7:0]` (line 51) and the author clearly intended a
sign-extended `e_lat << 8`. But a concatenation in SystemVerilog is **always
unsigned**, whatever its operands. One unsigned operand makes the whole addition
unsigned, and `>>>` applied to an unsigned expression degrades to a logical
shift. `acc` is `logic signed [31:0]` (line 60) and is frequently negative, so a
negative accumulator is reinterpreted as a value near 2^32, the logical shift
yields something near 2^24, and `e3_sat16` clamps it to `32767`. The coordinate
rails, permanently.

Corroboration that this is a defect and not a design choice: `eam_controller.sv`
lines 37-41 use the identical sign-extension idiom on the identical kind of
expression and **do** wrap it in `$signed(...)`:

```systemverilog
st[i] <= eam_sat8($signed({{8{st[i][7]}}, st[i]})
                + $signed({{8{vec[8*i+7]}}, vec[8*i +: 8]}));
```

The repository already knows the correct form. `eam03e_core.sv:229` omits it.

Measured on untrained encoders, shipped rule:

| Seed | acc cells negative | h cells railed | share of rails traceable to negative acc | acc_min |
|------|------------------:|---------------:|----------------------------------------:|--------:|
| 0x11111111 | 46-57% | 68-76% | 56-62% | -3.2e7 |
| 0x22222222 | 34-39% | 74-83% | 39-41% | -2.7e7 |
| 0xAE7C9805 | 39-48% | 74-89% | 41-51% | -4.0e7 |

The remaining rails come from genuinely large positive `acc`, so the signedness
defect is the dominant but not the sole cause. Stated precisely: it explains
roughly half of the railing and all of the sign asymmetry.

**H2 (arithmetic signedness defect) is CONFIRMED as the mechanism.**

### Confirmed in XSim on the real RTL, not only in the twin

`tests/xsim/tb_eam03e_sat_probe.sv` instantiates `eam03e_core` and reads the
internal `h` array through a hierarchical reference after each encode. Untrained,
seeded weights only, no training, no host involvement:

| Seed / string | railed at 32767 | negative |
|---------------|----------------:|---------:|
| 0x11111111 / BETA. | 29/32 | 0 |
| 0x11111111 / OMEGA | 24/32 | 0 |
| 0x22222222 / ALPHA | 27/32 | 0 |
| 0x22222222 / OMEGA | 29/32 | 0 |
| 0xAE7C9805 / ALPHA | 28/32 | 0 |
| 0xAE7C9805 / OMEGA | 30/32 | 0 |

167 of 192 valid cells railed (87.0%), zero negative cells anywhere. Marker
`A7EAM03E_SATPROBE_CONFIRMS_UNSIGNED_RAIL`. This is XSim evidence and it agrees
with the twin's 0.79-0.89 saturation.

A seventh probe was discarded: the first encode after reset returns `x` on every
coordinate because `e_ra` has no reset in the RTL and `S_SEED` never writes it,
so the first read address is undefined. That matches the twin's documented
power-on prime requirement and is a separate latent issue worth its own note.

## The encoder is already damaged before training

At update 0, with no training at all, saturation is 0.793-0.892 and effective
rank is 12-29 of 32. Between 79% and 89% of the "32-dimensional state" is a
constant, on arrival. Training does not create the collapse; it completes one
that the seeded arithmetic already started.

## The terminal state is absorbing, not merely bad

Once every coordinate of every state rails at 32767, `hA[k] - hB[k] == 0` for
all k, so `gA = gB = 0`, so `sgn8` returns 0, so no weight is written. Learning
halts permanently. Cumulative weight writes:

| Seed | writes stop at | E writes final | Wh writes final |
|------|---------------:|---------------:|----------------:|
| 0xAE7C9805 | 256 updates | 5,778 | 6,624 |
| 0x7A9BE636 | 512 updates | 48,605 | 54,496 |
| 0x37410899 | 5000 updates | 43,001 | 49,152 |
| 0x11111111 | still trickling | 20,846 | 24,445 |

Three of the first four seeds reach exactly zero further writes and stay there
for the rest of the horizon. This is a dead fixed point, so no amount of
additional training data can recover it. It also means the DIFF gate is not the
bottleneck: it is measured open 100% of the time after ~1000 updates, but there
is no gradient left for it to gate.

## Ablation: repairing signedness is necessary and not sufficient

Reference-model ablation only (`tools/a7eam03e_rootcause.py`). Not a law, not
RTL, no contract implied. Signed add plus arithmetic shift, everything else
identical, 1000 updates:

| Seed | Rule | Untrained AUC | Trained AUC | Sat | Rank | Unique d1 |
|------|------|-------------:|-----------:|----:|-----:|----------:|
| 0x11111111 | shipped | 0.474 | 0.500 | 1.000 | 0 | 1 |
| 0x11111111 | signed | 0.519 | **0.658** | 0.000 | 27 | 45 |
| 0x22222222 | shipped | 0.667 | 0.500 | 1.000 | 0 | 1 |
| 0x22222222 | signed | 0.688 | **0.393** | 0.480 | 1 | 13 |
| 0xAE7C9805 | shipped | 0.582 | 0.500 | 1.000 | 0 | 1 |
| 0xAE7C9805 | signed | 0.695 | **0.259** | 0.467 | 17 | 48 |

Repairing the signedness removes the rail (rail rate 0.73 → 0.00-0.03),
restores negativity (0.000 → ~0.48) and gives full rank 32 untrained. The total
collapse to AUC 0.500 disappears.

But on two of three seeds the trained encoder becomes **worse than untrained**,
one of them at 0.259, which is far enough below chance to be an ordering
inversion rather than noise. So there is a second, independent defect in the
update rule that the rail was previously masking.

That is the honest summary: **two separate failures, discovered in sequence.**
Only the first is diagnosed.

## Classification

| Claim | Class |
|-------|-------|
| Collapse reproduces on 11/11 seeds | EVIDENCE (reference model) |
| Wh/acc runaway does not occur | EVIDENCE (reference model) |
| Unsigned concat rails h from negative acc | EVIDENCE (**XSim** + reference model + RTL reading) |
| State is never negative on real RTL | EVIDENCE (**XSim**, 192 cells, 0 negative) |
| First encode after reset is X (`e_ra` unreset) | EVIDENCE (**XSim**) |
| Terminal state is absorbing (zero writes) | EVIDENCE (reference model) |
| Signedness repair removes the rail | EVIDENCE (reference model ablation) |
| A second defect exists in the update rule | EVIDENCE that it exists, NOT diagnosed |
| The signed variant is the right law | NEEDS_EXPERIMENT — not claimed |

No board evidence is claimed for anything in this document. The rail mechanism is
XSim-confirmed on the real RTL; everything about the 10,000-update trajectory,
the absorbing state and the signed ablation is reference-model only and is
labelled as such. The two are not mixed.

## Experiment control

`e_ra` persists across pairs in the RTL, so evaluating perturbs training.
Evaluation saves and restores `e_ra`, slot buffers and mode so that the
checkpoint schedule does not alter the trajectory. This is a deliberate
deviation from board behaviour, taken so that checkpoints are comparable across
seeds and schedules.

## Pre-registration

Seeds, checkpoints, dataset and split were fixed in
`tools/a7eam03e_stability.py` before the first run. Ten seeds come from the
published `frozen_seeds` rule, `0x22222222` is included deliberately as the
known inversion case, and `0x11111111` is prepended because it is the seed the
board golden is pinned to. No seed was dropped. Dataset is split by connected
component and `assert_no_leakage` passes.

## Artifacts

| File | SHA256 |
|------|--------|
| `stability_sweep.json` | `BABC23BC1CAE83D3AAB9AC21AF3365B197C2B10A57F9C3C9D2FF9E0700078472` |
| `rootcause.json` | `9F469C7DF80101A143030E4992DDD4029D2BDE355077EF7AAB30AB3FBC50F742` |
| `tools/a7eam03e_stability.py` | `4ADBC1854F1E14F3F2C47EBA6FE2700D2B67395032F18463CE620C5C1B9AA31F` |
| `tools/a7eam03e_rootcause.py` | `DB4583D1E2E3F8636BFD32F3D39D4E7676CA99006FF0B312049FBBBC9529E235` |
| `python/eam/eam03e_twin.py` | `490D9A91501A3D5C0D171D042DCC62C73A8C02CC7A4F50A8D2AC8E79D2C2E583` |
| `python/eam/eam03e_bench.py` | `E20FCCBF4264D4524930D32F533538EDF55F6FDE4359ADA318BA3E107F133BDF` |

The only twin change this phase was recording `acc_max_abs` / `acc_wrapped` in
`ForwardTrace`. The 7 A0.1-T goldens and all 10 twin golden tests still pass
byte-identically after that addition, so the twin remains a valid oracle.

## Downstream status

A0.2-L stays **CLOSED**. Implementing triplet hinge on top of an encoder whose
state is 80% constant before training and fully railed after would produce a
margin number with nothing behind it, which section 8 of the mandate exists to
prevent.

A1 stays **CLOSED**. Kidi stays **CLOSED**.

## Recommended next experiment, and why it needs authority first

The evidence points to one change, not three: repair the `h_update` signedness.
That is a change to numerical law, so under the mandate and `BAN_GIAO` section 8
it cannot ride on the A0.1-T version. It needs a new law id, a new contract
frozen before implementation, and its own T-style timing and golden lineage
(the A0.1-T goldens will necessarily change, which is legitimate for a new law
and forbidden for this one).

The second defect in the update rule should be diagnosed on the signed
reference model before any RTL is written, so that one RTL revision does not
carry two unresolved unknowns.
