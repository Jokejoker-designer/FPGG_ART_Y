# AUDIT — ROOT B TRANSACTION INTEGRITY

```text
ROOT/GATE                    = G14-ROOT-B-TXN-AUDIT-00
CLASS                        = ROOT_B_PARTIALLY_CONFIRMED
FIRST_DIVERGENCE             = NONE (on frozen bit 1F0F2ABB)
ROOT_CAUSE                   = not a closed silicon fail; missing single txn object + ACK≠commit by construction
FIX                          = none this gate (no RTL)
XSIM                         = reused GO-REQUEST-PENDING-00 / GO-GRANT-QUIESCE-00 (HISTORICAL XSIM)
IMPLEMENTATION               = not this gate
BOARD_REQUIRED               = NO

ROOT_A_EPOCH                 = BOARD_CLOSED
ROOT_B_TRANSACTION           = PARTIALLY_CONFIRMED (latent + evidence-gap; not silicon-open)
PERSISTENCE_IDENTITY         = OPEN_ACCEPTANCE
RESET_RETRAIN                = OPEN_ACCEPTANCE
TEACHER_OFF                  = OPEN
LM_ACTIVE_CHAIN              = OPEN
SCALE_800K                   = OPEN

READY_TO_PROGRAM             = NO
PROGRAM                      = NO
GATE14_PASS                  = NO
BOARD_PASS                   = not_claimed
NATIVE_V1_MINI_AI_BOARD_PASS = NO
```

Evidence classes are labeled in-line. Historical 748/GEN=`FFFFFFFF` is **not**
this root (`BOARD`, commit `9656245`).

---

## A. Current Truth

```text
ROOT_A = BOARD_CLOSED
         HISTORICAL_C9_748_ROOT = CLOSED
         P_BOOT_DIRTY_DDR_ROOT  = CLOSED
         bit 1F0F2ABB programmed once; do not reopen without new epoch invariant break

ROOT_B = ROOT_B_PARTIALLY_CONFIRMED
         The SoC has no single transaction identity that is host-visible
         from request through architectural RAM write through retirement.
         That is an RTL_FACT. It is NOT a demonstrated fail on 1F0F2ABB.

GATE14 = NO
         remaining: persistence identity, reset/retrain, teacher-off
         causality, LM-06 active chain, memory/parallelism, 800k
```

Do not conflate those remaining items with Root B.

---

## B. WDMA Map

Active Gate14 producer (`RTL_FACT`):

```text
tiny_gpt803k_core
  → weight_tile803k dest FSM
       dma_owner = (dst != D_IDLE)
       dma_go    = one-cycle pulse (go_sent; default dma_go<=0 every cycle)
  → a7ng_native_v1_ab_core.wdma_go
  → soc_top.wdma_go
  → a7ng_wdma_cdc.m_go          (core_clk)
       cmd_hold  (until m_owner && !cmd_full)
       cmd FIFO  XPM async 16 deep
  → s_go pulse                  (ui_clk, C_IDLE→C_GO one cycle)
  → ddr_tile_dma.go && wdma_owner_ui
  → AW/W/B or AR/R
  → s_busy / s_done
  → m_done CDC pulse, m_busy = busy_hold & s_busy_cdc
  → dest D_GO waits dma_busy then D_FEED/D_DRAIN
```

`lm06_persist` is **level-until-busy**. It is **not** the C9 SoC WDMA
producer. TinyGPT tile dest is.

### m_go semantics (`RTL_FACT`, not comments)

| Driver | Law |
|--------|-----|
| `weight_tile803k` dest | **one-cycle pulse**, then wait `dma_busy` |
| `lm06_persist` dest | **level-until-busy** (inactive on this SoC) |
| `a7ng_wdma_cdc` | **not** valid/ready: no `m_go_ready`. Capture on `m_go && !cmd_hold_valid` |
| accept | `cmd_hold_valid && m_owner && !cmd_full`; same-cycle `m_go` is **not** relatched |
| next cycle if `m_go` still 1 | **second capture** (`else if m_go && !cmd_hold_valid`) |

Same semantic request can be captured twice **if** `m_go` is a level that
survives the accept cycle. The **active** TinyGPT dest does not do that.

Two distinct requests can collapse to one FIFO command **if** the second
`m_go` arrives while `cmd_hold_valid=1`: overflow sticky, first payload
kept, second **dropped**. No backpressure. Overflow is **not** on CFRAME.

### cmd_hold_overflow

```text
overflow reachable?  YES in adapter  (XSIM GO-REQUEST-PENDING-00 CASE D)
                     NO  from active TinyGPT dest under current dest law
                         (LATENT / NOT_REACHABLE for that producer)
payload lost?        second request  (first kept)
backpressure?        NO
observable?          overflow flop only; not UART
completion?          producer waiting dma_busy never sees the dropped go
```

