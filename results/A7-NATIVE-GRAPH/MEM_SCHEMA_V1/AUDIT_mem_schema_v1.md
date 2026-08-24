# AUDIT — mem_schema_v1 (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **PYTEST** (Node/Edge/Episode serdes goldens) + **XSIM** (SV size/addr golden) — not BOARD, not silicon  
**GATE:** `mem_schema_v1` / law `a7ng-mem-schema-v1`  
**LOOP_STATE:** first OPEN / `next` = `mem_schema_v1` (matches this audit)  
**Implementer DISPATCH:** `a7-ng-memory-arch` / `PASS` / marker `A7NG_MEM_SCHEMA_V1_PYTEST_PASS` / primary `F0FE426E…`  
**Parallel VERIFY:** `a7-vivado-gate` PASS (XVLOG exit 0 + frozen MATCH); `a7-ng-xsim-verify` log `A7NG_MEM_SCHEMA_V1_SV_GOLDEN_PASS` / `A7NG_MEM_SCHEMA_V1_SV_OK`  
**Refuse rule:** DONE_ENG allow **false** if residual 8 B Node/hotset stride remains, dual conflicting RecordV1 sizes, golden edit-to-pass, or frozen LM/01R/02M/A0.3 SHA drift.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=mem_schema_v1
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS
allow_loop_done_eng: true
severity_metrics: Node16/Edge32/Episode32 LE v1 pinned; pytest 10/10 re-run; SV golden PASS; no residual <<3/8B hotset stride; frozen LM-06/01R/02M/A0.3 MATCH; Evidence_class=PYTEST+XSIM
```

Single authoritative compact RecordV1 layout is file-backed under `a7ng_mem_schema_v1.{sv,h}` + `python/native_graph/mem_schema_v1.py`.  
**Do not declare BOARD_PASS.** Orchestrator may flip LOOP — this auditor does **not**.

---

## Declared checks (graded)

| Check | Claim | Auditor grade |
|-------|-------|---------------|
| One Node/Edge/Episode V1 | sizes 16/32/32, version=1, LE | **EVIDENCE** (pkg + header + Python + pytest + XSim) |
| Golden serdes | round-trip hex vectors | **EVIDENCE** (re-derived bit-identical) |
| No residual magic 8 B hotset stride | `<<3` removed; Node miss uses `<<4` | **EVIDENCE** (RTL + TB + grep) |
| Frozen bits untouched | 01R / 02M / LM-06 / A0.3 | **EVIDENCE** (live SHA MATCH) |
| Consumers import helpers | GATE: “consumers use `a7ng_*_byte_addr`” | **PARTIAL** — see MINOR-1 |
| Dual size literals in `a7ng_pkg` | “aliases schema” | **ENGINEERING_INFERENCE** risk — see MINOR-2 |

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| Implementer PASS `mem_schema_v1` / `a7-ng-memory-arch` | **PASS** — DISPATCH_LOG |
| Agent vs `run_blueprint_loop.py` FALLBACK | **PASS** — `mem_schema_v1` → `a7-ng-memory-arch` |
| `LOOP_STATE.next` / first OPEN | **PASS** — `mem_schema_v1` |
| Parent claimed BOARD_PASS | **PASS** — none |
| Evidence_class mixed with board/silicon | **PASS** — PYTEST / XSIM / XVLOG only |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Headline numbers (auditor re-derived)

| Item | Claim / archive | Auditor |
|------|-----------------|---------|
| `a7ng_mem_schema_v1.sv` SHA256 | `F0FE426EB7B6968392458F7377BB86D579F768FFE66ABE2A4D8E8FD8D57DEB85` | **MATCH** (re-hash) |
| pytest | 10 passed | **MATCH** (re-run 10 passed / 0.04s) |
| `GOLDEN_NODE_HEX` | `070000000200110001e0c0a700010301` | **MATCH** |
| `GOLDEN_EDGE_HEX` | `100000002000000005000000fdff0200040001002a0000000100000000000000` | **MATCH** |
| `GOLDEN_EPISODE_HEX` | `07000000000100000002000000030000000400000005000000060000c0000100` | **MATCH** |
| addr id=7 | node `0x01000070` / edge `0x020000E0` / episode `0x040000E0` | **MATCH** (`<<4` / `<<5`) |
| XSim marker | `A7NG_MEM_SCHEMA_V1_SV_GOLDEN_PASS` | **MATCH** (`xsim_mem_schema_v1_verify.log`) |
| xvlog | exit 0 | **MATCH** (vivado VERIFY) |

Sizes pinned: `NODE_REC_BYTES=16`, `EDGE_REC_BYTES=32`, `EPISODE_REC_BYTES=32`, `SCHEMA_VERSION=1`.

---

## Stride / hotset (8 B residual)

| Location | Was (pre-gate) | Now | Grade |
|----------|----------------|-----|-------|
| `a7ng_bram_hotset.sv` ddr_addr | magic `<<3` (8 B) | `{…, 4'b0000}` (16 B NodeRecordV1) | **EVIDENCE** — 8 B **stride** gone |
| `tb_a7ng_hotset.sv` | expected 8 B | expects 16 B | **EVIDENCE** |
| `DATA_W=64` hotset BRAM width | feature-line cache | **not** DDR record stride | **EVIDENCE** (documented; not a schema size) |

Repo grep under `rtl/native_graph` / `tests` for residual Node `<<3` / `REC_BYTES=8` hotset stride: **none**.

---

## Frozen artifact law

Live re-hash vs reset_00 control EXPECT (all **MATCH**):

| Lane | Path | SHA256 |
|------|------|--------|
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` |
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` |

No BOARD_PASS language in gate artifacts.

---

## Findings

```
[MINOR] Hotset still uses inline Node <<4, not a7ng_node_byte_addr
  where     : rtl/native_graph/memory/a7ng_bram_hotset.sv:76
  claim      : GATE_mem_schema_v1.md — “consumers use a7ng_*_byte_addr / REC_BYTES”
  evidence   : ddr_addr_o <= {5'b0, node_id_i[22:0], 4'b0000}; helper used by shard_fetch / episode_bank / ddr_store / ng03_top
  why it matters: correct 16 B math today, but a second literal stride can drift from the package helper
  fix        : call a7ng_node_byte_addr(0, node_id_i) (or documented relative-offset helper) on a follow-up patch; do not re-open this DONE_ENG
```

```
[MINOR] a7ng_pkg duplicates REC_BYTES literals instead of importing schema package
  where     : rtl/native_graph/pkg/a7ng_pkg.sv:19-21
  claim      : “Strides alias mem_schema_v1 — no magic forks”
  evidence   : independent `localparam … = 16/32/32` twin of A7NG_*_REC_BYTES; pytest only regex-checks NG_NODE_REC_BYTES==16
  why it matters: future edit of one side without the other re-creates dual authority
  fix        : import a7ng_mem_schema_v1_pkg and assign NG_* from A7NG_* (or generate both); optional follow-up
```

---

## Forbidden-route scan

| Route | Result |
|-------|--------|
| Golden hex edited to match impl | **Not found** — auditor re-derived from Python structs |
| Tests deleted / weakened | **Not found** — 10 tests present; checksum + bad-version reject covered |
| Host computes answer/winner | **N/A** — schema/serdes only |
| Frozen bit overwrite | **Not found** — SHA MATCH |
| Evidence called “board/silicon” | **Not found** |
| Residual 8 B Node/hotset stride | **Not found** |

---

## allow_loop_done_eng

**true** — pytest goldens + XSim SV golden + primary SHA + frozen MATCH + no residual 8 B hotset stride. MINOR consumer-helper / pkg-duplication do not falsify the freeze.

---

## NOT VERIFIED

- Full post-route / bitstream / JTAG for any NG schema integration (**SILICON_DEFERRED** — out of scope).  
- C `_Static_assert` compile of `a7ng_mem_schema_v1.h` on a C toolchain (header text-checked by pytest only).  
- Whether `BRAM_WORKING_MEMORY_SPEC.md` §6.1 `adjacency_ptr` example will be updated before BRAM-WM-00 (schema doc already excludes it from compact V1 — **documented**, not measured as a second RTL layout).  
- Index / prior 16 B companion strides (explicitly non-RecordV1 per STRIDE_AUDIT).
