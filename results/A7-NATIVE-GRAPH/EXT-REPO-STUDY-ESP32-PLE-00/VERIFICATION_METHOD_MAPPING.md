# VERIFICATION_METHOD_MAPPING — EXT-REPO-STUDY-ESP32-PLE-00

Maps external verification methodology to Native AI practice. **No new tests implemented.**

---

## 1. External verification chain (observed)

| Stage | Artifact | Gate | Source | Classification |
|-------|----------|------|--------|----------------|
| Train | PyTorch model | — | `src/train.py` | EXT_REPO_OBSERVED |
| Quantize | Group-128 int4 | — | `src/quantize.py` | EXT_REPO_OBSERVED |
| Export | `model.bin` + `golden.txt` | Quantized dequant for golden | `src/export.py` | EXT_REPO_OBSERVED |
| Host verify | max abs logit diff < 0.02 | Port correctness | `firmware/host_verify/verify.c` | EXT_REPO_OBSERVED |
| Host ppl | CE with/without int8 act | Quality before int8 deploy | `firmware/host_verify/ppl.c` | EXT_REPO_OBSERVED |
| Device | Same `llm.h` | Claim: max diff 0.00001 | RESULTS.md | EXT_REPO_MEASURED (not re-run) |
| Bandwidth bench | Synthetic probes | Table ≪ head cost | `bandwidth_bench.ino` | EXT_REPO_OBSERVED |
| Ablation | 5 arms, matched core | Causal attribution | `run_ablation.sh` | EXT_REPO_OBSERVED |

---

## 2. Native AI verification chain (observed / measured)

| Stage | Artifact | Gate | Classification |
|-------|----------|------|----------------|
| XSim golden | Scoreboard / markers | MIG-METRIC-00, ddr_wavefront_00, lm06_wm_00 | NATIVE_AI_MEASURED |
| Post-route timing | WNS/TNS reports | Vivado gates | NATIVE_AI_MEASURED |
| Board UART | Per-run metric_clear | mig_board_r2 | NATIVE_AI_MEASURED |
| Bit-exact CONTROL | Frozen LM-06 reference | lm06_wm_00 | NATIVE_AI_MEASURED |
| HLB audit | Host must not compute answer | All gates | NATIVE_AI_OBSERVED |
| Evidence auditor | Dispatch law, evidence class | Closeout law | NATIVE_AI_OBSERVED |

---

## 3. Methodology mapping

| External method | Native analogue | Transfer? | Blueprint tag |
|-----------------|-----------------|-----------|---------------|
| Golden on **exported quantized** layout | Golden on **frozen deployed** representation (bit-exact LM-06) | **YES** — same class | ALREADY_SUPPORTED |
| Separate **port** vs **quality** tests | Twin correctness vs task metrics | **YES** | SUPPORTS_EXISTING_DOCTRINE |
| Host verify before device | XSim before board | **YES** | ALREADY_SUPPORTED |
| Synthetic bandwidth probes | MIG 4×4 + wavefront traffic | **YES** | NATIVE_AI_MEASURED (partial) |
| Core-matched ablation | One-unknown scientific gates | **YES** | SUPPORTS_EXISTING_DOCTRINE |
| On-chip tok/s as sign-off | **Forbidden** — HS-02 needs Native board + blind exam | **NO** | NOT_TRANSFERABLE |
| Host training loss as Native evidence | **Forbidden** — HLB | **NO** | CONFLICT |

---

## 4. Proposed Native principle (documentation only)

Split future verification into two non-substitutable classes:

### MODEL-LAW QUALITY TEST

- Semantic accuracy, teacher-off exam, retrieval correctness  
- Changes require law id / TRAIN-V2 discipline  

### PACKING / ADDRESSING / MEMORY-PLUMBING CORRECTNESS

- Bit-exact vs CONTROL  
- Tile packing, persist/reload, DDR layout migration  
- lm06_wm_00 is exemplar of this class  

External `verify.c` isolates **packing/port** from training quality via quantized golden —
analogous split, different domain.

**Classification:** TRANSFERABLE_PATTERN. **Not implemented in this gate.**

---

## 5. Strengthening future gates (recommendations only)

| Future gate | Verification lesson from external repo |
|-------------|----------------------------------------|
| Random metadata DDR | Separate synthetic random probe (like flash random bench) before integration |
| LM06-WM ladder | Golden on exact tile packing, not host-computed expected token |
| BRAM ownership switch | Quiesce + verify counters per phase (analogous to ppl gate before format change) |
| Post-quant LM (research) | Host ppl + device golden — **FUTURE_RESEARCH ONLY** |

---

## 6. Q6 answer

**Does external repo provide evidence for Native AI correctness?**

**NO.**

It provides external precedent and methodology. Native AI requires independent XSim / post-route /
board evidence per gate.

**Classification:** NOT_TRANSFERABLE (as Native evidence).