```text
WDMA_SILENT_DROP_REACHABLE   adapter + double-pulse producer   XSIM
WDMA_EXACTLY_ONCE_PROVEN     NOT proven in general (no m_go_ready)
active Gate14 producer       one-cycle pulse → drop not exercised  RTL_FACT
```

**WDMA verdict for this SoC:** `WDMA_PROTOCOL_AMBIGUOUS`

Classification: `HIGH_RISK_ARCHITECTURAL_HAZARD` (no ready; silent overflow)
+ `LATENT_DEFECT` for drop under a level/`m_go` producer
+ `NOT_REACHABLE` for TinyGPT dest as written
+ `FALSIFIED` as the 748 root

### Coverage matrix (existing XSim; do not duplicate)

| Stimulus | Bag | Result |
|----------|-----|--------|
| one-cycle go delayed grant | GO-REQUEST-PENDING-00 A | REQUEST_HELD 1 cmd / 1 s_go |
| never grant | GO-REQUEST-PENDING-00 C | hold stays; no s_go |
| duplicate go while hold | GO-REQUEST-PENDING-00 D | overflow, first kept |
| FIFO full | GO-REQUEST-PENDING-00 B | 16th held, no write |
| grant hold in AR, drop after idle | GO-GRANT-QUIESCE-00 | QUIESCE_HOLD |
| held-high go after accept | **EVIDENCE_GAP** vs TinyGPT (pulse) | would 2nd-capture |
| done + new request same cycle | **EVIDENCE_GAP** | |
| reset pending | **EVIDENCE_GAP** | |

### busy / done / retirement (`RTL_FACT`)

| Signal | Meaning |
|--------|---------|
| `busy_hold` | set on `m_go`, clear on `m_done` |
| `m_busy` | `busy_hold &` CDC(`s_busy`) — can drop while dest still D_GO if CDC busy glitches |
| `m_done` | pulse CDC of `s_done` |
| `s_busy` | `ddr_tile_dma` st ∉ {IDLE,DONE} |
| `s_done` | one-cycle in DMA DONE |
| `ghost_busy_rel` | dest D_GO/D_WAITDONE ∧ dma IDLE → pop cmd despite `s_busy` |
| `cmd_st` | C_IDLE / C_GO / C_BUSY |

Can DONE belong to an older request? **INCONCLUSIVE** if FIFO depth>1 and
two cmds in flight. Dest waits busy after one pulse, so typical in-flight=1
(`HYPOTHESIS` from dest law, not a FIFO theorem).

Can a new command enter before previous effects retire? **YES** in the
adapter (FIFO 16). **NO** from TinyGPT dest until `dma_busy` then back to
IDLE (`RTL_FACT`).

---

## C. AXI Owner Map

Active mux owners on `arty_a7_ng_native_v1_ab_soc_top` (`RTL_FACT`):

| Owner | Domain | When | Channels |
|-------|--------|------|----------|
| SOA boot | `ui` `soa_phase` | boot write | AW/W/B |
| WMEM boot | `ui` `wmem_phase` | boot write | AW/W/B |
| PERSIST | `persist_owner_ui` | grant: `persist_req && !wdma_owner_ui && rpath_idle && !soa && !cdc_arvalid`; drop: `idle && !req` | AR/R and AW/W/B |
| WDMA | `wdma_owner_ui` = CDC(`wdma_owner_grant`) | grant: `(wdma_owner\|\|tile_miss) && !soa_running`; drop: `!owner && rel_ok` (cmd_empty ∧ dma IDLE ∧ AR/R outstanding==0) | AR/R and AW/W/B |
| QUERY/CDC | default when neither persist nor WDMA nor boot | AR/R only | |

**Response routing uses current owner**, not a latched issuing owner
(`RTL_FACT`: `rvalid && persist_owner_ui`, `rvalid && wdma_owner_ui`, else CDC).

### READ_OWNER_LIFETIME

```text
PERSIST = PROVEN     U_AR → U_R waits rvalid&&rready&&rlast before U_DONE;
                     idle_o only in U_IDLE; req_o holds grant; mux uses current
                     owner which is held until idle. RTL_FACT
WDMA    = PROVEN     arr_outst ++ on owned AR handshake, -- on owned RLAST;
                     grant drop waits arr_outst==0 (GO-GRANT-QUIESCE-00 XSIM
                     + RTL). CLASS XSIM for the slice, RTL_FACT on SoC wiring
```

### WRITE_OWNER_LIFETIME

```text
PERSIST = PROVEN     U_AW → U_W → U_B waits bvalid&&bready; then U_DONE/idle
WDMA    = INCONCLUSIVE  ddr_tile_dma is sequential AW/W/B with bready=1;
                        no outstanding-write counter on the mux; grant can
                        drop on rel_ok which does not count B-in-flight
                        (only AR/R). LATENT if a write is in B when grant drops.
```

### QUIESCENT_OWNER_SWITCH

