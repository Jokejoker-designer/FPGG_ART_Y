# ROOT CAUSE — Gate14 C9 / generation identity

```text
GATE14_PASS = NO
BOARD_PASS  = NO
NATIVE_V1_MINI_AI_BOARD_PASS = NO
PROGRAM     = NO
```

This note is the architectural diagnosis. It is **not** a Gate14 pass claim
and **not** a bitstream.

BASE_SHA = `1e71eb12b12be4405fa7aa490b2da04782ad18eb`

---

## 0. What the owner asked

Stop stacking local predicates (`header_ok` clauses, P_INVAL tweaks, dual-FSM
copies). Find the **single identity law** that, if it had existed, would have
made the silicon C9 fail *and* the wrap-forget hole *and* the next cookie
bug the same defect.

---

## 1. Silicon facts (not inference)

Frozen oracle:

```text
HOLD_A C9  = 8382238122802120
HOLD_A OUT = 653
```

Historical fail bit `3A7EF204…`:

```text
20 facts accepted (UART)
20 reward commits reported by UART-facing counters
C8 GEN     = FFFFFFFF   at boot, before fact #1
HOLD_A C9  = 2322838281802120
OUT        = 748
```

XSim reconstruction `TWO_FREE` (30 vis_w rows stamped `0xFF` + 2 free) produced
**exactly** silicon C9. That is the causal reconstruction of the board pack.

Reset / START / owner on unique bit `7ECCA0E2…` are **closed**. Do not reopen.

---

## 2. The first downstream *symptom* (already patched)

Old P_BOOT:

```text
accept header if bit0==1 AND gen!=0
```

Dirty DRAM `FFFFFFFFFFFFFFFF` satisfies that, so:

```text
live_gen = FFFFFFFF
stamp window = live_gen[7:0] = 0xFF
vis_w matches garbage rows whose stamp happens to be 0xFF
TRESET sees gen>=WRAP_LIMIT → P_INVAL
P_INVAL zeros DDR and returns to IDLE with live_gen still FFFFFFFF
and BRAM still vis_w-true
free list = !vis_w  → almost no free slots
UART ack_count still ++ (20)
architectural commit_seq only ++ on RAM write (2 in TWO_FREE)
C9 = A0,A1,U0..U3,A2,A3  ≠  A0..A3,U0..U3
```

The merged P0 patch (`header_ok` + P_CLR) **closes the dirty-boot entry**.
It does **not** close the identity law. That is why the next holes were
already visible in the same file:

- P_INVAL still left `live_gen` and BRAM
- `a7ng_persist_gen_fast` still used the old cookie test
- stamp is 8 bits of a 32-bit gen
- DDR slot packing truncates `{subj,obj}` to 16 bits

Those are not independent bugs. They are the same missing object.

---

## 3. Root cause

**Training generation was never a single epoch object.**

It was six loosely coupled copies, each mutated by a different FSM state:

| Copy | Width | Writer | Reader | Legal predicate (pre-fix) |
|------|------:|--------|--------|---------------------------|
| DDR word 0 header | 64 | P_FLUSH | P_BOOT | `bit0 && gen!=0` |
| `live_gen` FF | 32 | P_BOOT, TRESET bump, rst | vis_w, wrap, C8 | none |
| BRAM per-slot stamp | 8 | P_UPD, P_RELOAD | vis_w | `== live_gen[7:0]` |
| DDR slot payload stamp | 8 | P_FLUSH | P_RELOAD | `!= 0` means occupied |
| `ws_live` | 1 | P_CLR, P_RELOAD, kill | vis_w | flag |
| UART C8 | 32 | graph assign | host | copy of `live_gen` |

There is no commit that writes **all** of them, and no boot that **verifies
all** of them. Each “patch” added a predicate to **one** row.

That is the patch treadmill.

### 3.1 The law that already existed and was forked

RESET-00 (`BRAM_RESET_RETRAIN_PLAN.md`, `a7ng-reset-epoch-v0`,
`a7ng-reset-learned-v0`) already defined:

```text
FAST RESET  = bump generation (logical invalidation, no BRAM wipe)
HARD RESET  = physical scrub of BRAM + learned DDR, then verify
entry visible iff entry.gen == active_training_generation   (full 32-bit)
```

RTL for that law exists and is **not** on the Gate14 path:

```text
rtl/native_graph/memory/a7ng_epoch_mgr.sv          // owns training_generation
rtl/native_graph/memory/a7ng_learned_gen_view.sv   // 32-bit gen stamp, vis by equality
```

Gate14 persist (`a7ng_learned_prior_store`) reimplemented a weaker private
copy:

- owns its own `live_gen` (epoch_mgr is not instantiated in `g1g5_cofit`)
- truncates identity to 8-bit stamp
- WRAP_LIMIT = 6 so the 8-bit window never collides — then uses wrap as an
  excuse for a **physical** DDR wipe
- boot **restores** `live_gen` from an untrusted DRAM cookie
- wrap wipe (`P_INVAL`) is “zero DDR” **without** destroying the epoch

So the silicon fail is not “P_BOOT was one `&&` short”.

It is: **Gate14 persist forked RESET-00’s epoch law into a cache-restore
heuristic, then used 8-bit vis_w as if it were identity.**

Dirty DRAM is not an epoch. `FFFFFFFF` is not a generation. vis_w matching
`stamp==0xFF` is not “learned A-facts”. UART ack_count is not commit_seq.

### 3.2 Two operations an epoch actually has

