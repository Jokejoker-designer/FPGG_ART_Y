# Arty A7-100T Native Online-Training Transformer Program — Bản gốc cuối hợp nhất nghiên cứu

> **DEPRECATED / HISTORICAL.** Not the active roadmap. Use `Revised Arty A7 Program Master.md`. A7-LM-03 is BOARD_PASS / FROZEN; A7-LM-04 is NEXT.

## Phán quyết nghiên cứu và những điều cần sửa trước khi khóa bản Master

Sau khi đối chiếu hai bản chương trình hiện tại của bạn với các công trình NeuronFabric, Ultra Memory-Efficient On-FPGA Training, LUT-LLM, TerEffic, ZyboGPT, INT8 Training, SpecMamba, LowRank-SSM, MiniLLM, Hummingbird, luận văn Waterloo, openENOC, ControlPULP, cùng các nguồn nền tảng như Hinton KD, Adafactor, LoRA, activation recomputation và FlashAttention, kết luận của tôi là:

> **Không nên thay kiến trúc A7-LM hiện tại bằng bất kỳ paper nào.**
>
> Nên giữ A7-LM là **xương sống chứng minh native online training**, rồi lấy từng ý tưởng từ literature thành **các research branch có contract riêng**.

Điều này đặc biệt quan trọng vì chương trình hiện tại đã có một tài sản mà hầu hết paper không có: **một chuỗi milestone contract-first có board evidence và freeze semantics**. Bản Copy đã quy định A7-LM-00/01/02 là frozen, A7-LM-03 đang OPEN với 25.088 tham số BRAM-resident và `lm05-signsgd-v1`; đồng thời khóa official Digilent AXI MIG và cấm research recommendation tự ý ghi đè milestone. fileciteturn0file1 Bản gốc vẫn rất có giá trị về tensor architecture, tiling, roofline và scale ladder, nhưng recommendation cũ về native MIG `app_*` phải được coi là archived alternative vì đã mâu thuẫn với contract mới hơn. fileciteturn0file2

Có một sửa chữa quan trọng đối với phần tổng hợp nguồn bạn đưa vào:

**NeuronFabric chưa chứng minh on-FPGA training.** Paper ngày 15/6/2026 tự gọi mình là *software reference architecture*, dùng C# để kiểm tra numerical correctness và memory budget; tác giả viết rõ rằng FPGA implementation là bước tiếp theo và **không có FPGA measurements trong paper**. Cấu hình 334K BF16W đạt validation loss 1.5426 so với 1.5224 cho FP32 GPU sau 80K samples, nhưng đó là CPU/software experiment. citeturn10view0

Ngược lại, **Ultra Memory-Efficient On-FPGA Training** mới là nguồn trực tiếp mạnh nhất trong danh sách của bạn cho luận điểm end-to-end Transformer training trên FPGA: nhóm tác giả báo cáo single-batch end-to-end training trên AMD Alveo U50, dùng low-rank tensor compression, dưới 6 MB BRAM và 22.5 MB URAM cho các model FP32 có kích thước 36.7–93.5 MB. citeturn9academia2turn11view0

Điều này dẫn đến quyết định kiến trúc cốt lõi:

```text
                 PROGRAM_MASTER
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
 A7-LM BASELINE                RESEARCH BRANCHES
 contract-first                experimental
 native training
        │
        │                      A7-OPT
        │                      A7-KD
        │                      A7-LR
        │                      A7-QTRAIN
        │                      A7-INF
        │                      A7-SSM
        │                      A7-NOC
        │
        ▼
 measured ceiling
```

**Không paper nào được phép trực tiếp sửa A7-LM-03 đang build.**

### Phân loại literature để tránh trộn claim

| Nguồn | Thực sự chứng minh gì | Áp dụng vào GrOK | Không được suy diễn |
|---|---|---|---|
| NeuronFabric | Software full backprop + local Adam; BF16W memory analysis | local update, vocabulary budget, activation recomputation, optimizer research | không gọi là FPGA-trained |
| Ultra Memory-Efficient | End-to-end FPGA Transformer training trên U50 | low-rank/tensor contraction branch | không nhét ngay vào LM-03 |
| LUT-LLM | 1B+ FPGA **inference** bằng VQ + table lookup | AFTER/inference research | không dùng làm bằng chứng training |
| TerEffic | ternary LLM **inference** | ternary inference branch | không phải ternary training |
| ZyboGPT | tiny ternary autoregressive FPGA inference | Artix/Zynq low-resource design ideas | training vẫn nằm trên host |
| INT8 CNN Training | gradient quantization stabilization | gradient-law research | chưa chứng minh Transformer |
| MiniLLM | reverse-KL LLM distillation | later KD objective | không phải drop-in cho sparse top-K |
| SpecMamba | FPGA Mamba speculative **inference** | future SSM branch | không thay Transformer ladder |
| LowRank-SSM | low-rank Mamba **inference** | DDR/rank scheduling ideas | SVD không chạy động trên FPGA |
| Hummingbird | embedded-FPGA LLM **inference** | memory-offloading/roofline | không phải embedded training |
| Waterloo thesis | integer-only Transformer inference | nonlinear fixed-point research | không chứng minh backward |
| openENOC | Ethernet L2 NoC | future multi-FPGA | không phải transport dependency hiện tại |
| ControlPULP | RISC-V power/control system | future management plane | không cho soft CPU vào base ladder |

