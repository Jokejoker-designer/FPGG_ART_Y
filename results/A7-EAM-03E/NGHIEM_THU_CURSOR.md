# Nghiệm thu công việc Cursor — A7-EAM-03E

**Người nghiệm thu:** Grok Build session `019ffa1c-a65c-71e0-8521-7d285e7c2ffd`  
**Đối tượng:** Cursor peer (logic audit + A0.1-T close + work sau T)  
**Ngày:** 2026-08-20 (đối chiếu artifact trên đĩa, không tin handshake suông)  
**Authority:** `PATCH_DRAFT`. AI **không** tuyên bố BOARD_PASS.

Phạm vi Grok giao lúc pause: **A0.1-T timing only** (S_DIST pipeline), không đổi law, không A0.2 RTL, không mở A1.

---

## Quyết định

| Hạng mục | Verdict |
|----------|---------|
| **A0.1-T (đúng phạm vi giao)** | **ACCEPT — 5/5 cổng kỹ thuật đạt** |
| BOARD_PASS | **KHÔNG cấp.** Để người có thẩm quyền. Ghi `GATES_MET_PENDING_HUMAN_DECLARATION` |
| Discriminative geometry / seed robustness | **FAIL** (cố ý reproduce, không phải regression T) |
| A1 | **vẫn CLOSED** |
| A0.2-L RTL | **không mở** — twin FAIL; đúng |

---

## A. A0.1-T — đối chiếu độc lập

Patch: `S_DIST` đăng ký `ad`, `S_DADD` cộng saturating. Empty-B clear acc. Law `eam03e-a0-signsgd-v1`. Host `STEPS=32`.

Hash Grok tự đo (SHA256):

| Artifact | SHA đo được | Khớp registry |
|----------|-------------|----------------|
| live `rtl/eam/eam03e_core.sv` | `F8221477803E74DCFF1F801B38FEF839A1B0586397F73DAFE2989451A89ADEA5` | = A01T_CLOSE core |
| snapshot eupd (trước patch) | `717025A88F12C22B356DD626651CC359E2D5533083ACC9FADF3086F7815B04EE` | khác live, đúng parent |
| `A01T_CLOSE` bit | `80F2ED9E0C1A1679F87D5362F2D953258DEF640C6C2079E41B7BFBD7BCD12F41` | khớp skill registry |
| `build/out/arty_a7_eam03e.bit` | `80F2ED9E…12F41` | = A01T_CLOSE, không mất eupd archive |
| eupd archive bit | `ADD9E46280A697FD40C46911F5E477EF5B3A02EF36FE8054F9642216951C2262` | giữ |
| 02M frozen | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | **không đụng** |
| 01R frozen | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | **không đụng** |
| LM-06c3 frozen | `222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6` | **không đụng** |

Cổng T (đọc file, không copy closeout):

| Gate | Bắt buộc | Đo | File | Result |
|------|----------|-----|------|--------|
| XSim golden 32 bước | 3930/5362→1093/2012→3930→451/1574 | đúng + marker `A7EAM03EA01T_XSIM_PASS` | `A01T_CLOSE/t1_xsim.log` | **PASS** |
| WNS | ≥ 0 | **+0.637** ns @ 100 MHz | timing_route.rpt L141 | **PASS** |
| TNS | = 0 | 0.000, 0/18857 fail | cùng rpt | **PASS** |
| DSP | = 0 | 0 | util rpt L121 | **PASS** |
| Silicon vs xsim | exact 7 số | board JSON: 3930/5362/1093/2012/3930/451/1574 | `board_ladder_a01t_close.json` | **PASS** |
| Hold | report | WHS +0.037, THS 0 | timing rpt | **PASS** |
| LUT | — | 7713 | util | note |

Seed xấu **cùng lần silicon**, không che:

```
0x22222222  SAME 2135→1487  DIFF 1679→229  M_L1=−1258
```

Đó là EVIDENCE law fail, không phải T fail.

RTL: `S_DIST`/`S_DADD` giữ thứ tự i=0..31, `>>5`, saturating add. Extra 32 cycle/distance. Arithmetic transparent **vì** xsim+silicon exact (không còn là inference).

