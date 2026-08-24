# PROVENANCE — `a7-ng-memory-arch` implementer run for `ddr_wavefront_00`

Written because this archive directory was observed being written **concurrently by another agent
run** during this session. Everything below is authored by `a7-ng-memory-arch` for gate
`ddr_wavefront_00`; anything not listed here is **not mine** and my closeout does not rely on it.

## My artifact set (authoritative for my PASS_NARROW)

| File | Role |
|------|------|
| `PREREGISTER.md` | preregistration, written before any RTL edit or measurement |
| `RESULTS.md` | measured tables, 4 traffic patterns |
| `CLOSEOUT.md` | verdict PASS_NARROW, LIMITs, LM06-WM-00 working-set number |
| `FROZEN_VERIFY.md` | law-freeze SHA comparison vs MIG-METRIC-00 |
| `SHA256.txt` / `sha256.ps1` | hash list + regeneration script |
| `ddr_wavefront_xsim.prj` | generated compile list |
| `xvlog_ddr_wavefront.log` | xvlog |
| `xelab_ddr_wavefront.log` | xelab (`-mt off -O0`) |
| `xsim_ddr_wavefront.log` | **raw gate log** — `A7NG_DDR_WAVEFRONT_XSIM_PASS` |
| `xsim_preflight_synth_axi.log` | synthetic preflight, explicitly NOT gate evidence |
| `run_console.txt` | Vivado batch console for my run |

My RTL/TB (SHA in `SHA256.txt`):

```text
rtl/native_graph/memory/a7ng_cue_wave_stage.sv      5D3D0EAE…5A10
rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv   E6DDD67A…B2E4
tests/xsim/tb_a7ng_ddr_wavefront.sv                 6EE8E884…5C28
tests/xsim/tb_a7ng_ddr_wavefront_pre.sv             6177C843…3A50
tests/xsim/run_a7ng_ddr_wavefront.tcl               2325B065…EDFE
```

My testbench top is **`tb_a7ng_ddr_wavefront`** and my marker is
**`A7NG_DDR_WAVEFRONT_XSIM_PASS`**.

## Files in this directory that are NOT mine

Observed being written by a concurrent run between 11:37 and 11:42 with a **different** testbench
top, `tb_a7ng_wavefront_mig`:

```text
syncheck/                 wavefront_xsim.prj        xvlog_wavefront.log
xelab_wavefront.log       xsim_wavefront.log        frozen_sha_verify.txt
```

I did not create, read as evidence, modify, or delete any of them. If a later file in this directory
contradicts `RESULTS.md` / `CLOSEOUT.md`, it came from that other run, not from this one.

## Flag for the parent / auditor

Two different implementer-class testbenches were writing into one gate archive at the same time.
Per `PIPELINE_DISPATCH`, the parent may launch parallel **VERIFY** tasks, but must not run two
implementers on one OPEN gate. The parent should decide which artifact set is authoritative before
the auditor reads this directory. I did not police it further and I did not touch the other run's
files.
