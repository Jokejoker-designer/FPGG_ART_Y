# E6 — scale-targeted decay, threshold 1024: NOT a development pass, and Branch C

11 pre-registered **selection** seeds, 100,000 updates, `m = 4096`, decay shift
3, single change `scale_target = 1024`: apply the `Wh` decay only on transactions
where `max|h|` exceeds the target. Threshold set `{256, 512, 1024, 2048}`
pre-registered in `SCALE_TARGET_SET`; the tool refuses anything outside it.

Evidence class: **REFERENCE MODEL**. Control is the identical configuration with
unconditional decay, `results/A7-EAM-03E/A02_L_S3/horizon100k/`.

## Which law E6 runs on — the question that had to be settled first

E6 uses `TripletTwin.triplet()`. That method computes
`active = (d_pos − d_neg + margin) > 0` and **never references `E3_MARG` as a
gate**. The identifier `gate_open` does not appear in the file. The old DIFF gate
`d1 < E3_MARG` lives only in `pair()`, which `triplet()` does not call. The base
state update is `h_update_signed`, i.e. the A0.3 law whose RTL is XSim- and
silicon-exact.

So E6 is **neither the old gated-DIFF law nor an ungated-DIFF baseline**. The
triplet law has no absolute-distance gate at all: every triplet whose margin is
violated pushes its negative, regardless of how far apart they already are. The
gating variable is the margin, not a distance threshold.

Two consequences, stated because they change what E6 can be used for:

- E6 does **not** need redoing on an ungated baseline. It already has no
  absolute-distance gate.
- E6 does **not** replace the H5 experiment either. H5 was tested separately at
  `results/A7-EAM-03E/E1_UNGATED_100K/` with its own sanity gate
  (`diff_suppressed_count = 0`) and was falsified there, 11/11 collapse. Two
  independent questions, each already answered on its own terms.

E6 therefore answers the scale-control question only, which is what it was for.

## Verdict by the locked decision order

| # | criterion | result |
|---|-----------|--------|
| 1 | no collapse (`unique_d1 > 1` and rank > 1) | 10/11 |
| 2 | no saturation (`sat < 0.5`) | **11/11** |
| 3 | **rank retained (>= 8)** | **1/11** |
| 4 | no inversion (`M_L1 >= 0`) | 9/11 |
| 5 | `M_cos >= 0` | 9/11 |
| 6 | worst ΔAUC | −0.169 |
| 7 | median ΔAUC | +0.108 |

Fails at criterion 3. **Not `E6_DEVELOPMENT_PASS`.** No threshold freeze, no
confirmation run.

## The gate made scale regulation worse, which falsifies my own reasoning

Side by side against unconditional decay, same seeds, same horizon:

| | base (S3 unconditional) | E6 (gated at 1024) |
|---|---:|---:|
| `max|h|` spread | **275 … 611** (2.2×) | **384 … 24399** (64×) |
| rank >= 8 | **10/11** | 1/11 |
| `E_rail` median | 204 | 308 |
| `M_L1 >= 0` | 9/11 | 9/11 |
| `M_cos >= 0` | 5/11 | **9/11** |
| AUC median | 0.655 | **0.721** |
| AUC max | 0.753 | **0.864** |

E6 was built on my claim that "a fixed decay rate cannot hold a band: `>>3`
overshoots down to ~150 within 32 updates". The endpoint data says the opposite.
Unconditional `>>3` holds `max|h|` inside 275–611 across all eleven seeds — that
is tight regulation. Gating it off below a threshold destroyed that, letting two
seeds reach 15572 and 24399.

I had mistaken S3's initial transient for a failure to regulate. The crush to
~150 at update 32 is real, but it is a transient; the *endpoint* was already
well controlled. Removing the restoring force in the region where it was doing
the fine regulation is what broke it.

Mechanically this is unsurprising in hindsight: unconditional decay is
proportional, so it self-regulates — larger `Wh` means a larger absolute
subtraction. A one-sided gate deletes that feedback below the threshold, `Wh`
drifts up unopposed, and by the time `h` crosses 1024 the decay acts on `Wh`
while `h` lags far behind, overshooting.

