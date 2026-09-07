# Native AI V3.1 — kế hoạch đóng đúng tham vọng trên Arty A7

Ngày audit: 07-09-2026. Worktree: D:/Jetking_sem4/SEM_4/arty-a7-online-lm-g14-preboard-00. Branch: grok-orch/v31-canonical-00.

HEAD được kiểm: 4ca071e7927aa4ceb6b9868eb17630ffa985eaf0. FINAL_SOURCE_COMMIT: bdddbd68b048054dc0c52e87685829a590f25270. Master: UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md. Tài liệu này là kế hoạch/audit; không sửa RTL, master, oracle hoặc status gate. Không chạy U9R/Vivado/program trong phiên lập kế hoạch.

## 1. Quyết định và mục tiêu

**Bắt đầu tiếp theo tại P10/U9R-FINAL-REGRESSION-00. Không quay về identify/audit U8-R3 chỉ vì note cũ ghi không mở U8R/U9.** U8R có PASS về chọn nguồn C9; U9 đã ghi source freeze. Giữ nguyên lịch sử đó.

Tuy nhiên freeze chứng minh danh tính source, không tự chứng minh source thỏa toàn Master. U9 tự liệt kê các residual: TYPE_CLASS chain chưa là UART production SoC, WDMA ready chưa wired, semantic LM mismatch. Vì thế U9R cần trả cả regression result và bảng điều kiện final còn thiếu. Không chuyển P10 PASS hẹp thành quyền U9S/program.

Final target của V3.1: một hệ thống FPGA-owned duy nhất, raw query→representation→sparse800k-addressable knowledge→learned contextual scoring→exact retained Top-K→structured C9→LM06→FPGA output; teacher-off, persistence/reset/retrain, metrics và physical closure. Không tự thêm yêu cầu Astra shared-SGD/2-hop engine vào đường đóng V3.1. Nếu muốn các năng lực đó, chúng vẫn thuộc nhánh Astra độc lập hoặc một amendment riêng.

## 2. Bằng chứng đã kiểm lại

| Hạng mục | Bằng chứng | Phạm vi được giữ |
|---|---|---|
| P8/U8R | xsim.log: PROD65/66/67, FIX0/0/0;155ns; SYNTHETIC_CAND_GEN=0 trong soc_top | mux nguồn C9 đúng trong g1g5 slice; không full query/reward |
| P9/U9 | HEAD/manifest; tự tính lại17 hash trong SHA256.txt đều khớp | source/config set được chỉ định; toàn dirty worktree không phải clean release |
| P7 TYPE_CLASS→LM | raw log ENC==CTX,12tokens,1busy rise/1done, pred861 | module chain thực, SIM_FULL=1; log ghi SOC_TOP=NOT_INSTANTIATED |
| P7b WDMA | raw log stall/full NAK/65 AXI writes/flush-reload/reset PASS | slice topology; đích ready chưa wired xuyên production core |
| P3/U7C | write33 NAK,32keys; existing keys vẫn update được | capacity-limited32-entry store; chưa learned cache scalable |
| U7 learning | reward[-1,+2,0] thay rank; freeze/neutral/duplicate controls; context isolation | adaptation XSim có thật; held-out leak_chiller có learned=0, chưa held-out improvement |
| U5Q TYPE_CLASS | host scan443 classes trên corpus800k | class-level equality filtering trên generated catalog, không tự chứng minh member evidence retrieval |
| U6Q | báo cáo OOC positive slack trước freeze | không được dùng thay full-chip timing sau integration |

Các U8-R3 TB/prereg/metrics/log vẫn đang có tracked modifications sau source freeze; không xóa. Phải dùng exact version/hash của test và source cho từng run; không đọc path live bị ghi đè rồi gán kết quả cho frozen run khác.

## 3. Bảng trở ngại → giải pháp → phép thử

