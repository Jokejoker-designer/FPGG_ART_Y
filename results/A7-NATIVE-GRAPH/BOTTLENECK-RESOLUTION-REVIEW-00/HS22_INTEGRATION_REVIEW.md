# HS22_INTEGRATION_REVIEW — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

**Reviewer role:** a7-integration-hlb-reviewer (via `a7-hlb-auditor`)

---

## 1. PROPOSAL D — BRAM phase ownership FSM

**Verdict: ACCEPT (AMEND)**

Doctrine sequence (matches proposal §16):

```text
GRAPH → BLOCK_NEW_WORK → DRAIN_PE → DRAIN_FRONTIER → DRAIN_QUEUE
      → RESOLVE_DIRTY_POLICY → DDR_COMMIT_IF_REQUIRED → WAIT_DDR_IDLE
      → VERIFY_QUIESCENT → OWNER_SWITCH → LM
```

| Amendment | Reason |
|-----------|--------|
| `RESOLVE_DIRTY_POLICY` explicit | HLB R3 post-WM-00: writable tiles need per-phase write counters |
| `WAIT_DDR_IDLE` | MIG-BOARD-R2 integrity before switch |
| `phi_switch` measure-only | No arbitrary threshold |
| One writer per bank per cycle | Hard invariant — **not evidenced** yet |

**REJECT:** Fine-grained simultaneous GRAPH+LM sharing without FSM.

---

## 2. PROPOSAL E — HS-22 single real LM-06

**Verdict: ACCEPT (AMEND)**

### TinyGPT duplication analysis

| Artifact | Additive BRAM | TinyGPT on path | HS-22 |
|----------|--------------:|-----------------|-------|
| TINYGPT-SOC | 260>135 | hier=0 on UA SoC | OPEN |
| BRAM-CONSOL | 132 co-fit proxy | ABSENT | OPEN |
| TINYGPT-CONSOL | 264 naive | ABSENT; DSP=0 | OPEN |
| HS02-LMPATH | — | `lm_path=1`, `pe_alive=0` | OPEN |
| HS02-SEMANTIC | — | no query/answer path | LIMIT |

**Q7 answer:** Historical path **duplicates** memory machinery (UA128 + LM132 additive). Preferred: **ONE** frozen LM-06 core + phase-shared pool + native evidence packet.

**REJECT:**
- Sticky `lm_path=1` as HS-22 close  
- `LM_COMPOSE` XSim as active compute  
- Co-fit proxy as answer-path SoC  

Gate `HS22-LM06-ACTIVE-00` must include actual MAC/DSP/activation/weight/argmax path.

---

## 3. PROPOSAL HS-02 chain (proposal §18)

**Verdict: ACCEPT (AMEND)**

```text
raw bytes → FPGA query/anchor → native retrieval + global Top-K evidence
         → LM-06 → FPGA next token
```

**Ordering (mandatory):**

1. WF-GLOBAL-TOPK-00  
2. LM Pareto ladder + `bram_owner_00`  
3. HS22-LM06-ACTIVE-00  
4. HS-02 teacher-off semantic (held-out wording)  
5. Human §14 BOARD_PASS  

**Teacher-off authority (must hold on silicon):**

```text
teacher=0, external_LLM=0, host_semantic_cue=0, host_winner=0,
host_episode_address=0, host_next_token=0, host_weight_writes=0
```

Offline scoring after exam: **allowed**. Blind-query hints: **forbidden**.

Current `teacher_off_exam` / `hs02_semantic`: **PASS_NARROW** framing only — **not** §14 semantic HS-02.

---

## 4. Phase-lifetime matrix (proposal §23) — gaps

| Block | BRAM | Phase | persistent? | shareable? | DDR? | Evidence gap |
|-------|-----:|-------|-------------|------------|------|--------------|
| encoder A0.3 | 3 | ? | frozen | ? | no | concurrent vs phased |
| 01R router | 56 | GRAPH | run | **NO** (frozen bit) | index DDR | not integrated |
| graph cue stage | ≤2 tiles arch | GRAPH | transient | yes | yes | not post-route |
| frontier | partial | GRAPH | transient | TBD | partial | integrate_fit cut |
| global Top-K acc | **0** | GRAPH | transient | — | — | **MISSING** |
| NG-02R Top-K primitive | 0 | GRAPH | — | — | — | DONE |
| 02M episode | 52 frozen / 0 DDR win | GRAPH | DDR | NO | yes | MEM-01/02 XSim |
| LM u_w/u_a/u_snap | 132 | LM | run | phase mux | weights DDR | POST_ROUTE |
| LM compute | DSP path | LM | — | — | — | partial cuts only |
| MIG / arbiter | TBD | always | yes | no | — | partial |
| FIFOs | TBD | GRAPH/HOLD | transient | TBD | no | **OPEN** |
| TinyGPT duplicate | **must be 0** | — | — | — | — | HS-22 requirement |

```text
B_peak = B_always + max(B_encoder?, B_graph, B_lm)
```

**Hypothesis only** until integrated post-route enum + owner FSM proof.

---

## 5. HLB violation risks (if proposals ignored)

| Severity | Risk | Fix |
|----------|------|-----|
| CRITICAL | Per-wave Top-K sold as global | WF-GLOBAL-TOPK-00 |
| CRITICAL | HS-02 from UART stub / lm_path sticky | HS22 then HS-02 chain |
| MAJOR | Host next-token at compare time | Recorded silicon CONTROL only |
| MAJOR | TRAIN-V2 host ranking as FPGA retrieval | Keep harness ≠ board |

Current archived gates: **HLB CLEAN** within scoped evidence classes.

---

## 6. HS-22 — do not build second LM

**ACCEPT** proposal §17. Measured falsification of additive 260/264 BRAM stacks supports single-core + phase-share architecture.