## But E6 produced the best representation quality in the program

This is the part that must not be buried under the failed criterion.

`M_cos >= 0` rose from 5/11 to 9/11 — nearly double, with values well clear of
the 1.5% `e_ra` angular noise floor (+0.612, +0.597, +0.524, +0.399). AUC median
rose 0.655 → 0.721 and the maximum reached **0.864**, against a previous
program-wide ceiling of 0.753. Five seeds peak at the 100k horizon, still
climbing.

The two seeds that gained most are exactly the two that failed under base S3:
`0x7A9BE636` 0.479 → 0.613 and `0xEC62BC77` 0.515 → 0.825.

## Reading the two together gives the setpoint

Sorting E6 seeds by final `max|h|` against AUC:

| `max|h|` | 384 | 545 | 547 | 800 | 1638 | 1777 | 1930 | 3142 | 4541 | 15572 | 24399 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| AUC | 0.525 | 0.727 | 0.555 | **0.853** | 0.627 | **0.864** | **0.825** | **0.841** | 0.721 | 0.613 | 0.708 |

Best AUC clusters at `max|h|` between roughly **800 and 3100**. Below that and
above that both degrade. Base S3 regulates tightly but at **275–611 — below the
productive band**, which is why its median AUC is 0.655 while E6 seeds that
happen to land in the band reach 0.84–0.86.

So the target is not "stop regulating"; it is "regulate at a higher setpoint".

That has already been tried by the obvious route and it does not work: weakening
the decay to shifts 4, 5 and 6 was run at 11 seeds and 100k
(`A02_L_S3/sh4`, `sh5`, `sh6`) and gentler decay collapses to rank 1 rather than
settling higher. A weaker restoring force does not raise the equilibrium here, it
loses control.

## Branch determination: C, not B

Against the pre-agreed branch definitions:

- **Not Branch A.** Criterion 3 fails at 1/11.
- **Not Branch B.** Branch B requires healthy `h` scale with `E` rails rising.
  `h` scale is emphatically not healthy — a 64× spread across seeds — and
  `E_rail` rose only modestly, median 204 → 308 out of 8192 entries. `E` drift is
  present but it is not the distinguishing failure here.
- **Branch C.** "Single-threshold one-sided decay is sufficient" is
  **FALSIFIED**, and falsified in a specific direction: the one-sided gate is
  worse than no gate at all for scale control.

The next experiment on this branch is the two-sided controller. Note that plain
hysteresis as sketched — decay ON above `T_hi`, OFF below `T_lo` — is still
one-sided in the sense that matters: nothing *raises* scale when it sits too low.
E6's data says the failure mode below the band is as real as above it
(`max|h|` 384 → AUC 0.525). A controller that only removes decay cannot lift a
seed from 384 into the 800–3100 band; that is what base S3 already does and it
lands at 275–611.

So the honest specification for the next experiment is a controller with a
setpoint in the 800–3100 band and action in **both** directions, not merely a
gate with two thresholds. What supplies the upward action is an open design
question and must be one unknown on its own.

## Not claimed

No RTL, XSim or board evidence for any scale-controlled law. No claim about
thresholds 256, 512 or 2048 — they remain pre-registered and unrun, and given
that 1024 already produced a 64× spread, a lower threshold is expected to gate
off more often and spread further rather than less. No confirmation run: E6 did
not earn one. The 800–3100 band is read off eleven points and is a hypothesis
about where the setpoint lies, not a measured optimum.

## Standing state

Best configuration by the locked order remains **triplet hinge + unconditional
S3 decay `>>3`** (rank >= 8 on 10/11, `M_L1 >= 0` on 9/11, AUC median 0.655).
Best configuration by representation quality is E6, which fails the order.
Neither is a PASS. `A1`, `Kidi`, `NATIVE-V1` stay CLOSED. No RTL beyond A0.3.