Các phân loại trên bám đúng phạm vi các nguồn: LUT-LLM chuyển linear computation thành vector-quantized table lookups cho inference; TerEffic là ternary LLM inference; SpecMamba và LowRank-SSM đều là Mamba inference accelerators; Hummingbird là embedded-FPGA LLM inference. citeturn9academia3turn11view4turn12academia12turn12academia13turn16academia0

## Bài học thực sự từ các công trình và cách đưa vào Arty A7

### NeuronFabric: lấy “local update”, chưa lấy BF16W

Ý tưởng đáng giá nhất của NeuronFabric đối với GrOK **không phải BF16**. Nó là:

> **compute → gradient → optimizer → write-back xảy ra cạnh model state, không gửi gradient ra host.**

NeuronFabric mô tả `NeuronCore` sở hữu weights, thực hiện backward rồi cập nhật tại chỗ; trong BF16W, weights được lưu 2 byte nhưng cast sang FP32 để tính/update, còn Adam `m` và `v` giữ FP32. Tổng state từ 12 byte/parameter của FP32 Adam giảm xuống 10 byte/parameter. citeturn10view0

Đó chính xác là triết lý mà GrOK nên giữ:

```text
External data / teacher
          │
          ▼
      FPGA forward
          │
          ▼
       FPGA loss
          │
          ▼
     FPGA backward
          │
          ▼
    FPGA optimizer
          │
          ▼
 FPGA-owned model write
```

Nhưng **BF16W không nên thay INT8/sign-SGD hiện tại**.

Arty A7-100T chỉ có 4,860 Kbit BRAM, tức khoảng 607.5 KB, trong khi NeuronFabric dự toán 3.34 MB cho weights + FP32 Adam moments của model 334K trên ZCU102. Vì thế ưu điểm “mọi model state nằm trong BRAM” của NeuronFabric không chuyển nguyên xi được sang Arty. Arty của bạn bù lại bằng 256 MB DDR3L, và A7-LM-01 thực tế đã đo khoảng 1.166 GB/s sequential read, 1.152 GB/s write và 1.159 GB/s mixed cùng 100/100 recalibration. citeturn8search0turn10view0 fileciteturn0file10

Nếu dùng đúng BF16W+Adam 10 byte/parameter của NeuronFabric, state tối thiểu sẽ xấp xỉ:

| Cấu hình | Params | INT8 weight hiện tại | BF16W + FP32 m/v |
|---|---:|---:|---:|
| LM-03 | 25,088 | ~24.5 KiB | **0.239 MiB** |
| LM-04 | 100,352 | ~98 KiB | **0.957 MiB** |
| LM-07 | 1,495,040 | ~1.43 MiB | **14.26 MiB** |
| LM-08 | 4,276,224 | ~4.08 MiB | **40.78 MiB** |
| MAX tied | 8,454,144 | ~8.06 MiB | **80.63 MiB** |
| MAX untied | 10,551,296 | ~10.06 MiB | **100.63 MiB** |

Các model đó vẫn có thể *fit* trong DDR 256 MB về mặt persistent state thô, nhưng **FIT không đồng nghĩa TRAIN**: Adam phải liên tục đọc/ghi moments, làm traffic trên mỗi parameter tăng mạnh so với sign-SGD không có moment tensor. citeturn8search0turn10view0

Còn một lý do nữa để không copy BF16W trực tiếp: Artix-7 sử dụng DSP48E1 với multiplier fixed-point 25×18 và accumulator 48-bit; đây không phải một BF16 FMA block chuyên dụng. BF16 datapath hoàn toàn có thể được xây, nhưng sẽ là một architecture experiment mới chứ không phải “free upgrade” của 128-lane INT8 datapath hiện tại. citeturn20search3turn20search5

Do đó:

```text
A7-LM:
INT8 W + current fixed-point law
             KEEP

A7-OPT-BF16W:
BF16 W + FP32-like moments
             EXPERIMENT LATER
```

### Ultra Memory-Efficient: đây mới là hướng scale-training đáng nghiên cứu nhất

Paper tensor-compressed training quan trọng với GrOK hơn tôi nghĩ ban đầu. Nó chứng minh một nguyên lý phù hợp trực tiếp với FPGA:

> **Muốn scale training, không chỉ nén weights; phải đồng thời giảm activation/gradient/intermediate tensor footprint và FLOPs.**

Nhóm tác giả dùng low-rank tensor decomposition cùng *bi-directional contraction flow*, giữ compressed parameters và gradient information on-chip ở từng training stage, đồng thời xây custom forward/backward/update kernels. Họ báo cáo end-to-end training trên U50 cho các model FP32 36.7–93.5 MB với <6 MB BRAM và 22.5 MB URAM. citeturn9academia2turn11view0

Tôi không đưa nó vào LM-04 ngay, vì tensorization thay đổi cả model law và gradient law. Thay vào đó:

```text
A7-LM-07 BOARD_PASS
        │
        └── A7-LR-00
              full-rank baseline
                    ↓
              low-rank forward exact/reference
                    ↓
              low-rank backward
                    ↓
              compressed update
                    ↓
              quality / BW / U_MAC comparison
```

Đây có thể là con đường làm **effective model capacity lớn hơn** mà không chỉ mua thêm RAM.

### Activation recomputation nên được đưa vào Master

NeuronFabric recompute activations layer-by-layer trong backward để đổi compute lấy SRAM; kỹ thuật checkpoint/recompute rộng hơn đã được Chen et al. formalize từ 2016, cho thấy có thể giảm activation memory từ linear sang \(O(\sqrt n)\) với chi phí gần một extra forward pass trong thiết lập của họ. citeturn10view0turn18academia24

Điều này rất hợp với Arty:

```text
Option A
forward
 ↓
write many activations → DDR
 ↓
read again for backward

Option B
store sparse checkpoints
 ↓
recompute local activation
 ↓
backward
```

Với DDR chỉ khoảng 1.16 GB/s thực đo, **recompute có thể thắng spill-to-DDR dù dùng thêm DSP cycles**, đặc biệt nếu tensor engine đang chưa bão hòa compute. Đây là inference kiến trúc cần đo bằng:

\[
T_{\text{recompute}}
\quad\text{vs}\quad
T_{\text{DDR write}}+T_{\text{DDR read}}
\]

chứ không quyết định bằng cảm giác. DDR measurements hiện tại của board cung cấp baseline thực nghiệm cho phép làm phép so sánh đó. fileciteturn0file10

### LUT-LLM, TerEffic và ZyboGPT chỉ nên tối ưu AFTER

LUT-LLM co-quantizes activations/weights, dùng vector quantization và precomputed 2D dot-product tables để biến nhiều arithmetic operations thành memory lookups; bản v2 báo cáo customized Qwen3 1.7B trên AMD V80. Đây là architecture cho inference chứ không phải weight-updating training. citeturn9academia3turn11view2

Điều này tạo ra một xung đột với online learning:

```text
training:
W changes every update
       ↓
centroids / codebooks / lookup relationships
may become stale
```

Vì vậy LUT-LLM không nên thay tensor core training. Nhưng nó rất thú vị cho:

```text
A7-INF-LUT
teacher-free AFTER accelerator
```

sau khi một checkpoint đã freeze.

TerEffic cũng là inference architecture cho ternary `{-1,0,+1}` models. citeturn11view4 ZyboGPT là một minh chứng thực tế rất gần với tài nguyên nhỏ: repository mô tả model khoảng 115K params trên Zybo Z7-10, ternary weights + INT8 activations, 30.5/60 BRAM, 67/80 DSP và time-multiplexed tensor logic; tuy nhiên pipeline của nó là **train bằng Python → export weights → FPGA inference**, không phải FPGA online training. citeturn14view0

Bài học nên lấy từ ZyboGPT là:

> BRAM packing, integer RMSNorm/Softmax, serial/time-multiplexed compute và ternary decode có thể làm model rất nhỏ chạy hiệu quả.

Không phải:

> “Chuyển GrOK sang ZyboGPT architecture.”

### INT8 nonlinear và quantized-gradient research

Luận văn Waterloo cho thấy integer-only inference của BERT có thể giữ cả GELU, Softmax và LayerNorm trong integer/fixed-point path, đồng thời báo cáo 2.6× throughput so với single-sequence design và ít nhất 10× so với CPU-offload trong thiết lập nghiên cứu đó. citeturn12search0turn12search1

Trong khi đó, paper unified INT8 training chỉ ra rằng **quantizing gradients** nguy hiểm hơn quantizing forward tensors; nhóm tác giả đề xuất Direction Sensitive Gradient Clipping và Deviation Counteractive Learning Rate Scaling để giảm direction deviation và tránh update sai hướng. Nhưng bằng chứng của họ là trên CNN, không phải Transformer. citeturn12academia14

Tôi sẽ biến thành:

```text
A7-QTRAIN-00
current law baseline

A7-QTRAIN-01
gradient saturation telemetry

A7-QTRAIN-02
DSGC-inspired clipping

A7-QTRAIN-03
DCLRS-inspired LR adjustment

A7-QTRAIN-04
held-out comparison
```

Không thay `lm05-signsgd-v1` cho LM-03.

## Kiến trúc Master hiện hành

Bản Master mới nên tuyên bố rõ rằng **contract/release authority cao hơn architecture research**.

```text
AUTHORITY ORDER

BOARD RECEIPT / BOARD EVIDENCE
          ↓
docs/contracts/A7-LM-xx.md
          ↓
immutable BOARD_PASS release
          ↓
PROGRAM_MASTER.md
          ↓
architecture experiment docs
          ↓
NotebookLM / ChatGPT / Grok / papers
```

Bản Copy hiện đã thể hiện tinh thần này: research answer không được reopen release, không được tự đóng milestone và không được tự sửa RTL của frozen foundation. fileciteturn0file1

### Trạng thái chính thức

