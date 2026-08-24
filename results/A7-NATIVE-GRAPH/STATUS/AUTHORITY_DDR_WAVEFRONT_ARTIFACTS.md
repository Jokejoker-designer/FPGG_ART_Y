# AUTHORITY — which `ddr_wavefront_00` artifact set counts

**Decision date:** 2026-08-22
**Decided by:** `a7-ng-orchestrator` (parent)

## What happened

Two implementer-class runs wrote into `results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/` concurrently.
`PIPELINE_DISPATCH` forbids two implementers on one OPEN gate; this was an orchestrator dispatch
error (a duplicate `--dispatch` + Task after a session fork), not an agent fault.

## Authoritative set — CITE THIS

Implementer `a7-ng-memory-arch`, the only run with an implementer line in `DISPATCH_LOG.jsonl`
for `gate=ddr_wavefront_00`.

```text
testbench top : tb_a7ng_ddr_wavefront
marker        : A7NG_DDR_WAVEFRONT_XSIM_PASS
verdict       : PASS_NARROW
evidence_class: MIG_XSIM_WAVEFRONT
```

| Artifact | Role |
|----------|------|
| `PREREGISTER.md` | preregistration (before RTL edit) |
| `RESULTS.md` | 4 traffic patterns, measured |
| `CLOSEOUT.md` | verdict + LIMITs + LM06-WM-00 carry-in number |
| `FROZEN_VERIFY.md`, `SHA256.txt`, `sha256.ps1` | law-freeze + hashes |
| `ddr_wavefront_xsim.prj` | compile list |
| `xvlog_ddr_wavefront.log`, `xelab_ddr_wavefront.log` | compile/elab |
| `xsim_ddr_wavefront.log` | **raw gate log** |
| `xsim_preflight_synth_axi.log` | synthetic preflight, explicitly NOT gate evidence |
| `run_console.txt` | Vivado batch console |
| `PROVENANCE_a7-ng-memory-arch.md`, `PROVENANCE_SHA256.txt` | provenance |

RTL/TB:

```text
rtl/native_graph/memory/a7ng_cue_wave_stage.sv
rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv
tests/xsim/tb_a7ng_ddr_wavefront.sv
tests/xsim/tb_a7ng_ddr_wavefront_pre.sv
tests/xsim/run_a7ng_ddr_wavefront.tcl
```

## NON-authoritative set — DO NOT CITE as gate evidence

Concurrent run with testbench top `tb_a7ng_wavefront_mig`. It has **no implementer line** in
`DISPATCH_LOG.jsonl`, therefore it cannot close this gate.

```text
syncheck/                  wavefront_xsim.prj         xvlog_wavefront.log
xelab_wavefront.log        xsim_wavefront.log         frozen_sha_verify.txt

rtl/native_graph/memory/a7ng_cue_wavefront.sv
rtl/native_graph/memory/a7ng_wavefront_mig_top.sv
tests/xsim/tb_a7ng_wavefront_mig.sv
tests/xsim/tb_a7ng_wavefront_smoke.sv
tests/xsim/run_a7ng_wavefront_mig.tcl
```

Status: **RETAINED, UNCITED.** These files are additive (distinct module names) and did not overwrite
the authoritative set. They are kept as an independent cross-check, not deleted, but no PASS,
metric, or §14 claim may rest on them. If a number in that set contradicts `RESULTS.md`, the
contradiction must be resolved by a fresh single-implementer gate, not by choosing the nicer number.

### AMENDMENT 2026-08-22 (post-verify) — the uncited set moved and grew

While the verify trio was running, the uncited run relocated itself into
`results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/PINGPONG16/` and added its own closeout. Three PASS
markers and two closeouts now exist on disk under one gate id. Naming them explicitly so nobody
cites the wrong one:

```text
UNCITED marker   : A7NG_DDR_WAVEFRONT00_XSIM_PASS      (note the "00" — not the gate marker)
UNCITED files    : PINGPONG16/CLOSEOUT.md
                   PINGPONG16/PREREGISTER.md
                   PINGPONG16/METRIC_ROWS.txt
                   PINGPONG16/preflight_smoke.log
AUTHORITATIVE marker : A7NG_DDR_WAVEFRONT_XSIM_PASS
```

`syncheck/` was removed from the gate directory during the audit window and is **unaccounted for**.
It was uncited work product; its loss does not affect the authoritative evidence, whose hashes were
re-verified as unchanged after the mutation.

**Known cross-set divergence** (auditor MAJOR-3, xsim-verify F-2): the two runs agree exactly on all
traffic (1024 B, 64 beats, 64/16/4 bursts, 16 B per candidate, conservation, zero data mismatch) and
disagree on throughput normalisation — uncited `jobs_per_cycle_during_wave` 0.615–0.653 vs
authoritative 0.441–0.444; `wavefront_fill_cycles` 16.0–16.5 vs 35.0–35.25. The authoritative set
holds the more conservative number, which is the honest direction. The divergence is a denominator/
UNIT difference, not established physics, and stays unresolved by rule.

## Consequence

Auditors must scope `ddr_wavefront_00` verification to the authoritative set above and record the
duplicate-dispatch as a process finding against the orchestrator.