| ID / ưu tiên | Tham vọng V3.1 | Trở ngại hiện tại | Hành động cụ thể | Bằng chứng đủ để đóng | Vai trò thực hiện / phụ thuộc |
|---|---|---|---|---|---|
| C00 / P0 | Điều phối tiến lên theo DAG | workflow default gate cũ; scout có thể thay current bằng gate đã PASS; note cũ được dùng như global stop | parent khóa requested start=U9R, kiểm enum gate/ancestry/terminal state; loại reject lùi DAG; test scout trả stale U8-R3 | dry-run map P8/P9 accepted→P10; stale answer bị reject; không chạy Vivado trong dry-run | Parent maintainer; ngay |
| C01 / P0 | Reproducible final source | production source clean set nhưng TB/docs dirty; snapshot có stale report | giữ U9 immutable; pinned source bdddbd68 + test/config manifest riêng; chỉ build qua manifest, output U9R riêng |17hash đã khớp; U9R phải kiểm toàn dependency closure, không file ngoài manifest | Evidence/build owner; C00 |
| C02 / P0 | One production path | P7 chain không instantiate soc_top, clk_dma=0; production vẫn native_ctx_bind | trace netlist nguồnUART→QSE→retrieval→learn→encoder/fwd→single LM; test full top ở SIM_FULL=0 với fast AXI responder; nếu thiếu nối, correction revision riêng | câu hỏi raw thực vào top→đúng C9/ctx→one accepted forward→done; data phase traces; không lực vào intermediate bus | Integration RTL owner; C01 |
| C03 / P0 | Query/reward liveness sau U8R | qv_to_graph=0, p_qr=1, nhưng p_pending/p_snap vẫn từ disabled graph | U9R gọi query thật + reward; watchdog trên accepted query/pending/snapshot/commit; thay source pending/snapshot bằng completion của parent path trên correction revision | query không kẹt S_QWAIT; pending được tạo từ Top-K thực; reward có commit; không chỉ assert parent ID vào mux | Integration+learn owner; C02 |
| C04 / P0 | Transaction-safe DDR/WDMA | weight_tile có dma_go_ready default1; core/top không expose/wire; slice PASS không cover đích thực | nối CDC ready đến producer qua LM wrapper/core; giữ payload/query owner đến retire; accepted count = outstanding+retired+explicit aborted | stall/double request/reset/owner-switch tại top; không overflow/drop, R/B/length check; negative injection bị bắt | DDR/CDC owner; C02 |
| C05 / P0 | M10 kho800k có evidence | TYPE_CLASS443 lớp; member_ptr không dùng trong LM; table compile-time; gold/hits dùng cùng predicate | chốt TYPE_CLASS là index/category hay final knowledge object; giữ class index, thêm member evidence lookup hữu hạn nếu cần giữ facts khác nhau; collision/refinement witness | hai facts cùng class nhưng khác object/negation/source không bị đồng nhất; sentinel thật đọc từDDR; corpus/member hash; query quality independent gold | Memory+scientific owner; C01, trước final promote |
| C06 / P0 | Exact C9/OUT theo oracle frozen | TYPE_CLASS stream12tokens→861; old HOLD_A oracle653 khác context/checkpoint | kiểm same-input, same-weight replay; tách bug encoding khỏi semantic mismatch; xác định compatibility của law mới với Master trước final | legacy tuple/input cùngweights→oldpred; final production semantic path đáp ứng oracle/approved law; không pad/train để ép số861→653 | LM owner+manager; C02,C05 |
| C07 / P1 | Học trên held-out query | U7 chứng minh rank flip trên query train; held-out được nêu lại có0 learned effect | corpus20/40facts A/B theo luật; chọn held-out wording cùng semantics được query law hỗ trợ; lập correct ranking trước train độc lập; no-update/neutral/shuffled controls | held-out Top-K/evidence thay đúng do reward, unrelated không hưởng prior; contextual isolation; không host chọn winner/rank reward | Learn+test owner; C02,C05 |
| C08 / P1 | Learned-state DDR-backed, bounded BRAM |32slots đạt NAK sau6queries; LIMIT là policy, chưa cache/allocation/eviction | giữ NAK-safe baseline; thiết kế exact-tag bounded set-associative hot cache + DDR backing chỉ khi working-set requirement cần; hoặc ghi rõ capacity claim và chứng minh workload thực thỏa | capacity/occupancy trace; >32 distinct keys không silently mất update; eviction/loadstate exact nếu quảng bá scalable learn | Memory owner; C07; không cộng800k dense weights |
| C09 / P0 | Reset/forget/retrain | stale epoch row có thể được restamp cùng prior cũ; controls dùng full reset/emptyDDR thay train_reset | directed test +3→train_reset→same-key +1 phải thành+1 nếu từzero law; prior+penalty của oldgen invisible và không revive; reuse slot versioned | cùngkey/crosskey/reset-midtxn tests; no resurrection; warm persistence migration đúng schema | Learn/persist owner; C01 |
| C10 / P1 | Host contribution=0 có khả năng bị bác bỏ | counters stub0 không kiểm được forbidden ingress | check actual UART decoder/opcodes; inject forbidden frame làm rejection/counter++; trace all consumers, weightswrite after freeze thật; normal run0 | cả positive path và negative leakage tests; không dùng constant-zero output làm bằng chứng tổng | Protocol/test owner; C02 |
| C11 / P1 | PHYS4 hữu dụng | U6 TYPE_CLASS hiện một scorer_lane; PHYS4 metadata xuất phát SOA khác | per-path hierarchy và enable counters; thiết kế4-lane class/evidence scoring với same exact comparator hoặc ghi request architecture decision nếu giảmPHYS | final synthesized4active lanes nếu claimPHYS4, utilization/stall measurement trên query thật | Scorer+physical owner; C02,C05 |
| C12 / P0 trước bit | Fit/timing/CDC/DRC | historical full-chip report trước U8R; OOC không chứng minh cofit | sau correctness: remove duplicate logic, BRAM sequential tables/logits/cache, giảm control sets có chứng minh; frozen manifest→full synth/route | hard device fit; WNS≥0/TNS0,WHS≥0/THS0;route/DRC0;reviewedCDC; no unconstrained critical path | Physical owner; C02–C11 đủ phạm vi |
| C13 / P0 trước final | Board final trên cùng artifact | old bits không phải final; board/COM12 dùng chung Astra | current lease+JTAG+UART-before-program+bit SHA; corpus/weights/load path pinned; board blind train/exam/reset sequence | bit/config/corpus/log identity một chuỗi; no hidden reprogram; full required boxes measured | Board operator + independent auditor; C12+U9P |

