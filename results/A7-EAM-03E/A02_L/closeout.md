# A0.2-L triplet hinge — twin pre-check, and where the encoder actually breaks

Law: `eam03e-a02-triplet-v1` on the `eam03e-a03-signed-h-v1` base.
Evidence class: **REFERENCE MODEL**. No RTL was written, which was the point:
A0.3 proved the twin predicts the RTL to the integer, so a failing law is
supposed to cost minutes here rather than a synthesis run.
Margin: `m = 4096`, the `E3_MARG` value named in `docs/contracts/A7-EAM-03E-A02.md`.
Pre-registered margin set `{4096, 2048, 1024, 512}` frozen in
`tools/a7eam03e_a02l_twin.py`, which refuses anything outside it.

## Verdict

`A0.2-L twin pre-check: FAIL` — 0 of 11 pre-registered seeds pass. RTL not
started, correctly.

| Seed | AUC init | AUC peak | at update | AUC final | rank | M_L1 | M_cos | hinge active |
|------|--------:|--------:|---------:|---------:|-----:|-----:|------:|------------:|
| 0x11111111 | 0.519 | 0.633 | 32 | 0.500 | 1 | 0.0 | −0.703 | 0.63 |
| 0x7A9BE636 | 0.457 | 0.642 | 32 | 0.500 | 1 | 0.0 | +0.202 | 0.74 |
| 0x37410899 | 0.651 | **0.771** | 64 | 0.500 | 3 | 0.0 | −0.183 | 0.54 |
| 0xAE7C9805 | 0.695 | **0.782** | 64 | 0.500 | 2 | 0.0 | +0.105 | 0.58 |
| 0x68323257 | 0.697 | 0.697 | 0 | 0.500 | 1 | 0.0 | +0.048 | 0.72 |
| 0xEC62BC77 | 0.490 | **0.743** | 64 | 0.500 | 1 | 0.0 | −0.035 | 0.76 |
| 0xE6C4400D | 0.697 | 0.738 | 32 | 0.500 | 1 | 0.0 | +0.391 | 0.74 |
| 0xFB8CACAA | 0.620 | 0.620 | 0 | 0.500 | 1 | 0.0 | −0.189 | 0.85 |
| 0xB2B49299 | 0.705 | **0.771** | 64 | 0.500 | 1 | 0.0 | −0.171 | 0.82 |
| 0xCCAC16C3 | 0.633 | 0.633 | 0 | 0.500 | 1 | 0.0 | −0.470 | 0.74 |
| 0x22222222 | 0.688 | 0.688 | 0 | 0.419 | 6 | 32.8 | −0.050 | 0.52 |

Contract A02 hard stop: worst-seed `M_L1 >= 0` **and** `M_cos >= 0`.
Worst `M_L1` = 0.0, worst `M_cos` = −0.703. **FAIL.**

`M_L1 = 0.0` is not a near miss. It is the signature of total degeneracy: every
distance is zero, so the margin is zero by construction. Under `final.md` §8
("do not trust `M_L1` if `effective_rank` collapses") a non-negative `M_L1` here
would have been a forbidden PASS, not a win. The earlier 256-update smoke run
showed exactly that trap: `M_L1 = +94` with rank already down to 2.

## The one genuinely encouraging number

Peak AUC reaches **0.782** and exceeds 0.74 on four seeds, at 32–64 updates.
That is the best this program has measured under any law: the shipped law never
passed 0.582, and the signed pair law peaked at 0.804 on a single seed while most
sat lower. The triplet hinge does make the early trajectory better, and it does
it while the hinge is active on 52–85% of transactions, so it is genuinely doing
work rather than idling.

The law has a good operating point at roughly 50 updates and no mechanism that
stays there.

## H6 tested and falsified: the embedding table is not the problem

Every failing variant so far ends identically — all distances zero, one unique
`d1`, `effective_rank` 1. The one component they all share is `E`, a 256×32
table updated by a ±1 delta broadcast to every byte of every string in the
transaction. So the obvious hypothesis was that `E` is being erased.

Measured on the rows `E` actually uses (52 distinct bytes touched by TRAIN),
three seeds, same checkpoints:

| updates | E effective rank | mean pairwise row L1 | min row L1 | identical row pairs | top-1 spectrum share |
|--------:|----------------:|--------------------:|-----------:|-------------------:|--------------------:|
| 0 | 32/32 | 2721 | 1839 | 0 / 1326 | 0.055 |
| 1000 | 32/32 | 2750 | 1815 | 0 / 1326 | 0.060 |
| 5000 | 32/32 | 3195 | 160 | 0 / 1326 | 0.171 |
| 10000 | **32/32** | **3583** | 0 | 5 / 1326 | 0.259 |

