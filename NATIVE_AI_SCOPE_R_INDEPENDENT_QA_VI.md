# Báo cáo kiểm định độc lập SCOPE-R / HMPS cho Native AI

**Vai trò:** Nhà kiểm định chất lượng độc lập, ưu tiên phản biện và giới hạn bằng chứng  
**Đối tượng kiểm định:** Đề xuất `SCOPE-R — Stability-Constrained Online Plasticity with Episodic Replay + Meta-Search of Learning Laws`  
**Ngày:** 21/08/2026  
**Kết luận cấp cao:** **Chưa sẵn sàng để gọi là thuật toán đột phá, chưa sẵn sàng đưa thẳng vào RTL hoặc chạy Meta-Search theo công thức hiện tại.**

## 1. Verdict độc lập

SCOPE-R là một **ý tưởng nghiên cứu có hướng đi đúng**, nhưng bản đề xuất hiện tại đang trộn quá nhiều cơ chế chưa định nghĩa đủ: homeostasis, decorrelation, replay, adaptive coefficient, Lyapunov-inspired gate, local predictive error và Meta-Search. Nó có giá trị như một **research framework**, nhưng chưa phải một learning law có thể audit, tái lập và triển khai trên FPGA.

Điểm tích cực là đề xuất đã chạm đúng một phát hiện quan trọng của dự án: SignSGD thuần không có cơ chế fixed point ổn định; S3 là cơ chế duy nhất trong các nhánh đã thử giữ được rank và tránh saturation trên phần lớn seed; đồng thời kết quả 100k cho thấy mọi law hiện tại đều có xu hướng tiếp tục update sau peak và phá representation. [1] [2] Vì vậy, hướng “stability-constrained plasticity” đáng được kiểm tra.

Tuy nhiên, điểm yếu nghiêm trọng hơn là đề xuất đang biến **một hypothesis hợp lý** thành **một hệ thống gồm nhiều biến chưa được chứng minh**, sau đó dùng Meta-Search để tìm ra tổ hợp tốt. Cách này có thể tạo ra một candidate đạt điểm trên twin nhưng không biết cơ chế nào tạo ra cải thiện, không biết có overfit vào 11 seed hay không, và có nguy cơ tạo một law quá đắt hoặc không thể ánh xạ lên FPGA.

> **Verdict:** SCOPE-R nên được giữ lại, nhưng phải hạ cấp từ “thuật toán đột phá” xuống **khung tạo và kiểm định các learning law ổn định**. Phiên bản triển khai đầu tiên phải là `SCOPE-R0`, chỉ có một thay đổi có thể falsify, không phải toàn bộ công thức hiện tại.

## 2. Điểm mạnh thực sự

### 2.1. Bám đúng evidence quan trọng nhất

Đề xuất không bắt đầu từ việc tăng parameter hoặc gắn thêm GlassBox, mà bắt đầu từ stability, long-horizon và anti-collapse. Đây là hướng đúng vì E1 ungated-DIFF đã đạt sanity gate nhưng cuối 100k cả 11 seed đều collapse về AUC `0.500`, rank `1–3`, `unique_d1=1`. [3] Điều đó bác bỏ ý tưởng rằng chỉ cần bỏ DIFF gate là representation sẽ khỏe.

Nhánh S1 giảm tần suất cập nhật `Wh` 16 lần cũng thất bại 11/11 ở horizon 100k; nó chỉ trì hoãn collapse. Ngược lại, S3 tạo restoring force và là nhánh duy nhất giữ được rank/saturation tương đối tốt ở phần lớn seed, dù vẫn chưa đạt M_L1/M_cos/AUC gate đầy đủ. [2] SCOPE-R correctly nhìn thấy rằng vấn đề không chỉ là “repulsion yếu”, mà còn là **thiếu cơ chế điều hòa trạng thái lâu dài**.

### 2.2. Nhấn mạnh Meta-Search trên long horizon

Việc buộc candidate sống qua `100k updates × 11 seeds` là đúng hướng và phù hợp với lịch sử dự án. Các short screen trước đây nhiều lần cho kết quả đẹp ở đúng vùng peak rồi đảo chiều ở 100k. [2] Nếu Meta-Search được dùng đúng cách, nó có thể giúp khám phá không gian hệ số mà con người khó quét thủ công.

