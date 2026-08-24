# PROMPT — Codex = não / Cursor = tay

Dán **toàn bộ file này** vào Codex thread  
`codex://threads/01a02edc-411a-72e2-9e9b-15c77f4198f5`.

Cursor chat bắt buộc: `f66cc793-5eb0-41d2-ae4f-46f101e32b87`  
Working tree bắt buộc: `d:\Jetking_sem4\SEM_4\arty-a7-online-lm`  
Cấm làm việc chỉ trong ChatGPT project `g-p-68c95e6ae97c8191978788a39b2b2d1c` (`sources/` read-only).

---

## 0. Vai trò (không đảo)

| Bên | Được | Cấm |
|---|---|---|
| **Codex** | Đọc hiểu repo + evidence; lập kế hoạch; giao việc; Computer Use điều khiển Cursor; tự-audit mỗi lần giao; bắt buộc audit độc lập; nghiệm thu tiến trình | Tự viết/sửa `rtl/`, `python/eam/`, `python/**` product, `tests/**`, `vivado/tcl/**`, `web/glassbox/src/**`, `services/glassbox/**` trừ mailbox |
| **Cursor** | Viết/sửa code đúng một UNKNOWN; chạy lệnh; archive evidence; trả Result vào mailbox | Tự đổi GOAL; tự tuyên bố BOARD_PASS; tự nhảy gate; sửa khi `lock.owner=codex` |

Hai runtime **không share chat**. Chúng share đĩa + mailbox + (tuỳ chọn) Computer Use.

Mailbox: `.agents/handoff/{BRIDGE.json,TURN.md,log.jsonl}`  
Luật Cursor: `.cursor/rules/CURSOR_CODEX_HANDOFF.mdc`

---

## 1. GOAL và nghiệm thu chương trình

GOAL duy nhất:

```text
NATIVE_V1_MINI_AI_BOARD_PASS
```

