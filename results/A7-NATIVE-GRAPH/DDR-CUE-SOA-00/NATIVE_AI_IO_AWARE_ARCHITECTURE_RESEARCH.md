Tôi đã đọc các phần quan trọng của `harvard-edge/cs249r_book` trên branch `dev`, tập trung vào **Hardware Acceleration, Model Compression, Benchmarking, Performance Engineering, Inference at Scale, Edge Intelligence** và bibliography mà sách dùng. Kết luận lớn nhất là:

> **Hướng tốt nhất cho Native AI không phải làm một “GPT nhỏ hơn trên FPGA”, mà là xây một hệ thống AI stateful được hardware-software co-design quanh giới hạn data movement của Artix-7.**
>
> Tức: **DDR-resident persistent intelligence + BRAM bounded working set + IO-aware graph retrieval + frozen LM composer + một lớp native local learning cực nhỏ.**

Điều đáng chú ý là nhiều kết luận dự án hiện tại đã đi đúng hướng với literature; repo Harvard giúp chúng ta **siết lại thứ tự ưu tiên** và chỉ ra một vài thay đổi quan trọng.

---

# 1. Bài học lớn nhất từ repo: tối ưu byte trước khi tối ưu MAC

Chương Hardware Acceleration của sách nói rất rõ: accelerator không thắng chỉ vì có nhiều arithmetic units; vấn đề trung tâm là **memory wall**, và workload phải khớp với data movement pattern của phần cứng. Sách dùng Roofline để phân biệt compute-bound và bandwidth-bound, đồng thời nhấn mạnh tiling/dataflow phải tối đa hóa reuse trong giới hạn on-chip memory.

Williams, Waterman và Patterson formalize:

[
P\_{\text{attain}}
\le
\min(P\_{\text{compute}}, B\_{\text{mem}}\times I)
]

