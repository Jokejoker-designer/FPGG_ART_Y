# Vivado-gate verify — bram_consolidate

**Mode:** VERIFY_ONLY — re-derive post-route consol metrics from archived reports + live SHA (no new place/route; no golden/frozen edit)  
**Verified_at_utc:** 2026-08-22T02:45:59+00:00  
**Device:** xc7a100tcsg324-1 (Arty A7-100T)

## Provenance

| Artifact | Path |
|----------|------|
| Util (post-route) | `results/A7-NATIVE-GRAPH/BRAM-CONSOL/consol_util.rpt` |
| Timing (post-route) | `results/A7-NATIVE-GRAPH/BRAM-CONSOL/consol_timing.rpt` L141 |
| Bit | `results/A7-NATIVE-GRAPH/BRAM-CONSOL/arty_a7_ng_bram_consol.bit` |
| Implementer control | `results/A7-NATIVE-GRAPH/BRAM-CONSOL/frozen_sha_control.txt` |
| This VERIFY rehash | `results/A7-NATIVE-GRAPH/BRAM-CONSOL/frozen_sha_verify.txt` |
| MIG (cited) | `vivado/ip/mig_7series_0/mig_7series_0/mig.prj` |

## Live SHA recompute (this VERIFY)

| Label | SHA256 | Verdict |
|-------|--------|---------|
| CONSOL bit | `83A438B5342446C9E79A537196777B1BCF2468FC57F9379EA2CB8EFE0A7D3AEF` | **MATCH** gate/SHA256.txt |
| CONTROL UA (LM06-UA + repair) | `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E` | **MATCH** |
| Frozen LM-06 | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | **MATCH** |
| Frozen 01R | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | **MATCH** |
| Frozen 02M | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | **MATCH** |
| Frozen A0.3 | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | **MATCH** |
| mig.prj (vivado IP) | `870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D` | **MATCH**; `<PortInterface>AXI</PortInterface>`; `app_*=0` |

## Gate rows (re-derived)

| Check | Measured | Provenance | Verdict |
|-------|----------|------------|---------|
| WNS ≥ 0 | **+0.586** ns | post-route `consol_timing.rpt` Design Timing Summary | **PASS** |
| TNS = 0 | **0.000** | same | **PASS** |
| WHS / THS | **+0.069 / 0.000** | same | **PASS** (hold non-neg) |
| BRAM tiles ≤ 135 | **132 / 135** (97.78%) | `consol_util.rpt` Block RAM Tile | **PASS** |
| RAMB36E1 / RAMB18 | **132 / 0** | util primaries | **PASS** |
| Prefer ≤ 130 | **132** | soft target | **NOT MET** (documented) |
| DSP = 0 | **0** | util | **PASS** |
| Slice LUT / FF | **141 / 23** | util (Slice LUTs / Slice Registers) | report |
| LUT cells (METRICS) | 153 | `METRICS.json` primitive sum ≠ Slice LUTs 141 | note only |
| Co-fit vs additive 260 | shared pool **132** ≤ 135 | ENGINEERING + measured | co-fit path OK |
| Headroom after | **3** (135−132) | arithmetic | headroom≥132 **not** claimed |
| Frozen LM/01R/02M/A0.3 + UA | MATCH | live Get-FileHash | **PASS** |
| mig.prj AXI / untouched | MATCH + AXI + app_*=0 | vivado IP SHA | **PASS** |
| BOARD_PASS | false | — | not claimed |
| HS-22 closed | false | proxy ≠ answer path | OPEN |

## Cleanup

No new Vivado batch this VERIFY. External `vivado` pid **25604** + `vivado_pid25604.str` present in repo root (not started by this VERIFY; left alone). No new `xsim.dir` from this gate.

## Verdict

**PASS_NARROW** — reconfirmed: BRAM **132**, WNS **+0.586**, TNS **0**, SHA `83A438B5…`, frozen+mig **MATCH**, Prefer≤130 **not met**; HS-22 OPEN; **no BOARD_PASS**.