### 2.3. Giữ teacher-off ở FPGA boundary

Đề xuất vẫn giữ nguyên nguyên tắc host không tính gradient, weight delta, cue, winner, address hoặc next token trong proof teacher-off. Đây là điểm mạnh về integrity. Tuy nhiên, việc đề xuất “replay gradient từ 02M” hiện chưa phù hợp với boundary và semantics đã frozen; phần này cần sửa, như phân tích ở mục 4.

### 2.4. Có ý thức ghi rõ uncertainty

Đề xuất đã tự ghi nhận rằng `δ_local` cần verification, minority-seed residual còn chưa giải quyết, và “average model intelligence” chỉ có ý nghĩa trong domain hẹp. Đây là thái độ khoa học đúng. Vấn đề là các uncertainty này phải trở thành **hard gates trước khi mở rộng scope**, không chỉ nằm ở cuối tài liệu như chú thích.

## 3. Điểm yếu nghiêm trọng cần phản biện

## 3.1. Công thức hiện tại chưa phải một learning law hoàn chỉnh

Công thức đề xuất là:

```text
Δw = η_fast · pre · δ_local
     − λ_t · (w − μ_i)
     − γ · D_decor(w)
     + ρ · G_replay
```

Công thức này mới là một khung ý tưởng. Muốn thành law có thể chạy, cần định nghĩa chính xác cho từng thành phần ở mức bit-width, state, timing, saturation, transaction order và ownership.

| Thành phần | Vấn đề kiểm định | Trạng thái |
|---|---|---|
| `δ_local` | Chưa có local head, target, scale, quantization hoặc chứng minh rằng residual phản ánh task | **NEEDS_EXPERIMENT** |
| `μ_i` | Nếu là EMA bám quá sát `w_i`, lực homeostasis gần bằng 0; nếu cố định, phải định nghĩa checkpoint/anchor và chi phí lưu trữ | **Chưa đủ đặc tả** |
| `λ_t` | Trộn rank, variance và target trong các đơn vị khác nhau; chưa có normalization, fixed-point range hoặc clamp | **Chưa đủ đặc tả** |
| `D_decor` | Gram decorrelation là tín hiệu toàn cục, không tự nhiên là local update; cần chọn object, window và sketch | **Rủi ro cao** |
| `G_replay` | 02M lưu episodic key/value, không mặc nhiên cung cấp gradient khả vi | **Sai/thiếu contract** |
| `L(t)` | Gọi là Lyapunov-inspired nhưng chưa chứng minh boundedness, monotonicity hoặc invariant set | **Chỉ là heuristic** |
| `ΔL` gate | Cần tính trạng thái trước/sau, dễ tăng latency, dễ từ chối mọi update vì nhiễu lượng tử | **Rủi ro cao** |

Không được gọi biểu thức `L(t)` là Lyapunov function nếu chưa chứng minh ít nhất một property hữu ích: chẳng hạn boundedness của `Wh/h`, giảm drift trong một miền xác định, hoặc không tăng khi update được chấp nhận. Tên đúng hiện tại là **stability score heuristic**.

## 3.2. `D_decor` mâu thuẫn với tuyên bố “local”

Nếu `D_decor` được tính từ Gram matrix của representation dimension `d=32`, nó cần các tích chéo giữa các chiều, tối thiểu là một cấu trúc cỡ `32×32`, tức khoảng 1.024 phần tử trước khi tính loss và update. Nếu tính trên batch hoặc nhiều timestep, tín hiệu còn trở thành toàn cục theo cửa sổ dữ liệu.

Điều này không có nghĩa decorrelation chắc chắn không thể chạy trên FPGA. Nó có nghĩa phải trả lời ba câu hỏi trước khi code:

1. Decorrelate cái gì: `h`, `E`, `Wh`, cue hay episode key?
2. Tính trên một sample, một transaction, một cửa sổ hay một batch?
3. Có dùng random projection/sketch để giảm chi phí hay không, và sketch có còn phản ánh collapse thật không?

Nếu chưa trả lời, `D_decor` chỉ là một regularizer trên giấy. Đưa nó vào cùng homeostasis, replay và adaptive gate sẽ làm mất khả năng biết nguyên nhân cải thiện.

