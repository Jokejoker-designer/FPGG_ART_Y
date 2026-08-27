# XSIM graph_late_materialize_00

**GATE:** one unknown — expensive `NodeRecordV1` (16 B) fetch only after global Top-K commit  
**Law:** `a7ng-late-mat-v0`  
**Evidence_class:** XSIM  
**Verdict:** **PASS**  
**Marker:** `A7NG_LATE_MAT_XSIM_PASS` (+ tcl `A7NG_LATE_MAT_XSIM_OK`)  
**When:** 2026-08-27 12:00:16–12:00:26 (xsim v2026.1, SW Build 6511674)  
**Authority:** VERIFY_ONLY / `a7ng-xsim-verify`  
**Not BOARD.** Not UART. Not `pred=664`. Not `NATIVE_V1_MINI_AI_BOARD_PASS`.

XSim ≠ board. Observation below is simulation only.

## CHANGED this session

None. RTL/TB/tcl reviewed; no one-unknown bug that would fail the vector. No TermGen/Top-K retune. `LOOP_STATE.json` not edited. COM12 not programmed. Frozen bits not touched.

## TESTS

```text
$env:XILINXD_LICENSE_FILE = 'D:\Xilinx\licenses\vivado_basic.lic'
call C:\2026.1\Vivado\settings64.bat   # not ...\bin\settings64.bat
cd tests\xsim
vivado -mode batch -notrace -source run_a7ng_late_materialize.tcl
```

Sources (xvlog -sv):

- `rtl/native_graph/pkg/a7ng_pkg.sv`
- `rtl/native_graph/memory/a7ng_mem_schema_v1.sv`
- `rtl/native_graph/memory/a7ng_late_materialize.sv`
- `rtl/native_graph/memory/a7ng_axi_mem_model.sv`
- `tests/xsim/tb_a7ng_late_materialize.sv`

TB vector: `valid_mask=8'b0010_0101` (idx 0,2,5 valid / 5 skip) → late 3×16=**48 B**, early would be 8×16=128 B. IDs `{3,99,7,11,13,21,22,23}`; id 99 is a loser and must not generate AR.

## EXPECTED / ACTUAL

| Check | Expected | Actual |
|-------|----------|--------|
| xvlog | analyze DUT+TB, no VRFC error | INFO only (see snippet) |
| xelab | snapshot `tb_a7ng_late_materialize` | Built simulation snapshot |
| AR before `commit_i` | 0 | 0 (`early_ar_fault=0`, `ar_before_commit=0`) |
| Invalid slots never AR | n_skip=5, n_fetch=3, ar_beats=3 | 5 / 3 / 3 |
| `payload_bytes == n_fetch * 16` | 48 (late) not 128 (early) | 48 |
| Address law | `a7ng_node_byte_addr(NG_DDR_NODE_BASE, id)` | schema helper identity holds (`NG_DDR_NODE_BASE + {id[23:0],4'b0}`) |
| DSP | 0 (this module FSM+AXI) | no `*` / DSP48 in RTL; **not** post-route util (XSIM class) |
| Marker | `A7NG_LATE_MAT_XSIM_PASS` | PASS at 405 ns |
| tcl wrapper | `A7NG_LATE_MAT_XSIM_OK` | printed; vivado exit 0 |

## LOG SNIPPETS

### xvlog (`tests/xsim/xvlog.log` → copy in this dir)

```text
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../rtl/native_graph/pkg/a7ng_pkg.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../rtl/native_graph/memory/a7ng_mem_schema_v1.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../rtl/native_graph/memory/a7ng_late_materialize.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_late_materialize
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../rtl/native_graph/memory/a7ng_axi_mem_model.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_axi_mem_model
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../tests/xsim/tb_a7ng_late_materialize.sv" into library work
INFO: [VRFC 10-311] analyzing module tb_a7ng_late_materialize
```

### xelab (`tests/xsim/xelab.log`)

```text
Running: C:\2026.1\Vivado\bin\unwrapped\win64.o\xelab.exe tb_a7ng_late_materialize -s tb_a7ng_late_materialize -timescale 1ns/1ps
Compiling package work.a7ng_pkg
Compiling package work.a7ng_mem_schema_v1_pkg
Compiling module work.a7ng_late_materialize
Compiling module work.a7ng_axi_mem_model
Compiling module work.tb_a7ng_late_materialize
Built simulation snapshot tb_a7ng_late_materialize
```

### xsim (`tests/xsim/xsim.log`) Start of session Thu Aug 27 12:00:24 2026, PID 248488

```text
run -all
A7NG_LATE_MAT_XSIM_PASS
payload_bytes=48 n_fetch=3 n_skip=5 (losers not fetched)
$finish called at time : 405 ns : File ".../tests/xsim/tb_a7ng_late_materialize.sv" Line 154
exit
INFO: [Common 17-206] Exiting xsim at Thu Aug 27 12:00:26 2026...
```

Vivado batch also printed `A7NG_LATE_MAT_XSIM_OK` then exited 0.

## SHA256

| File | SHA256 |
|------|--------|
| `rtl/native_graph/memory/a7ng_late_materialize.sv` | `0BCA59BAF44577617CBB9F58E2B0675B3828A30DFF74C16CF6A7CADA63D366D7` |
| `tests/xsim/tb_a7ng_late_materialize.sv` | `4502F497E0BD20CBE4D7CBFCC009AFB86B7FB3E999E7C62BF143DF813C6F1B7D` |
| `tests/xsim/run_a7ng_late_materialize.tcl` | `4145708AA12E4056C3ECB2A0998996022DCF2C5569B9DBE0BFBF6D0B24CDCF32` |

Hashes match the pre-run parent freeze (no DUT edit).

## AUDITOR NOTES (not FAIL)

1. GATE address row is checked as **schema helper identity**, not sampled DUT `m_axi_araddr` for ids `{3,7,21}`. Counts still prove late vs early (48 B vs 128 B). Tightening ARADDR capture is a later coverage delta, not this unknown.
2. `beat_last_o` is `idx == K-1`, not “last valid fetch”. Not in GATE table; unused by this TB.
3. DSP=0 is **RTL inspection** (no multiply / DSP48). Post-route DSP count is a different evidence class.
4. `C:\2026.1\Vivado\bin\settings64.bat` does not exist; working path is `C:\2026.1\Vivado\settings64.bat`.

## Follow-on independent (same unknown)

TB replication: empty mask → 0 B / 8 skip; full K → 128 B / 0 skip. Marker still `A7NG_LATE_MAT_XSIM_PASS` (885 ns).

Host golden: `pytest tests/native_graph/test_late_materialize.py -q` → **4 passed** (RTL has no `addr_i`).

OOC synth (`vivado/tcl/ooc_a7ng_late_materialize.tcl`): **`A7NG_LATE_MAT_OOC_DSP0_PASS`**. `ooc_util.rpt`: Slice LUTs **142**, **DSPs 0**. Evidence_class=OOC, not BOARD.

## NEXT

- Treat `graph_late_materialize_00` as **XSIM_PASS + OOC DSP=0**. Do **not** promote to BOARD / existence / HS-02.
- Do not program COM12. Do not overwrite frozen bits. Do not retune TermGen / Top-K.
- Parallel: `lm06_wm_trace_00` PLAN exists; `M_peak` still MISSING — next is WMTR_REC sink, **not** the ladder.
