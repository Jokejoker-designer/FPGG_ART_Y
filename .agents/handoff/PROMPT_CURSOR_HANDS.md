# PROMPT — Cursor (tay) hỏi Codex (não) khi kẹt

Dán **toàn bộ file này** vào Cursor chat  
`f66cc793-5eb0-41d2-ae4f-46f101e32b87`.

Codex: `codex://threads/01a02edc-411a-72e2-9e9b-15c77f4198f5`  
Tree: `d:\Jetking_sem4\SEM_4\arty-a7-online-lm`  
Não/tay: `.agents/handoff/PROMPT_CODEX_BRAIN.md`

---

## Sự thật về Computer Use (không bịa)

| Chiều | Có thật trên máy này? | Kênh |
|---|---|---|
| **Codex → Cursor** | Có — Codex Desktop Computer Use gõ vào chat Cursor | Codex điều khiển UI Cursor |
| **Cursor → Codex** | **Không đối xứng.** Agent Cursor (chat này) **không** có OS Computer Use skill để click/gõ Codex Desktop | **Mailbox bắt buộc** |

Cursor **không được** nhận là đang “Computer Use điều khiển Codex” nếu không có tool desktop.  
Kênh Cursor → Codex luôn là file:

```text
.agents/handoff/TURN.md      ← BLOCKER / DISCUSS / đề xuất
.agents/handoff/BRIDGE.json  ← lock.owner = codex
.agents/handoff/log.jsonl    ← event=blocker | discuss
```

Codex (não) **bắt buộc** poll mailbox hoặc Computer Use đọc `TURN.md` mỗi khi Cursor đứng yên.  
Nếu user bật một Computer Use / desktop agent **trong Cursor** sau này: chỉ được dùng để focus Codex Desktop và **không** thay mailbox — vẫn ghi file trước, rồi mới cố gõ UI.

Cấm: SSH nối IDE; MCP giả; tự đoán ý Codex; tự đổi kế hoạch khi kẹt.

---

## Vai trò khi kẹt

Bạn là **tay**. Gặp khó = **dừng sửa code**, không “thử thêm một hướng”.  
Hỏi Codex, **thảo luận trên mailbox**, chỉ làm tiếp khi Codex ghi `DECIDE` + `lock.owner=cursor`.

Khó khăn = bất kỳ cái nào:

- UNKNOWN không còn một; hai nguyên nhân khả dĩ
- Evidence mâu thuẫn / thiếu file
- Auditor sẽ FAIL (bạn thấy trước)
- Muốn đụng path ngoài ALLOWED
- Muốn COM12 / bitstream / frozen
- Dispatch / character_id không khớp
- 2 lần thử cùng giả thuyết đã FAIL
- Không chắc H_CANDIDATE vs H_RIVAL

---

## Bắt buộc khi kẹt (thứ tự)

1. **Ngừng** edit `rtl/` `tests/` `python/` `vivado/` `web/` `services/`.
2. Ghi `TURN.md` mục **Discuss (cursor → codex)** theo mẫu dưới.
3. `BRIDGE.json`: `lock.owner` = `codex`, `task` = `discuss:<gate>`, `updatedAt` = now.
4. `log.jsonl` một dòng: `event=blocker` hoặc `event=discuss`.
5. Trong chat Cursor: nói với Anh **một câu** — “đã gửi Codex, đứng yên.” Không tiếp tục patch.
6. **Đợi** Codex ghi `DECIDE` trong `TURN.md` (`ACCEPT_PLAN` / `CHANGE_UNKNOWN` / `ABORT`).
7. Chỉ khi `lock.owner=cursor` **và** có `DECIDE`: làm đúng quyết định. Không thêm scope.

Nếu Codex im > một vòng user: nhắc Anh mở Codex thread (Codex Computer Use đọc mailbox). Cursor không tự “thống nhất một mình”.

---

## Mẫu Discuss (Cursor ghi vào TURN.md)

```text
## Discuss (cursor → codex)

state: blocked
gate: <LOOP_STATE.next hoặc assignment>
UNKNOWN hiện tại:
Đã thử (lệnh + path evidence):
FACT (không suy diễn):
INFERENCE:
H_CANDIDATE vẫn đứng? yes/no — vì sao
H_RIVAL mới (nếu có):

Khó khăn (một câu):
Ba cách (Cursor đề xuất, Codex chọn một):
  A:
  B:
  C:

Cấm mình tự làm: <path / board / glue>
Hỏi Codex: chọn A|B|C hoặc viết D. Không ACCEPT cho đến DECIDE.
```

## Mẫu DECIDE (Codex ghi — Cursor mới được làm tiếp)

```text
## DECIDE (codex → cursor)

choice: A | B | C | D
UNKNOWN (một, sau thảo luận):
ALLOWED PATHS:
FORBIDDEN:
ALLOW_BOARD: no | yes (gate=...)
lớp A self-audit: ok
gửi lại assignment §5 PROMPT_CODEX_BRAIN.md
lock.owner: cursor
```

Không có `DECIDE` = Cursor **cấm** sửa product.

---

## Thảo luận thống nhất — luật

- Một UNKNOWN. Không “làm cả A và B”.
- XSim ≠ board. Hypothesis ≠ evidence.
- Codex chốt; Cursor phản biện **một lần** trên mailbox nếu DECIDE trái FACT (ghi `Discuss` lần 2, không lặng lẽ sửa khác DECIDE).
- Lần 2 vẫn lệch: `BLOCKED_HUMAN` — Anh chốt.
- Độc lập sau khi có Result: vẫn `a7-evidence-auditor` + `a7-hlb-auditor`. Thảo luận không thay auditor.

---

## Mở phiên Cursor (làm ngay)

Đọc `BRIDGE.json`, `TURN.md`, `PROMPT_CODEX_BRAIN.md`.  
Nếu đang kẹt hoặc không chắc UNKNOWN: chạy § “Bắt buộc khi kẹt”, **không** `--dispatch` thêm, **không** implement.
)