## 3.3. `G_replay` từ 02M là claim sai nếu không sửa interface

02M là episodic memory, không phải differentiable optimizer. Một episode record có thể cung cấp key, value, hit/miss, distance hoặc hard-negative candidate; nó không tự động cung cấp gradient `G_replay` cho `E`, `Wh` hoặc LM-06.

Nếu host chọn hard negative, vi phạm boundary. Nếu 01R/02M tự chọn candidate, đó có thể là **negative sample index** hoặc **binary replay signal**, nhưng không được gọi là gradient trừ khi có một local loss và update rule cụ thể trên FPGA.

**Giải pháp kiểm định:** đổi tên và thu hẹp thành:

```text
G_replay → replay_signal
```

Trong phiên bản đầu, `replay_signal` chỉ được phép là một trong các tín hiệu rời rạc sau:

```text
HIT_POSITIVE
HIT_CONFLICT
MISS_EXPECTED
HARD_NEGATIVE_FOUND
```

Sau đó định nghĩa một update local riêng cho từng signal. Không được đưa “gradient từ 02M” vào contract khi chưa có derivation và bit-exact reference.

## 3.4. `M_cos`, rank và saturation không được tùy tiện trở thành training control

Roadmap hiện tại quy định cosine là **EVAL telemetry only**, không dùng để TRAIN nếu chưa có law riêng. [4] SCOPE-R sử dụng `var(M_cos)` để điều chỉnh `λ_t` và dùng `M_cos` trong potential `L(t)`. Đây là một thay đổi learning-law lớn, không phải telemetry bổ sung.

Có ba rủi ro:

- Nếu `M_cos` lấy từ held-out set, training đã nhìn vào evaluation signal và làm hỏng independence.
- Nếu `M_cos` lấy từ training triples, nó có thể chỉ đo fit local, không đo generalization.
- Nếu tính on-chip mỗi transaction, cần thêm dot product, norm approximation, window state và pipeline; đó là chi phí phần cứng mới.

**Giải pháp tốt nhất:** trong `SCOPE-R0`, không dùng `M_cos` để điều khiển update. Chỉ dùng telemetry hiện có để đánh giá. Nếu sau này muốn dùng angular signal, phải tạo một law riêng, contract riêng, train/eval split riêng và chứng minh chi phí phần cứng.

## 3.5. “Lyapunov gate” có thể biến learning thành chọn lọc kết quả

Đề xuất nói: nếu `ΔL < θ` thì bỏ qua update. Ý tưởng nghe an toàn nhưng có thể gây ba failure mode:

| Failure mode | Cơ chế |
|---|---|
| Update starvation | Quantization làm `ΔL` nhỏ/nhiễu, hầu hết update bị bỏ |
| Greedy local trap | Chỉ nhận update cải thiện metric tức thời, không đi qua valley cần thiết |
| Metric gaming | Chọn trọng số `α…ε` để làm score tăng dù representation xấu |

Ngoài ra, `L(t)` chứa các metric khác đơn vị: margin, cosine, rank, saturation, drift. Không có normalization và calibration thì tổng này không có ý nghĩa vật lý. Một giá trị `+1` của rank không thể tự nhiên so sánh với `+0.01` của cosine.

**Sửa bắt buộc:** đổi từ “Lyapunov gate” thành **bounded-update guard**. Guard đầu tiên chỉ kiểm soát các đại lượng có ý nghĩa trực tiếp và cùng đơn vị cố định:

```text
accept update nếu:
  no arithmetic overflow
  abs(delta_w) <= delta_max
  sat_count không vượt rail_limit
  drift_window <= drift_limit
```

Guard này không được quyết định dựa trên held-out `M_cos` hoặc AUC. Sau khi law ổn định, mới mở một thí nghiệm về consolidation/hold.

## 3.6. Meta-Search đang được dùng quá sớm và quá rộng

Meta-Search không thể sửa một architecture chưa xác định. Nó chỉ tìm được cấu hình tốt trong hypothesis class đã cung cấp. Nếu hypothesis class thiếu local target, thiếu consolidation hoặc thiếu output learning, search sẽ tối ưu một họ law sai.

