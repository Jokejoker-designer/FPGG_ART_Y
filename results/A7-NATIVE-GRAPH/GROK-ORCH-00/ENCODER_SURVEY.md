MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).

# Encoder survey — A7-EAM-03E for Native AI V1 close

**Date:** 2026-08-29  
**Authority token:** `READ_ONLY_AUDIT` / `REPORT_ONLY`  
**Lane:** Grok orch (`research/native-ai-v1-grok-orch-00`)  
**This file is not silicon evidence. AI does not declare `BOARD_PASS`.**

**Read first (this session):**

- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\MUST_READ_UNBLOCK_H5.md`
- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-03E\MUST_READ_UNBLOCK_H5.md`

**Evidence roots (do not mix trees):**

| Tree | Path | Role |
|------|------|------|
| Main authority / 03E archive | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm` | encoder closeouts |
| This orch worktree | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` | survey / host Python only |
| Cursor board (not this lane) | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board` | JTAG / COM12 existence |

**Stale first-line vs later evidence (do not collapse):**

`MUST_READ_UNBLOCK_H5.md` still requires the first session line above and still names **ungated DIFF twin** as the next *causal* experiment. That instruction was **executed**. Twin pre-check **NO-GO**. Human-approved 2026-08-22 **REJECT**s ungated DIFF as the remaining remedy. See §2.

No encoder RTL was edited for this survey. Frozen 01R / 02M / A0.3 / LM-06 bits were not touched.

---

## 1. Frozen vs open (encoder)

### 1.1 Frozen (do not overwrite / do not rebuild as “the same bit”)

| Artifact | Status (as archived) | Evidence |
|----------|----------------------|----------|
| **A7-EAM-01R** | **FROZEN / BOARD_PASS** (human archive). Sparse exact/near retrieval. `HIT_MAX=8`, `MARGIN_MIN=4`. | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\docs\contracts\A7-EAM-02M.md` (depends on 01R); `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-01R\bit_01r.sha256` = `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` |
| **A7-EAM-02M** | **FROZEN / BOARD_PASS**. Multi-cue exact bind + teacher-off recall of **bound** cues. **Not semantic.** | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-02M\CLOSEOUT.md`; SHA `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` (`arty_a7_eam02m.sha256`) |
| **A7-LM-00 … A7-LM-06** | **FROZEN / BOARD_PASS** (program authority). LM-06 `P_LM = 802816`. Scale/oracle claim, not 8-class retrieval. | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-03E\final.md` §5; `AGENTS.md` |
| **A0.1-T arithmetic + timing gates** | XSim exact + WNS **+0.637** + TNS **0** + DSP **0** + silicon exact vs golden `3930/5362 → 1093/2012 → 3930 → 1574/451`. Law `eam03e-a0-signsgd-v1` **unchanged**. **AI does not stamp BOARD_PASS.** Human declaration reserved. | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-03E\A01T_CLOSE\closeout.md`; bit SHA `80F2ED9E0C1A1679F87D5362F2D953258DEF640C6C2079E41B7BFBD7BCD12F41` |
| **A0.3 signed-h silicon arithmetic** | Law `eam03e-a03-signed-h-v1`. XSim + silicon exact `739/581 → 164/1957 → 742 → 137/1370`. Twin ↔ board **5000/5000** PAIR `learn=1` (`d1` and `dH` every step). **Arithmetic OK; geometry not established.** | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-03E\A03_SIGNED\board_ladder_a03.json`; `twin_board_equiv_closeout.md`; bit SHA `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` |
| **A0.1-T / A0.3 goldens** | Do not rewrite A0.1-T bag or A0.3 predicted bag to match a new law. | `MUST_READ_UNBLOCK_H5.md` Cấm |
| **S2 Wh-clamp** | **FALSIFIED** as medicine. Tightening clamp made rank/uniq_d1 worse. **Do not re-run as a remedy.** | `MUST_READ_UNBLOCK_H5.md`; `A03_S/closeout.md` |
| **A1 glue / Kidi / GlassBox / NATIVE-V1 mini-AI** | **CLOSED** until encoder freeze gates pass. | `final.md` §5; `NATIVE_AI_V1_ROADMAP.md` §1, §10, §13–15 |

**Note on stale contract text:** `docs/contracts/A7-EAM-03E-A03.md` header still says “No RTL exists yet.” Silicon artifacts in `results/A7-EAM-03E/A03_SIGNED/` supersede that sentence for **existence of A0.3 RTL/bit**. The contract still correctly keeps **A0.2-L, A1, Kidi, NATIVE-V1 CLOSED**.

