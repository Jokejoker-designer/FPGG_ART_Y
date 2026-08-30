# EXISTENCE_SURVEY — Native AI V1 owner-fence / LONGBOOT (READ-ONLY)

MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).  
This file is **not** an encoder closeout. H5 / S2 / 01R-glue were not opened.

**Surveyor:** Grok-orch-00 (read-only catalog).  
**Written:** 2026-08-29 (session after STATUS `MASTER_PREFLIGHT` 19:39+07).  
**Authority token:** `READ_ONLY_AUDIT` / `REPORT_ONLY`.  
**This tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` branch `research/native-ai-v1-grok-orch-00` @ `140345e1e848bd66552e412b43197e895f94715c`.  
**RTL edited this survey:** **NONE.** **Program:** **NO.** **`open_hw_manager`:** **NO.**

XSim ≠ board. UART stickies ≠ same-cycle occupancy. Hypothesis ≠ evidence.  
`UNIT_PASS` ≠ `pred=664` ≠ `NATIVE_V1_EXISTENCE_BOARD_PASS` ≠ `NATIVE_V1_MINI_AI_BOARD_PASS`.  
AI does not stamp `BOARD_PASS`.

---

## Trees (do not mix CWD)

| Role | Path | State used here |
|------|------|-----------------|
| **STATUS authority / mailbox** | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\STATUS\` | Sealed ranking, audits, preregs, `MASTER_PREFLIGHT` |
| **Cursor live board (DIRTY — do not edit)** | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board` | UART LONGBOOT bag; fence XSim bags; live `rtl/` |
| **Grok-orch clean base** | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` | `140345e` product RTL; this survey only |

Lane note: `research/NATIVE_AI_GROK_ORCH_LANE.md` — parent = orchestrator; this lane does **not** steal JTAG/COM12.

---

## Standing existence law

| Field | Value | Class |
|-------|-------|-------|
| Goal (human) | `NATIVE_V1_MINI_AI_BOARD_PASS` | STATUS `MASTER_PREFLIGHT` |
| Existence predicate | UART exact `pred=664` / `NATIVE_V1_EXIST_ROW,pred=664` | **absent** |
| `EXISTENCE` | **NO** | FACT (no UART row) |
| `BOARD_PASS` | **not_claimed** | FACT |
| `lock.owner` | grok (R6; not stolen) | STATUS |
| `PROGRAM` (now) | **NO** until a **new** `com12_authorized_gate` | STATUS + lane doc |
| `LOOP_STATE.next` | `graph_late_materialize_00` QUEUED, **DEFERRED** (`EXISTENCE_BEFORE_QUALITY`) | not existence |
| Do not mix | LM-06 golden **744** vs Native-V1 **664** | doctrine |

`ALLOW_PROGRAM_GROK.md` (2026-08-25, gate `native_v1_existence_board_parallel_00`) is **not** a current COM12 license.

---

## 1. Sealed vs dirty vs unknown — owner-fence P0-A / P0-B

Ranking authority: `STATUS/E2R_OWNER_FENCE_CLASS.md` (2026-08-29T18:11+07, SHA256 `E3F8D1ECD7536E4BF8FDFE20E81708B9E4B0573C38AC5872A368667263DD0F82`).  
Invariant: tile may enqueue/start DMA without grant; grant only switches the MIG mux. One unowned `m_go` is enough.

### 1.1 Locked ranking (static; not a C-FIX license)

| # | Finding | Static RTL | LONGBOOT silicon |
|---|---------|------------|------------------|
| **P0-A** | Command path does not wait for grant (`cmd_wr_en` lacks `m_owner`; `cmd_rd_en` / `s_go` lack `s_owner`; tile `D_GO` pulses `dma_go` with no grant AND) | **SEALED CONFIRMED** | UART pack compatible (`MGO=1` with grant/idle bits); **s_go not counted** |
| **P0-B** | Unselected DMA still samples raw `arready`/`rvalid`/`rdata` | **SEALED CONFIRMED composition** | reachable **if A fires**; **not** LONGBOOT waveform |
| **P0-C** | Level `dma_go`/`m_go` → `cmd_wr_en` can multiply FIFO | CONFIRMED hole | **UNKNOWN** (need `cmd_wr_en` / D_GO counts) |
| **P0-D** | Release owner without transport quiesce | CONFIRMED design flaw | **not proven** on LONGBOOT |
| **P1** | `cur_rg` not valid | CONFIRMED | does **not** explain hang |

`RPATH_IDLE=0` is a FACT grant **blocker**, not licensed leftover-query-R deadlock root.

### 1.2 CONTROL SHA (ungated live at CLASS.md 18:11) — **SEALED**

Hashed on **board tree** at ranking time (also Grok-orch `140345e` **law text** matches; this survey did **not** re-`Get-FileHash`):

| File | SHA256 | Law |
|------|--------|-----|
| `rtl/board/a7ng_wdma_cdc.sv` | `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` | `cmd_wr_en = m_rst_n && m_go && !cmd_full` — **no** `m_owner` |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` | `8298376EA060D028303A7148591D99416D8F7C56D116E011E7A32543BC3A2CF0` | mux `arvalid = wdma_owner_ui ? d_arvalid : cdc_arvalid`; DMA `.m_axi_arready(arready)` **raw**; `.go(dma_go)` **ungated**. **No git blob** in the 6-commit worktree (DIRT note). |
| `rtl/ddr/ddr_tile_dma.sv` | `20BAE36ECCB6C94C2C5C9635D5FB7F771F09539E252316CC75D8F723810AD7C5` | AR handshake on raw ready |
| `rtl/lm/weight_tile803k.sv` | `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` | `D_GO`: `dma_go <= 1` with **no** grant AND |