Không gian đề xuất có ít nhất 10 chiều: learning rate, homeostasis, adaptive coefficients, decorrelation, replay, timescale, margin, error source, hard-negative policy và có thể thêm thresholds. Với mỗi candidate chạy 100k × 11 seed, chi phí không chỉ lớn; còn có rủi ro **winner’s curse**: candidate đứng đầu trên cùng seed set sẽ được chọn vì may mắn.

Meta-Search cũng vi phạm tinh thần “một unknown mỗi lần” nếu dùng đồng thời để tìm nhiều loại cơ chế. SCOPE-R phải được chia thành hai tầng:

```text
Tầng 1: falsify từng cơ chế bằng ablation one-change.
Tầng 2: search hệ số trong một law family đã sống sót.
```

Không được search trước khi từng primitive đã có evidence độc lập.

## 4. Kiểm định teacher-off và các điểm mâu thuẫn

### 4.1. “Pure teacher-off” đang trộn ba chế độ

Đề xuất ghi:

```text
teacher = 0, learn = 0 hoặc η cực nhỏ
```

Đây là mâu thuẫn. Có ba chế độ phải tách riêng:

| Chế độ | Flags | Ý nghĩa |
|---|---|---|
| TRAIN | `teacher=1, learn=1, freeze=0` | Học có supervision từ teacher nhưng FPGA tự update |
| TEACHER-OFF EVAL | `teacher=0, learn=0, freeze=1` | Proof inference độc lập, không mutation |
| SELF-ADAPT | `teacher=0, learn=1, freeze=0` | Học không teacher; đây là research mode khác |

Nếu `η` còn khác 0 trong EVAL, đó không phải teacher-off frozen evaluation. Nếu chạy `SELF-ADAPT`, phải có contract riêng, safety gate riêng và benchmark catastrophic forgetting riêng.

### 4.2. Replay/sleep không được chạy trong final EVAL

Sleep-like replay có thể hữu ích ở TRAIN hoặc maintenance mode, nhưng nếu `02M` tiếp tục mutate trong EVAL thì hệ thống không còn reproducible. Final proof phải khóa:

```text
teacher=0
external_LLM=0
learn=0
freeze=1
episode_writes=0
weight_writes=0
```

Replay chỉ được chạy ở một mode riêng và phải đo xem nó làm thay đổi state như thế nào.

## 5. Đánh giá khả năng ánh xạ vào FPGA

| Cơ chế | Khả năng phần cứng | Đánh giá kiểm định | Quyết định |
|---|---|---|---|
| S3/homeostasis dạng shift | Khá tốt | Đã có tiền lệ trên `Wh -= Wh >> k`; chi phí thấp nhưng anchor phải định nghĩa | **Giữ để làm baseline** |
| Per-weight EMA anchor | Trung bình/thấp | Tăng state, DDR/BRAM traffic và update bandwidth; EMA bám theo weight có thể vô nghĩa | **Không dùng trong R0** |
| Per-tensor/per-group anchor | Khá hơn | Ít state hơn, nhưng regularization thô hơn | **Ứng viên R1** |
| Adaptive `λ_t` | Trung bình | Cần quantized monitor, normalization, clamp và timing budget | **Chỉ sau baseline pass** |
| Gram decorrelation | Rủi ro cao | Global cross-coordinate calculation, nhiều MAC/state, chưa có local reduction | **Hoãn** |
| Replay signal từ 02M | Có thể, nếu là discrete signal | Cần interface mới; không gọi gradient | **Thiết kế lại** |
| Lyapunov `ΔL` gate | Rủi ro cao | Tính trước/sau, noise, latency, dễ starvation và overfit | **Hoãn; thay bằng bounded guard** |
| Meta-Search | Có thể chạy host-side | Không ảnh hưởng teacher-off nếu chỉ dùng để chọn law trước freeze | **Giữ nhưng chạy sau ablation** |

### Ước lượng tài nguyên và nguy cơ chưa được xác minh

Không có evidence trong gói cho việc SCOPE-R làm tăng bao nhiêu LUT/FF/BRAM/DSP, DDR bytes/update hoặc cycles/update. Vì vậy mọi câu như “phù hợp FPGA” hiện chỉ là **ENGINEERING_INFERENCE**. Cần một report tài nguyên cho từng primitive trước khi tích hợp.

