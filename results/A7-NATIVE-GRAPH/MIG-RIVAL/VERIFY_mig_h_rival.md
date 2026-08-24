# VERIFY_ONLY: mig_h_rival (a7-ng-xsim-verify) - post-repair

**Mode:** VERIFY_ONLY  
**Result:** **PASS**  
**Marker:** A7NG_MIG_RIVAL_XSIM_PASS - **PRESENT**  
**MIG_SWEEP_ROW:** **PRESENT** (2 cells)  
**H_RIVAL:** **FALSIFIED** (honest - Digilent MIG_XSIM rows archived; synthetic-only rival rejected)  
**Evidence class:** **MIG_XSIM** (ddr3_model + Digilent AXI) - **not BOARD**, **not HS-02**  
**Gate:** mig_h_rival (LOOP_STATE first OPEN / next)  
**Verified_at_utc:** 2026-08-22T01:56:30Z  
**Implementer DISPATCH:** 7-ng-memory-arch / PASS_NARROW / repair (ts_utc 2026-08-22T01:53:54Z)

## Scientific frame (VERIFY)

| Slot | Value |
|------|-------|
| OBSERVATION | Repair claims xelab -mt off -O0 PASS; xsim marker; MIG_SWEEP_ROW (1,1)/(4,8); H_RIVAL FALSIFIED; frozen+mig.prj MATCH |
| UNKNOWN | Independent rehash + log parse: marker/rows real? H_RIVAL claim honest? frozen/mig drift? |
| H_CANDIDATE | Archives confirm MIG_XSIM stall rows; rival closed under Digilent path |
| H_RIVAL | Invented rows; log spoof; frozen MISMATCH; H_RIVAL FALSIFIED without MIG numbers; BOARD_PASS claim |
| FALSIFIER | Marker ABSENT; sweep ABSENT/mismatch; mig.prj SHA drift / app_*; frozen MISMATCH |
| UNIT | Gate archive (xsim log + SHA controls) - not clock cycle |
| CONTROL | Prior ACCESS_VIOLATION archives; synthetic DDR-FEED; implementer GATE |
| METRICS | marker; MIG_SWEEP_ROW cells; mig.prj SHA+PortInterface; frozen SHAs |

## Checks

| Check | Result |
|-------|--------|
| xvlog_repair.log ERROR/FATAL | **PASS** - none |
| xelab_repair_O0.log | **PASS** - -mt off -O0; simulation snapshot built |
| Prior default xelab | Corroborates ACCESS_VIOLATION (CONTROL) |
| xsim_mig_rival.log (UTF-16-LE) | **PASS** - calib complete; 2x MIG_SWEEP_ROW; A7NG_MIG_RIVAL_XSIM_PASS; \ |
| MIG_SWEEP_ROW (1,1) | **PASS** - stall_frac=**0.958710** drop=0 |
| MIG_SWEEP_ROW (4,8) | **PASS** - stall_frac=**0.549296** drop=0 |
| MIG_SWEEP_ROW.md vs log | **PASS** - cells match log |
| H_RIVAL | **FALSIFIED** - Digilent MIG_XSIM rows exist; not board PE stall |
| mig.prj SHA | **MATCH** 870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D |
| PortInterface | **AXI**; app_* hits=0 |
| a7ng_ddr_feed_mig_top.sv | **MATCH** EE52D9C4C1A5E5106A7C996379A3CAE06C031D5FC62D9FA577E97308084ACBF1 |
| a7ng_ddr_feed_axi_bridge.sv | **MATCH** 63C709FE56FA39830DE086328B57BF30D75270678D25B5589CBCDA3569F283D8 |
| run_a7ng_ddr_feed_mig.tcl | **MATCH** 4ACC1DE170C4E1A30E69FBA53E4EB845F0C964E399A8E77336371B72BDF173A8; contains -mt off -O0 |
| LM-06 / 01R / 02M / A0.3 | **MATCH** (see frozen_sha_verify.txt) |
| Invented GB/s / BOARD_PASS | **REFUSED** / not present |

## Headline grades

| Claim | Grade |
|-------|-------|
| xvlog MIG+feed+ddr3_model | **EVIDENCE PASS** |
| xelab elaborates (-O0) | **EVIDENCE PASS** |
| MIG-backed stall_frac rows | **EVIDENCE** MIG_XSIM |
| H_RIVAL (synthetic only) | **FALSIFIED** |
| Synthetic 0.961544->0.475410 | **CONTROL** - not MIG equality (MIG best 0.549296) |
| Frozen bits + mig.prj | **MATCH** |
| Board silicon PE stall | **ABSENT** (LIMIT) |

## Logs / controls

- results/A7-NATIVE-GRAPH/MIG-RIVAL/xsim_mig_rival.log
- results/A7-NATIVE-GRAPH/MIG-RIVAL/xelab_repair_O0.log
- results/A7-NATIVE-GRAPH/MIG-RIVAL/xvlog_repair.log
- results/A7-NATIVE-GRAPH/MIG-RIVAL/MIG_SWEEP_ROW.md
- results/A7-NATIVE-GRAPH/MIG-RIVAL/frozen_sha_verify.txt
- Implementer: GATE_mig_h_rival.md

## Note

No RTL/golden edit. No LOOP_STATE flip (parent/orchestrator/auditor). No BOARD_PASS. No HS-02. Evidence_class remains MIG_XSIM != board.