### 1.3 XSim gates — STATUS-sealed (PASS_NARROW only)

| Gate | CLASS | DUT | PROGRAM | STATUS audit |
|------|-------|-----|---------|--------------|
| `E2R-OWNER-FENCE-XSIM-00` | **AB_COMPOSE** `CMD_WR_EN=1 S_GO=1 FALSE_AR=1` DMA_ST=4 peak=5 | CONTROL CDC `FE13D1BB…` + mux copy + `ddr_tile_dma` + stub `arready=1` | NO | `AUDIT_E2R_OWNER_FENCE_XSIM_00.md` + `E2R_OWNER_FENCE_XSIM_00_XSIM_VERIFY.md` (18:21–18:23) |
| `E2R-OWNER-ISSUE-GATE-00` | **ISSUE_GATED** unowned all-0; owned `CMD_WR_EN=1 S_GO=1 DMA_AR=1` peak=5 | CDC **one-wire** `cmd_wr_en && m_owner` SHA `A036F216…`; other product MATCH CONTROL | NO | audit 18:42 + XSim verify 18:41 |
| `E2R-OWNER-POP-GATE-00` | **POP_GATED** `DROP_S_GO=0 GRANT_S_GO=1` leftover held | CDC **second wire** `cmd_rd_en && s_owner` SHA `C02F0D54…`; issue-gate kept | NO | audit 19:08 + XSim verify 19:07. Auditor **MAJOR**: live top/tile C-FIX dirt **after** bag seal (not this DUT). |
| `E2R-OWNER-FENCE-CFIX-SNAP-00` | **UNSTABLE** (no xvlog) | inventory vs 19:14 table; **5/6 DRIFT** at 19:19:02 | NO | `AUDIT_E2R_OWNER_FENCE_CFIX_SNAP_00.md` CLEAN UNSTABLE |
| `E2R-OWNER-FENCE-CFIX-SNAP-01` | **ISSUE_GATED** `CMD_WR_EN=0 S_GO=0 FALSE_AR=0` `DMA_ST_PEAK=0` | **snap copies only** CDC `C02F0D54…` + dma; **snap top omitted from xvlog** | NO | audit 19:35 (2 MINOR) + XSim verify 19:35 |

`READY_GATED` is **not** in the STATUS audit filename set. `MASTER_PREFLIGHT` / `AGENT_LANE_SNAPSHOT` (19:39+07) still name **READY-SNAP-00 as the next executable gate**. `DISPATCH_LOG.jsonl` last fence line: READY-SNAP **DISPATCHED** 19:39 (no STATUS `result=PASS` line yet).

### 1.4 Cursor / mailbox bag — READY-SNAP-00 (not STATUS-sealed)