Đặc biệt, nếu `μ_i` là per-weight state, số byte persistent gần như tăng ít nhất một state phụ cho mỗi weight. Với LM-06, state này có thể làm tăng traffic DDR trong mỗi update, dù sức chứa DDR vẫn đủ. Bottleneck của LM-06 là bandwidth/compute path, không chỉ capacity; vì vậy “tham số có thể nhiều” không đồng nghĩa có thể thêm state miễn phí. [5]

## 6. Phương án tốt nhất: SCOPE-R0 thay vì full SCOPE-R

### 6.1. Nguyên tắc thiết kế

Phương án tôi đánh giá tốt nhất không phải triển khai toàn bộ SCOPE-R. Đó là một phiên bản tối giản, kiểm định được, gọi là **SCOPE-R0 — Consolidation-first bounded plasticity**.

SCOPE-R0 chỉ giải quyết hypothesis có bằng chứng gần nhất: **các law hiện tại đều đạt peak rồi tiếp tục update và phá peak; cần một cơ chế hold/consolidation trên FPGA**. Nó không thêm decorrelation, không replay gradient, không adaptive M_cos, không local LM residual và không Meta-Search ngay từ đầu.

### 6.2. Law R0 đề xuất

Giữ nguyên candidate tốt nhất hiện tại làm control:

```text
BASE = triplet hinge + unconditional S3 >>3
```

Thêm đúng một cơ chế mới:

```text
R0 = BASE + on-chip consolidation/hold
```

Cơ chế hold phải sử dụng tín hiệu local đã có trong transaction, không dùng held-out AUC/M_cos. Một bản đặc tả tối thiểu có thể là:

```text
Mỗi cửa sổ W transactions:
  đo violation_count
  đo saturation_count
  đo update_count
  đo distance trend trên training transaction

Nếu:
  violation_rate <= τ_v
  AND saturation_rate <= τ_s
  AND update_state ổn định trong W
thì:
  chuyển encoder sang HOLD trong H transactions
  không ghi E/Wh

Nếu có hard-negative violation mới sau HOLD:
  mở lại TRAIN trong một cửa sổ đã định nghĩa
```

Đây vẫn là hypothesis và phải được preregister. Nhưng nó có ba ưu điểm: một unknown rõ ràng, bám trực tiếp vào evidence “peak bị phá do tiếp tục update”, và không cần đưa `M_cos` held-out vào training.

### 6.3. Vì sao không chọn full SCOPE-R ngay

Full SCOPE-R có thể sẽ cho một kết quả đẹp trên twin, nhưng khi thất bại sẽ không biết failure đến từ homeostasis, decorrelation, replay, local residual, adaptive lambda hay Lyapunov gate. Trong một dự án đã nhiều lần bị short-horizon reversal, đó là rủi ro chất lượng cao nhất.

SCOPE-R0 có thể kém “đột phá” hơn về mặt trình bày, nhưng có xác suất tạo ra knowledge đáng tin cậy cao hơn. Nếu R0 pass, ta mới có cơ sở mở R1 homeostasis, R2 replay signal, R3 decorrelation và cuối cùng là Meta-Search hệ số.

## 7. Thí nghiệm falsification bắt buộc

### E0 — Reproduce control

Chạy lại `triplet + S3 >>3` trên 11 seed, horizon 100k, đóng các metrics: rank, saturation, unique distance, M_L1, M_cos, AUC, update count và drift. Không được dùng số từ lần chạy trước nếu command/tool/dataset hash không khớp.

### E1 — SCOPE-R0 hold-only

Thay đổi duy nhất là bật consolidation/hold. Giữ nguyên triplet, S3, margin, dataset, seed và evaluator. Không thêm `D_decor`, replay, adaptive lambda hoặc local LM residual.

**PASS candidate:**

```text
11/11 seed không rank collapse
11/11 seed saturation dưới ngưỡng đăng ký
worst M_L1 >= 0
worst M_cos >= 0 nếu M_cos vẫn chỉ là EVAL metric
AUC_final không về ~0.5
AUC_post > AUC_init trên majority
hold_event_count và resume_event_count được archive
```

