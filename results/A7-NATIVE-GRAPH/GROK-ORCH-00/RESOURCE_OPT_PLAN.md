# Resource optimization — grok-orch lane (research only)

**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e`  
**PROGRAM:** NO unless human names `com12_authorized_gate` for **existence**, not QoR.  
**Authority reused:** `A7-NATIVE-V1-RESOURCE-BALANCE-PLAN-00` (`PLAN_COMPLETE_PARETO_FOUND`, 2026-08-24)

Board trống **không** đổi luật: LUT/BRAM tối ưu bằng **Vivado P&R**, không bằng JTAG. Arty trống nên dành cho **UART `pred=664`**, không cho DSE tài nguyên.

---

## 0. Số đã đo (đừng tối ưu ảo)

Device XC7A100T: LUT 63400 · FF 126800 · BRAM36 **135** · DSP 240.

| Build | LUT | FF | BRAM36 | DSP | WNS | Class |
|-------|-----|----|--------|-----|-----|-------|
| Native existence SoC (two-pass POST_ROUTE) | **54314** (~86%) | 56693 | **103** | (low) | **+0.534** | FACT `AUDIT_E2R_EMB_TWO_PASS_00_POST_ROUTE` |
| LA Pmod observe bit (earlier) | ~55k | — | **103** | 19 | +0.37 / core +9 | FACT session |
| LM-06 C1 **alone** | 37.6k | 35.9k | **132** | 154 | +0.179 | FACT envelope; Slice ~95% |
| Late-mat OOC | 142 | 559 | 0 | 0 | — | FACT independent |

**Kết luận envelope:** Native SoC **đã fit**. BRAM 103/135 = YELLOW-GREEN. LUT ~86% = YELLOW-RED (đầu cho thêm logic). Bottleneck đóng dự án **không** phải “hết BRAM” — là **existence hang** (`pred=664` absent).

Additive GRAPH+LM **243 BRAM = FALSIFIED**. Luật đúng: `peak = max(B_ENC, B_GRAPH, B_LM)` ≤ **130 soft / 135 hard**.

---

## 1. Board trống — dùng thế nào

| Việc | Cần Arty? | Làm trên grok-orch? |
|------|-----------|---------------------|
| LUT/BRAM/WNS DSE | **Không** — chỉ P&R | Có (OOC / synth) |
| UART `pred=664` | **Có** | Không — Cursor/token existence |
| Joulescope / tok/s | Có, **sau** 664 | Không now |
| Dual-buffer POS 16 KB | P&R + silicon | **Cấm** now (P0 fence + BRAM) |

**Phương án tối ưu thời gian board trống:**  
1) Cursor xong OPEN-CTRL XSim → freeze SHA fence → **một** token program existence.  
2) Grok-orch **song song** (không JTAG): OOC/resource notes dưới đây.  
3) Không program leftover `9DC0F8DF` / `15B0E502` “cho có số util”.

---

## 2. Ngân sách được phép hy sinh (đã đóng)

Correctness **không** đụng: Top-K exact, FPGA token, `host_next_token=0`, LM-06 law, pred golden **664** vs **744**.

Latency **được** tăng: +25%…+100% cycles nếu chain thật (`EXISTENCE_BEFORE_QUALITY`).

---

## 3. Hàng tối ưu — ranked cho nhánh này

Làm **một unknown / một gate**. Không dual-read. Không `SIM_FULL=1` silicon.

### T0 — Existence-compatible (làm trước, rẻ LUT)

Giữ SoC ≤ ~55k LUT / 103–110 BRAM khi vá fence.

| Làm | Không làm |
|-----|-----------|
| Issue/pop/ready-gate (vài LUT + FF) | Pin POS 4×RAMB36 |
| `D_WAIT_GNT` nhỏ | `ram_style=block` trên `line_wr` (đang registers, 128 B) |
| Two-pass **lịch** ST_EMB (0 BRAM) | Dual-port `need_b` (C0 oscillation) |

**Hiệu ứng:** 151 MB EMB → ~144 KiB nếu two-pass **sau** fence sống. Không phải QoR LUT.

### T1 — LOW risk, **sau** 664 (host P&R, không cần board)

Từ `EXPERIMENT_LADDER` / Pareto:

1. **C3 snap→LUTRAM** (−2 BRAM, ~875 LUT/BRAM OOC). Fullchip OPEN. Gate sẵn `LM06-SNAPSHOT-LUTRAM-01`.  
2. **FIFO depth = peak occupancy+1** (hls4ml-style). SLICEM, không BRAM 103.  
3. **QoR Explore / AggressivePacking** trên **cùng RTL existence** — WNS≥0 TNS=0, pred không đổi.

Pass: WNS≥0 TNS=0 BRAM≤135, **không** đổi law.

### T2 — MEDIUM, sau C3

- **C2 pingpong lifetime** BOARD weight 32→16 nếu `both_live=0`.  
- **C4 act lifetime** (`LM06-WM-TRACE-00` — `M_peak` vẫn MISSING).  
Không pack lại `LM06-BOARD-WEIGHT-PACK-01` (**NO_PACK_GAIN**).

### T3 — HIGH leverage, **sau** existence + exclusivity

**C8 GRAPH↔LM phase-share** (`bram_owner_00`). BLOCKED cho đến drain/outstanding=0. Đây là chỗ lấy lại 100+ BRAM ảo (max vs sum). Không task `graph_late_materialize_00` như existence.

### T4 — CẤM / FALSIFIED

| Ý | Lý do |
|---|--------|
| Cộng 01R+02M+LM BRAM | 243/260/264 illegal |
| C0 −34 BRAM dưới frozen LM-06 | FALSIFIED recipe |
| Dual-buffer POS now | BRAM + C0 port B |
| Encoder ungated DIFF để “nhẹ SoC” | NO-GO 11/11 @ 100k |
| Ép LUT 87→75 bằng `ram_style=block` line buffers | Đổi topology, không evidence |

---

## 4. Việc grok-orch làm **ngay** (không board)

1. Ledger SoC existence: LUT 54314 / BRAM 103 / WNS +0.534 làm **CONTROL** cho mọi C-FIX fence.  
2. Ước delta LUT của ready-gate + `D_WAIT_GNT` (OOC `weight_tile803k` + `a7ng_wdma_cdc` trên **cây này** @ `140345e` ungated — so CONTROL, không merge Cursor dirty).  
3. Không synth full MIG trên grok-orch trừ khi human mở (tránh CWD mix).  
4. Không mở `bram_owner_00` / pingpong.

---

## 5. Pareto nhớ (không score)

Best BRAM/cost còn mở: **C3 −2**.  
Best architecture: **C8 phase max**.  
Dominated: lane-cut không đổi topology; DDR-back working set trước khi đo B/query.

---

## 6. Quyết định orchestrator

**Tối ưu tài nguyên ≠ dùng board trống.**  
Board trống → **existence token**.  
Nhánh mới → **nghiên cứu T0/T1 trên giấy + OOC**, không program QoR bit.

Existence SoC **đã nằm trong envelope**. Cắt BRAM lúc này không đóng `pred=664`.
