# AUDIT — Gate T teacher-off native causality (READ-ONLY)

```text
RTL_EDIT = NO
PROGRAM  = NO
```

Evidence class: **RTL_FACT** until XSim.

---

## Active C9 SoC path (not teacher_off_glue, not query_anchor)

```text
UART decoder  (cmd/tok/rew only)
  → a7ng_g1g5_cofit.u_glue  (a7ng_gate14_c9_glue)
       host_cue/winner/addr/next/wren/mode  TIED 64/32/32/10/0/0
       C_FREEZE → mode=4'h8 → p_learn=mode[2]=0  p_freeze=mode[3]=1
  → a7ng_learned_prior_graph
       candidates = functions of query_id (HOLD_A=2 …)
       lookup learned BRAM vis_w
       scorer_lane + minheap Top-8
       c9_pack = pack of TopK ids
  → glue c9_topk_o = p_topk_id_i[7:0] per slot
```

`a7ng_query_anchor` (teacher_override entity/intent) is **not** in this fileset.
`a7ng_teacher_off_glue` is a **legacy** XSim wrapper, not C9 SoC.

`external_LLM` is not a live net on this SoC. TinyGPT is on-FPGA (Gate L).
Gate T treats “no external LLM / no host next-token / no host weight write.”

---

## Host semantic wires (`RTL_FACT`)

Tied at `a7ng_g1g5_cofit` glue instance:

```text
host_cue_i    = 0
host_winner_i = 0
host_addr_i   = 0
host_next_i   = 0
host_wren_i   = 0
host_mode_i   = 0
```

Glue increments `n_host_*` if any of those is nonzero. Silicon `ab_core`
does not export `n_host_*` to UART (`n_host_*_o()` tied off) — **BOARD
EVIDENCE_GAP**. XSim can sample the counters.

UART may send **exam token** `0xA2` (which query). That is the query id,
not a teacher label of the answer / winner / entity.

---

## What C9 is (`RTL_FACT`)

C9 bytes = graph TopK node ids after mixing:

- hardcoded candidate `{s,r,o}` for qid (native, not host)
- learned prior lookup `lk_pri/lk_pen` when vis_w
- one scorer_lane, one minheap

If host wires stay 0 and freeze=1/learn=0, a wrong C9 is a **retrieval**
fail (Gate T), not LM.

---

## Exam-mode law

```text
C_TRAIN  → mode=5  learn=1 freeze=0
C_FREEZE → mode=8  learn=0 freeze=1
```

Gate T samples **during HOLD_A exam** (after freeze).

---

## Distinction (HS-25)

```text
Gate T  host-off → native retrieval → C9     (this bag)
Gate L  C9 exact → LM-06 compute → OUT       (not this bag)
```