Nếu R0 chỉ làm giảm số update nhưng quality không tốt hơn, kết luận phải là **hold đúng cơ chế nhưng chưa đủ**, không được thêm tất cả cơ chế còn lại vào cùng run.

### E2 — Homeostasis anchor riêng

Chỉ chạy nếu E1 có stability nhưng quality còn yếu. So sánh per-tensor anchor với fixed anchor; không dùng per-weight EMA ở vòng đầu. Đo thêm state bytes, DDR bytes/update, cycles/update và timing.

### E3 — Replay signal riêng

Không truyền gradient từ 02M. Chỉ test một discrete replay signal, ví dụ `HARD_NEGATIVE_FOUND`, với một update rule đã định nghĩa. Đo false-hit, candidate count, host boundary và quality. Nếu cần host chọn candidate, test FAIL.

### E4 — Decorrelator riêng

Chỉ mở khi rank/saturation ổn nhưng geometry vẫn fail. Trước RTL, so sánh ba biến thể: full Gram reference, sketch reference, no decorrelation. Nếu sketch không tương quan với full reference, dừng nhánh.

### E5 — Meta-Search sau cùng

Chỉ search các hệ số trong law family đã pass primitives. Search phải dùng:

| Thành phần kiểm soát | Quy tắc |
|---|---|
| Candidate space | Nhỏ, preregister trước; chỉ search hệ số fixed-point |
| Screening | Có thể dùng subset seed nhưng không được dùng để claim |
| Confirmation | Chạy toàn bộ 11 seed và thêm seed chưa từng dùng nếu có |
| Early stop | Chỉ dừng vì collapse/saturation/overflow; không dừng để chọn candidate đang peak |
| Selection | Lexicographic: safety → worst-seed → median → resource; không chọn theo max AUC |
| Artifact | Mỗi candidate có ID, config SHA, command, output SHA, negative notes |
| Silicon | Chỉ candidate được chọn theo rule đã freeze mới được board-confirm |

## 8. Tiêu chí Meta-Search đúng và sai

### Meta-Search đúng

Meta-Search là một công cụ đo lường có kiểm soát: search trong một family nhỏ, dùng long-horizon, phạt worst-seed, tách screening và confirmation, không chạm held-out benchmark để điều chỉnh law, và chỉ promote candidate đã có artifact mới.

### Meta-Search sai

Meta-Search là sai nếu nó chạy mọi tổ hợp SCOPE-R, chọn candidate có AUC cao nhất trên 11 seed, sau đó gọi đó là “law tốt nhất”; nếu dùng M_cos/AUC held-out để điều khiển training; nếu dùng 10–30 candidate nhưng không báo cáo toàn bộ candidate fail; hoặc nếu top-3 silicon confirm được chọn sau khi nhìn thấy kết quả mà không có selection rule được preregister.

## 9. Scorecard kiểm định

Đây là đánh giá chuyên môn của auditor, không phải điểm benchmark thực nghiệm:

| Hạng mục | Đánh giá | Nhận định |
|---|---:|---|
| Bám đúng root cause hiện có | 4/5 | Đúng ở stability/fixed-point; chưa chứng minh decorrelation/replay là root cause |
| Tính hoàn chỉnh của công thức | 2/5 | Nhiều symbol chưa có định nghĩa bit-level/transaction-level |
| Kỷ luật one-change | 1/5 | Roadmap đề xuất quá nhiều cơ chế cùng lúc |
| Khả năng FPGA | 2/5 | Homeostasis shift có triển vọng; Gram/replay/Lyapunov gate chưa được budget |
| Teacher-off integrity | 3/5 | Boundary đúng, nhưng replay và `η cực nhỏ` làm mờ mode semantics |
| Meta-Search methodology | 3/5 | Đúng hướng long-horizon nhưng thiếu nested confirmation và chống selection bias |
| Khả năng tạo insight đáng tin | 4/5 nếu dùng R0 | Tốt nếu chia primitive; thấp nếu triển khai full công thức |
| Rủi ro scope creep | 5/5 | Rất cao |

## 10. Quyết định triển khai

### Không được làm ngay

