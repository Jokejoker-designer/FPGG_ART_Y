# A7-EAM-03E-A0.3 — signed state update (`eam03e-a03-signed-h-v1`)

**Status:** FROZEN as a contract. **No RTL exists yet.**
**Parent:** `A7-EAM-03E-A.md`
**Law id:** `eam03e-a03-signed-h-v1`
**Supersedes for new work:** nothing. `eam03e-a0-signsgd-v1` stays frozen and
keeps its own golden bag as regression authority.
**A0.2-L, A1, KIDI, NATIVE-V1:** remain CLOSED. This contract does not open them.

Frozen before implementation, per `final.md` §21. It must not be rewritten to
match whatever the RTL turns out to do.

## Why this law exists

Phase S measured, on 11 pre-registered seeds over 10,000 updates
(`results/A7-EAM-03E/A02_STABILITY/`):

- `STABILITY_FAIL` 11/11. Final AUC exactly 0.500, `effective_rank` 0,
  `unique_d1_count` 1, saturation 1.000.
- The hypothesis in `final.md` §1 and §8 — recurrent scale runaway — is
  **FALSIFIED**. `Wh_l1` moves by at most 0.4%, `max_abs_Wh` never leaves 128,
  `max_abs_acc` peaks at 1.6% of the 2^31 wrap threshold and *decreases*,
  `fraction_acc_wrapped` is 0.000 throughout.
- Therefore the §8 remedies S1 (reduce Wh update rate), S2 (bound Wh) and S3
  (Wh decay) are **not applied**: they treat a mechanism that does not occur.
- `negativity_rate` is exactly 0.0 in all 110 measurements. The state cannot be
  negative.

Root cause, `rtl/eam/eam03e_core.sv:229`:

```systemverilog
h[k] <= e3_sat16((acc[k] + {{8{e_lat[k][7]}}, e_lat[k], 8'd0}) >>> E3_SH);
```

`e_lat` is `logic signed [7:0]` and the intent is a sign-extended `e_lat << 8`.
But a SystemVerilog concatenation is always unsigned regardless of its operands,
an unsigned operand makes the whole addition unsigned, and `>>>` on an unsigned
expression degrades to a logical shift. `acc` is `logic signed [31:0]` and is
negative in 34–57% of cells, so a negative accumulator is reinterpreted as a
value near 2^32, shifts down to near 2^24, and `e3_sat16` clamps it to `32767`.

Confirmed in XSim on the real RTL by `tests/xsim/tb_eam03e_sat_probe.sv`:
167 of 192 valid state cells railed at 32767 (87.0%), zero negative cells,
untrained. Marker `A7EAM03E_SATPROBE_CONFIRMS_UNSIGNED_RAIL`.

The same idiom is used **correctly** elsewhere in this repository,
`rtl/eam/eam_controller.sv:37-41`, wrapped in `$signed(...)`.

## The change, and only this change

```systemverilog
h[k] <= e3_sat16($signed({{8{e_lat[k][7]}}, e_lat[k], 8'd0}) + acc[k]) >>> E3_SH);
```

Signed add, arithmetic shift right. Nothing else moves. Explicitly unchanged:
seed schedule and 9280 xorshift fill, embedding rotation and `e_ra` behaviour,
`Wh` recurrence and its INT8 range, `d1 = Σ(|hA−hB| >> 5)` with `16'hFFFF`
saturation and term order `i = 0..31`, `dH`, the ±1 projection and its unsigned
`!= 0` cue compare, SignSGD on `E` and `Wh`, `E3_MARG = 4096`, the DIFF gate,
`E3_SH = 8`, the tokenizer, the UART protocol, and the `S_DIST`/`S_DADD`
pipeline that closed A0.1-T timing.

One unknown per patch. This contract fixes signedness. It does **not** carry the
triplet law, and it does **not** carry the second defect below.

## Pre-registered golden bag

The A0.1-T integers belong to `eam03e-a0-signsgd-v1` and are **not** this law's
authority. They must not be edited.

A new law needs new integers, and taking "whatever the RTL prints" as the golden
would make the regression vacuous. So the integers below were **predicted from
the reference twin before any RTL was written**, by
`tools/a7eam03e_a03_predict.py`, and frozen here.

Seed `0x11111111`, strings `ALPHA` / `BETA.` / `OMEGA`, 32 steps, replaying the
exact `tb_a7eam03e.sv` sequence:

| Phase | d1(AB) | d1(AC) |
|-------|-------:|-------:|
| after seed + prime | **739** | **581** |
| after 32× BETA=SAME | **164** | **1957** |
| after RESEED | **742** | — |
| after 32× OMEGA=SAME | **1370** | **137** |

Predicted state health at the same point: `h` saturated **0/32** coordinates,
against 29/32 under the shipped law.

Evidence class: REFERENCE MODEL prediction. The same harness reproduces all
seven A0.1-T integers exactly, which is what licenses the prediction.

