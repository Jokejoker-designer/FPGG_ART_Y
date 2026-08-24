# A7-LM-06 lessons — reuse for A7-LM-07

**Status:** frozen after C3 BOARD_PASS (2026-08-19)  
**Close bit:** `build/out/arty_a7_lm06c3.bit` SHA `222F8043…` WNS +0.359  
**LM-07:** authorized by timing, **not opened** in this file.

This is the operating memory from C0–C3. Copy the rules, not the 803k numbers.

## 1. What actually closed

`ARTY_A7_803K_DDR_SCALE_LM_BOARD_VALIDATED` is scale + host-compare oracle, not 8-class CE.

Silicon C3 conjunctive gates (do not drop any of these on LM-07):

| Gate | C3 value |
|------|----------|
| K257 → K511 → K513 | first issue, fold exact |
| upload spots | TOK / POS / L0–L3 / HEAD / last |
| fold0 | xor=5 add=94638317 |
| one_full | pred=744 loss=16 wr_n=655616 |
| fold1 | xor=23 add=94627297 wr_n=655616 |
| four layers | each start line moved and matched oracle |
| persist 802816 | flush **and** reload A6, xor=23, no under/berr/rerr |
| reload fold | equals fold1 |
| AFTER | wr_n unchanged |
| timing | WNS ≥ 0 TNS = 0 to close; ≥ +0.20 to authorize next law |

C1 flush-only was **not** a close. Leftover A6 / leftover `persist=true` is not reload-complete.

## 2. Candidate ladder (keep every fail)

| Cand | Bit | Result | Keep |
|------|-----|--------|------|
| C0 | stall-fail | upload hang @131072 (tile miss oscillation) | `hardware_c0/` |
| C1 | `arty_a7_lm06.bit` `67C37DD5…` WNS +0.179 | all train gates PASS; **reload A6 never returned** | `hardware_c1/` |
| C2 | `arty_a7_lm06c2.bit` `EDAAF120…` WNS +0.120 | train gates PASS; **flush A6 null** (regression) | `hardware_c2/` |
| C3 | `arty_a7_lm06c3.bit` `222F8043…` WNS +0.359 | `hardware_pass=true` | `hardware_c3/` |

Rules that saved the close:

- New candidate = new bit name + new `hardware_cN/` + new manifest. Never overwrite a recorded ladder.
- Lock previous bit SHAs in the next `build_*.tcl` and in the ladder `static_checks`.
- Official close filename need not be `arty_a7_lmNN.bit`. C1 already occupied that name. Close is C3.
- PowerShell has no `cd /d`. Use `Set-Location`.

## 3. Silicon debug that worked

Vivado 2026.1 **BASIC** cannot ILA / `create_debug_core`. Hardware Manager will say “no supported soft debug core(s)”. Do not spend a candidate on a debug bit.

What worked:

- UART peek (`0x58` / ILA-map bits on clk50): persist bst/dst/ch, tile bst/dst/rg, `wdma_owner`, `p_busy`, `dma_busy`, `w_stall`.
- Hang signature: `persist=true busy=true`, A6 never returns, bytes stuck.
- C1 mid-reload peek: persist STORE, tile REQ HEAD miss, `mem_addr=0` (TOK). That is dest/mux deadlock, not “DDR broken”.
- Do not treat a later IDLE peek on a **different** bit as C1 close.

## 4. Sim vs silicon (the expensive gap)

`SIM_FULL=1` (core `tb_a7lm06`) is a 1M behavioral W with **stall=0**. It cannot see tile-miss hangs. It still must stay green so fold/train law does not regress.

The hang that blocked close only appeared when:

- `SIM_FULL=0` (one 131072 region), **and**
- persist reload while the tile was parked on another region (HEAD), **and**
- mock/MIG **ignores `go` while not IDLE** (same as `ddr_tile_dma`).

Mandatory before programming a persist-touching bit:

1. Core xsim (`A7LM06_XSIM_PASS` / LM-07 equivalent).
2. Persist-reload TB: park HEAD (or last region), pulse reload, require dest ACK + at least one real tile miss + ≥2 persist chunks. Do **not** wait the full param count in xsim.
3. Park protocol: set `host_addr`, **clock ≥2 cycles**, require `stall=1`, then wait stall clear, then check `cached_rg`. Setting addr and immediately `wait !stall` returns on the old hit.

A TB PASS that only used `mem_sel=0` during B_REQ did **not** match silicon flush. TB mux must match the board mux.

## 5. DMA / dest rules (copy these)

C1 root cause, confirmed:

- Dest IDLE computed `busy && owner`. Dest is IDLE ⇒ `owner=0` ⇒ `busy` looks 0 ⇒ dest pulses `go` into a still-busy MIG. MIG drops `go`. Dest sits in DRAIN. Persist stays B_REQ/STORE forever.
- Persist STORE waited a TOK miss. Tile dest could not refill because persist owned the DMA mux.

C3 rules that closed it:

1. **Mux:** tile-W > persist > tensor (`wdma_owner` first).
2. **Busy into tile dest and persist dest:** raw `dma_busy` / `dma_done`, not AND-owned.
3. **Dest D_IDLE:** `req && !dma_busy && !tile_hold` (persist). Tile dest: `req && !dma_busy`.
4. **Dest D_GO:** hold `dma_go=1` until `dma_busy` rises, then FEED/DRAIN. One-cycle `go` can miss MIG IDLE.
5. **Persist dest** captures `is_flush` / addr when leaving IDLE (clk50 → ui_clk).
6. **Reload after WAITACK:** `B_TOUCH` (we=0, wait `!stall` ~2 cycles) then STORE. Matches UART 0x30 preload.
7. **Mem port:** `p_busy` for the **whole** persist op (FILL/REQ/TOUCH/STORE). Do not drop the port in B_REQ.

C2 `mem_sel` (only FILL/TOUCH/STORE) is the known regression: B_REQ released the tile onto the last UART address (layer-3 probe). Every persist chunk became a 131072-byte refill. Flush never returned A6 in 300 s. xsim did not see this because the TB host addr was HEAD, not a mid-probe UART leftover — until we matched muxes.

First reload B_REQ may still present `mem_addr=0` and miss TOK if the tile is on HEAD. That **one** refill is OK. A refill **per chunk** is a hang.

Tensor may still see owner-gated busy. Do not copy that gating onto tile/persist dest.

## 6. Packing (do not copy 06 numbers)

LM-06 lock (`A7-LM-06-TILE.md`): one 131072 INT8 W region (32 BRAM), act 8·C·D INT16 (64 BRAM), snap 4096 INT16 (2), tensor+MIG ~34, **~132 / 135**.

PROGRAM LM-07 geometry (not a TILE lock):

```text
V=2048 C=128 d=160 L=4 H=5 d_ff=320
P = 2Vd + Cd + L(4d² + 2 d d_ff) = 1,495,040
persist lines = 1495040 / 128 = 11680
```

**INFERRED packing risk (must re-lock before LM-07 RTL):**

- Same act formula 8·C·D INT16: 8·128·160 = 163840 cells → **80** RAMB36 if the 06 mapping holds. 06 had 64. +16 BRAM does not fit in 135 − 32 − 2 − ~34 ≈ 67 remaining.
- W can stay one 131072 INT8 region (32 BRAM). Params grow in **DDR**, not BRAM.
- TOK/HEAD are 327680 B each (2.5 regions). A persist walk crosses more region boundaries than 06. Miss cost is still a full 131072 (or POS-size) refill.
- DSP/LUT budget in PROGRAM is engine-sized, not param-sized. If 1.5M adds tens of kLUT, something leaked out of the tile.

Write `A7-LM-07-TILE.md` and freeze it **before** the first 07 bit. Do not start 07 RTL on the 06 TILE file.

## 7. Timing

| Cand | Post-route WNS | Note |
|------|----------------|------|
| C1 | +0.179 | close-legal, not +0.20 |
| C2 | +0.120 | congestion (16×16 north); flush hang |
| C3 | +0.359 | simpler mem mux; LM-07 authorized |

Do not start the next law on WNS in (0, +0.20). Do not treat mid-route WNS as final.

BASIC license + `route_design Explore` on this part: 25–40 min. Leave the live Vivado job alone; snapshot the log.

## 8. Board ladder

- COM12, 115200, Digilent `210319BE776EA` (JTAG) / UART on FTDI B (`…776EB`).
- Wait calib before any command.
- Persist opcode timeout 300 s is enough when dest works; a hang looks identical to a timeout (`persist_*=null`). Peek FSM if A6 is late.
- After reload, wait the explicit fold. `auto_fold` may be null; compare `fold_reload` to fold1.
- Do not send reload while flush is still `p_busy` (C2 did this after flush timeout and left `persist=true`).
- Refuse overwrite if `hardware_cN/ladder.json` exists.

## 9. LM-07 first-week checklist

Do these before a 07 bit:

1. New `law_id` (geometry changed). Freeze confirmation **before** the quality/hardware ladder.
2. Lock TILE against 135 RAMB36. If act does not fit, shrink/serialize act — do not enlarge W BRAM.
3. Carry C3 dest/mux/TOUCH/`p_busy` as the default. Do not re-introduce owner-masked busy or `mem_sel`.
4. xsim: core law + persist-reload with `SIM_FULL=0` and a parked foreign region.
5. Candidate bits `arty_a7_lm07c0.bit`… Never write over 00–06 frozen bits or `arty_a7_lm06c3.bit`.
6. Close gates = 06 list with 07 oracle numbers. Persist bytes must be **1,495,040**, both directions.
7. Quality (PROGRAM): held-out NLL after < before, ≥10% relative, no saturation. **Do not** close 07 on unguarded CE% like R4. Hardware+oracle may ship first only if the confirmation file says so **before** the run.
8. WNS ≥ 0 TNS = 0 to close 07; do not start 08 on < +0.20 if that remains the house rule.

## 10. Do not do again

- Close on flush without reload + AFTER.
- ILA candidate on BASIC.
- `SIM_FULL=1` as the only persist test.
- Pulse `dma_go` one cycle and assume MIG took it.
- Gate dest `busy` with `owner`.
- Let persist hold DMA while the tile is in miss.
- Drop the persist mem port mid-FSM so UART addr leaks in.
- Overwrite C0/C1/C2 (or 07-cN) ladders.
- Start LM-07 in the same session that only authorized it.

Evidence: `results/A7-LM-06_CLOSEOUT.md`, `hardware_c{0,1,2,3}/`, `docs/contracts/A7-LM-06.md`.
