# Cursor ↔ Codex mailbox

Hai runtime không share chat. Chúng share **cùng git working tree** và hộp thư này.

| Bên | ID |
|---|---|
| Cursor chat | `f66cc793-5eb0-41d2-ae4f-46f101e32b87` |
| Codex project | `g-p-68c95e6ae97c8191978788a39b2b2d1c` |
| Codex session | `01a02edc-411a-72e2-9e9b-15c77f4198f5` |
| Deeplink | `codex://threads/01a02edc-411a-72e2-9e9b-15c77f4198f5` |

## Files

- `BRIDGE.json` — identity + lock
- `TURN.md` — việc hiện tại (request / result)
- `log.jsonl` — append-only, một event / dòng

## Protocol (bắt buộc)

1. Đọc `BRIDGE.json`. Nếu `lock.owner` là bên kia → **không** sửa source; chỉ đọc `TURN.md`.
2. Nhận việc: `lock.owner` = bạn, `updatedAt` = now, viết Request hoặc Result trong `TURN.md`.
3. Làm **một** việc. Ghi lệnh và path evidence thật.
4. Trả lock (`none` hoặc bên kia). Append `log.jsonl`.
5. Đồng bộ: cùng folder trên đĩa. Commit mailbox khi muốn bên kia thấy qua git; nếu cả hai mở cùng path thì save file là đủ.

## Mở Codex đúng thread

Trong Codex Desktop / browser: `codex://threads/01a02edc-411a-72e2-9e9b-15c77f4198f5`

Rồi nói: working tree là `d:\Jetking_sem4\SEM_4\arty-a7-online-lm`, đọc `.agents/handoff/TURN.md`.

## Không làm

- SSH để “nối” hai IDE
- MCP bridge giả giữa Cursor và Codex
- Hai agent cùng edit `rtl/` / `web/` / `python/`
- Ghi secret vào mailbox