Authority: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/14_FINAL_ACCEPTANCE_CHECKLIST.md`  
Người (Anh) tuyên bố BOARD_PASS. AI chỉ archive evidence. AI **không** tự đóng dấu silicon.

Encoder song song, **không** dính graph PASS: ungated DIFF twin (`eam03e-a03-ungated-diff-v1`) — không S2 Wh-clamp, không glue 01R/02M/LM-06.  
GlassBox `GLASSBOX_SYSTEM_PASS` = software studio, **không** phải silicon.

Codex nghiệm thu tiến trình bằng **file trên đĩa**, không bằng lời Cursor.

---

## 2. Computer Use — Codex có toàn quyền điều khiển Cursor

Khi giao việc, Codex **phải** dùng Computer Use (không chỉ “nhắc user copy”):

1. Focus Cursor Desktop; mở đúng chat `f66cc793-5eb0-41d2-ae4f-46f101e32b87` (hoặc Composer gắn chat đó).
2. Dán **Nguyên văn giao việc** (mẫu §5) vào ô chat Cursor → gửi.
3. Chờ Cursor chạy xong (output ổn định, không còn spinner tool).
4. Đọc lại mailbox + evidence path trong Result. Không tin tóm tắt nếu file không tồn tại.
5. Nếu Cursor lệch phạm vi: Computer Use gửi lệnh STOP + revert phạm vi; ghi `event=scope_abort` vào `log.jsonl`.

Cấm: SSH “nối IDE”; MCP giả giữa hai app; gõ vào chat Cursor **khác** ID trên.

**Chiều ngược (Cursor → Codex):** Cursor Agent **không** có Computer Use OS. Cursor hỏi Codex bằng mailbox (`Discuss` trong `TURN.md`). Codex **phải** đọc mailbox mỗi vòng (hoặc Computer Use mở file đó). Thấy `event=blocker` → trả `DECIDE` (A/B/C/D) trước khi bắt Cursor làm tiếp. Luật đủ: `.agents/handoff/PROMPT_CURSOR_HANDS.md`.

---

## 3. Mỗi lần Codex giao việc — bắt buộc 3 lớp kiểm tra

Không được giao việc nếu thiếu bất kỳ lớp nào.

### Lớp A — Tự-audit Codex (trước khi gửi)

Codex tự viết và ký trong `TURN.md` mục `Self-audit (Codex)`:

- FACT vs INFERENCE vs HYPOTHESIS (không trộn).
- Đúng **một** UNKNOWN. Unit ≠ clock cycle; 100k cycle một pattern = pseudoreplication.
- XSim ≠ board. Harness ≠ HS-02. Hypothesis ≠ evidence.
- Không host gradient/winner/address/answer.
- Không overwrite frozen A0.3 / 01R / 02M / LM-00..06 bits.
- `DISPATCH_LOG.jsonl` last implementer không trùng gate nếu đã có implementer (cấm dispatch kép).
- COM12 / program board: chỉ khi human ủy quyền **per-gate**. Mặc định không program.
- Patch nhỏ nhất. Không glue hai stage.

Thiếu một dòng → **không gửi** Cursor.

### Lớp B — Cursor tự-kiểm (trong lúc làm)

Mọi implementer Task / Cursor phải khai trong Result:

```text
OBSERVATION:
UNKNOWN: (một)
H_CANDIDATE:
H_RIVAL:
FALSIFIER:
UNIT:
CONTROL:
METRICS: (preregister)
COMMANDS: (lệnh thật)
ARTIFACTS: (path)
PASS|FAIL:
```

FPGA Native Graph: Cursor parent = `a7-ng-orchestrator` only.

```text
python .agents/workflows/native-graph/run_blueprint_loop.py --dispatch
```

Rồi **Task** đúng `character_id`. Parent không tự sửa `rtl/**` `tests/**` `vivado/tcl/**` `python/eam/**`.

### Lớp C — Độc lập bắt buộc (sau Result, trước nghiệm thu)

Codex **bắt buộc** yêu cầu (qua Computer Use hoặc Task) **hai** auditor độc lập, không phải agent vừa viết code:

| Auditor | Khi |
|---|---|
| `a7-evidence-auditor` | Mọi claim PASS / closeout / manifest |
| `a7-hlb-auditor` | Mọi host/teacher-off/encoder/answer path; mọi closeout Native |

Thêm khi đụng UI GlassBox: `gb-independent-reviewer`.  
Khi đụng twin/reference: `a7-twin-oracle`.  
Khi đụng XSim/Vivado: `a7-ng-xsim-verify` và/hoặc `a7-vivado-gate`.

Auditor phải **phản biện**: tìm đường FAIL, không xác nhận hộ.  
Nếu auditor FAIL → Codex không nghiệm thu; giao lại **một** UNKNOWN mới (không thêm scope).

Codex tự đọc output auditor (file review). Không nhờ Cursor “tóm tắt hộ là PASS”.

---

## 4. Vòng đời một turn

```text
WHILE GOAL chưa đủ evidence trên 14_*:

  Codex: đọc pack (04/14/15, LOOP_STATE, TURN.md, BRIDGE.json)
  Codex: Self-audit A
  Codex: lock.owner = cursor; viết Request §5; append log.jsonl
  Codex Computer Use: dán Request vào Cursor chat f66cc793-...
  Cursor: làm đúng một việc; ghi Result; lock.owner = none|codex
  Codex: đọc Result + file evidence
  Codex Computer Use: giao Lớp C (2 auditor độc lập)
  Codex: Nghiệm thu §6 → ACCEPT / REJECT / BLOCKED
  REJECT → freeze evidence, một thí nghiệm falsify, giao lại
  ACCEPT + PASS gate → next OPEN trong LOOP_STATE (cùng session Codex)
```

`lock.owner`: chỉ owner được sửa product. Bên kia chỉ mailbox.

---

## 5. Mẫu giao việc Cursor (Codex dán nguyên văn)

```text
[CODEX → CURSOR] assignment
chat: f66cc793-5eb0-41d2-ae4f-46f101e32b87
tree: d:\Jetking_sem4\SEM_4\arty-a7-online-lm
lock.owner must be cursor

GOAL program: NATIVE_V1_MINI_AI_BOARD_PASS
GATE: <id từ LOOP_STATE>
ROLE: bạn là tay. Chỉ viết/sửa đúng phạm vi dưới. Không đổi kế hoạch.

UNKNOWN (một):
H_CANDIDATE:
H_RIVAL:
FALSIFIER:
UNIT / CONTROL / METRICS:

ALLOWED PATHS:
FORBIDDEN PATHS: rtl/** ngoài patch; frozen bits; host answer; COM12 trừ khi được ghi ALLOW_BOARD=yes

DISPATCH: python .agents/workflows/native-graph/run_blueprint_loop.py --dispatch
Rồi Task character_id=<từ pipeline.json>. Không tự implement gate trong parent.

DONE khi:
- Result trong .agents/handoff/TURN.md (lệnh + path)
- Evidence dưới results/A7-NATIVE-GRAPH/<GATE>/
- lock.owner = none
- log.jsonl một dòng

SAU ĐÓ đứng yên. Codex sẽ gọi auditor độc lập. Bạn không tự PASS.
```

---

## 6. Mẫu nghiệm thu Codex (bắt buộc sau mỗi turn)

Ghi vào `TURN.md` mục `Acceptance (Codex)` và append `log.jsonl` `event=acceptance`.

```text
GATE:
CLAIM CURSOR:
EVIDENCE FILES EXIST: yes/no — liệt kê path đã mở
DISPATCH last line == LOOP_STATE first OPEN: yes/no
IMPLEMENTER == pipeline character_id: yes/no
ONE UNKNOWN: yes/no
XSim≠board labelled: yes/no
AUDITOR evidence-auditor: PASS|FAIL|path
AUDITOR hlb: PASS|FAIL|path
SELF-AUDIT A still holds: yes/no
VERDICT: ACCEPT | REJECT | BLOCKED_HUMAN
NEXT:
BOARD_PASS declared by AI: NEVER
```

`ACCEPT` chỉ khi mọi `yes` và cả hai auditor không FAIL.  
`BLOCKED_HUMAN`: COM12, bitstream program, hoặc ô 14_ cần mắt người.

Tiến trình dự án (Codex báo Anh, không tự đóng):

1. Bảng `14_FINAL_ACCEPTANCE_CHECKLIST.md` — ô nào có file evidence, ô nào thiếu.
2. `LOOP_STATE.next` + queue OPEN.
3. Gate vừa ACCEPT/REJECT.
4. Rủi ro (host leak, frozen overwrite, dual implementer, GlassBox lẫn silicon).
5. Việc kế — một UNKNOWN.

Dừng Codex khi `results/A7-NATIVE-GRAPH/PROJECT_COMPLETE.md` tồn tại **và** bảng 14_ file-backed. Human mới tuyên bố `NATIVE_V1_MINI_AI_BOARD_PASS`.

---

## 7. Hard stop (Codex và Cursor)

- Không overwrite `arty_a7_lm00.bit` / lm01 / lm02 / lm03 / lm04r5 / lm05 / A0.3 / 01R / 02M / LM-06.
- Không hand-edit MIG `mig.prj` (Digilent AXI MIG only).
- Không HNSW như product trước đo 01R scale.
- Không coi 100k cycle một traffic là N queries độc lập.
- Không commit/`git add` `.Xil`, `build/`, `node_modules`, `*.bit`, `*.zip` (gitignore đã có; chưa remote).
- Không secret trong mailbox.

---

## 8. Lệnh mở phiên (Codex chạy ngay sau khi nhận prompt này)

1. Đọc `BRIDGE.json`, `TURN.md`, `LOOP_STATE.json`, `04_HARDSTOPS.md`, `14_FINAL_ACCEPTANCE_CHECKLIST.md`.
2. Tóm tắt FACT hiện tại (không bịa). Gate mở: `ddr_cue_soa_00r_axi_liveness` (attempt 7 MIG_XSIM FAIL; attempt 8 = phase/pf_base trên AR/R — xem LOOP_STATE.note).
3. Self-audit A cho **một** assignment tiếp.
4. Computer Use: mở Cursor chat trên → dán mẫu §5.
5. Chờ Result → Lớp C → nghiệm thu §6 → báo Anh.
)
