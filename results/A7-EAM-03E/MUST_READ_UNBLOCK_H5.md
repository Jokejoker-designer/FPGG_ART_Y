# MUST READ — đọc TRƯỚC mọi RTL / sweep / closeout encoder

**Bắt buộc.** Session Native AI / A7-EAM-03E / A0.3 / A0.2-L / Phase S: đọc file này **hết** rồi mới `final.md`. Không skip. Không tóm tắt thay cho đọc.

Constitution vẫn: `results/A7-EAM-03E/final.md`  
Pack đầy đủ: `D:\Jetking_sem4\SEM_4\eam-03e-research\docs\CRAWL_UNBLOCK_H5.md`  
Bản gốc repo: `MUST_READ_UNBLOCK_H5.md`

---

## Một câu

A0.3 silicon **đã exact**. Nút thắt **không** phải FPGA, signedness, hay kẹp `Wh`.  
Nút thắt: **DIFF bị cổng nhị phân** `d1 < E3_MARG` (4096) → SAME hút trên `E` dùng chung → `d_pos`/`d_neg` co về 0 (H5). Metric **rỗng**.

```text
python/eam/eam03e_twin.py  ~339
gate_open = d1 < E3_MARG
if same: pull
elif gate_open: push
else: g = 0          ← hầu hết DIFF tắt vì d1 untrained ~12k
```

---

## Đã đo — đừng thí nghiệm lại như thuốc

| Thử | Kết quả | Ý |
|-----|---------|---|
| S2 clamp Wh {128,64,32,16,8} | **FALSIFIED**. ±128 = sat8 **control**. ±64 **tệ hơn** (rank 1, uniq_d1 1) | **Cấm siết clamp thêm** |
| A0.3 signed `h` | XSim + silicon exact `739/581→164/1957→742→137/1370` bit `05E478FF…` | Arithmetic OK; **không** geometry |
| Copy always-repel vs live gated, seed `0x22222222`, `Σ\|Δ\|>>5` | silicon **M=−1258**; hinge m=0 **+42**; always-repel **+1545** | Thuốc H5 = **ungated DIFF** |
| Copy L0 vs L1 hinge | always-repel 5/8; hinge 1/8 | **Không** copy hinge m=0 lên silicon như thuốc đầu |

---

## Việc tiếp (một unknown / lần)

1. Twin, **law mới** `eam03e-a03-ungated-diff-v1`: DIFF **luôn** push khi `learn && !same`. Bỏ cổng 4096. Giữ A0.3 signed `h`. Golden **mới** pre-register. **Không** RTL trước twin PASS.  
2. Gate twin: `d_pos`/`d_neg` không co về 0; rank không 32→1; `0x22222222` `M_L1≥0` trên cùng `>>5`.  
3. Rồi RTL + xsim + impl (bit **mới**, không ghi đè `80F2ED9E…` / `05E478FF…`).  
4. S1 (giảm rate Wh) **chỉ** nếu còn muốn FALSIFY F_wh — **không** gộp với bước 1.  
5. A0.2-L combined `(A,P,N)` **sau** khi 1–2 giữ rank. Cosine = EVAL.  
6. Kidi: negative độc lập (T1); early-stop 24 vs 48.

S1 optional **trước** bước 1 chỉ khi archive S1-only sweep. Không gộp S1 + ungated + triplet.

---

## Cấm

- Siết S2 / kẹp `Wh` thêm  
- Glue 01R / 02M / LM-06 lên encoder sụp  
- Sửa golden A0.1-T (`3930/5362…`) hoặc A0.3 predicted  
- Gộp signedness + e_ra + S1 + ungated DIFF + triplet  
- Cosine TRAIN; host gradient/winner/address  
- `E3_MARG` như HIT/no-HIT (QTQ binary-to-conditioning: **FAIL** nếu còn gate 0/1)  
- LSH / Q2 / GlassBox / PYNQ / “1.6M parameters”  
- Tuyên bố BOARD_PASS  

---

## Đọc thêm (sau file này)

1. `results/A7-EAM-03E/final.md`  
2. `results/A7-EAM-03E/A03_SIGNED/second_defect.md`  
3. `D:\Jetking_sem4\SEM_4\eam-03e-research\docs\HANDSHAKE_019ffa1c.md`  
4. `D:\Jetking_sem4\SEM_4\eam-03e-research\docs\CRAWL_UNBLOCK_H5.md`  

Trả lời session: dòng đầu tiên phải là  
`MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).`
