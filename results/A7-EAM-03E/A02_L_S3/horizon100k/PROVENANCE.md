# Provenance verification — 100k horizon run, triplet + S3 `>>3`

Answers the checks demanded by `Executive Summary.md` §9 and
`NATIVE_AI_V1_ROADMAP.md` §23 for this run.

## Two concurrent runs existed. This is the record of which one is archived.

| | run A (not archived) | run B (archived here) |
|---|---|---|
| launched by | not this agent | this agent |
| started | 2026-08-20 15:39:35Z | 2026-08-20 16:32:45Z |
| ended | 17:01:13Z | 17:49:08Z |
| flag used | `--long-horizon` | `--max-updates 100000` |
| output dir | `results/A7-EAM-03E/A02_L_S3/horizon100k` | same directory |
| elapsed | 4,897,513 ms | 4,582,727 ms |

Both wrote to the same path, so `triplet_twin_sweep.json` was written twice and
the later write won. The archived file carries
`ts = 2026-08-20T17:49:08.111857+00:00`, which matches run B's end time, so **the
archived artifact is run B**. Run A's output was overwritten and is recoverable
only from its console transcript.

Sharing one output directory between two runs is a provenance hazard and should
not recur. Future concurrent runs must use distinct `--out` paths.

## The two runs agree exactly

Run A's console transcript and run B's archived JSON contain the same eleven
rows, digit for digit, including `M_L1 = -13.316` and `M_cos = -0.30133` on
`0x7A9BE636` and `M_L1 = -9.637`, rank 3 on `0xEC62BC77`.

That is a useful accident: two independently launched processes, different
command-line flags, same seeds and dataset, identical output. It confirms the
sweep is deterministic and that neither run picked up hidden state. It also
resolves an earlier concern of mine — I flagged two rows of the Executive
Summary table as unverifiable because my transcript had not yet reached them.
They were accurate; the document had simply read a run that was further along.

## Parameter check

Archived JSON records:

```
wh_decay_sh        = 3
attribution        = broadcast
margins_run        = [4096]
wh_clamp           = null
checkpoints        = 0,32,64,128,256,512,1000,2000,5000,10000,20000,50000,100000
runs               = 11
decay_preregistered = [6,5,4,3]
```

No unexpected parameter. `wh_clamp` is null, so decay and clamp were not
silently combined — the tool refuses that combination anyway. The margin is the
contract's `E3_MARG` value and was not tuned. Checkpoints extend the original
list by appending only, so every previously reported number stays comparable.

## Twin oracle state

`golden_check()` exact and `tests/golden/test_eam03e_twin.py` 10/10 before and
after the run. `E3_MARG` is 4096 at rest. The signed `h` rule used here is the
one whose RTL is XSim- and silicon-exact (`bit 05E478FF…`).

## Tool provenance note

`tools/a7eam03e_a02l_twin.py` currently contains **both** a `--max-updates` flag
(line 251, written by this agent) and a `--long-horizon` flag (lines 252, 295,
not written by this agent). The peer observer is declared read-only in
`Executive Summary.md` §9 and `NATIVE_AI_V1_ROADMAP.md` §23, so the presence of
externally authored flags in the experiment harness is a boundary violation and
is recorded here rather than quietly removed. Both flags were inspected; they do
not interact, and run B's checkpoint list is the expected one.

The same applies to `--diff-gate` in `tools/a7eam03e_stability.py`, documented in
`results/A7-EAM-03E/A03_UNGATED/closeout.md`.

## Verdict on the run

Valid. Archived artifact is run B, parameters are as pre-registered, the oracle
was intact, and an independent concurrent execution reproduced every number.
