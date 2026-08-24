# R6 freeze-manifest (DRAFT — planning only)

**Gate:** `R6-PARALLEL-BOARD-PREP-00` / `native_v1_ab_integrate_accept_00`  
**Date:** 2026-08-24T20:35:00+07:00  
**Author:** Cursor (read-only lane)  
**Status:** DRAFT — not a freeze seal; Grok R6 authoritative until CLOSEOUT  

```text
This manifest records immutable inputs at R6 start + live append-only evidence.
It does NOT stop, hash-finalize, or copy xsim_ab_mig.log while xsimk is running.
```

---

## 1. Git / worktree (FACT @ 20:35 +07)

| Field | Value |
|-------|-------|
| Repo | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm` |
| Branch | `master` |
| HEAD | `43273753ab2fe237c90101cd0d60d179b996146d` |
| Dirty paths | ~140 (`git status --porcelain` count) |
| Worktree policy | **current tree only** — no second worktree in this task |

---

## 2. Active R6 processes (FACT @ 20:35 +07)

| PID | Name | Start (local) | CPU (s) | Command line |
|-----|------|---------------|---------|--------------|
| **62640** | `vivado.exe` | 2026-08-24 16:25:45 | ~2.6 | `vivado.exe -mode batch -notrace -source tests\xsim\run_a7ng_native_v1_ab_mig.tcl` |
| **176860** | `xsim.exe` | 2026-08-24 16:26:51 | ~1.3 | `xsim.exe tb_a7ng_native_v1_ab_mig_sim -runall` |
| **177056** | `xsimk.exe` | 2026-08-24 16:26:52 | **~10222** | `xsim.dir/tb_a7ng_native_v1_ab_mig_sim/xsimk.exe -runall -simmode gui -wdb tb_a7ng_native_v1_ab_mig_sim.wdb -simrunnum 0 -socket 51925` |

**Human snapshot @ 20:02:** `xsimk` 177056, CPU ~8883 s, log ~16.5 MB — consistent with live run.

**Wall @ 20:35:** ~4.1 h since `xsimk` start.

---

## 3. Immutable R6 inputs — SHA256 (sealed at xelab 16:26)

| Artifact | SHA256 |
|----------|--------|
| `tests/xsim/run_a7ng_native_v1_ab_mig.tcl` | `600F52FA73FF969C0B97C6E8D3D83279E318668F5F34ED3F547F38245B40E2EE` |
| `tests/xsim/tb_a7ng_native_v1_ab_mig.sv` | `2154EB75A8083AF39282AD94E439892054B648045CEED576FCF4894ADCD48C1D` |
| `rtl/native_graph/integrate/a7ng_native_v1_ab_core.sv` | `7C4252978CC8071BB35693BAA3DDD55B3D8C3640B9DD1BEE18FED11BA0670F21` |
| `results/.../native_v1_ab_mig_xsim.prj` | `9A44AF652D018C49C2DD1AA1667F1F91B2665864338E8C97121A2C07A6799347` |
| `results/.../xelab_ab_mig.log` | `59BDF44FDB1A3CCAFA635E544B5D0859E7C2283D9A66D5AD055196BD8628F237` |
| `results/.../PREREGISTER.md` | `D41BEEBFD1C49C17CC7FCFFD1FF1DB9DC9C7BFD180BEAA4CE0290DCDE5246DDD` |
| `PREREGISTER_SEAL_SHA256.txt` | `6B1CD666DD9CBC7CCEA1FAE3FF15A20C67DE6D887FD0160EF188DFB26CEA11D9` |

**Note:** PREREGISTER seal file content = PREREGISTER.md hash (MATCH).

---

## 3b. Transitive source ledger (R1 @ 20:44 +07)

| Field | Value |
|-------|-------|
| Ledger | `results/A7-NATIVE-GRAPH/R6-PARALLEL-BOARD-PREP-00/R6_TRANSITIVE_SOURCE_SHA256.tsv` |
| Parsed from | `native_v1_ab_mig_xsim.prj` (non-comment source lines) |
| Source count | **134** (TSV rows = `.prj` source count — MATCH) |
| Missing files | **0** |
| Duplicate paths | **0** |
| Ledger SHA256 | `2151615A1E6A2B7D315FC56CE12DF656BC0E87E2ABD80FEEA9AC552582B42A0B` |
| Status | DRAFT — hashes sources at R1 read time; does not modify sources |

**Composition:** 29 SV (product/TB) + 104 Verilog (MIG RTL/model) + 1 `glbl.v`.

---

## 4. Live append-only evidence

| Artifact | Policy | FACT @ 20:35 |
|----------|--------|--------------|
| `results/A7-NATIVE-GRAPH/NATIVE-V1-AB-INTEGRATE-ACCEPT-00/xsim_ab_mig.log` | **APPEND_ONLY / FINAL_SHA_PENDING** | **19,264,473 B**; LastWrite **20:34:51** |
| Action | **Never** copy, truncate, re-hash-for-closeout, or lock while `xsimk` alive | — |

### Corroborated markers (file-backed; not terminal)

| Marker | Status |
|--------|--------|
| `CAPTURE_OK pack=3b392b291b190b09` | YES |
| `LNO` ×8 @ R5-identical times through 794.5e6 | YES |
| `MV0` WQ L0 tokens dest 32768…33664 | YES (≥8 prints) |
| `LM_HB` cyc=200000, 400000 | YES; `pred=0`, `bind_done=0` |
| Human @ 20:02 | WQ L0 token 6 @ 5.72 ms; token 7 pending; **no WK/ATT/SMX yet** |
| `NATIVE_V1_AB_MIG_XSIM_PASS` / `pred=664` | **NOT YET** |

---

## 5. Protected directories (do not delete / rebuild / share)

| Path | Why |
|------|-----|
| `tests/xsim/xsim.dir/` | Active compiled snapshot + `xsimk.exe` |
| `tests/xsim/xsim.dir/tb_a7ng_native_v1_ab_mig_sim/` | Kernel, wdb, reloc, mem |
| `results/A7-NATIVE-GRAPH/NATIVE-V1-AB-INTEGRATE-ACCEPT-00/` | R6 logs, prj, FAIL rounds |
| `results/.../vivado_console_mig.log` | Vivado batch journal (static after 16:26) |
| `tests/xsim/*.wdb` (if present) | Wave DB tied to live xsim |

**Runner Tcl side effect:** `run_a7ng_native_v1_ab_mig.tcl` line 7 deletes `xsim.dir` **before** build — must **not** re-run while R6 active.

---

## 6. Archived FAIL rounds (immutable; do not overwrite)

| Round | Artifact |
|-------|----------|
| R1 | `FAIL_R1_XELAB.md`, `xsim_ab_mig_r1_*` |
| R2 | `FAIL_R2_WMEM_STALL.md`, `xsim_ab_mig_r2_wmem_stall.log` |
| R3 | `FAIL_R3_CAPTURE.md`, `xsim_ab_mig_r3_capture.log` |
| R4 | `FAIL_R4_GRANT_HOLE.md`, `xsim_ab_mig_r4_capture.log` |
| R5 | `FAIL_R5_LM_SLOW.md`, `xsim_ab_mig_r5_lm_slow.log` SHA `1C4FA16A…BD69` |

---

## 7. Closeout freeze actions (future — Grok only)

When R6 terminal and `xsimk` exited:

1. Record final `xsim_ab_mig.log` SHA256 once (no mid-run hash).  
2. Append terminal line refs to CLOSEOUT.  
3. Do not retro-edit TB/RTL/prj hashes above without new round id.  

Cursor **must not** perform steps 1–3 while R6 runs.