## 4. Vì sao C05 TYPE_CLASS phải được quyết định rõ

Ở host_m10_tc.py, gold và hits đều gọi type_hit trên danh sách unique types. Đây là phép thử exact class predicate/cap, không phải phép đo độc lập để suy ra chất lượng nội dung trên800k facts. Tập type saturate443 vì catalog giới hạn không tự chứng minh mọi corpus lớn đều có443 lớp.

TYPE_CLASS hoàn toàn có thể là một abstraction/index hữu ích. Giữ nó nếu nhanh và tiết kiệm, nhưng phải biết abstraction giữ hay mất cái gì. Test đơn giản: hai records cùng(eid,iid,rid,xid) nhưng object/source/negation khác. Nếu câu hỏi được phép cần phân biệt chúng mà hệ thống chỉ trả class, abstraction chưa đủ cho claim knowledge.

Phương án hợp V3.1: class lookup→bounded member retrieval theo typed discriminators→real descriptor/evidence→learned rank/Top-K. Không lấy first member mặc định làm câu trả lời; không full scan trong lớp lớn. Có candidate và byte cap global, overflow explicit. Exact address được FPGA sinh từ index; instance identity đầy đủ không lấy classID làmNID.

Nếu workload chỉ yêu cầu class taxonomy thì có thể ship class classifier với corpus provenance800k. Nhưng claim này nhỏ hơn tham vọng episodic/relational evidence của Master; cần explicit scope decision, không gọi metric class của443 hàng là tự thỏa M10 full knowledge.

## 5. Vì sao861 không giải được bằng sửa expected output

R1 checkpoint/context report ghi input train[1]→target32, token meanings chưa có, không tokenizer semantic. R2 định nghĩa stream typed tuples mới; R3 đã chuyển stream đúng vào LM và ra861. Đó là kết quả deterministic có thể đúng arithmetic nhưng thiếu liên hệ semantic với task.

Giải quyết theo thứ tự:

1. Pin exact WMEM/checkpoint hash và cả context bytes của legacy và TYPE_CLASS.
2. Chạy fixed-ref cùng input để xác định861 có arithmetic đúng hay không. Nếu đúng, dừng debug arithmetic cho sự khác nhau do input.
3. Giữ old oracle như regression của law/context cũ. Không reseat old bit để tạo cảm giác đãclose.
4. Master vẫn yêu cầu final HOLD_A653 cùng final path. Lập ORACLE_COMPATIBILITY.md: test nào dùng query/context/law nào; có thể giữ semantic exactness qua canonical encoder hay không. Không lập bảng answer token theo query.
5. Nếu chứng minh không thể giữ nguyên final oracle khi đổi semantics/checkpoint, ghi AUTHORITY_CONFLICT và đề xuất amendment versioned cho người dùng quyết định. Thiết kế kỹ thuật chưa có quyền tự retarget. New checkpoint training cần dataset/vocab/grounding objective độc lập, không optimize để trúng4số.

Q-head bị cấm hiện tại: không mở Q-head hoặc train checkpoint ngầm trong regression. Tất cả phần trên có thể bắt đầu bằng read-only/offline checks, không cầnboard.

## 6. U9R cụ thể: regression trên snapshot hiện tại

U9R kiểm chứng snapshot, không sửa frozen source trong cùng run để đổi FAIL thành PASS. Nếu thiếu wiring, ghi FAIL/GAP rồi tạo corrective revision mới; U9/bdddbd68 vẫn là lịch sử hợp lệ.

| Nhóm | Input và oracle | Điều kiện và phân loại |
|---|---|---|
| R0 provenance | bdddbd68, source/test/config/input manifest | Không dùng dirty TB vô danh; ghi source SHA và TB SHA |
| R1 contracts | Query vectors, route validity, exact heap/tie/pads | Match versioned golden; FAIL marker thắng PASS marker |
| R2 completion | Production parameter0, query rồi reward thật | Có snapshot, pending và commit; watchdog hữu hạn |
| R3 production top | Actual soc_top, SIM_FULL=0, fast AXI responder tại memory boundary | Đúng hierarchy, UART ingress và tất cả clients; thiếu đường nối phải báo INTEGRATION_GAP |
| R4 WDMA | Downstream ready held low, hai request, reset/owner switch | Accepted = retired + outstanding + explicit aborted; không ghost done hoặc drop |
| R5 learned state | Freeze, duplicate, full store, reset rồi same-key retrain, reload | Exactly-once; không hồi sinh old prior; identity nguyên vẹn |
| R6 M10 | Phân biệt class và record; image/index/member provenance; sentinel | Class-control PASS riêng; thiếu evidence lookup không được claim M10 toàn phần |
| R7 LM | Legacy và TYPE_CLASS contexts với pinned weights | Structural/arithmetic PASS khác semantic mismatch; không đổi861 thành653 bằng expected value |
| R8 negative tests | Corrupt AXI beat, wrong RID/RESP/LAST, forbidden frame | Harness thực sự phát hiện lỗi; counter hằng0 không đủ |
| R9 summary | Source không đổi, requirement matrix | Regression verdict, READY_FOR_FINAL_SYNTH và residual owner; không BOARD_PASS |

Fast AXI model kiểm logic, không thay bằng chứng MIG PHY. Sau fast full-top mới dùng real MIG cho checkpoint transport/calibration/CDC. Không sửa acceptance của run đã đăng ký chỉ vì chậm. Có thể đăng ký decomposition cho gate mới: fast full-forward + real MIG transport + full prediction trên board.

Không chạy lại full-forward khi source/input/config và unknown đều không đổi. R3 vừa chạy khoảng110 giây cho context đã biết; đó chỉ là baseline của phép thử này, không phải ETA toàn dự án.

P7b CASE_G còn in under=1. Source ddr_tile_dma đặt cờ này khi W đang chờ mà input w_valid=0; do đó không được tự quy nó thành corruption. U9R phải phân biệt input starvation được backpressure hợp lệ với dữ liệu bị mất, bằng byte/beat scoreboard. ACK=BRESP count riêng lẻ chưa chứng minh toàn bộ payload đúng. Nếu cờ chỉ là starvation sticky thì đặt tên/phân loại telemetry đúng, không lén bỏ qua một lỗi dữ liệu thật.

