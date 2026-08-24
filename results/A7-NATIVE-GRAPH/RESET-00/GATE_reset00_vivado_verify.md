# GATE reset_00 — a7-vivado-gate VERIFY_ONLY

**Gate:** `reset_00`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** XVLOG (reset RTL leaves) — not post-route / not silicon

## TESTS (measured)

| Test | Provenance | Verdict |
|------|------------|---------|
| xvlog `-sv` leaves (6 SV) | Vivado 2026.1 VRFC, exit 0 | **PASS** |
| Live reset RTL SHA == RESET-00 `SHA256.txt` | file hash | **PASS** |
| Share control SHA untouched | live vs expect `4413C74B…B9EB6` | **PASS** |
| Frozen 01R / 02M / LM-06 / A0.3 | SHA + mtime | **PASS** (MATCH) |
| Full impl / bitstream / JTAG | — | **SILICON_DEFERRED** |

### xvlog (this session)

```text
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_epoch_mgr.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_epoch_mgr
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_wm_authority.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_wm_authority
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_learned_gen_view.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_learned_gen_view
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_reset_ctrl.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_reset_ctrl
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_reset_verify.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_reset_verify
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_reset00_top.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_reset00_top
XVLOG_EXIT=0
```

Log: `results/A7-NATIVE-GRAPH/RESET-00/vivado_verify_xvlog.log`  
Log SHA256: `C9A246010FF60EBEDF042AF4DAEC8D3B84D53E1EEB8343C4FCE6355CC0FA6B6D`  
SHA dump: `results/A7-NATIVE-GRAPH/RESET-00/vivado_verify_sha_frozen.txt`

### Implementer XSim (pre-existing; not re-run by vivado-gate)

`xsim_reset00.log` → `A7NG_RESET00_XSIM_PASS` (logical QUERY+TRAIN; HARD rejected; frozen MATCH)

## Frozen bit integrity

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH (mtime 2026-08-18) |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| A0.3 signed | `results/A7-EAM-03E/A03_SIGNED/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |

## RTL SHA256 (live = RESET-00 archive)

| File | SHA256 | Match |
|------|--------|-------|
| `rtl/native_graph/memory/a7ng_epoch_mgr.sv` | `407FC4BE12ACDBF32DD4D29B9752CB3876B0F861E2FD8D7DEEA05563D596EDAC` | True |
| `rtl/native_graph/memory/a7ng_wm_authority.sv` | `8226B1F4760ABDA838904765411E71736DF40D8A3E032923BD22637F62EA184B` | True |
| `rtl/native_graph/memory/a7ng_learned_gen_view.sv` | `63EF9883CBE13BD20E77D8431BDE59304D67D8F2C1F8DBDA3FC1910398D4D832` | True |
| `rtl/native_graph/memory/a7ng_reset_ctrl.sv` | `CC774F32D8632F9099FB55E92FE81FD334FA514A49802CAE16915E031A17E532` | True |
| `rtl/native_graph/memory/a7ng_reset_verify.sv` | `0AA2E21934CA15DACFFDE96779857E6ADF2A231952C2299F98D460B065ABA43B` | True |
| `rtl/native_graph/memory/a7ng_reset00_top.sv` | `F34A2F9F1DCF15A1977A92A28FA3D99228F2B7C2CDB6CDD6A65B20F89BB1ECDE` | True |
| `rtl/native_graph/share/a7ng_multi_agent_share.sv` | `4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6` | True |

## Explicit non-claims

- Not BOARD_PASS  
- Not integrate_fit / WNS / TNS post-route  
- Not OOC synth util for this VERIFY (user scope = xvlog leaves + frozen bits)  
- SILICON_DEFERRED  
- Pre-existing MCP Vivado sessions (PIDs 24500/58624/65504) left untouched; xvlog batch left no `vivado_pid*.str` under RESET-00

## NEXT

Orchestrator may continue VERIFY trio / `--dispatch` STATUS flip for `reset_00`. No BOARD_PASS.