Handshake Cursor lúc đầu ghi “xsim not run / board disconnected”. **Đã supersede** bởi `A01T_CLOSE` ngày 2026-08-20. Nghiệm thu theo artifact close, không theo handshake cũ.

---

## B. Việc Cursor làm thêm (ngoài phiếu T)

Không trộn vào ACCEPT của T.

| Lane | Claim Cursor | Grok đối chiếu | Verdict |
|------|----------------|----------------|---------|
| A0.3 signed-h | XSim + WNS + silicon exact bag predicted | bit SHA `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` khớp registry; ladder board = predicted 739/581→164/1957→742→137/1370 | **ACCEPT silicon-exact.** Không phải geometry. |
| Phase S (unsigned law) | STABILITY_FAIL 11/11 | `A02_STABILITY/` | **ACCEPT fail** (đúng hướng: đo collapse) |
| S2 Wh-clamp | FALSIFIED | MUST_READ_UNBLOCK_H5 | **ACCEPT fail.** Cấm siết clamp thêm. |
| A0.2-L twin hinge | 0/11, RTL không viết | `A02_L/closeout.md` | **ACCEPT fail + đúng không viết RTL.** |
| Nút thắt hiện tại | H5 gated DIFF `d1 < 4096` | MUST_READ + live core L308 vẫn `d1_acc < E3_MARG` | **CONFIRMED trên RTL live T.** Next = ungated DIFF twin, law mới. |

`docs/contracts/A7-EAM-03E-A03.md` header còn “No RTL exists yet” — **stale** so với `A03_SIGNED/`. Không làm hỏng silicon A0.3, nhưng contract phải sửa provenance.

GlassBox / web UI: **ngoài phiếu encoder T.** Không ACCEPT/REJECT ở đây.

---

## C. Điều Cursor làm đúng (kỷ luật)

- Không glue 01R/02M/LM-06 vào encoder.
- Không sửa golden A0.1-T.
- Không tuyên bố BOARD_PASS.
- Không retune `E3_MARG` để “chữa” seed 2.
- Không mở A1.
- A0.2-L fail trên twin thì **không** synthesize.
- Reproduce inversion trên silicon T — tăng niềm tin đây là law, không phải timing.

---

## D. Điều chưa / không ACCEPT

1. **BOARD_PASS** — 5 cổng T đạt; tuyên bố để người.  
2. **Encoder discriminative** — vẫn `M=−1258`.  
3. **A0.2-L** — twin degeneracy (rank→1, AUC 0.5); không phải “sắp xong”.  
4. **Live `eam03e_core.sv` vẫn unsigned concat** L229 (law T). A0.3 nằm file riêng `eam03e_a03_core.sv`. `build/out/arty_a7_eam03e.bit` **là T-close**, không phải A0.3. Program nhầm bit = fail provenance.  
5. Handshake đầu phiên (xsim chưa chạy) **lỗi thời** — không dùng làm trạng thái hiện tại.

---

## E. Việc tiếp (một unknown / lần)

Theo `MUST_READ_UNBLOCK_H5.md`, không theo kế hoạch A0.2-L cũ:

1. Twin law **`eam03e-a03-ungated-diff-v1`**: DIFF luôn push khi `learn && !same`. Giữ signed `h` A0.3. Golden mới pre-register. **Không RTL trước twin PASS.**  
2. Twin gate: `d_pos`/`d_neg` không về 0; rank không 32→1; seed `0x22222222` `M_L1≥0` trên `>>5`.  
3. Rồi RTL + xsim + impl bit **mới**. Không ghi đè `80F2ED9E…` / `05E478FF…` / 02M / 01R / LM.  
4. A0.2-L combined triplet **sau** khi ungated giữ rank.

---

**Một câu cho Anh Quân:** Cursor đã đóng A0.1-T đúng kỹ thuật (xsim = silicon = golden, WNS +0.637, DSP 0, frozen bits nguyên). Tôi chấp nhận cổng T. Không cấp BOARD_PASS. Encoder vẫn chưa học được margin; bước sau là ungated DIFF trên twin, không phải UI hay 01R.
