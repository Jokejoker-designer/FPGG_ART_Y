# AUDIT — termgen (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **PYTHON_ORACLE + XSIM + OOC_SYNTH** (not silicon, not BOARD)  
**GATE:** `termgen`  
**LOOP_STATE:** first OPEN / `next` = `termgen` (matches this audit)  
**Implementer DISPATCH:** `a7-ng-rtl-scorer` / `PASS` / marker `A7NG_TERMGEN_XSIM_PASS`  
**Verify trio:** `a7-ng-xsim-verify` PASS; `a7-vivado-gate` PASS (DSP=0, WNS=+2.617 post-synth)  
**Refuse rule:** DONE_ENG allow **false** if any of four families miss exact golden, Top-8/frozen SHA drift, candidates/s throughput claimed, DSP preferred route falsified without disclosure, BOARD_PASS language, or missing XSim marker.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=termgen
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS
allow_loop_done_eng: true
severity_metrics: four families exact vs golden (n=32); DSP=0; Top-8+bucket+frozen MATCH; no candidates/s; Evidence_class=PY+XSIM+OOC; no BOARD_PASS
```

H_CANDIDATE (RTL TermGen emits Hamming + BIND + intent/context + path bit-exact vs oracle) **SUPPORTED** under **python oracle + XSim + OOC** — **EVIDENCE**.  
H_RIVAL (host-composed / partial terms / dual-side BIND cancel) **FALSIFIED** for archived law — backup OOC showed Synth 8-7129 dead `relation_cue`; final RTL/OOC has no 8-7129; `relation_match ≠ entity_match` on 29/32 vectors — **EVIDENCE**.  
**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).

---

## Declared scientific frame (graded)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | candidates/s needs full TermGen, not composer-only | **ENGINEERING_INFERENCE** (motivation; not a measured throughput) |
| UNKNOWN | four families exact + DSP=0 preferred? | **Closed** for this bag — **EVIDENCE** |
| H_CANDIDATE | TermGen bit-exact vs oracle | **SUPPORTED** — **EVIDENCE** (XSim + independent re-derive) |
| H_RIVAL | host-composed / partial / BIND cancel | **FALSIFIED** this archive — **EVIDENCE** |
| FALSIFIER | missing family; golden miss; Top-8/frozen regress | **Did not fire** |
| UNIT | 32 candidate vectors (seed `0xA7622201`), not cycles-as-queries | **EVIDENCE** |
| CONTROL | Top-8 + bucket + LM-06/01R/02M/A0.3; scorer lane/array SHA | **EVIDENCE** (live rehash) |
| METRICS | exact golden; 16 lanes; DSP; OOC WNS; no BOARD_PASS; no candidates/s | **EVIDENCE** (with MINOR caveats below) |

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| Implementer PASS `termgen` / `a7-ng-rtl-scorer` | **PASS** — DISPATCH_LOG |
| Agent vs `run_blueprint_loop.py` FALLBACK | **PASS** — `termgen` → `a7-ng-rtl-scorer` |
| `LOOP_STATE.next` / first OPEN | **PASS** — `termgen` |
| xsim-verify / vivado-gate VERIFY_ONLY | **PASS** — both logged PASS before this audit |
| Parent BOARD_PASS / silicon claim | **PASS** — explicit non-claims |
| Evidence_class mixed as board | **PASS** — labeled XSim/OOC; silicon deferred |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Required checks (this gate)

### 1. Four feature families exact vs golden — **PASS**

| Family | Term fields | Auditor check |
|--------|-------------|---------------|
| Hamming | `entity_match` | Independent re-derive 32/32 MATCH golden JSON |
| BIND | `relation_match` = `sim8(q ⊕ ROTL1(r), n)` | RTL + pkg + oracle agree; not dual-cancel |
| intent/context | `intent_match`, `context_match` | 32/32 MATCH |
| path | `path_confidence` | 32/32 MATCH |

- Golden SHA live: `7BBE92AE…CF8BE0` MATCH `SHA256.txt` / verify control.  
- Extremes: v0 entity/path=64; v1 entity=0 — **EVIDENCE**.  
- XSim: implementer `xsim_termgen.log` + verify `xsim_termgen_verify.log` both `A7NG_TERMGEN_XSIM_PASS` lanes=16 vectors=32.  
- TB checks all four families + prior + contradiction exact (`!==` golden).

### 2. DSP=0 preferred — **PASS**

- `ooc_util.rpt` DSPs = **0** — **EVIDENCE**.  
- `ooc_synth.log` `TERMGEN_OOC_DSP=0` — **EVIDENCE**.  
- LUT=12610 FF=8112 MATCH manifest/GATE/vivado-verify.

### 3. No candidates/s overclaim — **PASS**

- GATE/closeout/manifest: explicit **non-claim** of end-to-end / 1.6G candidates/s.  
- No numeric throughput asserted as measured. OBSERVATION mentions candidates/s as *motivation only* — graded ENGINEERING_INFERENCE above.

### 4. Top-8 / frozen MATCH — **PASS**

| Artifact | Live SHA256 | Status |
|----------|-------------|--------|
| `a7ng_topk.sv` | `F671FCB1…AA197636` | **MATCH** |
| `a7ng_frontier_buckets.sv` | `CE38FEC3…ACDD2C565` | **MATCH** |
| `arty_a7_lm06.bit` | `67C37DD5…4282E3BA` | **MATCH** |
| `arty_a7_eam01r.bit` | `57D1DF1B…0E9EF6CF` | **MATCH** |
| `arty_a7_eam02m.bit` | `DB3BC58A…84CFE696` | **MATCH** |
| `arty_a7_eam03e_a03.bit` | `05E478FF…142BEC09` | **MATCH** |
| primary `a7ng_termgen_lane.sv` | `DD637EDA…22DF5218` | **MATCH** |

### 5. Hierarchy / law — **PASS**

- OOC hierarchy: `g_tg[0..15].u_tg` = 16/16 — **EVIDENCE**.  
- Final OOC: no Synth 8-7129 on `relation_cue` (rival cancel archived in `ooc_synth_74368.backup.log` only).  
- Law `a7ng-termgen-v0` formulas match RTL stage1 XOR/ROTL + stage2 `64-pop`.

---

## Findings

### [MINOR] NG-01 scorer regress claimed without TERMGEN-local log

- **where:** `GATE_termgen.md` TESTS row “NG-01 scorer regress | PASS `A7NG01_XSIM_PASS`”
- **claim:** Scorer compose regress ran and passed this gate
- **evidence:** No `A7NG01_XSIM_PASS` log under `TERMGEN/`. Scorer lane/array SHAs MATCH this gate’s own `SHA256.txt` (self-control). `a7ng_pkg.sv` **was** changed (TermGen helpers). NG-01 `SHA256.txt` does not carry a comparable scorer-lane baseline line.
- **why it matters:** Reader may treat NG-01 as re-proven under the new pkg; only TermGen XSim + SHA self-list are archived here
- **fix:** Drop the row or archive a dated NG-01 regress log under `TERMGEN/`

### [MINOR] Evidence_class overstates PYTEST; GATE TG-U1 omits synth-estimate caveat

- **where:** `manifest.json` / `GATE_termgen.md` `PYTEST_BEHAVIORAL+XSIM+OOC_SYNTH`; GATE TG-U1 WNS line
- **claim:** Pytest behavioral + WNS=+2.617 as clean util row
- **evidence:** TG-P1 is `python tests/xsim/termgen_oracle.py` (not pytest). Vivado-gate correctly labels WNS as post-synth estimate; `ooc_synth.log` warns HD.CLK_SRC unset in OOC. Closeout says “OOC estimate”; implementer TG-U1 table does not.
- **why it matters:** Inflates test-framework rigor and timing maturity if skimmed without vivado-verify
- **fix:** Relabel `PYTHON_ORACLE+XSIM+OOC_SYNTH`; suffix TG-U1 WNS “post-synth estimate”

---

## Forbidden-route scan

| Route | Result |
|-------|--------|
| Golden edited to match DUT | **Not found** — oracle law generates golden; independent re-derive 0 mismatches |
| Failing test deleted / tolerance widened | **Not found** — TB uses exact `!==` |
| Seeds dropped after results | **Not found** — n=32 fixed seed `0xA7622201` |
| Host winner/answer/gradient | **N/A** — TermGen feature emit only |
| Dual-side BIND cancel shipped | **Not found** in final — archived + fixed |
| Top-8 / frontier modified | **Not found** — SHA MATCH |
| Frozen bits overwritten | **Not found** — SHA MATCH |
| candidates/s sold as measured | **Not found** |
| BOARD_PASS self-declared | **Not found** |

---

## allow_loop_done_eng

**true** — four families exact vs golden (n=32); DSP=0; Top-8 + bucket + frozen MATCH; XSim marker present (implementer + verify); no candidates/s overclaim; no BOARD_PASS. Two MINOR documentation issues do not block DONE_ENG.

**false would require:** family golden miss, Top-8/frozen SHA drift, candidates/s throughput claim, DSP>0 hidden, or BOARD_PASS language.

---

## NOT VERIFIED

- Board / silicon TermGen latency or util (OOC synth only; SILICON_DEFERRED)
- Post-route WNS/TNS (Design State = Synthesized)
- End-to-end TermGen→scorer→Top-K→frontier candidates/s (explicitly out of scope)
- Independent re-execution of full Vivado OOC this audit (numbers confirmed from archived `ooc_util.rpt` / `ooc_timing.rpt` / `ooc_synth.log` + vivado-gate)
- Whether parent will flip LOOP after this audit (orchestrator only)

---

```text
allow_loop_done_eng: true
families: hamming+BIND+intent/context+path EXACT n=32
DSP: 0
Top-8_law: MATCH F671FCB1…
frozen: MATCH LM-06/01R/02M/A0.3
candidates/s: not claimed
BOARD_PASS: not declared
LOOP_STATE: not modified
```