Cursor bag: `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board\results\A7-NATIVE-GRAPH\E2R-OWNER-READY-SNAP-00\`  
Mailbox copies (not under `STATUS/`): `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\E2R-OWNER-READY-SNAP-00\`

| Print | Value |
|-------|-------|
| CLASS | **READY_GATED** |
| OWNED_AR | **1** |
| DROP_AR_ADVANCE | **0** |
| DROP_ST | **4** (AR; did not enter R=5 while `owner_ui=0`) |
| MUX_FALSE_AR | **1** (**informational**; **not** the class input) |
| TOP_ELAB | **slice_not_soc** |
| UNIT_PASS | yes |
| PROGRAM / C_FIX / EXISTENCE | NO / NONE / false |

DUT = SNAP-01 snap CDC + snap `ddr_tile_dma` + bag-local `snap_top_ready_slice` (AND `wdma_owner_ui` on `go` / `arready` / `rvalid`) + bag TB. Stub `arready` 0 until after owner drop, then 1; `rvalid` held 0. Independent bag `AUDIT.md` 19:53 **PASS_NARROW** (3 MINOR).  
**Catalog:** Cursor **RUNS** on snap+slice. STATUS **mailbox not promoted** (`AUDIT_E2R_OWNER_READY_SNAP_00.md` **absent** from `STATUS/`). Do **not** treat as a C-FIX or program license.

### 1.5 Live Cursor `rtl/` — **DIRTY** (do not edit)

`STATUS/DIRT_E2R_OWNER_FENCE_CFIX.md` (19:12+07): **STOP RTL.** Concurrent unlicensed C-FIX.

| File | Sealed POP CONTROL | DIRT 19:12 | HOLD / SNAP-01 / live @ READY audit 19:53 |
|------|--------------------|------------|------------------------------------------|
| `a7ng_wdma_cdc.sv` | `C02F0D54…` | **`FF66D000…` DIRTY** | **`C02F0D54…` MATCH HOLD** (19:19:02) |
| `arty_a7_ng_native_v1_ab_soc_top.sv` | `8298376E…` (never in git) | **`FC4C0467…`** (via `3C2BE8B4…` at 19:10) | **`3C2BE8B4…` MATCH HOLD** |
| `weight_tile803k.sv` | `A4E5FEAC…` git HEAD | **`5A76AD69…`** | **`9EE30702…` MATCH HOLD** |
| `ddr_tile_dma.sv` | `20BAE36E…` | MATCH | MATCH |
| `tiny_gpt803k_core.sv` | — | drifted in SNAP-00 table | `355182A7…` HOLD |

DIRT 19:12 is **stale vs 19:19 HOLD restore** (READY-SNAP auditor). Live tree at 19:53 **EQ snap HOLD**, still **DIRTY vs git / 140345e** (unlicensed fence wires in product RTL).  
SNAP-01 snap top **text** (hashed, not xvlog'd until slice extract): `.go(dma_go && wdma_owner_ui)`, `.m_axi_arready(arready && wdma_owner_ui)`, `.m_axi_rvalid(rvalid && wdma_owner_ui)`. Comment `E2R-OWNER-FENCE-CFIX`.  
**Do not stack another implementer. Do not program this dirt.**

### 1.6 Grok-orch `140345e` product RTL — **CLEAN base / ungated CONTROL law**

Text inspection (this survey; no hash run):

- `a7ng_wdma_cdc.sv:96` `cmd_wr_en = m_rst_n && m_go && !cmd_full` — **P0-A open**
- `cmd_rd_en` — `s_owner` **absent**
- top `u_wdma`: `.go(dma_go)`, `.m_axi_arready(arready)` raw — **P0-B open**
- tile `D_GO`: `dma_go <= 1'b1` — no grant AND

No `tb_e2r_owner_*` in this checkout. Independent fence TBs live on Cursor bags / STATUS copies.

### 1.7 Catalog summary (P0-A / P0-B)

