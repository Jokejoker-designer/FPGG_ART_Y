# Chỉ đạo parent V3.1 — P10/U9R đúng source, đúng scope

Đọc kế hoạch đã audit:
C:/Users/phant/.codex/.chatgpt-projects/g-p-68c95e6ae97c8191978788a39b2b2d1c/audits/V31_CLOSURE_PLAN_20260907/PLAN.md

Nhánh này vẫn theo UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md. Không chuyển sang master Astra.

WORKTREE=D:/Jetking_sem4/SEM_4/arty-a7-online-lm-g14-preboard-00
BRANCH=grok-orch/v31-canonical-00
HEAD tại audit=4ca071e7927aa4ceb6b9868eb17630ffa985eaf0
FINAL_SOURCE_COMMIT=bdddbd68b048054dc0c52e87685829a590f25270

P8/U8R đã accepted ở scope nguồn C9; P9/U9 đã freeze docs. NEXT=P10/U9R-FINAL-REGRESSION-00. Note 'không mở U8R/U9' trong U8-R3 là historical scope, không phải next pointer hiện tại. Pred861 là mismatch đã biết, không tự coi là một lỗi transport mới để chạy lại U8-R3 vô hạn.

Chạy /blueprint-gate-loop với các trường:
start_gate=U9R-FINAL-REGRESSION-00
max_gates=1

XSim/regression only. Không U9S/U9I/bit/program/QHEAD; không reseat các frozen bits; không đổi HOLD_A oracle. Trước khi dispatch xác minh runtime workflow đang dùng đúng bản và thực sự nhận start_gate. Nếu scout trả U8-R3/U8R/U9 đã accepted, parent phải reject stale selection và giữ requested P10; không dùng một summary cũ để override DAG.

U9R phải:

1. Pin source bdddbd68 và toàn test/config/input manifest; kiểm hash. Đã đối chiếu17 entry SHA256 của U9 khớp, nhưng còn phải kiểm dependencies đầy đủ. Dirty historical TB/log không được ghi đè hoặc dùng mà không ghi hash.
2. Re-run các contract cần thiết trên frozen source; phân biệt fixture regression với actual production top. Output vào bag U9R riêng.
3. Kiểm actual query→snapshot/pending→reward/commit khi SYNTHETIC_CAND_GEN=0. Hiện qv_to_graph=0 nhưng pending/snapshot vẫn lấy từ graph đó; test mux65/66/67 của U8R chưa cover liveness này.
4. Trace production UART→QSE→retrieval→learn→context encoder/fwd→single LM. P7 chain SIM_FULL=1 và không instantiate soc_top không đủ để gọi full SoC PASS. Missing wiring phải được ghi INTEGRATION_GAP, không thay bằng top test đơn giản hơn rồi đổi claim.
5. Kiểm WDMA ready xuyên CDC→producer thật. dma_go_ready default1 khi không nối không được xem như đã kiểm ready. Scoreboard transaction, beat và data; phân biệt starvation flag under=1 với data corruption.
6. Kiểm freeze, full-store NAK, duplicate, reset rồi same-key retrain, schemaV2 reload, full-ID và epoch. From-zero law không được kiểm bằng empty-DDR reset khác với train_reset production mà không nêu rõ.
7. Tách TYPE_CLASS443-row predicate/cap PASS khỏi M10 member evidence quality. Test hai facts cùng class nhưng khác nội dung mà query cần phân biệt; không dùng cùng type_hit cho cả answer và gold để claim semantic coverage800k.
8. Tách legacy context/checkpoint golden khỏi TYPE_CLASS861 structural observation. Không chỉnh expected, không QHEAD, không train cho trúng4số. Báo ORACLE_COMPATIBILITY_GAP nếu Master và final context hiện không đồng nhất.
9. Test negative host ingress và corrupted data để chứng minh counters/harness có khả năng bắt lỗi; zero constants không phải full host-leakage proof.
10. Kết quả gồm REGRESSION_RESULT, FULL_SOC_RESULT, M10_SCOPE, ROOT_B_SCOPE, LM_ORACLE_COMPATIBILITY, READY_FOR_FINAL_SYNTH và NEXT. Không dùng PASS hẹp để tự mở downstream.

Nếu phát hiện lỗi: giữ U9 freeze và raw fail, trả first divergence + smallest corrective revision. Không sửa frozen RTL trong chính run rồi viết PASS lên cùng bag. Manager sẽ giao correction theo bảng C00–C13; các phép kiểm đã đúng không phải làm lại vì đổi tên gate.

Mục tiêu của P10 là biến các residual thành kết quả test có thể xử lý, không thêm một report PASS để bỏ qua integration. Giữ output cuối có đường dẫn source/test/log và điều kiện chuyển bước rõ ràng.