## 7. Từ P10 tới final

| Chặng | Việc phải hoàn thiện | Điều kiện chuyển |
|---|---|---|
| A — ngay | Parent nhận U9R; integrity và R0–R9 | Regression verdict và gap list cụ thể, BIT=NO |
| B — nếu lộ gap | Pending/snapshot, ready CDC, evidence semantics, reset, LM compatibility | Corrective revisions có tests; mỗi revision xử lý một nguyên nhân |
| C — refreeze | Reconcile Master trên candidate đã sửa | Manifest mới, affected tests và final suite PASS; không sửa lịch sử U9 |
| D — U9S/U9I | Synth rồi full placement/route đúng source | Hard physical criteria PASS; mọi thay đổi RTL quay lại tests liên quan |
| E — U9P | DDR map, model/corpus/index/schema, telemetry, board protocol | LAW/XSIM/MIG/METRIC gaps=0; READY_TO_PROGRAM có chứng cứ |
| F — U10 | Một program final candidate mới và blind exam | Cùng artifact chứng minh train/persist/reset/teacher-off/C9/OUT/metrics |
| G — reconciliation | Mỗi box trỏ vào artifact/log cụ thể | Người dùng xác nhận final claim |

Không tính phần trăm bằng P10/P14: chặng B có thể lớn hơn nhiều gate tài liệu. Chốt lịch calendar sau U9R xác định công việc là wiring fix, algorithm change hay checkpoint change. Theo dõi thời gian thực tế mỗi test/build và số nguyên nhân còn mở; không hứa xong trong một đêm khi chưa biết semantic blocker.

Phân công theo vai trò: parent quản lý ledger; integration owner nối top; DDR owner xử lý transaction; memory/scientific owner xử lý M10; learn owner xử lý pending/reset/cache; LM owner xử lý input/checkpoint; physical owner xử lý cofit; auditor kiểm độc lập. Trong một worktree chỉ một writer; kiểm tra read-only có thể chạy song song nếu không cản run.

## 8. Tối ưu tài nguyên theo thứ tự có căn cứ

1. Loại các engine production trùng sau khi chứng minh tương đương chức năng. Không tắt producer rồi bỏ quên completion/pending consumer.
2. Thử ROM/BRAM synchronous cho TYPE_CLASS và materialization, share lookup port theo phase. Read latency phải nằm trong transaction contract; không replicate toàn catalog cho mỗi PE.
3. Giữ PHYS=4 theo Master, serialize lookup/dedup/update. TYPE_CLASS hiện một scorer phải được báo đúng; không lấy4 PE của đường SOA khác làm bằng chứng.
4. Giảm control sets tương thích; dùng validity/epoch thay reset toàn RAM khi behavior cho phép. Không đặt false path chỉ để xóa negative slack.
5. Logits có thể chuyển LUTRAM sang BRAM nếu scheduler hấp thụ latency. BRAM115 là preferred,135 là hard device limit; cần đo tradeoff slice/BRAM/timing.
6. Learned cache không cần800k BRAM entries. DDR backing + cache bounded có thể giữ capacity lớn, nhưng eviction/write-back phải có U7A proof.

AMD UG949 giải thích registers trong một7-series slice chia sẻ clock/reset/enable, nên còn LUT chưa chắc còn slice có thể dùng. [Control sets](https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Control-Signals-and-Control-Sets), [Reducing control sets](https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Reducing-Control-Sets).