| Item | Seal | Notes |
|------|------|-------|
| P0-A static + AB_COMPOSE XSim | **SEALED** | CONTROL `FE13D1BB…` |
| P0-A issue-gate XSim (`m_owner` on `cmd_wr_en`) | **SEALED PASS_NARROW** | CDC `A036F216…` then POP `C02F0D54…` |
| P0-A pop-gate XSim (`s_owner` on `cmd_rd_en`) | **SEALED PASS_NARROW** | leftover-then-grant; **not** ready-gate |
| P0-A on SNAP-01 copies (unowned `m_go`) | **SEALED ISSUE_GATED** | xvlog omitted snap top |
| P0-B ready-gate on SNAP-01 xvlog | **SEALED as untested** | `DMA_ST_PEAK=0`; auditor MINOR |
| P0-B `DROP_AR_ADVANCE` / READY_GATED | **CURSOR-LOCAL / STATUS-UNKNOWN** | bag CLASS=READY_GATED; STATUS still “next gate” |
| Live Cursor product RTL | **DIRTY** | HOLD SHA ≠ git; ≠ 140345e |
| Grok-orch `140345e` RTL | **CLEAN ungated** | matches CLASS CONTROL law |
| Silicon P0-A/B as hang root | **UNKNOWN** | XSim ≠ LONGBOOT |
| C-FIX / bitstream of fence | **NONE licensed** | CLASS.md: one law later; DECIDE required |
| `pred=664` | **UNKNOWN / absent** | existence still open |

---

## 2. LONGBOOT STILL_STALL facts (2470 s, pred absent)

Authority pointer: `STATUS/E2R_UART_HOLD_LONGBOOT_00_RUN_CLOSEOUT.md` → board bag  
`D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board\results\A7-NATIVE-GRAPH\E2R-UART-HOLD-LONGBOOT-00\RUN_CLOSEOUT.md`  
Official bag closeout: same folder `CLOSEOUT.md` (PROGRAM=YES / CLASS=`STILL_STALL`). Bag `CLOSEOUT.md` PREP text is **not** this run (`STATUS/E2R_UART_HOLD_LONGBOOT_PREP_CLOSEOUT.md`).

```text
CLASS=STILL_STALL
ELAPSED_S=2470
UART_BYTES=593
CORE_DONE=false
pred=664 absent
EXISTENCE=NO
BOARD_PASS=not_claimed
C_FIX=NONE
```

