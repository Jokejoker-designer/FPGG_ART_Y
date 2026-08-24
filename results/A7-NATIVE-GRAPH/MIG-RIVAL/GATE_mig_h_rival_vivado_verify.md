# GATE mig_h_rival — a7-vivado-gate VERIFY_ONLY (post-repair)

**Gate:** `mig_h_rival`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS_NARROW**  
**Date:** 2026-08-22  
**Verified_at_utc:** 2026-08-22T01:55:49Z  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** **MIG_XSIM** (archived Vivado 2026.1 xvlog/xelab `-O0`/xsim) + live SHA rehash — **not BOARD silicon**

## Gate table (measured this session)

| Check | Value | Provenance | Verdict |
|-------|------:|------------|---------|
| `mig.prj` SHA256 | `870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D` | live rehash vs `SHA256.txt` / GATE | **MATCH** (untouched) |
| `PortInterface` | **AXI** | `mig.prj` XML | **PASS** |
| native `app_*` in `mig.prj` | 0 hits | string scan | **PASS** |
| `mig.prj` mtime | 2026-08-16T14:38:30Z (9058 B) | filesystem | pre-gate; not rewritten this repair |
| Frozen LM-06 / 01R / 02M / A0.3 | MATCH all | live SHA256 rehash | **PASS** |
| `a7ng_ddr_feed_mig_top.sv` | `EE52D9C4…084ACBF1` | live = `SHA256.txt` | **MATCH** |
| `a7ng_ddr_feed_axi_bridge.sv` | `63C709FE…9F283D8` | live = `SHA256.txt` | **MATCH** |
| `run_a7ng_ddr_feed_mig.tcl` | `4ACC1DE1…DF173A8` | live = `SHA256.txt` (`-mt off -O0`) | **MATCH** |
| Archived xvlog | ERROR count = 0 | `xvlog_repair.log` | **PASS** |
| Archived xelab | `-mt off -O0` → snapshot built | `xelab_repair_O0.log` | **PASS_O0** |
| Archived xsim | `A7NG_MIG_RIVAL_XSIM_PASS` | `xsim_mig_rival.log` | **PASS** |
| MIG stall (1,1) | **0.958710** | `xsim_mig_rival.log` / `MIG_SWEEP_ROW.md` | **PRESENT** |
| MIG stall (4,8) | **0.549296** | same | **PRESENT** |
| DROP | 0 both cells | same | **PASS** |
| Synthetic CONTROL stall | 0.961544→0.475410 LAT=24 | `CONTROL_synthetic_ddr_feed.md` | **CONTROL only** — not MIG equality |
| Bitstream / JTAG / board stall | — | — | **SILICON_DEFERRED** / **WAITING_BOARD** |

## Frozen bit integrity (this session rehash)

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| A0.3 signed | `results/A7-EAM-03E/A03_SIGNED/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |

Dump: `results/A7-NATIVE-GRAPH/MIG-RIVAL/vivado_verify_sha_frozen_post_repair.txt`  
Control list: `results/A7-NATIVE-GRAPH/MIG-RIVAL/frozen_sha_control.txt`

## Bandwidth honesty

- **Confirmed:** Digilent AXI MIG XSim stall rows present (not invented).  
- **Refused:** treat synthetic 0.475410 as MIG equality; claim board PE stall / GB/s / BOARD_PASS.  
- **H_RIVAL:** implementer claims **FALSIFIED** (synthetic-only rival) — this VERIFY confirms MIG_SWEEP_ROW numbers exist in archive; silicon still ABSENT.

## Report provenance

| File | Role |
|------|------|
| `vivado/ip/mig_7series_0/mig_7series_0/mig.prj` | Digilent AXI MIG project (**untouched**) |
| `MIG-RIVAL/xvlog_repair.log` | xvlog PASS (0 ERROR) |
| `MIG-RIVAL/xelab_repair_O0.log` | xelab PASS with `-mt off -O0` |
| `MIG-RIVAL/xsim_mig_rival.log` | xsim PASS + MIG_SWEEP_ROW lines |
| `MIG-RIVAL/MIG_SWEEP_ROW.md` | tabulated stall rows |
| `MIG-RIVAL/GATE_mig_h_rival.md` | implementer REPAIR PASS_NARROW |
| `MIG-RIVAL/LIMIT.md` | MIG_XSIM ≠ BOARD |

This VERIFY did **not** re-run full MIG xsim (numbers already archived; scope = SHA + frozen + archive consistency + no invent).

## Explicit non-claims

- Not BOARD_PASS  
- Not board / silicon PE stall  
- Not HS-02  
- Not post-route WNS/TNS for MIG SoC  
- Not synthetic stall = MIG stall  
- SILICON_DEFERRED / WAITING_BOARD  

## NEXT

Auditor may continue VERIFY trio. No BOARD_PASS.