| Milestone | Master status | Quyền thay đổi |
|---|---|---|
| A7-LM-00 | `BOARD_PASS / FROZEN` | ❌ |
| A7-LM-01 | `BOARD_PASS / FROZEN` | ❌ |
| A7-LM-02 | `BOARD_PASS / FROZEN` theo authority hiện hành | ❌ |
| **A7-LM-03** | **OPEN / Grok ACTIVE BUILD** | ✅ trong contract 03 |
| A7-LM-04 | LOCKED | chỉ tạo contract sau 03 |
| LM-05…07 | CANDIDATE / LOCKED | tuần tự |
| LM-08 | STRETCH | chưa claim |
| LM-MAX | SWEEP | không commitment |
| KD / OPT / LR / SSM | RESEARCH BRANCH | không được close LM |

Trạng thái 03 và các ràng buộc BRAM-resident, 25,088 params và `lm05-signsgd-v1` đã được bản Copy xác lập. fileciteturn0file1

### Top-level cuối

```text
                           HOST PC
┌─────────────────────────────────────────────────────────┐
│ corpus / tokenizer                                      │
│ experiment orchestrator                                 │
│ fixed-point reference / evaluator                       │
│ logging / manifests                                     │
│                                                         │
│ future only:                                            │
│ teacher sandbox / RF router / provenance               │
└────────────────────────┬────────────────────────────────┘
                         │
                  TOKENS / TARGETS
                         │
                         ▼
┌──────────────────── ARTY A7-100T ───────────────────────┐
│                                                        │
│ protocol RX + credit/backpressure                      │
│              │                                         │
│              ▼                                         │
│ command / training scheduler                           │
│        ┌──────────────┴──────────────┐                  │
│        ▼                             ▼                  │
│ forward FSM                    backward FSM             │
│        └──────────────┬──────────────┘                  │
│                       ▼                                 │
│              tensor microsequencer                      │
│                       │                                 │
│       ┌───────────────┼────────────────┐                │
│       ▼               ▼                ▼                │
│    GEMV/GEMM       vector ALU       nonlinear           │
│    DSP48E1         LUT/DSP          LUT/BRAM            │
│       │               │                │                │
│       └───────────────┼────────────────┘                │
│                       ▼                                 │
│                 optimizer/update                        │
│                       │                                 │
│        ONLY LEGAL MODEL-WRITE SOURCE                   │
│                       │                                 │
│                       ▼                                 │
│             BRAM scratchpad fabric                      │
│       ping | pong | act | psum | grad | KV             │
│                       │                                 │
│                       ▼                                 │
│                    AXI DMA                              │
│                       │                                 │
│             OFFICIAL DIGILENT AXI MIG                  │
│                       │                                 │
│                       ▼                                 │
│                 DDR3L 256 MB                            │
└────────────────────────────────────────────────────────┘
```

Digilent xác nhận A7-100T có 240 DSP slices, 4,860 Kbit on-chip memory và 256 MB DDR3L 16-bit ở 333 MHz/667 MT/s. citeturn8search0 Board test riêng của bạn đã chứng minh full 256 MiB sequential traversal hai lần và 100/100 recalibration, vì vậy DDR là một foundation có measurement chứ không phải chỉ datasheet assumption. fileciteturn0file10

### MIG được chốt một lần

Master cuối dùng:

```text
MIG = official Digilent profile
INTERFACE = AXI
BIST = AXI master
tensor DMA = AXI master

mig.prj modification = FORBIDDEN
native app_*          = ARCHIVED ALTERNATIVE
```

Không reopen A7-LM-01 chỉ vì paper hay AI nào cho rằng native interface có thể sạch hơn. Bản Copy đã cố ý giải quyết mâu thuẫn này so với recommendation `app_*` trong bản gốc. fileciteturn0file1 fileciteturn0file2

## Roadmap hợp nhất từ A7-LM-03 đến measured ceiling

### A7-LM-03 không thay đổi

Grok tiếp tục:

```text
V        = 128
C        = 16
d_model  = 32
L        = 2
H        = 2
d_ff     = 64
P        = 25,088

persistent W = BRAM
law          = lm05-signsgd-v1
```

Không đưa vào:

```text
BF16W
Adam
Adafactor
low-rank
ternary
teacher
RF
Mamba
Ethernet
soft CPU
new tokenizer law
DDR model-state migration
```

trong milestone đang mở.

Lý do khoa học rất đơn giản:

> **LM-03 phải chỉ trả lời câu hỏi “architecture và training law hiện tại có scale từ tiny baseline lên multi-layer/multi-head 25K hay không?”**

Nếu cùng lúc đổi precision, optimizer, memory placement và teacher, failure sẽ không còn định vị được.

### Ladder chính thức

Tôi giữ nguyên model ladder hiện tại:

| Stage | Params | Vai trò khoa học được chốt |
|---|---:|---|
| LM-03 | 25,088 | multi-layer/head scale, BRAM weights |
| LM-04 | 100,352 | **first DDR-resident persistent-weight model** |
| LM-05 | 399,360 | depth=4 + longer context |
| LM-06 | 802,816 | lower-bound primary scaled model |
| LM-07 | 1,495,040 | **primary program success** |
| LM-08 | 4,276,224 | DDR-dominated stretch |
| MAX tied | 8,454,144 | ceiling probe |
| MAX untied | 10,551,296 | ceiling probe |

