# GATE perfmon — a7-vivado-gate VERIFY_ONLY

**Gate:** `perfmon`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** XVLOG (leaf compile) — not post-route / not silicon

## TESTS (measured)

| Test | Provenance | Verdict |
|------|------------|---------|
| xvlog `-sv` leaf `a7ng_perfmon` | Vivado 2026.1 VRFC, exit 0 | **PASS** |
| Live `a7ng_perfmon.sv` SHA == PERFMON `SHA256.txt` | file hash | **PASS** `954DF536…E92B07` |
| Share control SHA untouched | live vs expect `4413C74B…B9EB6` | **PASS** |
| Frontier / Top-K SHA vs archive | live vs PERFMON `SHA256.txt` | **PASS** |
| Frozen 01R / 02M / LM-06 / A0.3 | SHA + mtime | **PASS** (MATCH) |
| Full impl / bitstream / JTAG | — | **SILICON_DEFERRED** |

### xvlog (this session)

```text
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_perfmon.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_perfmon
XVLOG_EXIT=0
```

Log: `results/A7-NATIVE-GRAPH/PERFMON/vivado_verify_xvlog.log`  
Log SHA256: `56CA962DFF4CAA4620DD7C8FAD38F0C5EF9437606D520573EFBBB7140800B2C2`  
SHA dump: `results/A7-NATIVE-GRAPH/PERFMON/vivado_verify_sha_frozen.txt`

### Implementer XSim (pre-existing; not re-run by vivado-gate)

`xsim_perfmon.log` → `A7NG_PERFMON_XSIM_PASS` (observer-only; share control MATCH)

## Frozen bit integrity

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH (mtime 2026-08-18) |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| A0.3 | `results/A7-EAM-03E/A03_SIGNED/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |

## RTL SHA256 (live = PERFMON archive)

| File | SHA256 | Match |
|------|--------|-------|
| `rtl/native_graph/perfmon/a7ng_perfmon.sv` | `954DF536F22A01F0BF2B25809DF506725A0D34C05D47FE70D52389DDB2E92B07` | True |
| `rtl/native_graph/share/a7ng_multi_agent_share.sv` | `4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6` | True |
| `rtl/native_graph/frontier/a7ng_frontier_buckets.sv` | `CE38FEC3562343C64AB718243CE5F4B815A128524EBA2903BE20CD5ACDD2C565` | True |
| `rtl/native_graph/topk/a7ng_topk.sv` | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` | True |

## Explicit non-claims

- Not BOARD_PASS  
- Not integrate_fit / WNS / TNS post-route  
- Not OOC synth util for this VERIFY (user scope = xvlog leaf + frozen bits)  
- SILICON_DEFERRED  

## NEXT

Orchestrator may continue VERIFY trio / `--dispatch` STATUS flip for `perfmon`; `mem_schema_v1` / `reset_00` remain blocked until parent updates `LOOP_STATE`.
