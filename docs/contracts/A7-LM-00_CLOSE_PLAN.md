# A7-LM-00 — phương án đóng

**Authority:** `docs/architecture/PROGRAM.md` + `docs/contracts/A7-LM-00.md`  
**Tham chiếu:** `deep-research-report (1).md`  
**Bit giữ nguyên:** `build/out/arty_a7_lm00.bit`  
SHA-256 `449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783`  
**Không:** đổi `law_id`, sửa golden, rebuild, mở `tiny_gpt05_core`, sang A7-LM-01.

---

## Kết luận khóa

Blocker **không** phải arithmetic. Isolated case (kể cả `[2]`) bit-exact; 128/128, 20/20, CE 512→304, AFTER=0, WNS +72.324 đã đạt.

Blocker là **đường thu/ghép telemetry** khi `dumpz` chạy liên tục (16 × 1000 frame `0x75`). Chưa đủ bằng chứng để gọi tên “FTDI FIFO overflow”.

Phạm vi sửa: **host parser + transaction barrier trước. RTL sau cùng.**

---

## Thứ tự (không nhảy)

| Bước | Việc | PASS | FAIL → |
|------|------|------|--------|
| **T0** | `FrameStream` + pytest chunk/garbage, **không kit** | recover 100% frame; 0 false-valid; 0 byte mất | sửa parser |
| **T1** | Host scorer stop-and-wait: đợi `0x74` rồi dumpz; `seen == {0,2,…,30}` | scorer mới + log idx/crc/resync | không chạy 1000 |
| **T2** | Same-case stress: load seed-2, fwd `[2]`, dumpz × 1000 | 1000/1000, retry=0 | raw UART; chưa đụng core |
| **T3** | Alternate case 0 / case 1 × 500 | 1000 dump exact, retry=0 | case-transition / stale frame |
| **T4** | Full golden 1000 prefix | exact 1000/1000 + dump complete + missing=0 + dup=0 + crc=0 + retry=0 | cây quyết định dưới |
| **T5** | Final contract **một session sạch**, cùng SHA bit | mọi cổng AND | không ghép run cũ |
| **T6** | `releases/A7-LM-00-BOARD-PASS-YYYYMMDD/` + SHA scorer + `git dirty=false` | mới viết claim A7-LM-00 | — |

Sleep **không** phải correctness. Chỉ back-off. Không `flush()` như RX barrier. Không `reset_input_buffer()` giữa dump khi FPGA có thể còn TX.

---

## T1 — contract transaction

```text
CASE n
  send ctx → send FWD → WAIT đúng 1 frame 0x74
  send DUMPZ
  collect 0x75 đến khi seen == {0,2,…,30}
  đủ idx + CRC + không trùng → so golden
  xong mới CASE n+1
```

Retry chỉ để **chẩn đoán**. Đóng milestone khi:

```text
logical_exact = 1000/1000
AND transport_retries = 0
```

1000/1000 mà còn retry → arithmetic có thể đúng, **chưa đóng** (tránh mang protocol yếu sang A7-LM-01).

---

## Cây nếu T4 vẫn FAIL

```text
robust parser
    └─ 1000 golden
         ├─ PASS → T5
         └─ FAIL
              └─ same-case 1000
                   ├─ PASS → transition/stale 0x74/0x75 (log từng case)
                   └─ FAIL → uart_raw.bin + frames.jsonl (parser đã loại)
                        └─ mới xét FTDI / FPGA TX
```

Mở `tiny_gpt05_core` **chỉ khi**:

```text
transaction-safe vẫn FAIL
AND isolated cùng case cũng FAIL
AND raw stream đủ frame + CRC OK
```

Hiện isolated **PASS** — điều kiện mở core **chưa có**. Nếu tới đó: `dump_z` / idx / TX handshake trước, **không** đụng Q/K/V/FFN.

---

## T5 — một session, không ghép số cũ

Cùng bit SHA:

| Cổng | Cần |
|------|-----|
| host golden | 1000/1000 |
| board logits | 1000/1000, retry=0 |
| grads | 128/128 |
| banks | 9/9 |
| wr_head / wr_blk | 512 / 2048 |
| CE | 512 → 304 |
| generate | 20/20 |
| AFTER | 0 |
| WNS / TNS | +72.324 / 0 (image này) |

Không dùng claim Basys `FULL_TINY_TRANSFORMER_BACKPROP_…`.

---

## T6 — release

```text
releases/A7-LM-00-BOARD-PASS-YYYYMMDD/
  RELEASE_MANIFEST.json
  CLOSEOUT.md  CONTRACT.md  SHA256SUMS.txt
  bitstream/arty_a7_lm00.bit
  reports/  golden/  board/  transport/
```

Hash **scorer mới** (blocker nằm ở verification). `git status --porcelain` rỗng.

UART evidence: **COM12** trừ khi Device Manager đổi.

---

## Việc không làm

- Rebuild / đổi pin / MIG / 128-lane  
- Sửa golden 50 case  
- FTDI latency timer như “cách chữa correctness”  
- A7-LM-01 trước T6