```text
WDMA    = PROVEN on the grant-drop path (BLOCK new by dest wait +
          DRAIN cmd_empty/dma idle/arr_outst). XSIM GO-GRANT-QUIESCE-00
PERSIST = PROVEN grant held while ust!=IDLE
BOOT vs others = mutually exclusive via soa_phase|wmem_phase
```

Not a full Blueprint `BLOCK_NEW_WORK → DRAIN → VERIFY_QUIESCENT → SWITCH`
object. It is **distributed heuristics**. Classification:
`HIGH_RISK_ARCHITECTURAL_HAZARD` for missing one object;
`FALSIFIED` as the 748 cause.

---

## D. ACK / Commit Map

One Gate14 fact (`RTL_FACT`):

```text
CMD_QUERY_TOKEN + CMD_QUERY_COMMIT     REQUESTED
feedback_resolver mint txn             ACCEPTED   p_txn / C6
reward_frame txn_echo                  EXECUTED   consume handshake
c5_cons  = consume_valid && consume_ready
                                         COMPLETED(host-visible)  C5
learned_prior_graph → store P_UPD
  ram_we on key hit OR (slot==32 && !wrote && have_free)
                                         COMMITTED  commit_seq++
  P_UPD exit always:
    ack_count++ ; c7_ack_valid ; persist_done
                                         COMPLETED(store)  even if wrote=0
c7_addr = PRIOR_BASE + {subj[15:0],4'h0}  QUERY_VISIBLE address, not seq
FLUSH/RELOAD                           PERSISTED  DDR header+slots
```

**Board CFRAME does not carry `commit_seq`.**
`a7ng_native_v1_ab_core` ties off `.c7_commit_seq_o(), .c7_ack_count_o()`.
Host C5 is consume count. Host C7 is last persist address + glue `last_ack`.

E2 on silicon (`BOARD`): cons 0→20, txn 1→20, addr 50987008…50987312
(+16 B × 19). That is **20 consume ACKs and 20 distinct C7 addrs**, not a
proven `commit_seq==20`. After epoch closure those likely coincide.
They are **different wires**.

```text
Can legal sequencing ACK without RAM write?
YES by construction: P_UPD end does ack_count++ / persist_done even if
wrote=0 (full 32 vis_w, no key match, have_free=0).
REACHABILITY: LATENT on the 20-fact exam (32 slots, 20 keys).
CURRENT_REACHABLE if a 33rd distinct fact arrives while 32 vis_w live.
```

That is **not** the TWO_FREE epoch mechanism (closed). It is the remaining
ACK≠commit hole.

Digest XOR `{npri,nstp,slot}` omits `{subj,rel,obj}` — `CODE_CLEANLINESS_DEBT`
/ observe-only C8; does not move C9 (`HISTORICAL` ROOT_CAUSE.md). Do not
mix into this patch.

16-bit DDR key truncation: `LATENT`; Gate14 keys `0xA000+i` fit.

---

## E. Root-B Verdict

```text
ROOT_B_PARTIALLY_CONFIRMED
```

Potential statement:

> The SoC lacks a single transaction identity/ownership object
> that survives request → execution → commit → retirement.

**Supported as architecture** (`RTL_FACT`). **Not supported as the open
silicon fail** (`BOARD` E0–E5 exact). Do not patch five modules.

| Item | Class |
|------|-------|
| No unified txn object | HIGH_RISK_ARCHITECTURAL_HAZARD |
| ack_count++ without wrote | LATENT_DEFECT (33rd-fact / full vis_w) |
| commit_seq not on UART | EVIDENCE_GAP |
| WDMA silent overflow | LATENT_DEFECT; NOT_REACHABLE from TinyGPT pulse |
| AXI current-owner mux | persist READ/WRITE lifetime PROVEN; WDMA write B INCONCLUSIVE |
| 748 / GEN=FFFFFFFF | FALSIFIED as Root B (that was Root A, BOARD_CLOSED) |

---

## F. Next Action

Exactly one bounded gate:

```text
G14-PERSISTENCE-IDENTITY-00
PROGRAM = NO
READY_TO_PROGRAM = NO
```

Reason: Root B is not a confirmed first-divergence on the frozen bit.
Gate14 still requires semantic

```text
state before FLUSH == state after RELOAD
```

The BOARD exam after KILL+RELOAD matching HOLD_A is **necessary but not
sufficient** (one query, no slot digest). Close that in XSim with
generation, occupancy, {s,r,o}, pri/pen, C9, OUT. Then reset/retrain.

Do **not** start a WDMA redesign bit.

If a later persistence TB shows ACK without write as the first divergence,
re-open a **narrow** `G14-ACK-COMMIT-00` (store P_UPD only). Not this
session's patch.

---

## Frozen

```text
bit 1F0F2ABB
oracle 653/689/237/60
epoch object
scorer / Top-K / TinyGPT / bind
```
