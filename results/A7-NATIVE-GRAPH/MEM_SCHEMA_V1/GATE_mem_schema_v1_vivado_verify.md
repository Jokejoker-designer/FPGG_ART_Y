# GATE mem_schema_v1 — a7-vivado-gate VERIFY_ONLY

**Gate:** `mem_schema_v1`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** XVLOG (schema package + consumers + TB) — not post-route / not silicon

## TESTS (measured)

| Test | Provenance | Verdict |
|------|------------|---------|
| xvlog `-sv` pkg + schema + 4 consumers + TB | Vivado 2026.1 VRFC, exit 0 | **PASS** |
| Live `a7ng_mem_schema_v1.sv` SHA == implementer primary | file hash | **PASS** (`F0FE426E…`) |
| Frozen 01R / 02M / LM-06 / A0.3 | SHA + mtime | **PASS** (MATCH) |
| Full impl / bitstream / JTAG | — | **SILICON_DEFERRED** |

### xvlog (this session)

Files (compile order):

1. `rtl/native_graph/pkg/a7ng_pkg.sv`
2. `rtl/native_graph/memory/a7ng_mem_schema_v1.sv`
3. `rtl/native_graph/memory/a7ng_bram_hotset.sv`
4. `rtl/native_graph/memory/a7ng_ddr_store.sv`
5. `rtl/native_graph/memory/a7ng_episode_bank.sv`
6. `rtl/native_graph/memory/a7ng_shard_fetch.sv`
7. `tests/xsim/tb_a7ng_mem_schema_v1.sv`

```text
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_pkg.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_mem_schema_v1.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_bram_hotset.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_bram_hotset
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_ddr_store.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_ddr_store
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_episode_bank.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_episode_bank
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_shard_fetch.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_shard_fetch
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../tb_a7ng_mem_schema_v1.sv" into library work
INFO: [VRFC 10-311] analyzing module tb_a7ng_mem_schema_v1
XVLOG_EXIT=0
```

Log: `results/A7-NATIVE-GRAPH/MEM_SCHEMA_V1/vivado_verify_xvlog.log`  
Log SHA256: `F64487487DF45011A6B7E164421C1CAF4900B492DBC2011FE9B4528487183FFD`  
SHA dump: `results/A7-NATIVE-GRAPH/MEM_SCHEMA_V1/vivado_verify_sha_frozen.txt`

### Implementer pytest (pre-existing; not re-run by vivado-gate)

`GATE_mem_schema_v1.md` → `A7NG_MEM_SCHEMA_V1_PYTEST_PASS` (10 passed). SV golden TCL archived; this VERIFY closes the prior `XVLOG_ABSENT` gap with measured xvlog exit 0.

## Frozen bit integrity

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| A0.3 signed | `results/A7-EAM-03E/A03_SIGNED/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |

## Primary RTL SHA256

| File | SHA256 | Match |
|------|--------|-------|
| `rtl/native_graph/memory/a7ng_mem_schema_v1.sv` | `F0FE426EB7B6968392458F7377BB86D579F768FFE66ABE2A4D8E8FD8D57DEB85` | True |

## Explicit non-claims

- Not BOARD_PASS  
- Not integrate_fit / WNS / TNS post-route  
- Not OOC synth util for this VERIFY (scope = xvlog + frozen bits)  
- Not full `run_a7ng_mem_schema_v1.tcl` xelab/xsim golden (xsim-verify lane)  
- SILICON_DEFERRED  

## NEXT

Orchestrator / remaining VERIFY trio for `mem_schema_v1`. No BOARD_PASS.
