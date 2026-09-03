# E2R-CORE-START-RST-PROBE-00 RTL audit (Steps A–C)

**PROGRAM=NO until unique bit SHA exists.** No GATE14_PASS / BOARD_PASS / EXISTENCE_PASS.

Module: `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv`

---

## Step A — sticky probe (first draft vs required semantics)

The bag already contained a 4-marker bank on `CLK100MHZ` / `btn[0]`. Audit found it **could not honestly classify Case 1**. Patched before synth.

### A1. Sticky survival across `clk_locked` drop

| Item | First draft | Required | After patch |
|------|-------------|----------|-------------|
| Probe FF clock | `CLK100MHZ` (board osc) | board osc, independent of MMCM | same |
| Probe FF reset | `btn0_100` only | not `clk_locked`, not `core_rst_n` | same |
| Inputs to edge counters | raw `clk_locked`; `core_rst_n_100` / `calib_100` from `sync_bits` with **`rst_n=clk_locked`** | 2FF, `rst_n=1'b1` | dedicated `u_lock_probe_100`, `u_crst_probe_100`, `u_calib_probe_100` |

`CLK100MHZ` is MMCM `CLKIN1` (`clk_arty_ddr` / `clk_core_12p5`). If the oscillator **stops**, the debug bank also stops — unobservable. If MMCM unlocks while CLKIN still runs, the bank keeps counting. That is the intended paradox bound: we can see lock loss, we cannot see CLKIN death.

UART `u_tx.rst_n = clk_locked` and `sent_mask` clear on `!clk_locked`. During a real lock drop, TX stops; after relock, BOOT reprints; probe stickies still hold.

### A2. False `f` / false MIG overwrite (first-draft bug)

`u_core_rst_100_sync` and `u_stat_sync` (feeds `calib_100`) use `rst_n=clk_locked` (`sync_bits.sv` lines 12–14: `if (!rst_n) meta/sync_out <= 0`).

Lock drop ⇒ those syncs **force 0** even if the source had not yet fallen in its own domain. Sequence:

1. `lock_d && !clk_locked` ⇒ `RST_CAUSE=4`
2. `core_rst_n_100` forced 0 ⇒ `crst_d && !core_rst_n_100` ⇒ **`f` increments (fake)**
3. Relock: `calib_100` still 0 for two cycles while `calib_d` is 1 ⇒ `RST_CAUSE=2` **overwrites LOCK**

Case 1 would present as MIG. Probe was not a discriminator until this was removed. Probe now samples `core_rst_n` (combo) and `calib` (MIG) with `rst_n=1'b1`.

`core_rst_n_q` (registered on `core_clk`) is **not** used: if `core_clk` stops on PLL unlock the registered copy freezes high and misses the fall.

### A3. `n` / `f` double-count

First draft sampled raw `clk_locked` on `CLK100MHZ` (LOCKED is async to fabric). Metastability can extra-edge `n`. Patch: 2FF (`ASYNC_REG` in `sync_bits`) then `lock_d` vs `lock_s`. Saturate at `8'hFF`.

### A4. `RST_CAUSE` priority

First draft last-write-wins in one `always_ff` (LOCK, then CRST, then MIG). Trailing calib/core_rst after a lock drop overwrote 4.

Patch: `if (lock_fall) CAUSE=4; else if (CAUSE != 4) { MIG if calib_fall && lock_s; else CRST if crst_fall }`.

`CAUSE=1` (BTN) is unreachable while `btn[0]` is the wipe. Do not press BTN0 on the silicon run.

### A5. BTN wipe vs UART emit

`btn[0]` is also **unsynchronized MMCM `RST`** on both `clk_arty_ddr` and `clk_core_12p5`. A press wipes stickies **and** unlocks both MMCMs. Silicon protocol: hands off the buttons.

On wipe, `start_tog_d <= start_tog_100` so a frozen toggle does not re-set `START_SEEN`.

### A6. `START_SEEN` ≠ `core_ran`

First draft: `core_ran` set on any cycle with `core_rst_n=1`, cleared on `!core_rst_n`. That is “reset was released”, already covered by `RST_REL`.

Spec: `START_SEEN` = START actually seen in the **core domain**.

Patch: toggle on `start_q` (1-cycle, `core_clk`, no `core_rst_n` reset) → 2FF to 100 MHz → edge detect → sticky. This is a toggle synchronizer, not a stretched pulse.

---

## Step B — `sent_mask` writers / reset (RTL, not README)

**Declaration:** `logic [74:0] sent_mask;` in `arty_a7_ng_native_v1_ab_soc_top.sv` (UART bank).

**Always block:** `always_ff @(posedge CLK100MHZ)` — **synchronous** reset, not async.

**Reset condition (only clear of the whole bank):**

```text
if (!clk_locked) begin
  ...
  sent_mask <= 75'd0;
```

`clk_locked` is `clk_arty_ddr.locked` (`MMCME2_BASE.LOCKED`), MMCM `RST=btn[0]`.

**Writers:**

1. Reset branch: `sent_mask <= 75'd0` when `!clk_locked`
2. `UT_NL_IDLE`: `sent_mask[msg_sel] <= 1'b1` after a line + `0x0A`

No other assignment. `core_rst_n` does not appear in this block.