Model sizes và progression này xuất phát từ program hiện tại; bản Copy đã chủ động biến MAX thành configuration sweep thay vì commitment. fileciteturn0file1

Tôi chỉ bổ sung một quyết định rõ hơn:

> **LM-04 nên là breakpoint mà persistent model state chuyển từ BRAM sang DDR.**

Như vậy 03 và 04 có câu hỏi khoa học khác hẳn:

```text
LM-03
Does the Transformer training architecture scale?
                     │
                     ▼ PASS

LM-04
Does the same learning machine remain correct
when persistent weights are streamed from DDR?
                     │
                     ▼ PASS

LM-05
Can depth/context scale?
                     │
                     ▼

LM-06/07
Can useful native training scale toward 1M+?
```

Đây là quyết định program-level cho contract 04 tương lai, không phải thay đổi contract 03 đang chạy.

### Từ LM-04: thêm activation accounting

Mỗi model từ 04 trở đi nên báo bốn traffic class riêng:

```text
weight_read_bytes
weight_write_bytes
activation_spill_bytes
activation_reload_bytes

optimizer_read_bytes
optimizer_write_bytes

KV_read_bytes
KV_write_bytes
```

Không chỉ báo một `DDR GB/s`.

Bởi vì hai thiết kế có thể đều đạt 1.1 GB/s nhưng một cái dùng 80% traffic cho useful weights còn cái kia đốt bandwidth cho activation spill.

### Từ LM-05: thử recomputation nhưng giữ exactness

Từ LM-05 trở đi, nếu activation footprint bắt đầu gây DDR traffic lớn, cho phép một optimization implementation-level:

```text
checkpoint activations
        +
recompute exact intermediate states
```

với contract:

\[
\text{recomputed tensor} =
\text{original fixed-point tensor}
\]

**bit-for-bit**.

Nếu exact thì không tạo `law_id` mới; nếu arithmetic/order/rounding thay đổi thì bắt buộc new law.

### LM-07 vẫn là primary success

Tôi vẫn giữ LM-07 làm primary program success thay vì đẩy mục tiêu chính lên 4M hay 10M:

> **FPGA-native small autoregressive Transformer with FPGA-resident forward, loss, backward and update; DDR-resident trainable state; teacher-free FPGA next-token generation.**

Đây là claim khoa học mạnh hơn rất nhiều so với “10M parameters fit DDR”.

Sau LM-07 mới mở toàn bộ research space.

### MAX không đo “fit”, mà đo useful-training ceiling

MAX sweep phải dừng ở **last full PASS**, không ở model lớn nhất compile được.

Mỗi probe phải thu:

```text
parameter_count
state_bytes

WNS / TNS
LUT / FF / BRAM / DSP

seq DDR BW
effective model BW
U_MAC GEMV
U_MAC GEMM

forward cycles/token
backward cycles/token
update cycles/token

tokens/s inference
tokens/s training

CE/NLL before-after
held-out NLL/PPL
saturation

power
thermal

failure_reason
```

Và giữ nguyên luật:

```text
FITS
 ≠
RUNS
 ≠
TRAINS
 ≠
CONVERGES
 ≠
USEFUL
```

Đây cũng là tinh thần contract-first đã được ghi trong bản Copy. fileciteturn0file1

## Training nâng cao, Knowledge Distillation và Random Forest

### Optimizer roadmap mới

NeuronFabric đặt một câu hỏi rất đúng: optimizer state có thể trở thành memory bottleneck. Nhưng tôi không cho rằng Adam/BF16W là câu trả lời tối ưu ngay cho Artix-7.

Một candidate đáng nghiên cứu hơn là **Adafactor**. Adafactor thay per-element second-moment tensor của một matrix bằng row/column statistics, giảm auxiliary state của second moment từ \(O(nm)\) xuống \(O(n+m)\) cho weight matrices; paper gốc báo cáo kết quả gần Adam trên Transformer WMT14 trong thiết lập của họ. citeturn18academia25

Vì vậy optimizer research sau LM-07 nên là:

```text
A7-OPT-00
sign-SGD
frozen reference

      ↓

A7-OPT-01
momentum INT16

      ↓

A7-OPT-02
SGD + error feedback

      ↓

A7-OPT-03
Adafactor-like
factored second moment

      ↓

A7-OPT-04
BF16W + Adam-like

      ↓

compare:
quality / state bytes / DDR bytes / step
```

Tôi thực sự ưu tiên **Adafactor trước full Adam** vì problem của Arty về lâu dài có khả năng là bandwidth/state traffic chứ không phải DDR capacity đơn thuần. Đây là engineering inference dựa trên Adafactor state structure và DDR measurements hiện tại, và phải được falsify bằng measured bytes/update và held-out convergence. citeturn18academia25 fileciteturn0file10

### LoRA là branch adaptation, không được giả danh full training