với (I) là operational/arithmetic intensity. ([eScholarship](https://escholarship.org/uc/item/78h8v7mr?utm_source=chatgpt.com "Roofline"))

Đối với Native Graph, tôi sẽ chuyển nó thành:

[
R\_{\text{candidate}}
\le
\min
\left(
R\_{\text{PE}},
\frac{B\_{\text{DDR,eff}}}
{\beta\_{\text{candidate}}}
\right)
]

và toàn query:

[
T\_{\text{query}}
\approx
\max
\left(
\frac{B\_{\text{query}}}{B\_{\text{DDR,eff}}},
\frac{O\_{\text{query}}}{R\_{\text{compute,eff}}}
\right)
\+
L\_{\text{control}}
]

Đây chính là "iron law" mà Performance Engineering chapter sử dụng: data, compute và fixed latency phải được tách riêng; tối ưu nondominant term gần như không mua được wall-clock performance.

### Hệ quả cho project

**Không tăng 16 PE → 32/64 PE.**

Wavefront hiện đã chỉ ra compute width tồn tại, nhưng sustained feed vẫn memory-bound. Đó chính xác là tình huống Roofline dự báo.

---

# 2. SOA hiện tại đúng hướng, nhưng không đủ mạnh để tự nó giải DDR

`DDR-CUE-SOA` đang hướng:

```text
AOS:
16 B/candidate
64 candidate
= 1024 B/query
```

sang lawful descriptor:

```text
node_id        32
node_cue       64
learned_prior   8
-----------------
              104 bit
```

tức:

```text
832 B/query
```

Giảm:

[
1-\frac{832}{1024}=18.75%
]

Nếu workload hoàn toàn bandwidth-bound và mọi thứ khác giữ nguyên, ceiling lý tưởng chỉ khoảng:

[
\frac{1024}{832}\approx1.23\times
]

Tức **SOA là đúng, nhưng không phải thuốc chữa 16×**.

Đây là insight quan trọng nhất tôi rút ra sau khi đọc Harvard repo:

> **Đừng đặt mục tiêu “SOA PASS rồi DDR solved”.**
>
> SOA chỉ là bước đầu của một **IO-aware graph dataflow**.

---

# 3. Hướng tôi đề xuất: IO-Aware Native Graph

FlashAttention là ví dụ rất phù hợp về *phương pháp*, mặc dù thuật toán không liên quan graph.

Dao và cộng sự không chỉ cố tính attention nhanh hơn. Họ thay đổi schedule để **không materialize tensor lớn ra HBM**, giữ tiles trong SRAM và chấp nhận thêm arithmetic nếu điều đó giảm IO. ([arXiv](https://arxiv.org/abs/2205.14135?utm_source=chatgpt.com "FlashAttention: Fast and Memory-Efficient Exact Attention with IO-Awareness"))

Sách Harvard rút ra cùng nguyên lý: khi memory-bound, tiling/fusion có thể làm thêm arithmetic nhưng vẫn chạy nhanh hơn nếu loại bỏ expensive memory round trips.

Tôi muốn áp dụng nguyên lý đó vào graph, không port FlashAttention.

### Dataflow nên trở thành

```text
                 QUERY
                   │
                   ▼
        native anchor/context
                   │
          stationary/broadcast
                   │
                   ▼
DDR compact descriptor stream
        │
        ▼
  ping/pong BRAM wave
        │
        ▼
16-lane exact scorer
        │
        ▼
wave Top-K
        │
        ▼
GLOBAL Top-K accumulator
        │
        ▼
ONLY survivors
        │
        ├── fetch relation/edge metadata
        ├── fetch episode payload
        └── bounded expansion
```

Tức nguyên tắc:

```text
SCORE CHEAP INFORMATION EARLY

FETCH EXPENSIVE INFORMATION LATE
```

Không thay scoring law.

Không thay 01R.

Không thay Top-K.

Không host hint.

---

# 4. Eyeriss cho ta một dataflow rất đáng học

Eyeriss của Chen, Krishna, Emer và Sze đi theo một nguyên lý cực kỳ phù hợp: **maximize local reuse để giảm expensive off-chip movement**, thay vì đơn giản tăng PE count. Row-stationary dataflow của họ giữ dữ liệu ở tầng memory rẻ nhất có thể và giảm DRAM accesses. ([DOI](https://doi.org/10.1109/JSSC.2016.2616357?utm_source=chatgpt.com "Eyeriss: An Energy-Efficient Reconfigurable Accelerator for Deep Convolutional Neural Networks"))

Không được copy `row-stationary` vì Native Graph không phải CNN.

Nhưng ta có thể tạo dataflow tương ứng:

## `Query-Stationary / Candidate-Streaming`

```text
FF/LUTRAM:
query cue
context
owner
epoch

         ↓ broadcast

BRAM:
candidate wave
score
global Top-K
frontier

         ↑
compact sequential DDR streams
```

Trong một scoring wave:

```text
query/context
= stationary

candidate descriptors
= streamed

Top-K
= stationary state across waves
```

Đây theo tôi là **native dataflow tự nhiên nhất cho project**.

Nó tốt hơn tư duy:

```text
PE0 gets record
PE1 gets record
...
PE15 gets record
```

mỗi cycle trực tiếp từ DDR.

---

# 5. SOA repair hiện tại: literature càng củng cố việc reuse một transport engine

Từ nguyên lý trên, tôi vẫn giữ phương án tôi đưa trước đó:

```text
SOA semantic scheduler
        ↓
generic/proven AXI burst engine
        ↓
R skid FIFO
        ↓
SOA unpack
        ↓
BRAM wave
```

Không:

```text
SOA FSM
+ AXI controller
+ semantic unpacker
+ completion FSM
```

trộn chung.

Với 64 candidates, descriptor hiện tại đẹp đến mức có thể schedule:

```text
ID:
16 beats

CUE:
16 + 16 beats

PRIOR:
4 beats
```

Tức:

```text
4 AXI burst transactions
52 R beats
832 bytes
```

Đó phù hợp tư tưởng của cả Roofline, Eyeriss và FlashAttention:

> **contiguous movement → local working memory → extensive local work.**

---

# 6. Nhưng có một đòn bẩy lớn hơn SOA: toàn bộ lifetime của BRAM

Đây là chỗ MCUNet rất đáng tham khảo bổ sung.

Lin và cộng sự không chỉ làm model nhỏ. TinyEngine lên lịch memory dựa trên **whole-network topology**, thay vì tối ưu từng layer độc lập; họ báo cáo giảm peak memory đáng kể nhờ co-design architecture + runtime. ([arXiv](https://arxiv.org/abs/2007.10319?utm_source=chatgpt.com "MCUNet: Tiny Deep Learning on IoT Devices"))

Áp dụng vào project, chúng ta không nên hỏi:

```text
LM = ? BRAM
graph = ? BRAM
01R = ? BRAM
02M = ? BRAM
```

rồi cộng lại.

Phải xây **buffer lifetime graph**:

# [ B\_{\text{peak}}

\max\_t
\sum\_{i\in live(t)} B\_i
]

Nếu phases thực sự exclusive:

# [ B\_{\text{peak}}

B\_{\text{always}}
\+
\max
(
B\_{\text{graph}},
B\_{\text{LM}},
B\_{\text{encoder}}
)
]

chứ không phải:

[
B\_{\text{graph}}+B\_{\text{LM}}
]

### Đây là hướng BRAM tôi đánh giá tốt nhất

Không:

```text
132 → 96 → 64 → 48 → 32
```

một cách mù.

Mà:

```text
TRACE lifetime
        ↓
find peak overlap
        ↓
remove unnecessary overlap
        ↓
phase-share physical arena
        ↓
only then shrink working set
```

---

# 7. TinyTL có một insight cực kỳ quan trọng cho LM06

Đây có lẽ là paper trong hệ reference Harvard có liên hệ trực tiếp nhất đến tình trạng hiện tại.

Cai, Gan, Zhu và Han viết TinyTL với luận điểm:

> giảm số **trainable parameters** không nhất thiết giảm training memory, vì **activations mới có thể là bottleneck chính**. ([arXiv](https://arxiv.org/abs/2007.11622?utm_source=chatgpt.com "TinyTL: Reduce Activations, Not Trainable Parameters for Efficient On-Device Learning"))

Sách Harvard cũng dùng TinyTL khi thảo luận adaptation trên thiết bị cực hạn và nhấn mạnh bias-only/frozen-backbone để giữ memory bounded.

Điều này map cực sát với LM06:

```text
u_w      64
u_a      66
u_snap    2
```

Persistent weights vốn đã DDR.

Vì vậy:

> **Trọng tâm nghiên cứu LM06 không nên là "nén parameter mạnh hơn" trước tiên.**
>
> Phải hiểu **activation lifetime / reuse / overwrite / recompute / spill**.

Đây là lý do tôi càng chắc rằng:

```text
LM06-WM-TRACE-00
```

phải đo riêng:

```text
u_a lifetime
u_a reuse distance
simultaneously-live words
phase-local peak
sequential regions
recompute opportunity
dirty state
```

---

# 8. Một công thức mới tôi muốn đưa vào project

Không chỉ:

```text
BRAM allocated
```

mà:

# [ M\_{\text{live}}(t)

\sum\_i
valid\_i(t)\times size\_i
]

và:

# [ M\_{\text{peak}}

\max\_t M\_{\text{live}}(t)
]

Sau đó với mỗi logical buffer:

```text
birth cycle
last-read cycle
writes
reads
reuse distance
phase
persistent?
dirty?
recomputable?
```

Từ đó mới quyết định:

```text
KEEP BRAM
SPILL DDR
RECOMPUTE
OVERLAY
PING-PONG
```

Đây là cách mạnh hơn việc chỉ nhìn `report_ram_utilization`.

---

# 9. Harvard Edge Intelligence xác nhận triết lý Native AI hiện tại

Chương này có một thông điệp rất giống thiết kế của dự án:

> với thiết bị hạn chế, nên freeze large backbone và giới hạn adaptation vào các state/module nhỏ; full fine-tuning làm activation, gradient và optimizer footprint tăng mạnh.

Nó phân cấp:

```text
bias-only
↓
small adapter
↓
LoRA
↓
sparse/selective fine-tuning
↓
full fine-tuning
```

theo resource capability.

Tôi sẽ map sang Native AI:

```text
Harvard edge architecture       Native AI

frozen backbone                 frozen LM-06
       │                             │
small local adaptation          path/relation scoring
       │                             │
local state                     graph learned state
       │                             │
replay buffer                   episodic memory
       │                             │
adapter                         future NAE/NPU
```

Đây không phải proof project đúng, nhưng **là một architectural precedent rất mạnh**.

---

# 10. NPU vì vậy càng đáng ưu tiên hơn LoRA cho V1.x

LoRA của Hu và cộng sự freeze backbone rồi học low-rank matrices. ([arXiv](https://arxiv.org/abs/2106.09685?utm_source=chatgpt.com "LoRA: Low-Rank Adaptation of Large Language Models"))

Nhưng TinyTL nhắc chúng ta:

```text
few trainable weights
≠
cheap training automatically
```

Nếu LoRA vẫn cần deep forward/backward và giữ activations/errors, memory problem vẫn tồn tại.

Trong khi NPU:

```text
existing candidate features
        ↓
score+
score-
        ↓
margin compare
        ↓
local integer update
```

không cần deep backward graph.

Vì vậy tôi xếp:

```text
V1:
graph/episode existing local learning

V1.x:
NPU pairwise path/relation update

V1.5:
small Adaptive Encoder

V2:
LoRA / low-rank neural adapter

V3+:
partial LM learning
```

Passive-Aggressive literature cũng cung cấp nền tảng toán học chuẩn cho online margin update thay vì phải phát minh optimizer phức tạp. ([Journal of Machine Learning Research](https://www.jmlr.org/papers/v7/crammer06a.html?utm_source=chatgpt.com "Online Passive-Aggressive Algorithms"))

---

# 11. Episodic memory nên được dùng như continual-learning replay

Edge Intelligence chapter cũng nhấn mạnh **experience replay** để giảm catastrophic forgetting.

Rolnick và cộng sự cho thấy replay một tập bounded các trải nghiệm cũ có thể giảm forgetting trong continual learning; ngay cả buffer có giới hạn vẫn hữu ích. ([arXiv](https://arxiv.org/abs/1811.11682?utm_source=chatgpt.com "Experience Replay for Continual Learning"))

Native AI đã có `02M episodic memory`.

Tôi sẽ không biến 02M thành neural replay buffer ngay trong V1.

Nhưng về kiến trúc tương lai:

```text
new training example
        +
small sample of old episodes
        ↓
NPU / NAE update
```

là hướng nghiên cứu rất tự nhiên.

Đặc biệt teacher không cần gửi replay address.

FPGA phải tự sample/resolve episodes.

---

# 12. Quantization: Harvard repo củng cố đúng doctrine hiện nay

Model Compression chapter nói thẳng:

- INT8 thường dễ hơn.
- INT4 và thấp hơn phụ thuộc model/method nhiều hơn.
- phải validate **per model/per task**.
- compression chỉ tạo runtime speed nếu hardware thực sự khai thác representation đó.

Nó cũng cảnh báo unstructured sparsity thường chỉ tiết kiệm storage nếu accelerator không có sparse engine; structured forms dễ biến thành real speedup hơn.

Do đó với LM06:

```text
W4A8
```

vẫn đáng nghiên cứu sau này để giảm DDR traffic.

AWQ là ví dụ tốt cho weight-only low-bit hardware-aware quantization; paper đặc biệt dùng activation statistics để bảo vệ salient weight channels thay vì naïvely quantize tất cả như nhau. ([arXiv](https://arxiv.org/abs/2306.00978?utm_source=chatgpt.com "AWQ: Activation-aware Weight Quantization for LLM Compression and Acceleration"))

Nhưng:

> **W4 không giải 66 BRAM** **`u_a`****.**

Do đó không cho nó chen vào critical V1 path.

---

# 13. Một thay đổi doctrine tôi rất khuyến nghị

Hiện ta hay nói:

```text
DDR = persistent
BRAM = working set
```

Sau nghiên cứu này, tôi sẽ nâng thành:

```text
DDR CAPACITY
│
├── DDR_STREAM
│   ├── LM weight tiles
│   ├── compact candidate planes
│   └── coalesced checkpoint/writeback
│
└── DDR_SPARSE
    ├── survivor metadata
    ├── edges
    ├── relations
    └── episodes


BRAM WORKING SET
│
├── staged descriptor wave
├── LM active tiles
├── activations
├── frontier
├── global Top-K
└── update buffer


LUTRAM / FF
│
├── query/context
├── counters
├── owner/epoch/valid
├── queue pointers
└── hottest score/control state
```

Đây là version mạnh hơn của memory architecture hiện nay.

---

# 14. Và DDR arbiter không nên fair-share GRAPH với LM mỗi cycle

Các paper/dataflow lessons đều dẫn đến một kết luận:

> **burst locality có giá trị hơn fine-grained fairness** trong workload hiện tại.

Do đó tôi vẫn thích:

```text
GRAPH
  ↓
DRAIN
  ↓
OWNER SWITCH
  ↓
LM
  ↓
DRAIN
  ↓
GRAPH
```

hơn:

```text
cycle0 graph
cycle1 lm
cycle2 graph
cycle3 lm
```

Fine-grained arbitration có thể phá sequential streaming.

---

# 15. Benchmarking chapter nói đúng chính xác vấn đề project đang gặp

Harvard nhấn mạnh:

> peak specification không phải sustained performance; phải benchmark ở micro, model và end-to-end level, trong representative workload.

Tôi muốn Native V1 có ba lớp metric chính thức:

| LớpĐo gì            |                                                                       |
| ------------------- | --------------------------------------------------------------------- |
| **Transport micro** | AR/R conservation, useful bytes, burst efficiency, latency            |
| **Native kernel**   | candidates/cycle, bytes/query, memory\_wait, global Top-K correctness |
| **End-to-end AI**   | raw query → retrieval → LM → FPGA token, quality + latency            |

Không được dùng:

```text
16 candidates/emission
```

để suy thành:

```text
16 candidates/cycle sustained
```

Và cũng không được dùng:

```text
832 B/query
```

để suy thành:

```text
23% faster
```

cho tới khi benchmark.

---

# 16. Hướng đi tối ưu tôi đề xuất từ giờ

Tôi sẽ thay roadmap kỹ thuật thành:

```text
PHASE A — FIX IO CORRECTNESS
──────────────────────────
DDR-CUE-SOA-00R-AXI-LIVENESS
        ↓
4 burst stream
R skid FIFO
scoreboard
832 bytes exact
        ↓
STOP / REVIEW


PHASE B — PROVE IO VALUE
────────────────────────
DDR-CUE-SOA-BENCH-01
AOS vs SOA
same candidate set
same law
        ↓
bytes/query
memory_wait
candidate/cycle
query latency
        ↓


PHASE C — IO-AWARE GRAPH
────────────────────────
GRAPH-LATE-MATERIALIZE-00
        ↓
compact early score
global Top-K
late edge/episode payload
        ↓


PHASE D — LM MEMORY PHYSICS
───────────────────────────
LM06-WM-TRACE-00
        ↓
u_w / u_a / u_snap
lifetime
reuse
MRC
peak-live
        ↓
choose ONE WM candidate
        ↓
P&R


PHASE E — GLOBAL MEMORY
───────────────────────
BRAM-OWNER-00
        ↓
phase-shared physical arena


PHASE F — REAL INTELLIGENCE PATH
────────────────────────────────
HS22-LM06-ACTIVE-00
        ↓
ONE real LM06
        ↓
FPGA token


PHASE G — EXAM
──────────────
HS02 teacher-off
```

Sau đó mới:

```text
NPU
↓
NAE
↓
W4/LoRA research
```

---

# 17. Nếu chỉ chọn một “big architectural bet”

Tôi sẽ chọn:

## **IO-Aware Stateful Native AI**

Không phải:

```text
FPGA Transformer
```

và cũng không phải:

```text
FPGA graph database
```

Mà:

```text
             FROZEN NEURAL CORE
                    LM06
                     ▲
                     │
               structured evidence
                     │
        ┌────────────┴────────────┐
        │                         │
 persistent graph           episodic memory
        │                         │
        └──────────┬──────────────┘
                   │
            sparse retrieval
                   │
         native learned ranking
                   │
             adaptive query
                   ▲
                   │
               user bytes
```

Toàn hệ thống được thiết kế sao cho:

```text
CAPACITY lives in DDR

USEFUL CURRENT STATE lives in BRAM

HOT CONTROL lives in FF/LUTRAM

COMPUTE follows DATA

LEARNING mutates small local persistent state

LM composes, not stores all knowledge
```

Đây theo tôi là architecture phù hợp Artix-7 hơn nhiều so với cố biến XC7A100T thành GPU.

---

# 18. Điều mới quan trọng nhất từ nghiên cứu này

Tôi rút ra **bốn thay đổi thật sự đáng đưa vào Master Blueprint**:

1. **Adopt an Iron-Law gate**: mỗi optimization phải nói rõ nó giảm `D_vol`, tăng `BW_eff`, tăng `R_eff`, hay giảm `L`. Nếu không chỉ ra được term nào thì chưa implement.
2. **Adopt whole-system buffer lifetime analysis** từ tư duy TinyEngine: BRAM peak phải tính theo lifetime, không theo sum module.
3. **Prioritize activation working set**, đặc biệt `u_a`, theo insight TinyTL; parameter compression không được giả định là memory solution.
4. **Make graph retrieval IO-aware** theo bài học FlashAttention/Eyeriss: giữ state có reuse on-chip, stream compact descriptors, chỉ materialize expensive payload sau khi survivor đã được xác định.

---

## Các nguồn nghiên cứu cốt lõi

| Công trìnhĐiều nên học                                                               |                                                                                                                                                                                                                              |
| ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Williams, Waterman, Patterson — **Roofline**, CACM 2009, DOI 10.1145/1498765.1498785 | Xác định bandwidth vs compute bound ([eScholarship](https://escholarship.org/uc/item/78h8v7mr?utm_source=chatgpt.com "Roofline"))                                                                                            |
| Horowitz — **Computing's Energy Problem**, ISSCC 2014                                | Data movement/energy là constraint cấp kiến trúc ([DOI](https://doi.org/10.1109/ISSCC.2014.6757323?utm_source=chatgpt.com "1.1 Computing's energy problem (and what we can do about it)"))                                   |
| Chen, Krishna, Emer, Sze — **Eyeriss**, JSSC 2017                                    | Local reuse + dataflow > thêm arithmetic units ([DOI](https://doi.org/10.1109/JSSC.2016.2616357?utm_source=chatgpt.com "Eyeriss: An Energy-Efficient Reconfigurable Accelerator for Deep Convolutional Neural Networks"))    |
| Dao et al. — **FlashAttention**, 2022                                                | IO-aware exact reformulation + SRAM tiling ([arXiv](https://arxiv.org/abs/2205.14135?utm_source=chatgpt.com "FlashAttention: Fast and Memory-Efficient Exact Attention with IO-Awareness"))                                  |
| Cai et al. — **TinyTL**, NeurIPS 2020                                                | Activation memory có thể quan trọng hơn trainable parameter count ([arXiv](https://arxiv.org/abs/2007.11622?utm_source=chatgpt.com "TinyTL: Reduce Activations, Not Trainable Parameters for Efficient On-Device Learning")) |
| Lin et al. — **MCUNet/TinyEngine**, 2020                                             | Whole-network memory scheduling + HW-aware architecture ([arXiv](https://arxiv.org/abs/2007.10319?utm_source=chatgpt.com "MCUNet: Tiny Deep Learning on IoT Devices"))                                                       |
| Hu et al. — **LoRA**, 2021                                                           | Frozen backbone + bounded trainable state ([arXiv](https://arxiv.org/abs/2106.09685?utm_source=chatgpt.com "LoRA: Low-Rank Adaptation of Large Language Models"))                                                            |
| Rolnick et al. — **Experience Replay for Continual Learning**                        | Bounded episodic replay chống forgetting ([arXiv](https://arxiv.org/abs/1811.11682?utm_source=chatgpt.com "Experience Replay for Continual Learning"))                                                                       |
| Crammer et al. — **Passive-Aggressive Algorithms**, JMLR 2006                        | Nền tảng toán học cho NPU/online margin learning ([Journal of Machine Learning Research](https://www.jmlr.org/papers/v7/crammer06a.html?utm_source=chatgpt.com "Online Passive-Aggressive Algorithms"))                      |
| Lin et al. — **AWQ**                                                                 | Hardware-aware low-bit weight representation ([arXiv](https://arxiv.org/abs/2306.00978?utm_source=chatgpt.com "AWQ: Activation-aware Weight Quantization for LLM Compression and Acceleration"))                             |

**Kết luận cuối:** repo Harvard không đưa ra một RTL để chúng ta copy. Giá trị lớn của nó là làm rõ **phương pháp thiết kế**. Và phương pháp đó ủng hộ rất mạnh việc dự án tiếp tục theo hướng **memory-first, IO-aware, phase-shared, frozen-backbone + bounded local learning**, thay vì tăng PE hoặc cố nhồi một Transformer lớn hơn vào FPGA. Với tình trạng hiện tại, tôi sẽ **không đổi critical path**: sửa dứt điểm `DDR-CUE-SOA-00R`, rồi chứng minh SOA có giá trị bằng benchmark, sau đó mới chuyển sang LM activation/lifetime và phase-shared BRAM.