| Field | Value |
|-------|-------|
| START / END | 2026-08-29T14:38:41+07 → 15:19:52+07 |
| ATOM1 | elapsed_s=**69.890**; then hold **2400 s** (`hold_after_atom`) |
| STOP_REASON | `hold_after_atom` (max 2700 not hit) |
| ATOM0 | `0000059C` dest=4 owner=1 grant=1 idle=0 latch=0 sticky=1 w_stall=1 core_done=0 mgo=1 |
| ATOM1 | `0000059D` dest=5 (other bits same) |
| UART last | `W_STALL` / `PHASE=01` (`uart_longboot.txt` L64–65) |
| Also printed | `WDMA_GRANT=0` `RPATH_IDLE=0` `MGO=1` `CMD_EMPTY=0` `SBUSY_PEND=1` `CMD_ST=2` `CMD_RD=1` |
| PRED_LINES | **NONE** |
| Bit SHA | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` (`E2R-ATOMIC-SDONE-PROBE-00` SDONE probe; BUILD not rewritten) |
| JTAG | `210319BE776EA` programmed (`End of startup status: HIGH`) |
| UART | COM12 `210319BE776EB` 115200 armed **before** program |
| Authorize | `com12_authorized_gate=E2R-UART-HOLD-LONGBOOT-00` **consumed** |
| Stale tcl `puts` | `PROGRAM not executed this gate` — **ignore**; Labtools programmed |

`uart_longboot.txt` SHA256 `E5870ED1…` 593 B / 65 lines. Matches REARM control ATOM hex and class.

**Do not re-run LONGBOOT.** Do not treat leftover REARM as a second license.  
Observer/truncation (300 s too short) **not supported** on this 2470 s window.  
UART `MDONE`/`SDONE` and grant bits are **non-atomic print-time**; CLASS.md retracts “slave never done.” ATOM `grant=1` vs later `WDMA_GRANT=0` is **snapshot conflict**, not a second experiment.

STATUS “NEXT” after LONGBOOT named `E2R-EMB-TWO-PASS-00` (PROGRAM=NO until new authorize). Two-pass EMB **does not patch P0-A/B/C/D**. Bit `15B0E502…` is inventory, not a hang-fix license.

---

## 3. What Cursor XSim already showed

Composition vehicle unless noted: stub slave, n small, **not MIG**, **not LONGBOOT waveform**.

### 3.1 AB_COMPOSE (CONTROL ungated) — STATUS sealed

- Unowned `m_go` → hierarchical `cmd_wr_en=1` → `s_go=1` → DMA AR (`st=4`) with `wdma_owner_ui=0` and mux `arvalid==cdc_arvalid` → `FALSE_AR=1` → next `s_clk` `st=5` (R).
- `CLASS=AB_COMPOSE`. Live bag `xsim_stdout.txt` may now show later `A_ONLY` overwrite; sealed prints live in `xsim_stdout_implementer.txt` + STATUS verify 18:23.

### 3.2 ISSUE_GATED — STATUS sealed (product one-wire + SNAP-01 copies)

- **ISSUE-GATE-00:** unowned pulse does not enqueue; owned pulse does (`OWNED_*` 1, peak 5). CDC `A036F216…`.
- **SNAP-01:** unowned `m_go` on snap CDC `C02F0D54…` (`cmd_wr_en && m_owner`) → `CMD_WR_EN=0 S_GO=0 FALSE_AR=0 DMA_ST_PEAK=0`. Ready-gate **TB-copied, not elaborated**. `DBG_M_GO_STICKY=1` with `CMD_WR_EN=0`.

### 3.3 POP_GATED — STATUS sealed (not P0-B)

- Enqueue while owned, drop owner, leftover `cmd_empty=0`, `DROP_S_GO=0`, DMA stays IDLE; re-grant → `s_go` + DMA AR/R. CDC `C02F0D54…`.
- Does **not** license ready-gate / P0-B.

### 3.4 READY_GATED — Cursor bag only (P0-B discriminator)

- SNAP-01 never reached DMA AR, so ready-gate untested there.
- READY-SNAP-00: owned start into AR (`OWNED_AR=1`, stub `arready=0`), drop owner, raise stub `arready=1`, `rvalid=0`.
- Discriminator = **`DROP_AR_ADVANCE`** (DMA leaves AR while `owner_ui=0`), **not** mux-law `FALSE_AR`.
- Result: `DROP_AR_ADVANCE=0` `DROP_ST=4` `CLASS=READY_GATED`. `MUX_FALSE_AR=1` occupancy while still in AR.
- `TOP_ELAB=slice_not_soc`. Auditor MINOR: no same-protocol ungated CONTROL on this TB (AB_COMPOSE is different stimulus).
- STATUS `MASTER_PREFLIGHT` has **not** consumed this bag.

### 3.5 Explicitly not shown (Cursor or STATUS)

- Full SoC / MIG / tile / core in xvlog
- Silicon MIG `arready` while unselected
- LONGBOOT same-cycle occupancy
- Owned issue still live on **live dirty rtl/** at an instant after 19:12 DIRT
- P0-C level-`m_go` FIFO multiply
- P0-D quiesce-before-drop
- Existence / program license

---

## 4. What Grok-orch may XSim on `140345e` WITHOUT touching Cursor tree

**Allowed (this worktree only, `PROGRAM=NO`, no `rtl/` write unless a later human gate names it):**

1. **CONTROL replay of P0-A/B (highest leverage).** Product RTL **is** the ungated CLASS CONTROL. Copy TBs into `results/A7-NATIVE-GRAPH/GROK-ORCH-00/` (not Cursor). xvlog **this tree’s** `rtl/board/a7ng_wdma_cdc.sv` + `rtl/ddr/ddr_tile_dma.sv` + bag TB mux copy. Expect **AB_COMPOSE** if the vehicle matches XSIM-00 (unowned `m_go`, stub `arready=1`). Independent of Cursor dirt.
2. **Bag-local snap copies** of SNAP-01 / READY-SNAP sources **copied into this tree’s results/** (byte copies; do not xvlog Cursor `rtl/`). Independent ISSUE_GATED / READY_GATED **re-run** on frozen snap SHA table. Does **not** prove live Cursor silicon.
3. **Same-protocol ungated CONTROL for `DROP_AR_ADVANCE`** (READY-SNAP auditor MINOR). On `140345e` raw `.m_axi_arready(arready)`, repeat owned-AR → drop → raise stub ready. Predict **READY_OPEN** (`DROP_AR_ADVANCE=1`) if P0-B composition is real. Fills the CONTROL gap **without** editing Cursor.
4. **Docs / encoder H5 ungated DIFF twin research** on MAIN `results/A7-EAM-03E` (read-only). Not this existence hang.
5. **Propose one ownership law** on paper. **Not** merge into Cursor dirty tree.

**Forbidden this lane:**

- Edit `rtl/` in Cursor **or** (this survey) Grok-orch product RTL
- `open_hw_manager` / `program_hw_devices` / COM12 / JTAG
- Re-run LONGBOOT; program `9DC0F8DF…` or two-pass `15B0E502…` as hang-fix
- xvlog live Cursor `rtl/`
- Steal `lock.owner`
- Task `graph_late_materialize_00` as existence
- Dual-read / pin-POS / `SIM_FULL=1` on silicon
- Touch frozen 01R / 02M / LM-06 / A0.3
- Declare `BOARD_PASS` / existence from XSim
- Mix 744 / 664

Grok-orch has **no** owner-fence TBs yet — first XSim needs a bag-local TB copy, not a product patch.

---

## 5. Board timeshare — Grok must not `open_hw_manager`

One Arty A7-100T:

| Port | ID |
|------|----|
| JTAG | `210319BE776EA` |
| UART COM12 | `210319BE776EB` |

| Window | Owner | Allowed |
|--------|-------|---------|
| Until UART `pred=664` | **Cursor** on `arty-a7-online-lm-board` | Fence XSim; program **only** with a **fresh** `com12_authorized_gate`; arm COM12 first |
| Grok this tree | Grok-orch | **XSim / docs / encoder research.** `PROGRAM=NO` |
| After `NATIVE_V1_EXISTENCE_BOARD_PASS` | Human names next token | Encoder silicon / Kidi / A1 — **not** before |

LONGBOOT authorize is **consumed**. `MASTER_PREFLIGHT`: **PROGRAM=NO.**  
Grok **must not** `open_hw_manager` while Cursor holds the board (even if Vivado is “idle”). No second target; PYNQ refused on LONGBOOT.

---

## 6. Next unknown (catalog, not a dispatch)

STATUS executable line still:

> **E2R-OWNER-READY-SNAP-00** — XSim P0-B on SNAP-01 copies: owned start into AR, then drop owner. Discriminator = `DROP_AR_ADVANCE`. No `rtl/` edit. PROGRAM=NO.

Cursor already produced that bag (`CLASS=READY_GATED`). Mailbox `STATUS/` has not filed `AUDIT_E2R_OWNER_READY_SNAP_00.md` or moved `MASTER_PREFLIGHT`.

Grok-orch useful next (no Cursor touch, no program):

1. Independent AB_COMPOSE + optional READY_OPEN CONTROL on `140345e` ungated RTL (fills auditor MINOR).
2. Do **not** C-FIX. CLASS.md: **one** ownership law after A+B XSim, still needs DECIDE + new `com12_authorized_gate`.
3. Do **not** re-LONGBOOT.

Existence remains **open**: `pred=664` **absent**.

---

## Sources (absolute)

- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\STATUS\MASTER_PREFLIGHT.md`
- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\STATUS\AGENT_LANE_SNAPSHOT.md`
- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\STATUS\DIRT_E2R_OWNER_FENCE_CFIX.md`
- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\STATUS\E2R_OWNER_FENCE_CLASS.md`
- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\STATUS\E2R_UART_HOLD_LONGBOOT_00_RUN_CLOSEOUT.md`
- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\STATUS\AUDIT_E2R_OWNER_FENCE_CFIX_SNAP_01.md`
- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\STATUS\E2R_OWNER_READY_SNAP_00_PREREG.md`
- Plus STATUS audits/verifies for XSIM-00 / ISSUE / POP / SNAP-00; `DISPATCH_LOG.jsonl`
- Board LONGBOOT `RUN_CLOSEOUT.md` / `CLOSEOUT.md` / `uart_longboot.txt`
- Board READY-SNAP `CLOSEOUT.md` / `RESULTS.md` / `AUDIT.md`
- `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\research\NATIVE_AI_GROK_ORCH_LANE.md`

**Not hashed this session:** live Cursor `rtl/` (rely on 19:53 auditor table). **Not run:** xvlog/xsim/program.