LoRA freeze pretrained weights và chỉ train các low-rank adapter matrices; paper gốc cho thấy điều này giảm mạnh số trainable parameters trong large-model fine-tuning. citeturn17academia0

Nó cực kỳ hấp dẫn cho Arty, nhưng claim phải chính xác:

```text
Full model:
10M stored params

Trainable LoRA state:
perhaps much smaller
```

thì không được nói:

> “FPGA full-trained 10M model.”

Phải nói:

> “FPGA-native parameter-efficient adaptation of a larger frozen base model.”

Do đó branch:

```text
A7-PEFT
```

tách khỏi A7-LM.

### Hinton KD trở thành nền, MiniLLM là experiment sau

Hinton et al. chỉ ra rằng teacher probabilities chứa thông tin tương đối giữa các class sai và dùng temperature để tạo soft targets; mục tiêu thông thường kết hợp hard-label CE với soft-target CE, và soft-target gradient cần scaling theo \(T^2\) khi phối hợp hai objective. citeturn21view0

Đây là nền tảng phù hợp cho GrOK.

MiniLLM sau đó đề xuất reverse KLD cho generative LMs nhằm tránh student overestimating low-probability teacher regions, và paper báo cáo experiments trên model từ 120M tới 13B. citeturn8academia14turn11view5

Nhưng **MiniLLM không nên là KD loss đầu tiên trên GrOK**.

Với cloud teacher chỉ cung cấp sparse top-K:

\[
D_{KL}(p_s\|p_t)
\]

cần teacher probability ở những nơi student có mass. Nếu teacher chỉ cho top-K và phần tail không biết, reverse-KL dễ biến “unknown” thành “zero”. Đây là vấn đề đặc biệt nghiêm trọng khi còn cross-tokenizer projection.

Tôi đề xuất:

```text
Sparse cloud teacher
        ↓
Hinton-style soft CE / forward target matching FIRST

Full-logit local teacher
        ↓
MiniLLM reverse-KL experiment LATER
```

### A7-KD ladder cuối

Bản Sandboxed Multi-Teacher hiện tại đã có boundary đúng: external models chỉ cung cấp targets; host không được viết weights/gradients/optimizer state; FPGA vẫn tính student forward, loss, backward và update. fileciteturn0file5

Tôi chốt ladder KD như sau:

| KD milestone | Experiment | Claim tối đa |
|---|---|---|
| KD-00 | frozen LM regression, teacher packets=0 | KD infrastructure does not alter base |
| KD-01 | GRTS target packets qua UART + credit | reliable target transport |
| KD-02 | one teacher, `SEQ_HARD` | sequence distillation works |
| KD-03H | sparse top-K Q0.16 hardware | soft-target hardware support |
| KD-03S | hard vs soft held-out experiment | useful dark knowledge **nếu thắng** |
| KD-04 | fixed multi-teacher ensemble | heterogeneous target fusion |
| KD-05 | disagreement + RF gating | adaptive teacher selection |
| KD-06 | replay + anchors + continual | bounded continual adaptation |
| KD-07 | all teachers disconnected | teacher-off retained student |

**KD-03H và KD-03S phải tách.**

Phần cứng có thể PASS soft-target arithmetic nhưng soft KD vẫn có thể không tốt hơn hard target.

KD-03S bắt buộc ghi:

```text
original_topk_mass
mapped_probability_mass

mapped_mass:
mean
p10
p50
p90

fallback_to_SEQ_HARD %
teacher entropy
student entropy

hard baseline held-out CE
soft KD held-out CE

hard baseline PPL
soft KD PPL

calibration

>= multiple independent seeds
```

Chỉ được viết:

```text
USEFUL_DARK_KNOWLEDGE_TRANSFER
```

nếu soft target cải thiện held-out result **lặp lại được**.

Nếu chỉ training loss đẹp:

```text
NOT SUFFICIENT
```

Hinton's original motivation chính là soft probabilities có thể truyền cấu trúc generalization mà hard labels bỏ mất; vì vậy held-out experiment mới là test đúng cho claim đó. citeturn21view0

### Random Forest phải làm router, không làm LLM teacher chính

Tôi giữ quan điểm cũ nhưng nâng thành architecture law:

```text
teacher outputs
      │
      ├── mapped mass
      ├── entropy
      ├── top1-top2 margin
      ├── teacher disagreement
      ├── teacher historical accuracy
      ├── domain
      ├── student entropy
      ├── sample type
      └── anomaly score
             │
             ▼
       RANDOM FOREST
             │
     ┌───────┼────────┐
     ▼       ▼        ▼
   trust   abstain   routing
   weight           teacher
```

RF không nên cố predict token trong vocab 2K–8K. Nó nên quyết định:

> teacher nào đáng tin cho sample này?

Hoặc:

> sample này có quá nhiều disagreement nên không update?

Đây phù hợp hơn với sandbox architecture hiện có. fileciteturn0file5

### Security boundary phải là hardware boundary

Checksum chỉ chứng minh packet không bị hỏng; không chứng minh target đúng.

Do đó:

