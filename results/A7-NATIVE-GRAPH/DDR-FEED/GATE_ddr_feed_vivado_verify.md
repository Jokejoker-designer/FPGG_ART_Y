# GATE ddr_feed — a7-vivado-gate VERIFY_ONLY

**Gate:** `ddr_feed`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** XVLOG (ddr_feed RTL leaves) — not post-route / not silicon / **not 100 MHz SoC**

## TESTS (measured)

| Test | Provenance | Verdict |
|------|------------|---------|
| xvlog `-sv` leaves (schema pkg + 3 ddr_feed SV) | Vivado 2026.1 VRFC, exit 0 | **PASS** |
| Live ddr_feed RTL SHA == DDR-FEED `SHA256.txt` | file hash | **PASS** |
| WM-00 / mem_schema control SHA untouched | live vs expect | **PASS** |
| Frozen 01R / 02M / LM-06 / A0.3 | SHA + mtime | **PASS** (MATCH) |
| Full impl / bitstream / JTAG / 100 MHz WNS | — | **SILICON_DEFERRED** / **NOT_CLAIMED** |

### xvlog (this session)

```text
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_mem_schema_v1.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_ddr_feed_lat_ddr.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_ddr_feed_lat_ddr
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_ddr_feed_pp.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_ddr_feed_pp
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../a7ng_ddr_feed_top.sv" into library work
INFO: [VRFC 10-311] analyzing module a7ng_ddr_feed_top
XVLOG_EXIT=0
```

Log: `results/A7-NATIVE-GRAPH/DDR-FEED/vivado_verify_xvlog.log`  
Log SHA256: `E113ED3D768CDFF11557C39ED5560805115820204B8AFF39B542D1653989801A`  
SHA dump: `results/A7-NATIVE-GRAPH/DDR-FEED/vivado_verify_sha_frozen.txt`

### Implementer XSim (pre-existing; not re-run by vivado-gate)

`xsim_ddr_feed.log` → `A7NG_DDR_FEED_XSIM_PASS` (engineering/XSIM; DROP=0; no 100 MHz claim)

## Frozen bit integrity

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH (mtime 2026-08-18) |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| A0.3 signed | `results/A7-EAM-03E/A03_SIGNED/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |

## RTL SHA256 (live = DDR-FEED archive)

| File | SHA256 | Match |
|------|--------|-------|
| `rtl/native_graph/memory/a7ng_ddr_feed_top.sv` | `EE57D1BC1E216EEE5B9FFF6D42EA7B87254A5F57EDE7E0F65D298E35F2125D60` | True |
| `rtl/native_graph/memory/a7ng_ddr_feed_pp.sv` | `163FCA2D34884298B863A64DFAE96DEC8B63C3D5F1C7AF7E9052A2D620EDE217` | True |
| `rtl/native_graph/memory/a7ng_ddr_feed_lat_ddr.sv` | `05FAD7F41BA4B5B1146D4266FD0201273F73F8DFC1EDD1A12F0F4DD39DEA41A0` | True |
| `rtl/native_graph/memory/a7ng_wm00_top.sv` | `1F7F39506DF0D0F21F0F7E60B658047AE38ACB11E5B0924E005413B2B8B8AD98` | True |
| `rtl/native_graph/memory/a7ng_mem_schema_v1.sv` | `F0FE426EB7B6968392458F7377BB86D579F768FFE66ABE2A4D8E8FD8D57DEB85` | True |

## Explicit non-claims

- Not BOARD_PASS  
- Not 100 MHz SoC / WM timing closure (WM-00 OOC WNS=−290.499 remains OPEN / not re-measured here)  
- Not MIG silicon bandwidth (H_RIVAL OPEN)  
- Not integrate_fit / post-route WNS / TNS for ddr_feed  
- Not OOC synth util for this VERIFY (user scope = xvlog leaves + frozen bits)  
- SILICON_DEFERRED  

## NEXT

Orchestrator may continue VERIFY trio / `--dispatch` STATUS flip for `ddr_feed`. No BOARD_PASS.