### 1.2 Open / parked (encoder science)

| Item | Status | Evidence |
|------|--------|----------|
| Encoder **discriminative geometry** | **OPEN / FAIL** on contract A02 hard stops at 100k | Standing candidate still `worst M_L1 = −13.316`, `worst M_cos = −0.301` |
| Encoder **useful freeze gate** (stability + ordering + geometry + generalization) | **OPEN** | `NATIVE_AI_V1_ROADMAP.md` §10 |
| Law beyond A0.3 on silicon | **No RTL** for triplet, S1, S3, attribution, L2, E6, E7, ungated DIFF | Every post-A0.3 closeout: evidence class **REFERENCE_MODEL** |
| `ENC-GEOM-DIAG-00` | **Authorized, not archived** — no `results/A7-EAM-03E/ENC-GEOM-DIAG-00/` in the 03E tree listing | Human approval 2026-08-22 |
| Encoder lane vs graph LOOP | **PARKED** relative to Native Graph | `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` (`encoder_lane`); `PROJECT_COMPLETE.md` |
| Native V1 existence (`pred=664`) | **OPEN** on Cursor board tree; **not** this orch lane; **not** encoder | `research/NATIVE_AI_GROK_ORCH_LANE.md` |
| A0.1-T seed inversion | **Reproduced on silicon**, not a T regression | seed `0x22222222`, `M_L1 = −1258` in `A01T_CLOSE/closeout.md` |

### 1.3 Standing candidate (not a PASS, not frozen)

**Triplet hinge + unconditional S3 decay `Wh -= Wh >> 3`** on signed `h`.

- 10k: rank 9–11, sat 0.000, `M_L1 > 0` 11/11; **FAIL** `M_cos` and `AUC_post > AUC_init`.  
  `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-03E\A02_L_S3\closeout.md`
- 100k: non-inversion **does not hold** (seed `0x7A9BE636` `M_L1 = −13.316`, `M_cos = −0.301`, AUC 0.479). Rank/sat mostly survive.  
  `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-03E\A02_L_S3\horizon100k\PROVENANCE.md`

This is the **best of six** 100k×11 configurations (`E2A_S1_RATE16/closeout.md`). It is **not** encoder GO.

---

## 2. Did ungated DIFF twin already NO-GO? At what horizon?

**Yes. Twin NO-GO. No RTL was (correctly) written.**

Law: `eam03e-a03-ungated-diff-v1` (remove `d1 < E3_MARG=4096`; DIFF always push when `learn && !same`). Base: A0.3 signed `h`.

| Horizon | Result | Path |
|---------|--------|------|
| **10,000** updates, 11 seeds, **matched gated control** | Ungated **FALSIFIED as the bottleneck**. No-decay: gated and ungated both **AUC final 0.500**. With S3: ungated **worse** (0.398 vs 0.408). Rank still → 1 without decay. | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-03E\A03_UNGATED\closeout.md` |
| **100,000** updates, 11 seeds, no decay/clamp/triplet | **`E1: NO-GO` 11/11.** Sanity gate **PASS** (`diff_seen = diff_push = 284251`, `suppressed = 0`). Every seed AUC final **0.500**, rank 1–3, `unique_d1 = 1`. | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-03E\E1_UNGATED_100K\closeout.md` |

**Mechanism vs remedy:**

- **Mechanism CONFIRMED:** gated law suppresses ~71% of DIFF pushes (short telemetry contrast in E1 closeout). H5 description in `MUST_READ` is right.
- **Remedy FALSIFIED:** removing the gate is **not** sufficient; ungated-alone is the **worst** 100k config (only one with 11/11 chance). Gate was an accidental rate limiter; unthrottled updates + no restoring force collapse fastest.

Short-horizon `MUST_READ` numbers (seed `0x22222222` always-repel `M_L1 = +1545`) are **not** contradicted as short-horizon margins; they **do not** license a long-horizon law. Human review: **REJECT ungated DIFF as next remedy** (`ENCODER_SCIENCE_REVIEW.md` §5; `HUMAN_APPROVAL_20260822.md`).

---

## 3. Next legal encoder experiment AFTER existence (not now on board)

**Do not do encoder silicon now.** Cursor owns JTAG/COM12 until UART `NATIVE_V1_EXIST_ROW,pred=664`. Grok orch: `PROGRAM=NO`.

Close hierarchy (`research/NATIVE_AI_GROK_ORCH_LANE.md`):