CDC structure và timing slack là hai bằng chứng khác nhau. CDC review không thay setup/hold report. [AMD UG906](https://docs.amd.com/r/2022.2-English/ug906-vivado-design-analysis/Report-Clock-Domain-Crossings).

## 9. Chuẩn bị final board exam trước bit

Trước U9P cần exact JTAG210319BE776EA/partxc7a100t, xác minh COM hiện tại, quyền dùng board chia sẻ với Astra, UART binary capture, bit/model/corpus/index/schema/script hashes, load path, deadline và recovery policy.

Chuỗi exam:
- BOOT/calibration/schema/CRC, không chỉ JTAG DONE.
- Train20facts A; raw query và reward không winner; kiểm commit thực.
- Freeze, teacher0, external_LLM0, forbidden-host0; có negative leakage test.
- Held-out wording, unrelated rejection, contradiction, typed/path evidence.
- FLUSH → BRAM loss → RELOAD → giữ identity và kết quả.
- Reset learned state → A bị quên → retrain B → behavior B.
- Đo candidate, DDR byte, latency, active lanes và accepted LM start/done.
- Kiểm frozen oracle theo compatibility đã giải quyết trước program.
- Không query-time host weights/answer; CPU chỉ codec/logging.
- Lưu raw.bin có CRC; không dùng newline-converted text như raw authority.

Nếu telemetry chưa đủ để bác bỏ claim thì đăng ký instrumentation trước final freeze với ngân sách rõ. Không build/program liên tục chỉ để thêm vài dòng UART. Một record gồm txn/source hashes/status/counters/digests từ tín hiệu thật thường hữu ích hơn nhiều sticky messages rời rạc.

## 10. Điều phối để không quay vòng

Workflow local hiện có default U8-SOC-ROOTB-WDMA-00 và cho phép identify override gate bằng text. Hành vi lùi về U8-R3 phù hợp với thiếu monotonic validation; chưa audit transcript runtime nên đây là inference về nguyên nhân, không khẳng định mọi workflow dùng cùng bản code.

Dùng ledger gồm gate_id, status, evidence_class, source SHA, test SHA, accepted_revision, next và scope. Parent chọn theo requested start và ledger; không cho scout tự lùi gate đã accepted. Note 'do not open U8R/U9' trong bag cũ là quyền/phạm vi lịch sử của bag đó.

Ledger cần phân biệt:
- lịch sử gate đã accepted;
- những prerequisite của final chưa được bằng chứng đó bao phủ;
- corrective revision hiện tại.

Auditor không gộp 'fraud=false' với functional PASS. Người làm trung thực vẫn có thể bỏ sót coverage. Review tập trung first causal divergence và violated invariant, không chỉ lặp lại summary.

## 11. Path evidence chính, relative to worktree

- docs/native_graph/CLOSE_NATIVE_V1_DAG.md
- docs/native_graph/GSTACK_PARENT_LOOP.md
- .grok/workflows/blueprint-gate-loop.rhai
- results/A7-NATIVE-GRAPH/GROK-ORCH-00/U9-FINAL-SOURCE-FREEZE-00/{RESULTS.md,SHA256.txt,SOURCE_MANIFEST.txt}
- results/A7-NATIVE-GRAPH/GROK-ORCH-00/U8R-REMOVE-SYNTHETIC-PRODUCTION-00/{CLOSEOUT.md,xsim.log,tb_u8r_remove_synthetic.sv}
- results/A7-NATIVE-GRAPH/GROK-ORCH-00/U8-UNIFIED-SOC-XSIM-00/xsim.log
- results/A7-NATIVE-GRAPH/GROK-ORCH-00/U8-SOC-ROOTB-WDMA-00/xsim.log
- results/A7-NATIVE-GRAPH/GROK-ORCH-00/U5Q-M10-TYPECLASS-SCALE-00/host_m10_tc.py
- results/A7-NATIVE-GRAPH/GROK-ORCH-00/U7-CONTEXTUAL-LEARNING-EFFECTIVENESS-00/{RESULTS.md,xsim.log}
- results/A7-NATIVE-GRAPH/GROK-ORCH-00/U8-R1-LM-CONTEXT-VOCAB-CONTRACT-00/RESULTS.md
- rtl/native_graph/integrate/a7ng_g1g5_cofit.sv:137 — disabled query producer
- rtl/native_graph/integrate/a7ng_native_v1_ab_core.sv:259 — old bind
- rtl/native_graph/integrate/a7ng_typeclass_soc_chain.sv — separate chain with tied-off DMA
- rtl/native_graph/memory/a7ng_typeclass_scan.sv — catalog scan
- rtl/native_graph/integrate/a7ng_u6_typeclass_retrieval.sv:138 — single scorer
- rtl/native_graph/learn/a7ng_learned_prior_store.sv:159 — epoch/restamp behavior
- rtl/lm/weight_tile803k.sv:29 — default dma_go_ready=1