`E` keeps full rank 32/32 at every checkpoint on every seed, and its rows move
**further apart** over training, not closer. Byte identity is never erased.

**H6 is FALSIFIED.** The input layer retains its information while the state
collapses to a single point. That dissociation is the most informative result in
this document.

## Where the encoder actually breaks

The recurrence, not the table and not the hinge.

`h_{t+1} = sat16((Wh · h_t + (e_t << 8)) >> 8)`. As `‖Wh‖₁` grows, the recurrent
term dominates the input term, so the map forgets `e` and converges to the
dominant mode of `Wh` — the *same* vector for every input string. That is
precisely what "all distances zero, unique `d1` = 1, rank 1" means, and it
explains why `E` can stay perfectly diverse while `h` does not: the information
is present at the input and destroyed in the loop.

It also explains the S2 result in `results/A7-EAM-03E/A03_S/`, which otherwise
looks contradictory. Clamping `Wh` to ±8 stops the forgetting (rank holds at 11)
but leaves a second, smaller flaw exposed: with a weak recurrence, `h` is
essentially a positionally weighted bag of bytes, and the byte-broadcast update
loses attribution. A byte shared between the anchor and the positive receives
`−sgn(gA)` and `−sgn(gP)` in succession, and those do not cancel to the pull we
want; `sgn(gA) = sgn(hN − hP)` drags the shared rows according to the *negative*.
English and Vietnamese names share letters heavily, so for exactly the pairs that
should be pulled together the update is contaminated by the negative. That is a
coherent mechanism for the sub-chance AUC (0.403 median, 11/11 seeds below 0.5)
measured at clamp ±8.

Two forces, now both localised:

1. **Recurrence gain.** `‖Wh‖₁` growth makes the state forget its input.
   Evidence: `A03_SIGNED` (Wh doubles, rank → 1), `A03_S` (clamping restores
   rank), this document (E stays full rank while h does not).
2. **Byte attribution loss.** The ±1 delta is broadcast per byte occurrence with
   no ownership, so shared bytes receive contradictory updates. Evidence:
   `A03_S` sub-chance AUC once force 1 is removed. **Hypothesised, not yet
   isolated by its own experiment.**

## Consequence for the queue

`A1`, `Kidi` and `NATIVE-V1` stay **CLOSED**. Gluing frozen 01R/02M/LM-06 onto
an encoder that provably maps every string to one point would manufacture a
retrieval demo out of a degenerate representation, which is the explicit hard
stop. The peak-AUC-0.78 operating point is not a substitute: it exists for a few
dozen updates and has no mechanism holding it there.

The next gate is therefore **not** in the current contract set. It is a new
encoder law addressing force 1 and force 2 **separately**, one per patch:

- **A0.4-G** — bound the recurrence gain so the state cannot forget its input,
  as a law rather than as an ablation clamp. `A03_S` already establishes the
  dose-response, so the pre-registration is available.
- **A0.5-ATTR** — per-occurrence gradient attribution so a byte shared between
  anchor, positive and negative is not updated by contradictory signs. This
  needs its own falsification experiment first: restrict updates to the
  symmetric difference of the three byte sets and measure whether sub-chance AUC
  disappears.

Both need a contract frozen before implementation, per `final.md` §21, and
neither may be bundled with the other.

## Artifacts

| File | Content |
|------|---------|
| `triplet_twin_sweep.json` | 11 seeds, 10 checkpoints, full telemetry, m = 4096 |
| `erank_probe.json` | H6 test, 3 seeds, E rank and row diversity |
| `tools/a7eam03e_a02l_twin.py` | triplet law on the twin |
| `tools/a7eam03e_erank_probe.py` | H6 probe |

Design choice recorded so it is not mistaken for a free parameter: the `Wh`
update is driven by the **anchor only**, because the anchor is the one vector
appearing in both hinge terms. Widening it to the positive and negative is a
separate experiment, not a tuning knob.

## Not claimed

No RTL. No XSim. No board. Margins 2048, 1024 and 512 were not run: the m = 4096
result is a collapse to `M_L1 = 0`, and a margin sweep tunes *when* the hinge
stops, not whether the recurrence forgets its input. They remain pre-registered
and available if a later result makes them informative.