**UART TX:** `uart_tx #(.CLK_HZ(100_000_000), .BAUD(115200)) u_tx (.clk(CLK100MHZ), .rst_n(clk_locked), ...)`

### Proofs

- **`core_rst_n` alone cannot reprint `BOOT`.** The only clear of `sent_mask[0]` is `!clk_locked`. Owner/query FSM reset does not touch this bank.
- **`clk_locked` drop can reprint `BOOT`.** Next `CLK100MHZ` edge with `clk_locked=0` zeros `sent_mask`; after relock `hb_next` returns 0 (`BOOT`) because `!mask[0]`.
- **GSR / JTAG program** also zeros every FF (`n` restarts at 0 then first lock → `n=1`). That is the arm-then-program concat caveat, not an in-bitstream lock drop.

`have_pending` / `hb_next` never clear bits; they only skip already-sent lines.

---

## Step C — START path (exact)

**Correction vs workorder wording:** `start_q` is **not** generated in 100 MHz and CDC’d into core. UART `CORE_START` is 100 MHz; `start_q` is core-domain.

### UART `CORE_START` (100 MHz, not consume)

```text
core_live_100 = calib_ui_100 && wmem_100 && boot_ui_100
hb_next: core_ok && !mask[4] → sel 4 "CORE_START"
```

Sources are `sync_bits` into `CLK100MHZ` with `rst_n=clk_locked`. This marker does **not** prove `start_query_i` was sampled.

### Owner FSM → pulse (core_clk)

Clock: `core_clk` (`clk_core_12p5`, 12.5 MHz). Reset: `core_rst_n`.

```text
core_rst_n = core_pll_locked && calib_core && boot_done_core && wmem_done_core
```

`{wmem_done, boot_done, calib}` → `sync_bits` `u_boot_core_sync` (clk=`core_clk`, rst_n=`core_pll_locked`).

```text
QS_IDLE      if (boot_done_core) → QS_WAIT_OWN
QS_WAIT_OWN  if (owner_ready)    → QS_START
QS_START     start_q <= 1; qs <= QS_WAIT_SOA     // one cycle, then start_q<=0
```

Pulse width: **1 `core_clk` cycle** (80 ns).

### Consume (same domain — no CDC)

`u_ab.clk = core_clk`, `u_ab.rst_n = core_rst_n`, `u_ab.start_query_i = start_q`.

`a7ng_cue_soa_mig_top`:

```text
start_d <= start_i;                  // reset 0 on !rst_n
start_pulse = start_i & ~start_d;    // rising-edge
OWN_IDLE: if (start_pulse) OWN_CLEAR or OWN_WAIT_DRAIN
```

Same clock, 1-cycle high matches the edge detector exactly.

### Race checklist

| Race | Result |
|------|--------|
| START while destination in reset | **Cannot.** `start_q` lives in the `always_ff` reset by `core_rst_n`; `u_ab.rst_n` is the same net. |
| Pulse shorter than dest window | **No**, same domain, 1-cycle = `start_i & ~start_d` window. |
| `CORE_START` UART vs consume | **Yes, independent.** 100 MHz combo can print while owner is still `QS_IDLE` / `QS_WAIT_OWN`. |
| `boot_*` CDC vs `core_rst_n` | Sync `rst_n=core_pll_locked` zeros the three legs until 2 core cycles after lock; then `core_rst_n` rises. Owner comes out of reset with `boot_done_core` already 1 (typical). |

If `START_SEEN=0` after `CORE_START` **and** after the UART delay to print sel 73 (~ms ≫ owner FSM), then either `QS_WAIT_OWN` never saw `owner_ready`, or `start_q` never toggled. That is ranking 2, not 4–6.

Archived `E2R-DDR-TILE-DMA-FSM-PROBE-00` already printed `OWNER_RDY` / `Q_GO` / `PHASE=01` **then** `BOOT`. On **that** bit, START **was** consumed; the first divergence is boot-domain restart, not CORE_START hang. This probe exists to classify the restart (`n`, `RST_CAUSE`) on a **new unique bit** after DONE.

---

## MMCM reset sources (pre-silicon, not yet “why unlocked”)

| MMCM | Module | CLKIN | RST |
|------|--------|-------|-----|
| 100→166/200 | `rtl/ddr/clk_arty_ddr.sv` | `CLK100MHZ` | **`btn[0]` unsync** |
| 100→12.5 | `rtl/board/clk_core_12p5.sv` | `CLK100MHZ` | **`btn[0]` unsync** |

No DRP. `STARTUP_WAIT="FALSE"`. Feedback = `BUFG` of `CLKFBOUT`. `locked` = `LOCKED` pin, no extra fabric.

If silicon returns `RST_CAUSE=4` and `n>=2`, next trace is: why `LOCKED` fell (BTN noise, CLKIN integrity, rail, GSR — not “MMCM unlocked” as a stopping claim). **Do not patch MMCM RST until Case 1 is measured.**

---

## UART_SLIM

Top default `UART_SLIM=1'b1` skips `SOA_OK` / `CORE_START` / owner stream. This experiment **must** synth with `UART_SLIM=0` so sel 4 and sel 71–74 appear after `CORE_START`. Slim would print probes after WMEM, **before** `start_q`, latching `START_SEEN=0` forever.