```text
HOST RX DMA
can write:
    TEACHER_INBOX
    TOKEN_INBOX
    CONTROL_MAILBOX

HOST RX DMA
CANNOT ADDRESS:
    WEIGHTS
    OPT_STATE
    TRAINABLE_EMBEDDINGS
```

Weight write invariant:

```systemverilog
weight_write_valid =
      train_enable
   && optimizer_commit
   && !freeze
   && !host_dma_owner;
```

Teacher poisoning vẫn có thể xảy ra qua malicious targets, nên semantic layer cần:

```text
quorum
disagreement abstention
anchor set
teacher rate cap
per-teacher trust
stale-target rejection
replay protection
domain cap
canary examples
```

Đó là lý do multi-teacher sandbox không thể chỉ dựa trên CRC. Bản KD hiện tại cũng đã nhận diện distinction này. fileciteturn0file5

## Những nhánh nghiên cứu không được đưa vào critical path hiện tại

### SSM/Mamba

SpecMamba xử lý speculative decoding cho Mamba với hidden-state backtracking, FIFO tree verification và hardware dataflow chuyên dụng; nó là **inference accelerator**, không phải on-FPGA Mamba training. citeturn12academia12

LowRank-SSM cũng là inference. Một correction quan trọng: paper dùng **post-training truncated SVD ở software side**, sau đó hardware hỗ trợ dual low-rank/full-rank projection path và runtime rank mask; không phải “FPGA tự chạy dynamic SVD để phân rã weights”. citeturn12academia13

Do đó:

```text
A7-LM Transformer
        │
        └── remains primary

after primary result:
        │
        └── A7-SSM
              Mamba/SSM research
```

Không đổi Transformer thành Mamba giữa LM-03…07.

### Hummingbird

Hummingbird là nguồn rất đáng đọc về **memory-bound inference** trên embedded FPGA: paper nhắm KV260/ZCU104, LLaMA3-8B, báo cáo 4.8 và 8.6 token/s và 93–94% model bandwidth utilization với offloading strategies. citeturn16academia0

Điều tôi lấy vào Master không phải một flash mapping cụ thể chưa được nguồn tôi kiểm chứng xác nhận, mà là metric:

\[
\text{Model Bandwidth Utilization}
=
\frac{\text{useful model bytes}}
{\text{available/observed memory bytes}}
\]

Từ LM-04, GrOK nên có metric tương đương.

### FlashAttention principle

FlashAttention cho thấy một nguyên lý rộng hơn GPU implementation cụ thể: attention performance có thể bị giới hạn bởi data movement, và tiling để giảm reads/writes giữa large memory và on-chip SRAM có thể quan trọng hơn chỉ giảm FLOPs. citeturn17academia1

Tôi không port FlashAttention code sang Artix.

Tôi lấy **IO-aware design law**:

> Mọi thay đổi attention phải báo cả operations và transferred bytes.

### openENOC

openENOC dùng Ethernet Layer-2 frame switching làm native NoC để nối processors, accelerators và peripherals. citeturn14view1

Đây là hướng rất thú vị nếu sau này GrOK đi:

```text
FPGA 0 — embedding
FPGA 1 — layers 0..N
FPGA 2 — layers N+1..
FPGA 3 — optimizer / specialist
```

Nhưng **không đưa vào single-Arty program**.

A7-LM và KD trước tiên dùng:

```text
UART + credit
```

sau đó nếu cần:

```text
100 Mb Ethernet
```

và chỉ khi multi-FPGA thật sự trở thành experiment mới xem:

```text
A7-NOC / openENOC-inspired
```

Arty A7 có 10/100 Ethernet, nhưng sự tồn tại của PHY không làm Ethernet stack trở thành dependency hợp lý cho việc chứng minh loss/backward. citeturn8search6

### ControlPULP

ControlPULP là một programmable RISC-V power-controller architecture với MCU, multicore cluster, DMA và FreeRTOS, nghiên cứu cho power/thermal control của many-core HPC. citeturn13academia28

Ý tưởng tốt cho một **future management plane**, nhưng hoàn toàn không phải lý do đưa MicroBlaze/RISC-V vào critical training path.

Master giữ:

```text
A7-LM-00 ... 07
NO SOFT CPU DEPENDENCY
```

Sau primary success mới có thể mở:

```text
A7-CTRL
```

để nghiên cứu telemetry, DVFS/power manager hay networking control.

## Contract nghiên cứu cuối và chỉ thị cho Grok

Từ đây, mỗi feature được đưa qua cùng một cổng quyết định:

```text
SOURCE / PAPER
      │
      ▼
What exactly was demonstrated?
      │
      ├── software only?
      ├── FPGA simulation?
      ├── board measurement?
      └── training or inference?
      │
      ▼
Does it modify numerical law?
      │
      ├── NO → implementation experiment
      │
      └── YES → new law_id / branch
      │
      ▼
Does it touch a frozen milestone?
      │
      ├── YES → FORBIDDEN
      │
      └── NO
      ▼
Define metric + falsification
      │
      ▼
board experiment
      │
      ▼
EVIDENCE
```

Ba evidence labels được giữ:

```text
EVIDENCE
→ trực tiếp hỗ trợ claim

ENGINEERING INFERENCE
→ metric + falsification bắt buộc

NEEDS EXPERIMENT
→ không dùng làm claim
```

