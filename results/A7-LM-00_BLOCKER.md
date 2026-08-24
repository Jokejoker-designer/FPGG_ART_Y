# A7-LM-00 — vì sao chưa đóng

**Date:** 2026-08-16  
**Status:** `PARTIAL` — không viết claim, không sang A7-LM-01.  
**Authority:** `docs/contracts/A7-LM-00.md` (mọi cổng **và** nhau).

Một cổng còn mở thì milestone **không được đóng**. Đó là lý do hành chính. Lý do kỹ thuật nằm ở cổng logits.

---

## 1. Cổng nào chặn

| Cổng (contract) | Kết quả | Chặn đóng? |
|-----------------|---------|------------|
| Host golden (cùng `lm05-signsgd-v1`) | 1000/1000 · 8×128 · 20 gen | không |
| Board 128-pack grads | **128 / 128** | không |
| Snapshot / 9 bank đổi / first-step wr | 512 head · 2048 block | không |
| AFTER writes | **0** | không |
| Generate 20/20 | **20 / 20** | không |
| Dumpz CE 32 cặp | **512 → 304 (40.625%)** = Basys LM-05 | không |
| WNS / TNS | **+72.324 / 0** | không |
| **Forward logits 1000/1000 exact** | **950 / 1000** (burst dumpz) | **CÓ** |
| git dirty == false + release dir | chưa đóng gói | phụ (sau khi 1000/1000 xong) |

Không đóng vì **thiếu 1000/1000 logits bit-exact trên kit**, không vì Arty không chạy, không vì sai part, không vì WNS.

---

## 2. Việc đã chứng minh trên silicon

- JTAG: `xc7a100t_0` Digilent `210319BE776EA`, `A7_LM00_PROGRAM_PASS`, startup HIGH.
- Bit: `build/out/arty_a7_lm00.bit`  
  SHA-256 `449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783`.
- UART thật: **COM12** (FTDI). COM10 **không có** trên PC lúc đo — đó là nhầm tên cổng, không phải lý do fail cổng logits.
- Law không đổi: `tiny_gpt05_core` copy từ Basys LM-05. Không DDR.

Các phép đo **không** đi qua 16 frame dumpz/case thì khớp golden:

- 128 grad `0x78` = 128/128  
- pred generate (frame `0x74` thôi) = 20/20  
- CE 32 cặp dumpz (ít hơn 1000) = đúng số Basys  
- Case 1 `[2]` chạy **một mình** sau load seed-2: 32 logit **bit-exact**, pred = 0 = golden.

---

## 3. 950/1000 nghĩa là gì

Mỗi case dumpz = **16 frame `A5 75`** (32 logit).  
1000 case ≈ **16 000 frame** liên tục trên 115200.

Ba lần burst (delay 1 ms / 6 ms / 20 ms, batch 10) đều ra **đúng 50 index**:

`1, 6, 35, 44, 46, 105, 107, …, 978, 992`

- Không lệch random từng lần.  
- Khoảng cách trung bình ~20 case.  
- Pred của các case lệch thường vẫn **đúng** (case 1: pred 0 = golden).  
- Cùng case 1, chạy lẻ: dumpz **khớp**.  
- Case 0 rồi case 1 (chỉ 2 case): cả hai **khớp**.

**Đã xác nhận:** sai số không phải “Arty tính sai 50 prefix cố định”. Máy đúng khi không bị dồn dumpz.

**Suy luận (chưa bắt UART analyzer):** host mất/lẫn frame `0x75` khi FIFO COM/FTDI đầy. 16 frame/case × 1000 vượt buffer; cùng lịch thời gian → cùng 50 chỗ. Không đủ bằng chứng để gọi đây là bug số học RTL.

Không được nói “50 case golden sai” — isolated chứng minh golden đúng với FPGA.

---

## 4. Việc **không** phải nguyên nhân

| Giả thuyết | Vì sao loại |
|------------|-------------|
| Chưa cắm / sai board | JTAG program `xc7a100t_0` PASS |
| Phải đúng COM10 | COM12 nói chuyện được: 128/128, CE, generate |
| Sai law / tối ưu nhầm | core copy LM-05; CE/grad/generate khớp Basys |
| WNS / fit 100T | WNS +72.324, TNS 0 |
| AFTER / SW0 | writes = 0 trên cmd 12 |
| Host tính next-token | generate lấy `pred` từ FPGA `0x74` |

---

## 5. Việc cần để **đóng** A7-LM-00

Kế hoạch khóa: `docs/contracts/A7-LM-00_CLOSE_PLAN.md`  
(tham chiếu `deep-research-report (1).md`).

T0 parser không kit → T1 stop-and-wait → T2 same-case 1000 → T3 alternate → T4 golden 1000 retry=0 → T5 final AND → T6 release.

Không rebuild bit `449A330B…`. Không mở core khi isolated còn PASS.