```text
BUMP     (RESET level 2, fast)
  live_gen := live_gen + 1
  sdig     := 0
  BRAM payload may remain
  vis_w hides old stamps
  !vis_w rows are allocatable

REBIRTH  (RESET level 3, hard)
  live_gen := 1
  BRAM     := empty
  DDR[0]   := 0 (illegal cookie; next boot cannot restore garbage)
  DDR[1..] := 0
  boot_done after BRAM wipe
```

P_BOOT of an illegal cookie **is REBIRTH** (already went to P_CLR).

P_INVAL at wrap **claimed** to be REBIRTH and was only a DDR scrub. After
wrap, vis_w still showed A-facts. Gate14 forget (`§14 Reset/retrain`)
**cannot pass** on that FSM even if dirty-boot is closed.

That is the same root, second entry point.

### 3.3 Dual implementation of the same law

| Module | Gate14 SoC (`g1g5_cofit`) | Cookie test (pre-fix) | Wrap |
|--------|---------------------------|------------------------|------|
| `a7ng_learned_prior_store` | **ACTIVE** | header_ok (P0) | P_INVAL zeros DDR only |
| `a7ng_persist_gen_fast` | not instantiated (teacher_off_soc_xsim) | old `bit0 && gen!=0` | same incomplete P_INVAL |
| `a7ng_prior_persist` | NG-05 ancestor | no generation at all | forget_i wipes BRAM+DDR |

Patching only the active file leaves a landmine copy of the old cookie
test. That is how the next “we forgot persist_gen_fast” patch is born.

---

## 4. Causal chain, restated as identity

```text
untrusted DRAM word
  is treated as training_generation
    because there is no epoch type, only a 64-bit cookie
      → live_gen becomes FFFFFFFF
        → vis_w uses live_gen[7:0]
          → garbage rows with stamp 0xFF become “learned prior”
            → TopK mix_terms + lk_hit changes HOLD_A ranking
              → C9 2322838281802120 / OUT 748
```

AND independently, same missing type:

```text
WRAP_LIMIT hit
  → P_INVAL destroys the cookie
    but not live_gen and not BRAM
      → vis_w still true for the previous epoch
        → Gate14 forget fails
```

One missing object. Two entry points. Unlimited future predicates if the
object is not introduced.

---

## 5. What is NOT this root (do not mix)

Classify separately. Do not “fix” them inside the epoch change.

| Item | Class | Why separate |
|------|-------|----------------|
| WDMA `cmd_hold` relatch if `m_go` held after accept | command pulse vs level | AXI DMA, not generation |
| `persist_owner_ui` AR→RLAST / AW→B lifetime | interconnect grant | boot hang class; closed on `7ECCA0E2` |
| digest XOR `{npri,nstp,slot}` omitting `{subj,rel,obj}` | knowledge identity vs slot checksum | C8 observe-only; does not move C9 |
| DDR slot `{subj[15:0],obj[15:0],…}` truncation | persist record ≠ live 32-bit key | Gate14 keys `0xA000+i` fit 16 bits; latent |
| Scorer / minheap / TinyGPT / bind / TopK | frozen | C9 moved because **inputs** (learned_prior vis_w) moved, not because the heap law moved |

---

## 6. The invariant (the actual fix target)

```text
I1  live_gen ∈ [1, WRAP_LIMIT] whenever boot_done
I2  DDR[0] is either illegal (must not load) or ng_epoch_pack(live_gen)
I3  vis_w(slot) iff occ && stamp == live_gen[7:0] && ws_live && live_gen!=0
I4  !vis_w ⇒ allocatable
I5  TRESET is BUMP if live_gen < WRAP_LIMIT, else REBIRTH
I6  P_BOOT is verify-or-REBIRTH, never “trust bit0”
I7  every persist FSM that reads the cookie uses ng_epoch_legal
I8  WRAP_LIMIT ≤ 2^NG_EPOCH_STAMP_W − 1  (compile-time)
I9  REBIRTH = {live_gen=1, DDR wipe, BRAM wipe, boot_done after wipe}
```

header_ok is I6 for one module. It is not I1–I9.

---

## 7. Root fix applied in this bag (not another cookie clause)

1. Epoch pack/legal/gen/visible live in `a7ng_pkg` — one definition.
2. `a7ng_learned_prior_store` **and** `a7ng_persist_gen_fast` call that
   definition (I7). FLUSH writes `ng_epoch_pack`.
3. P_INVAL is REBIRTH: after DDR wipe, `live_gen=1`, `ws_live=0`,
   `boot_done=0`, then **P_CLR** wipes BRAM and re-asserts boot_done (I5, I9).
4. Compile-time `$error` if WRAP_LIMIT exceeds the 8-bit stamp (I8).

What this bag deliberately does **not** do (would be a second unknown):

- Does not instantiate `a7ng_epoch_mgr` on the Gate14 path (query/path
  epochs are a different RESET-00 surface).
- Does not widen the BRAM stamp to 32 bits (WRAP_LIMIT=6 makes I8 hold;
  widening changes the 97-bit record and is a new persist format).
- Does not change DDR slot 16-bit key packing (Gate14 keys fit; latent I9
  of the *record*, not of the epoch).
- Does not retarget C9/OUT.
- Does not program the FPGA.

---

## 8. Trust

```text
board 3A7EF204 C9/GEN     >  XSim TWO_FREE reconstruction
                         >  current RTL
                         >  this note
```

XSim of REBIRTH is evidence that wrap forget is now I9. It is **not**
silicon. Next unique bit is still a one-unknown Gate14 replay, PROGRAM=NO
until the human programs.