### Diagnostic tree cuối

```text
BIT-EXACT FAIL
       │
       └─> arithmetic / RTL / DMA / ordering


BIT-EXACT PASS
CE DOES NOT DROP
       │
       └─> optimizer / fixed-point / corpus / saturation


TRAIN CE DROPS
HELD-OUT GETS WORSE
       │
       └─> overfit / catastrophic forgetting


GEMM U_MAC HIGH
GEMV U_MAC LOW
       │
       └─> weight bandwidth / tiling / DMA


BOTH U_MAC LOW
       │
       └─> FSM / pipeline / overlap


DDR BW HIGH
MODEL BW UTIL LOW
       │
       └─> wasted traffic / spill / small bursts


WNS < 0
       │
       └─> partition / pipeline / reduce lanes


SOFT KD TRAIN LOSS GOOD
HELD-OUT ~= HARD
       │
       └─> NO dark-knowledge claim


MAPPED MASS LOW
       │
       └─> SEQ_HARD fallback
```

### Những claim được phép

**Sau LM-03:**

> First board-validated scaled multi-head/multi-layer model under the frozen native-learning law.

**Sau LM-07:**

> FPGA-native small autoregressive Transformer with FPGA-resident forward, loss, backward and model updates, DDR-resident trainable state, and teacher-free autoregressive generation.

**Sau KD-03S nếu thắng hard baseline:**

> Sparse soft-target knowledge distillation provides reproducible held-out benefit over hard-target distillation on the tested FPGA student.

Không dùng “dark knowledge” nếu experiment không chứng minh câu đó.

**Sau A7-PEFT:**

> FPGA-native parameter-efficient adaptation.

Không gọi full-model training.

**Sau MAX:**

> Measured useful native-training ceiling of this Arty A7 implementation.

Không gọi model lớn nhất compile được là training ceiling.

### Chỉ thị hiện tại cho Grok

```text
CURRENT ACTIVE TASK = A7-LM-03

DO:
  continue current build
  V=128
  C=16
  d=32
  L=2
  H=2
  FF=64
  P=25,088
  BRAM persistent weights
  lm05-signsgd-v1
  exact fixed-point reference
  all-bank update evidence
  CE-drop evidence
  AFTER zero-write
  FPGA argmax
  timing closure
  immutable release

DO NOT:
  restart 03 because of these papers
  add BF16W
  add Adam
  add Adafactor
  add low-rank
  add ternary
  add LoRA
  add teacher
  add RF
  add Ethernet
  add soft CPU
  change MIG
  change frozen 00/01/02
```

Sau khi 03 BOARD_PASS:

```text
A7-LM-03 freeze
        │
        ├──── A7-KD-SHADOW
        │       dataset
        │       teacher probes
        │       tokenizer mapping
        │       mapped_mass study
        │       RF offline
        │       NO FPGA teacher-training yet
        │
        ▼
A7-LM-04
100,352 params
first persistent DDR model
        │
        ▼
A7-LM-05
399K
activation/recompute measurements
        │
        ▼
A7-LM-06
803K
        │
        ▼
A7-LM-07
1.495M
PRIMARY BOARD SUCCESS
        │
        ├──────── A7-KD live
        ├──────── A7-OPT
        ├──────── A7-QTRAIN
        ├──────── A7-LR
        ├──────── A7-PEFT
        ├──────── A7-INF
        └──────── A7-SSM
```

Đây là điểm mà deep research thay đổi roadmap theo cách có lợi nhất: **không làm roadmap rộng hơn trước 03; làm research space rộng hơn sau khi nền tảng đã chắc.**

Điểm mạnh độc đáo của GrOK không nên là “chúng ta cũng có quantization”, “chúng ta cũng có Mamba”, hay “chúng ta cũng gọi nhiều LLM teacher”. LUT-LLM, TerEffic, Hummingbird và các accelerator lớn hơn sẽ luôn thắng Artix-7 ở những benchmark nhất định. citeturn9academia3turn11view4turn16academia0

Điểm mạnh nên được đóng đinh là:

> **Một FPGA nhỏ tự giữ quyền sở hữu quá trình học: external systems có thể cung cấp data hoặc knowledge, nhưng forward, error formation, backward, optimizer decision và model-state write vẫn thuộc FPGA; mọi extension đều được thêm bằng falsifiable, immutable, contract-first experiments.**

NeuronFabric cung cấp một software-level vision rất gần với triết lý local update này nhưng chưa có FPGA evidence; Ultra Memory-Efficient cho thấy end-to-end Transformer training trên FPGA là khả thi trên phần cứng lớn hơn; còn board evidence của chính dự án bạn đã chứng minh memory foundation trên Arty hoạt động ổn định. citeturn10view0turn9academia2 fileciteturn0file10

Vì vậy **bản gốc cuối không nên “đuổi theo từng paper”**. Nó nên dùng papers như một thư viện các hypothesis có thể kiểm chứng, trong khi giữ A7-LM-03 → A7-LM-07 làm đường xương sống duy nhất tới claim native online training.