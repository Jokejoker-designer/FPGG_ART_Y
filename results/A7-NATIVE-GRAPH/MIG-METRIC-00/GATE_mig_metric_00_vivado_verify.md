# GATE mig_metric_00 — a7-vivado-gate VERIFY_ONLY

**Gate:** `mig_metric_00`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS**  
**Verified_at_utc:** `2026-08-22T04:02:51Z`  
**Evidence class:** **MIG_XSIM** (archived Vivado 2026.1 xvlog/xelab `-mt off -O0`/xsim) + live SHA rehash — **not BOARD**

## Gate table (measured this session)

| Check | Value | Provenance | Verdict |
|-------|------:|------------|---------|
| `mig.prj` SHA256 | `870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D` | live rehash vs `SHA256.txt` / `mig_prj_sha256.txt` | **MATCH** (untouched) |
| `PortInterface` | **AXI** | `mig.prj` XML | **PASS** |
| native `app_*` in `mig.prj` | 0 hits | string scan | **PASS** |
| `mig.prj` mtime / size | 2026-08-16T14:38:30Z / 9058 B | filesystem | pre-gate; not rewritten |
| Frozen LM-06 / 01R / 02M / A0.3 | MATCH all | live SHA256 rehash | **PASS** |
| `a7ng_ddr_feed_axi_bridge.sv` | `D07A9742BD61E6D1DAC34F7017B6B817697A2C98CD4A825EFA54F77275F48454` | live = `SHA256.txt` | **MATCH** |
| `a7ng_ddr_feed_mig_top.sv` | `F91EA825479B68F8F9834B676149F71438B30A382204DBF69D00F8FF7D7F7265` | live = `SHA256.txt` | **MATCH** |
| `a7ng_ddr_feed_pp.sv` | `1FB685BDC712B1F854F639B8715C207F9D86A838F56E72A95658854C1D274637` | live = `SHA256.txt` | **MATCH** |
| `tb_a7ng_ddr_feed_mig.sv` | `7097EDDB68B2B176DCF3341C7480DD34D183EEF97A443AB17DC415DF7DEDE1A1` | live = `SHA256.txt` | **MATCH** |
| Archived xvlog | ERROR count = 0 | `xvlog_mig_metric.log` | **PASS** |
| Archived xelab | `-mt off -O0` → snapshot built | `xelab_mig_metric.log` | **PASS_O0** |
| Archived xsim | `A7NG_MIG_METRIC_XSIM_PASS` | `xsim_mig_metric.log` | **PASS** |
| Cell (1,1) deltas | bytes=1024 bursts=64 beats=64 | `xsim_mig_metric.log` / `MIG_METRIC_ROW.md` | **PASS** |
| Cell (4,8) deltas | bytes=1024 bursts=16 beats=64 | same | **PASS** (not cumulative 2048/80) |
| Integrity both cells | data/rresp/rlast/pe_mm=0; records 64/64/64 | `MIG_INTEGRITY` lines | **PASS** |
| COM12 / JTAG program this VERIFY | — | refused | **NOT_RUN** |
| `mig_board` started this VERIFY | — | refused | **NOT_STARTED** |

## Explicit non-claims

- Not BOARD_PASS  
- Not board / silicon PE stall / GB/s  
- Not HS-02  
- Not `mig_board` reopen  
- MIG_XSIM ≠ BOARD  

## Report provenance

| File | Role |
|------|------|
| `vivado/ip/mig_7series_0/mig_7series_0/mig.prj` | Digilent AXI MIG (**untouched**) |
| `MIG-METRIC-00/xvlog_mig_metric.log` | xvlog PASS |
| `MIG-METRIC-00/xelab_mig_metric.log` | xelab PASS `-mt off -O0` |
| `MIG-METRIC-00/xsim_mig_metric.log` | xsim PASS + deltas + integrity |
| `MIG-METRIC-00/MIG_METRIC_ROW.md` | tabulated per-run metrics |
| `MIG-METRIC-00/CLOSEOUT.md` | implementer PASS |

This VERIFY did **not** re-run full MIG xsim (numbers already archived; scope = SHA + Digilent MIG provenance + archive consistency). Did **not** program COM12.

## NEXT

Auditor / parent closeout. Session override: **STOP** — do not auto-dispatch `mig_board` from this VERIFY.