```text
NATIVE_V1_EXISTENCE_BOARD_PASS     ← board lane; not this file
ENCODER_STABILITY / GEOMETRY / BOARD
KIDI20 / KIDI40_TEACHER_OFF
A1_EAM_INTEGRATION
…
```

**After existence, encoder silicon still needs a human-named token.** Science order (one unknown, twin first):

### 3.1 Next legal run (authorized, not yet in archive)

**`ENC-GEOM-DIAG-00`** — **REFERENCE_MODEL only**. **No training-law change.** Frozen standing law = **triplet + S3 `>>3`**.

- **Unknown:** under that frozen law only, do FAIL seeds show worse geometry (`E_balance`, `E_corr`, rank, `margin_success(m)`) than PASS seeds at matched checkpoints?
- **Preregistered transforms (binding):**  
  - sign-space `b_ij = sign(h_ij)` → `E_balance`, binary correlation  
  - continuous `z_ij = standardized(h_ij)` → covariance / correlation / effective rank  
  - **Do not** label raw int16 covariance as `E_corr`.
- Archive **only** under `results/A7-EAM-03E/ENC-GEOM-DIAG-00/` (main tree when executed). **No graph credit.**
- Authority: `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\BOTTLENECK-RESOLUTION-REVIEW-00\ENCODER_SCIENCE_REVIEW.md`  
  `HUMAN_APPROVAL_20260822.md`  
  `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/16_MASTERPLAN_EXECUTION_PATH.md` §2.4

### 3.2 After diagnosis (not bundled with 3.1)

If diagnosis does not license a new geometry law, the **one-change** hypothesis already written (still **untested as a registered 11×100k law**):

**SCOPE-R0 = standing candidate + on-chip consolidation/hold** (local TRAIN telemetry only; **cosine stays EVAL**; no host early-stop).

- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\NATIVE_AI_SCOPE_R_INDEPENDENT_QA_VI.md` §6–7  
- Hypothesis origin: `E2A_S1_RATE16/closeout.md` (“every law peaks ~0.68–0.78 then destroys it”)

Requires a **new contract + new law id**. Do not mix with decorrelation, replay, adaptive `M_cos`, L2, ungated DIFF, or S2.

### 3.3 Explicitly illegal as “next”

| Do not run as next | Why |
|--------------------|-----|
| Ungated DIFF twin again | Already NO-GO @ 10k and 100k |
| S2 clamp tighten | FALSIFIED |
| S1 rate ÷16 | FAIL 11/11 @ 100k (`E2A_S1_RATE16`) |
| Triplet without S3 | Rank collapse (`A02_L`) |
| Byte attribution | Falsified @ 100k (`E4_ATTR_100K`; `M_L1 > 0` 0/11 in E5 table) |
| L2 radial eq | DROP (`E5_L2_SWEEP`) |
| E6 scale-gated decay / E7 two-sided band | Fail locked rank criterion |
| Init-rank “fix” | E8: correlation only; lane closed |
| Encoder RTL / new bit | Twin law not frozen |
| Glue 01R/02M/LM-06 | A1 CLOSED |
| Encoder work on Arty while existence open | Board owned by Cursor; existence ≠ encoder |

---

## 4. Can encoder work run on Grok-orch **without** the Arty board?

**Yes — host Python REFERENCE_MODEL only.** This is the legal grok-orch encoder mode **now** (and after existence until a human silicon token).

**Allowed on `arty-a7-online-lm-grok-orch-00` (no JTAG, no COM12):**

| Asset | Path (orch tree mirrors main) |
|-------|-------------------------------|
| Twin | `python/eam/eam03e_twin.py` |
| Bench / collapse metrics | `python/eam/eam03e_bench.py` |
| Stability / ungated / S2 harness | `tools/a7eam03e_stability.py` |
| Triplet / S3 / long-horizon | `tools/a7eam03e_a02l_twin.py` |
| Norm diagnostic | `tools/a7eam03e_norm_diag.py` |
| Rank probe | `tools/a7eam03e_erank_probe.py` |
| Twin golden tests | `tests/golden/` (eam03e twin) |

Twin is licensed as **arithmetic authority for A0.3-derived sweeps** by 5000-step silicon match (`A03_SIGNED/twin_board_equiv_closeout.md`). That does **not** turn triplet/S3/R0 into board results.

**Must not on this lane:** `open_hw_manager`, program leftover bits, dual-read UART, pin-POS silicon, overwrite frozen bits, edit `a7lm06_expected.txt`.

XSim of **graph/existence** fences is orch-legal but **is not encoder work**. Encoder RTL changes are forbidden until a twin law PASSes freeze gates.

---

## 5. What must NOT be glued to 01R / 02M until encoder GO

Encoder GO = `NATIVE_AI_V1_ROADMAP.md` §10 freeze (stability + `M_L1>0` all seeds at registered horizon + `M_cos>=0` all seeds + generalization). **Not** A0.3 exact integers. **Not** graph `pred=664`. **Not** LM-06 802k.

Until that freeze (then new encoder RTL + new bit + silicon match of **that** law):

1. **Do not instantiate 01R or 02M** on a collapsing / sub-chance / inverted encoder (`MUST_READ` Cấm; `A02_L_S3/closeout.md` “hard stop against gluing frozen 01R/02M/LM-06 onto a weak encoder”).
2. **Do not open A1** (`03E → 64-bit cue → 01R → 02M`). A1 is **CLOSED** in `final.md`, `HANDOFF.md`, `docs/contracts/A7-EAM-03E.md`.
3. **Do not open Kidi-20 / Kidi-40 teacher-off** (roadmap §13–14 waits on encoder freeze).
4. **Do not claim semantic retrieval** from 02M (02M claim is exact bind of **given** cues only).
5. **Do not mix LM-06 next-token** into encoder evidence; do not use host gradient / winner / address / cue (`final.md` hardware learning boundary).
6. **Do not treat cosine as TRAIN**; cosine = EVAL (`MUST_READ`; A02).
7. **Do not treat `E3_MARG` as HIT/no-HIT** binary conditioner.
8. **Do not start GlassBox** until Native V1 freeze (`final.md` primary objective).
9. **Do not rename encoder diagnostic PASS as graph/HS-02 progress** (`ENCODER_SCIENCE_REVIEW.md` contamination risk).
10. **Do not overwrite** frozen bits: 01R `57D1DF1B…`, 02M `DB3BC58A…`, A0.1-T `80F2ED9E…`, A0.3 `05E478FF…`, LM-00..06.

---

## 6. One-page law ledger (host twin unless noted)

| Law / intervention | Horizon | Verdict | RTL? |
|--------------------|---------|---------|------|
| Unsigned SignSGD A0 / A0.1-T | 32-step golden + silicon | Arithmetic/timing gates met; seed invert `M=−1258` | **Yes** (T bit `80F2ED9E…`) |
| Phase S unsigned long run | 10k | STABILITY_FAIL 11/11; H1 falsified **on unsigned law** | A0 RTL |
| A0.3 signed `h` | 32-step + 5k twin-board | Silicon exact; quality not claimed | **Yes** (`05E478FF…`) |
| A0.3 signed long run | 10k | Still collapses; H5 attraction + Wh growth | No extra RTL |
| S2 clamp | 10k | FALSIFIED | No |
| Ungated DIFF | 10k matched + **100k** | **NO-GO** | **No** (pre-check fail) |
| Triplet hinge alone | 10k | FAIL, rank 1 | No |
| Triplet + S3 `>>3` | 10k / **100k** | Best standing; **FAIL** worst-seed at 100k | No |
| S1 rate ÷16 | 100k | FAIL 11/11 | No |
| Attribution exclusive | 100k | Falsified | No |
| L2 band 8 | 100k | DROP | No |
| E6 scale-target 1024 | 100k | Not development pass (rank) | No |
| E7 band 800–3100 | 100k | Worse than unconditional S3 | No |
| E8 init rank | diagnostic | Not the residual cause | No |
| ENC-GEOM-DIAG-00 | — | **Not run** | No |
| SCOPE-R0 hold | — | **Hypothesis only** | No |

---

## 7. Not claimed

- `BOARD_PASS`, `NATIVE_V1_EXISTENCE_BOARD_PASS`, `NATIVE_V1_MINI_AI_BOARD_PASS`.
- Encoder GO / A1 / Kidi.
- That `MUST_READ` H5 **mechanism** is wrong (it is measured).
- That ungated DIFF is still the untested next twin (it was tested and NO-GO).
- Any quality claim from A0.3 silicon exactness.

**Grok-orch next encoder action (host Python only, after/parallel to existence, not on board):** implement and archive **ENC-GEOM-DIAG-00** on the frozen triplet+S3 twin, with preregistered sign/z transforms, under `results/A7-EAM-03E/ENC-GEOM-DIAG-00/`. Do not glue. Do not write encoder RTL.
