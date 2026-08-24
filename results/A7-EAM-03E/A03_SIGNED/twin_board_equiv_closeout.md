# Twin ↔ board equivalence over 5000 learning transactions

Board test run 2026-08-21 after the board was reconnected. Law
`eam03e-a03-signed-h-v1`, bit `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09`.

## Why this test and not another golden check

Every conclusion in this program about 10,000 and 100,000 update horizons is
**reference model** evidence produced by `python/eam/eam03e_twin.py`. That twin
had only ever been validated against a **32-step** ladder. If it drifted from
silicon after a few hundred updates, ten closeouts would rest on nothing.

So the useful board test was not a fourth run of the same 7-integer golden. It
was: does the twin still equal silicon after thousands of learning steps?

## Result: exact, 5000/5000

`A7EAM03EA03_TWIN_BOARD_EQUIV_PASS`

5000 PAIR transactions with `learn=1`, deterministic sequence from the benchmark
train split, `d1` **and** `dH` compared after **every single transaction**, not
sampled. Zero divergences. Elapsed 240 s over UART at 115200.

Progress trace, board values, every 250 transactions:

```
   250  d1=6279     1500  d1=251     3000  d1=60
   500  d1=908      1750  d1=61      3250  d1=399
   750  d1=366      2000  d1=169     3500  d1=288
  1000  d1=239      2250  d1=166     4000  d1=205
  1250  d1=62       2500  d1=79      5000  d1=70
```

The twin matched all of it, including the non-monotone recovery around
transaction 3250.

## Two findings this produced beyond the pass

**1. The scale crush is real on silicon.** The distance falls from 14246 at the
aligned prime to the tens within about 1250 transactions and then oscillates
between roughly 28 and 400. That is the same collapse-then-partial-recovery
shape measured on the twin at
`results/A7-EAM-03E/A02_L_S3/horizon100k/`, and it is now **board evidence**, not
reference-model evidence. The diagnosis that this architecture crushes its own
state scale during training is confirmed on the chip.

**2. `e_ra` alignment is a required protocol step, and it is now quantified.**
The first comparison always diverges:

```
prime 0:  board d1=14933   twin d1=14668   not aligned
prime 1:  board d1=14246   twin d1=14246   aligned
```

`e_ra` has no reset in the RTL and `S_SEED` never writes it, so a board that has
run anything before carries a stale embedding read address while a freshly
constructed twin starts at zero. The address is fully determined by the last byte
processed, so exactly one forward on each side aligns them, and `learn=0` during
priming means no weight can move while that happens.

The harness now primes twice with learning off, requires the second prime to
match, and refuses to compare if it does not. Any future twin↔board comparison
must do the same. This is the same latent defect already recorded in
`docs/contracts/A7-EAM-03E-A03.md`; what is new is that it is now a measured
protocol requirement rather than a footnote.

## What this licenses, and what it does not

Licensed: the twin may be used as the arithmetic authority for long-horizon
sweeps of this law. That was previously an assumption resting on 32 integers; it
now rests on 5000 consecutive matches with learning enabled.

Not licensed: nothing about representation quality, and nothing about the laws
that exist only on the twin. The triplet hinge, S1, S2, S3, byte attribution, L2
and scale-targeted decay have **no RTL**. Their sweeps remain reference-model
evidence. The twin being exact for A0.3 makes those sweeps trustworthy as
simulations of *what A0.3-derived laws would do*; it does not turn them into
silicon results.

## Board state

| item | value |
|------|-------|
| JTAG | `localhost:3121/xilinx_tcf/Digilent/210319BE776EA` |
| device | `xc7a100t`, IDCODE `00010011011000110001000010010011` |
| UART | COM12 @ 115200 |
| programmed bit | `arty_a7_eam03e_a03.bit`, SHA `05E478FF…`, startup HIGH |

The 7-integer A0.3 golden was also re-run after reconnection and is still exact
on all seven values, so the reconnect did not perturb anything.

Note for future sessions: after re-plugging, the FT2232 enumerates as `USB Serial
Converter A/B` before Windows binds the virtual COM port. JTAG works immediately;
UART needs the COM binding to complete, which took a few minutes here. Absence of
COM12 with the converters present means "wait", not "broken".

## Artifacts

| file | content |
|------|---------|
| `twin_board_equiv.json` | full record, first-divergence field is null |
| `board_ladder_a03.json` | re-run of the 7-integer golden after reconnect |
| `tools/a7eam03e_a03_twin_board_equiv.py` | the harness |

No gradient, weight, cue, address or winner crossed the link in either
direction. Host sent UTF-8 bytes, a slot index, a label bit, a seed and a mode
flag, and read back `d1`, `dH`, `cue` and the mode bits.