Không đưa full SCOPE-R vào RTL. Không thêm decorrelation, replay gradient, adaptive `λ_t`, local LM residual và Lyapunov gate trong cùng một branch. Không dùng `M_cos` hoặc held-out AUC làm training control khi contract hiện tại quy định cosine là EVAL-only. Không gọi Meta-Search là bằng chứng intelligence.

### Nên làm ngay

Đóng một contract mới cho `SCOPE-R0`, giữ triplet + S3 làm control và thêm đúng một consolidation/hold mechanism trên twin. Cố định seed/data/horizon, chạy 100k × 11 seed, lưu raw telemetry, report worst-seed và resource proxy. Nếu R0 pass, mới mở homeostasis anchor; nếu R0 fail, phải falsify hypothesis stopping thay vì ném thêm regularizer vào công thức.

### Verdict cuối của kiểm định

> **SCOPE-R/HMPS hiện là một research direction đáng thử, nhưng chưa đạt chất lượng của một thuật toán có thể triển khai. Bản full công thức bị over-specified ở mức khái niệm nhưng under-specified ở mức phần cứng và bằng chứng.**

**Giải pháp tốt nhất cho dự án hiện tại là SCOPE-R0: consolidation-first, one-change, twin-first, worst-seed-first, không dùng held-out metric làm training control.** Nếu R0 pass, SCOPE-R có cơ sở phát triển thành một family có thể search. Nếu R0 fail, không nên tiếp tục tăng độ phức tạp; khi đó phải xem xét giới hạn của representation architecture, local target hoặc capacity của encoder.

Mức độ chắc chắn của các kết luận như sau:

| Kết luận | Phân loại |
|---|---|
| E1 ungated-DIFF không giải quyết collapse | **EVIDENCE** |
| S1 rate reduction không đủ | **EVIDENCE** |
| S3 tạo restoring force tốt nhất trong các nhánh đã đo | **EVIDENCE có phạm vi giới hạn** |
| Các law tiếp tục update sau peak | **EVIDENCE/hypothesis mạnh từ 100k data** |
| Consolidation/hold sẽ sửa được residual | **NEEDS_EXPERIMENT** |
| Decorrelator sẽ chống collapse trên FPGA | **NEEDS_EXPERIMENT** |
| Replay từ 02M cung cấp gradient hữu ích | **Chưa hợp lệ nếu chưa có interface/law mới** |
| SCOPE-R sẽ đạt intelligence ngang model trung bình | **Chưa có bằng chứng; không được claim** |

## References

[1]: `/home/ubuntu/native_ai_review/NATIVE_AI_V1_TAI_LIEU_2026-08-21_v2/04_KET_QUA_THUC_TE/results/A7-EAM-03E/E1_UNGATED_100K/closeout.md` "E1 ungated-DIFF 100k"

[2]: `/home/ubuntu/native_ai_review/NATIVE_AI_V1_TAI_LIEU_2026-08-21_v2/04_KET_QUA_THUC_TE/results/A7-EAM-03E/E2A_S1_RATE16/closeout.md` "E2A S1 rate reduction 100k"

[3]: `/home/ubuntu/native_ai_review/NATIVE_AI_V1_TAI_LIEU_2026-08-21_v2/04_KET_QUA_THUC_TE/results/A7-EAM-03E/A02_L_S3/closeout.md` "Triplet + S3 closeout và correction ở 100k"

[4]: `/home/ubuntu/native_ai_review/NATIVE_AI_V1_TAI_LIEU_2026-08-21_v2/01_KE_HOACH/NATIVE_AI_V1_ROADMAP.md` "Native AI V1 Roadmap — cosine EVAL-only và gate order"

[5]: `/home/ubuntu/native_ai_review/NATIVE_AI_V1_TAI_LIEU_2026-08-21_v2/04_KET_QUA_THUC_TE/results/A7-LM-06_CLOSEOUT.md` "LM-06 closeout — 802,816 parameters và resource/claim boundary"

[6]: `/home/ubuntu/native_ai_review/NATIVE_AI_V1_TAI_LIEU_2026-08-21_v2/04_KET_QUA_THUC_TE/results/A7-EAM-03E/A03_SIGNED/twin_board_equiv_closeout.md` "A03 signed twin-board equivalence"