**If the RTL disagrees with these numbers, one of the two models of the change is
wrong. Investigate both. Do not edit this table.** Only a documented, explained
modelling error in `tools/a7eam03e_a03_predict.py` may amend it, and the
amendment must be recorded with the reason.

## Known consequence: RESEED stops being idempotent

Under A0.1-T, `init_AB` and `reset_AB` are both 3930. Under this law they are
739 and 742. The difference is real and is caused by `e_ra`: it has no reset in
the RTL and `S_SEED` never writes it, so a reseed inherits the previous pair's
read address. The rail was hiding this. The same defect makes the first encode
after power-on read an undefined address, which XSim shows as `x`.

This is a **separate** latent defect. It is recorded here so the 739/742
asymmetry is not mistaken for a modelling error, and it is deliberately **not**
fixed in this patch. It gets its own lane.

## Second defect: known to exist, not diagnosed, not in scope

Reference-model ablation, 1000 updates, signedness repaired and nothing else:

| Seed | Untrained AUC | Trained AUC | Rank | Verdict |
|------|-------------:|-----------:|-----:|---------|
| 0x11111111 | 0.519 | 0.658 | 27 | improves |
| 0x22222222 | 0.688 | 0.393 | 1 | **worse than untrained** |
| 0xAE7C9805 | 0.695 | 0.259 | 17 | **worse than untrained, inverted** |

Repairing signedness removes the rail and the total collapse, but on 2 of 3
seeds training then makes the encoder worse than not training at all. There is a
second, independent defect in the update rule that the rail was masking.

It must be diagnosed on the **signed reference twin** before this RTL is
written, so that one RTL revision does not carry two unresolved unknowns. Its
fix, if any, is a further law id — not this one.

**Diagnosed 2026-08-20**, see `results/A7-EAM-03E/A03_SIGNED/second_defect.md`.
Two distinct forces reach the same endpoint:

- `‖Wh‖₁` roughly doubles (65277 → 129464) once the rail no longer clamps the
  recurrence, driving `effective_rank` 32 → 1.
- SAME pull is unconditional while DIFF push is gated by `d1 < E3_MARG`, so the
  net field is pure attraction and `d_pos`/`d_neg` co-contract to zero with
  their ratio pinned near 1.

The bag-of-bytes shortcut hypothesis was falsified: `spearman(d1, byte-histogram
L1)` stays at 0.09–0.37 with no upward trend.

**Scope correction that this contract must carry forward:** the Phase S closeout
says not to apply the `final.md` §8 remedies S1/S2/S3. That instruction is
correct **for `eam03e-a0-signsgd-v1` only**. Under a signed state update the Wh
runaway those remedies target does occur, so S1 and S2 become live candidates —
in a separate lane `A0.3-S`, one at a time, after this contract's RTL closes.

Consequently the phase after A0.3 is **not** A0.2-L. Order is A0.3 → A0.3-S
(stability under the repaired law) → A0.2-L (triplet hinge). The triplet hinge
is a plausible cure for the attraction asymmetry and is **not** a cure for the
Wh growth; the two must not be bundled.

## Deliverables and order

1. This contract, frozen. ✔
2. Pre-registered golden bag, frozen. ✔
   (`results/A7-EAM-03E/A03_SIGNED/golden_a03_predicted.json`)
3. Second-defect diagnosis on the signed twin. One hypothesis, one experiment.
4. Only then: RTL for this law, new XSim bag asserting the table above.
5. Implementation. Gate: WNS >= 0, TNS = 0, DSP = 0.
6. New result directory `results/A7-EAM-03E/A03_SIGNED/`, new bit filename
   `arty_a7_eam03e_a03.bit`, bit SHA256, source SHA256, timing and utilisation
   reports, source snapshot, host scripts, closeout.
7. Silicon on Arty `210319BE776EA` COM12, STEPS=32, board integers must equal
   XSim integers.
8. Re-run Phase S under this law against the same pre-registered seed set,
   checkpoints and dataset. The §8 stability gates apply unchanged.

## Must not

- Overwrite `results/A7-EAM-03E/A01T_CLOSE/` bit
  `80F2ED9E0C1A1679F87D5362F2D953258DEF640C6C2079E41B7BFBD7BCD12F41`,
  the `a01t_eupd` bit, or any frozen 01R / 02M / LM bitstream.
- Edit the A0.1-T golden integers, or call this law A0.1-T.
- Apply S1 / S2 / S3 Wh remedies for a runaway that measurement falsified.
- Bundle the triplet law, the `e_ra` reset, or the second-defect fix into this
  patch.
- Claim BOARD_PASS. An AI cannot declare it (`AGENTS.md`), and it additionally
  requires silicon exact plus the Phase S gates under this law.
- Glue 01R / 02M / LM-06, or open A1, because a distance number improved.
- Add ILA / LiteScope / GlassBox instrumentation.
