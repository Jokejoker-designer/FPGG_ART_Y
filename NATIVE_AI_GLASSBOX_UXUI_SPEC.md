# NATIVE AI GLASSBOX — UX/UI PRODUCT DESIGN SPEC

**Document type:** Product UX/UI specification  
**Product name:** Native AI GlassBox Studio  
**Target platform:** Desktop-first web application  
**Primary device:** Laptop/Desktop, 1440×900 and above  
**Secondary device:** Tablet landscape  
**Language:** Vietnamese-first, English technical labels where necessary  
**Audience:** End users, students, researchers, engineers  
**Primary goal:** Make the internal operation of Native AI understandable to people who know nothing about AI, while preserving a path down to exact FPGA/RTL evidence.  
**Implementation stage:** After Native AI V1 is functionally frozen.  
**GlassBox capture backend:** LiteScope + Native AI telemetry + snapshot plane  
**Scientific rule:** The UI may simplify explanations, but must never invent semantics or present simulation/twin data as silicon evidence.

---

# 1. PRODUCT VISION

Native AI GlassBox Studio is not a debugging console disguised as a product.

It is a finished end-user application that lets a person interact with Native AI and visually follow what happens from the moment they send a message until the FPGA produces a response.

The interface must answer, in order:

1. What did the user give the AI?
2. How was the input converted into machine data?
3. What internal representation was created?
4. What did the AI compare?
5. Did the AI decide to learn? Why?
6. What actually changed inside the model?
7. What memory was written or retrieved?
8. What did the language/model-processing path do?
9. Which output token was selected?
10. What happened electrically/cycle-by-cycle on the FPGA?
11. Is the model learning well, or collapsing?
12. Is the displayed evidence from BOARD, XSIM, TWIN, or derived analysis?

The central product promise is:

> **Every user interaction can be traced from human input → AI state → learning → memory → model processing → FPGA waveform → output.**

---

# 2. NON-NEGOTIABLE UX PRINCIPLE

The application must separate:

## 2.1 Hidden product requirements

These are implementation constraints for the design team and must **not** appear as explanatory text on normal end-user screens.

Examples:

- LiteScope capture groups.
- HLB rules.
- Exact FPGA signal names.
- Evidence provenance.
- Frozen milestone rules.
- Trigger-buffer implementation.
- DDR architecture.
- Mathematical definitions.
- Trace serialization details.

They influence the UI, but they are not automatically shown to ordinary users.

## 2.2 Actual screen content

Every visible screen must look like a real finished application.

Visible content should be:

- current interaction;
- real values;
- real graphs;
- real status;
- real controls;
- natural Vietnamese labels;
- concise contextual hints;
- real timestamps;
- real model state;
- real memory events;
- real waveform data.

The product must never fill the screen with implementation instructions such as:

- “This area is used to…”
- “Place graph here…”
- “Developer note…”
- “TODO…”
- “This button should…”
- “Mockup…”
- “Lorem ipsum…”

Those belong only in this specification.

---

# 3. TARGET USERS

## 3.1 Curious end user

A nontechnical person who asks the AI a question and wants to see “what happened inside.”

Needs:

- very clear flow;
- little jargon;
- strong visual hierarchy;
- plain-language explanations;
- obvious cause-and-effect.

## 3.2 Student

Wants to understand how AI, memory, learning and FPGA hardware connect.

Needs:

- ability to expand details;
- readable diagrams;
- simple explanations linked to exact numbers;
- replay and comparison.

## 3.3 AI researcher

Wants to inspect:

- representation;
- distance;
- margin;
- effective rank;
- saturation;
- learning updates;
- AUC/AP;
- episode behavior;
- model state.

Needs exact metrics and exportable evidence.

## 3.4 FPGA engineer

Wants:

- raw cycle data;
- LiteScope waveform;
- trigger;
- clock-domain context;
- memory transactions;
- exact signal values;
- WNS/TNS/build identity;
- artifact hashes.

Needs a direct path to RTL-level evidence without contaminating the beginner experience.

---

# 4. EXPERIENCE MODEL

The same underlying interaction is displayed at three levels.

## 4.1 DỄ HIỂU

For people who know nothing about AI.

Examples:

- “AI đang đọc tin nhắn của bạn.”
- “Ví dụ này hiện đang gần nhóm sai hơn.”
- “AI vừa thay đổi 286 giá trị đã học.”
- “Đã tìm thấy một ký ức phù hợp.”
- “Mô hình đã chọn ‘Artix’ làm token tiếp theo.”

## 4.2 RESEARCH

Shows scientific state.

Examples:

- `d_pos = 1320`
- `d_neg = 4810`
- `M_L1 = +3490`
- `effective_rank = 19/32`
- `hidden saturation = 2.1%`
- `AUC = 0.742`
- `Δweights = 286`

## 4.3 RTL

Shows hardware truth.

Examples:

- FSM state
- clock cycle
- `valid/ready`
- memory address
- update enable
- BRAM/DDR transaction
- LiteScope waveform
- exact registered values

All three modes must reference the same `interaction_id`.

The mode switch changes presentation, not data authority.

---

# 5. PRODUCT NAVIGATION

The main navigation follows the actual AI processing sequence.

1. **Tổng quan**
2. **Tương tác**
3. **Dữ liệu vào**
4. **Biểu diễn**
5. **So sánh**
6. **Học**
7. **Bộ nhớ**
8. **Mô hình**
9. **Đầu ra**
10. **Sóng FPGA**
11. **Sức khỏe**
12. **Replay**
13. **Bằng chứng**

The user can move freely between tabs, but the order communicates the causal flow.

---

# 6. GLOBAL APP SHELL

## 6.1 Top bar

Always visible.

### Left

**Native AI GlassBox**

`Native-V1`

### Center

`Interaction #1842`

Current mode:

`TRAIN` / `EVAL` / `FROZEN`

### Right

Connection status:

`● FPGA ĐANG KẾT NỐI`

or

`○ FPGA CHƯA KẾT NỐI`

Evidence badge:

`BOARD` / `XSIM` / `TWIN`

Clock:

`100 MHz`

Build:

`7CEBA85…`

## 6.2 Main process strip

Persistent below the header:

`INPUT → ENCODE → COMPARE → LEARN → MEMORY → MODEL → OUTPUT`

Each stage has four states:

- waiting;
- active;
- complete;
- error.

The strip also serves as navigation.

## 6.3 Persistent interaction context

When a user selects an interaction, all tabs remain locked to that interaction.

Example:

`Đang xem Interaction #1842 · 10:32:15.481`

This prevents different charts from silently showing unrelated transactions.

---

# 7. DESIGN SYSTEM

## 7.1 Visual character

The product should feel:

- scientific;
- precise;
- premium;
- calm;
- modern;
- approachable;
- not “hacker terminal”;
- not toy-like;
- not cyberpunk;
- not visually noisy.

## 7.2 Theme

Primary theme: dark interface optimized for charts and waveform visibility.

Optional light theme may be added later.

## 7.3 Color roles

Use semantic color roles consistently.

- **Primary action:** cool blue/cyan family
- **Healthy/pass:** green
- **Attention:** amber
- **Failure/collapse:** red
- **Learning/update:** violet
- **Memory:** teal
- **Model processing:** blue
- **Output:** green
- **Inactive:** neutral gray

Exact design tokens should be defined once in the implementation design system.

## 7.4 Typography

Recommended:

- UI: Inter / IBM Plex Sans / system sans
- Numbers/RTL: IBM Plex Mono / JetBrains Mono

Use tabular numerals where possible.

## 7.5 Corners

Cards: `12–16 px`

Controls: `8–12 px`

Pills/status: fully rounded.

## 7.6 Density

Default density: comfortable.

A research-density option can reduce spacing and expose more telemetry.

---

# 8. GRAPH DESIGN RULES

Graphs are not decoration. Every graph must answer one question.

## 8.1 Use

| Data | Visualization |
|---|---|
| Process flow | Animated stage flow |
| Stage duration | Waterfall / Gantt-like timeline |
| Input bytes/tokens | Token strip |
| Hidden vector | Heatmap / horizontal bar matrix |
| Representation relationship | 2D projection with `MINH HỌA 2D` badge |
| Distance | Horizontal comparison bars |
| Margin | Centered gauge |
| Weight change | Delta heatmap |
| Update distribution | Histogram |
| Long-horizon learning | Line chart vs update count |
| Representation health | Multi-line trend |
| Memory candidate reduction | Funnel |
| Memory occupancy | Density map |
| Layer runtime | Waterfall |
| Next-token selection | Ranked horizontal bars |
| DDR bandwidth | Time-series |
| FPGA signals | Digital waveform |
| Before/after | Side-by-side + delta |

## 8.2 Avoid

Do not use:

- radar charts for 32-dimensional hidden vectors;
- meaningless 3D neural network balls;
- decorative “brain glow” graphics;
- unlabeled gauges;
- 3D pie charts;
- giant node-link diagrams for 800k episodes;
- animations not driven by actual data.

---

# 9. TAB 1 — TỔNG QUAN

## Purpose

Answer in under five seconds:

> “AI đang làm gì ngay bây giờ?”

## Layout

### Left — Current interaction

**Câu hỏi hiện tại**

`Board hiện tại dùng chip gì?`

`Interaction #1842`

`10:32:15`

Buttons:

`Xem chi tiết`

`Replay`

### Center — Live AI process

Large animated pipeline:

`Đọc → Biểu diễn → So sánh → Học → Bộ nhớ → Mô hình → Trả lời`

### Right — Current state

**Trạng thái**  
`Đang học`

**Teacher**  
`Bật`

**Thay đổi**  
`286 giá trị`

**Bộ nhớ**  
`Episode #512`

**Model**  
`802.816 tham số`

**Đầu ra**  
`7 token`

## Bottom — Processing waterfall

| Stage | Duration |
|---|---:|
| Input | 0.8 ms |
| Encode | 4.3 ms |
| Compare | 1.4 ms |
| Learn | 11.9 ms |
| Memory | 8.7 ms |
| Model | 61.2 ms |
| Output | 5.6 ms |

## Plain-language event banner

`AI vừa học từ tương tác này.`

`286 giá trị đã thay đổi và Episode #512 đã được cập nhật.`

Do not show this unless backed by actual telemetry.

---

# 10. TAB 2 — TƯƠNG TÁC

## Purpose

The normal user-facing conversational interface.

It must feel like a polished AI product first.

## Main pane

User:

`Board hiện tại dùng chip gì?`

AI:

`Arty A7 sử dụng FPGA Artix-7.`

## Message metadata

`92 ms · 7 token · Episode #512`

Optional status:

`Đã học`

or

`Không cần học thêm`

## Interaction inspector

Selecting a message opens a right-side panel with:

- timestamp;
- mode;
- teacher state;
- learn/freeze state;
- memory result;
- model latency;
- output tokens;
- evidence source.

Primary CTA:

**Xem bên trong tương tác này**

---

# 11. TAB 3 — DỮ LIỆU VÀO

## Purpose

Explain how text becomes machine input.

## Main visualization

Token/byte strip.

Example:

`F  P  G  A     n  à  o`

Below:

`46 50 47 41 ...`

Hex on hover:

`0x46`

## Detail drawer

**Ký tự**  
`A`

**UTF-8**  
`0x41`

**Vị trí**  
`3`

**Embedding row**  
`E[65]`

## Embedding visualization

Use compact heatmap/barcode.

## Beginner copy

`Mỗi ký tự được đổi thành số trước khi đi vào phần học của FPGA.`

---

# 12. TAB 4 — BIỂU DIỄN

## Purpose

Answer:

> “AI đang biến input thành trạng thái nội bộ như thế nào?”

Do not claim individual dimensions have human-readable semantic meaning.

## Main hidden-state heatmap

Rows:

- Anchor
- Positive
- Negative

Columns:

`h0 … h31`

## Vector detail

Show:

`32 chiều`

`Max |h|`

`Mean |h|`

`Saturation`

`Effective rank`

## 2D projection

Show A / P / N as points.

Badge:

`MINH HỌA 2D`

Tooltip:

`Quyết định thực tế được tính trên vector đầy đủ trong FPGA.`

## Before/after toggle

`Trước khi học`

`Sau khi học`

Animated transition is allowed only when generated from recorded states.

---

# 13. TAB 5 — SO SÁNH

## Purpose

Explain why the model decided whether or not to learn.

## Relationship layout

**Anchor**  
`FPGA nào đang dùng?`

**Positive**  
`Board hiện tại dùng chip gì?`

**Negative**  
`Giá máy lạnh bao nhiêu?`

## Distance bars

`Đúng        ██████                   1320`

`Sai         ███████████████████      4810`

## Margin gauge

Left: `Cần học`

Center: `Ngưỡng`

Right: `Đã phân biệt tốt`

Current marker:

`+3490`

## Decision card

Success:

**Không cần cập nhật**

`Ví dụ đúng đã gần Anchor hơn ví dụ sai.`

Violation:

**Cần học thêm**

`Ví dụ sai đang quá gần Anchor.`

## Research metrics

Expandable:

- `d_pos`
- `d_neg`
- `M_L1`
- `M_cos`
- norm
- `dH`

Cosine must be labeled `ĐO / EVAL` when it is not part of the training authority.

---

# 14. TAB 6 — HỌC

## Purpose

Show exactly what changed inside the learned state.

## Summary cards

`9.216 giá trị học`

`286 giá trị thay đổi`

`141 tăng`

`145 giảm`

`0 clipped`

`12.4 ms`

## Weight-delta heatmap

Default mode:

**Δ only**

Optional:

- Before
- After
- Before → After

For `Wh`, use a 32×32 matrix.

For embedding, show rows changed in this interaction.

## Update histogram

Negative / zero / positive update distribution.

## Learning event timeline

`Compare → Margin violated → Update enabled → 286 writes → Update complete`

Each event is clickable.

## Causal summary

`AI cập nhật vì khoảng cách với ví dụ đúng chưa tốt hơn ví dụ sai đủ mức yêu cầu.`

## No invented gradient

If FPGA does not expose an exact gradient quantity, do not draw a fake gradient vector.

Instead show:

- update direction;
- update enable;
- changed addresses;
- before value;
- delta;
- after value.

A host-twin estimate must be labeled:

`MÔ HÌNH / KHÔNG PHẢI BOARD`

---

# 15. TAB 7 — BỘ NHỚ

## Purpose

Answer:

> “AI đã tìm ký ức nào và tìm bằng cách nào?”

## Retrieval funnel

Example:

`800.000 episodes`

↓

`126 postings`

↓

`9 candidate`

↓

`3 full-key checks`

↓

`Episode #488271`

## Episode card

**Episode #488271**

`Được học tại Interaction #932`

`Truy cập gần nhất: #1842`

`Cue: …`

`Payload: …`

`Confidence/state: …`

## Multi-cue map

Show only selected episode and linked cues.

## DDR density map

Visualize occupancy by page/block.

Do not render hundreds of thousands of literal boxes.

## Memory event stream

- READ
- WRITE
- HIT
- MISS
- INSERT
- UPDATE
- EVICT

Each event should link to exact underlying FPGA evidence if available.

---

# 16. TAB 8 — MÔ HÌNH

## User-facing name

**Mô hình xử lý**

Avoid claiming hidden activation equals human thought.

## Model pipeline

`Embedding → Layer 1 → Attention → Layer 2 → Memory context → LM head`

## Layer cards

Example:

**Layer 1**

`14.2 ms`

`128 chiều`

`Saturation 0.4%`

`DDR 42 KB`

`MAC 18.240 cycles`

## Model waterfall

Horizontal stage duration chart.

## Memory context injection

When an episode influences the model, show a real connection:

`Episode #488271 → Context → Model`

## Research panel

Optional:

- activation norm;
- saturation;
- MAC cycles;
- DDR bytes;
- stalls;
- context length;
- layer index.

---

# 17. TAB 9 — ĐẦU RA

## Purpose

Show how response tokens are produced.

## Current generated text

`Arty A7 sử dụng FPGA Artix-7.`

## Token timeline

`Arty → A7 → sử → dụng → Artix → - → 7`

Each token is clickable.

## Candidate ranking

For selected generation step:

`Artix      72%  █████████████████████`

`FPGA       11%  ███`

`AMD         7%  ██`

`board       4%  █`

If the model outputs scores rather than normalized probabilities, label them as **scores**, not percentages.

## Selection event

`SELECTED: Artix`

`cycle 8.218.441`

`interaction #1842`

## Trace-back action

**Xem vì sao token này xuất hiện**

Drawer:

- retrieved episode;
- model stage;
- relevant telemetry;
- exact waveform marker.

---

# 18. TAB 10 — SÓNG FPGA

## Purpose

Expose the raw silicon-level story.

LiteScope is the primary capture engine.

## Capture groups

### GROUP 0 — INPUT

Recommended:

- interaction ID;
- input valid;
- byte/token;
- sequence position;
- train/freeze;
- teacher flag;
- command state.

### GROUP 1 — FORWARD

Recommended:

- encoder state;
- embedding address;
- hidden index;
- MAC valid;
- accumulator;
- activation;
- clip/saturation;
- layer index.

### GROUP 2 — LEARNING

Recommended:

- A/P/N phase;
- d_pos;
- d_neg;
- margin;
- violation;
- update enable;
- write address;
- previous value;
- update delta;
- new value.

### GROUP 3 — DDR / MEMORY

Recommended:

- AXI/DDR request;
- read/write;
- address;
- wait/stall;
- cue;
- bucket/index;
- candidate ID;
- Hamming score;
- episode ID;
- hit/miss.

### GROUP 4 — OUTPUT

Recommended:

- LM stage;
- output-ready;
- candidate token;
- selected token;
- argmax/sampler;
- output-valid.

## Waveform layout

Sidebar: group visibility.

Top: capture controls.

Main: digital waveform.

Bottom: cursor inspector.

## Event annotations

Mandatory annotation lane above raw waveform:

- User input accepted
- Hidden complete
- Margin violation
- Update started
- Episode hit
- LM context loaded
- Token emitted

## Trigger presets

- Khi người dùng gửi câu hỏi
- Khi AI bắt đầu học
- Khi weight thay đổi
- Khi saturation xảy ra
- Khi memory HIT
- Khi memory MISS
- Khi sinh token
- Khi có lỗi
- Tùy chỉnh

## Capture controls

`Pre-trigger`

`Post-trigger`

`RLE`

`Subsampling`

`Single`

`Auto`

`Export`

Supported export when backend supports it:

- VCD
- CSV
- Sigrok/SR
- JSON event summary

---

# 19. TAB 11 — SỨC KHỎE

## Purpose

Detect whether learning is genuinely improving or silently collapsing.

## Health cards

**Chất lượng học**  
`TỐT`

**Effective rank**  
`19 / 32`

**Hidden saturation**  
`2.1%`

**Khoảng cách phân biệt**  
`146 mức`

**AUC**  
`0.742`

**False hit**  
`0`

## Long-horizon chart

X-axis:

`UPDATE COUNT`

Lines:

- AUC
- AP
- effective rank
- hidden saturation
- max |Wh|
- M_L1

## Collapse alert

**Cảnh báo: Representation Collapse**

`Effective rank: 18 → 11 → 4 → 1`

`Saturation: 7% → 34% → 78% → 100%`

`AUC: 0.71 → 0.66 → 0.53 → 0.50`

Plain-language explanation:

`AI vẫn đang thay đổi trọng số nhưng các trạng thái bên trong đang trở nên gần giống nhau. Khả năng phân biệt dữ liệu đang mất dần.`

## Baseline comparison

Optional:

- Untrained
- Current
- Best frozen
- Classical baseline

Never hide a baseline that beats the learned model.

---

# 20. TAB 12 — REPLAY

## Purpose

Let the user see what changed because of learning.

## Interaction selector

`Interaction #500`

vs

`Interaction #1842`

## Before/after summary

| Metric | Before | After |
|---|---:|---:|
| d_pos | 3910 | 1250 |
| d_neg | 2900 | 4800 |
| Margin | -1010 | +3550 |
| Effective rank | 14 | 20 |
| Saturation | 21% | 4% |
| Memory | MISS | #482 |
| Answer | Sai | Đúng |

## State comparison

Side-by-side hidden heatmaps.

## Weight comparison

Delta heatmap.

## Memory comparison

Show:

- episode added;
- episode updated;
- episode evicted;
- no change.

## Waveform replay

Timeline scrubber.

Dragging updates:

- process stage;
- state values;
- memory event;
- waveform cursor.

---

# 21. TAB 13 — BẰNG CHỨNG

## Purpose

Prevent attractive visualization from becoming scientific overclaim.

## Evidence badges

- `BOARD`
- `XSIM`
- `TWIN`
- `DERIVED`

## Evidence table

| Metric | Source |
|---|---|
| d1 | BOARD |
| Waveform | BOARD / LiteScope |
| M_L1 | DERIVED from BOARD |
| Cosine | DERIVED |
| Gradient estimate | TWIN |
| AUC | HOST EVAL |
| Weight delta | BOARD SNAPSHOT |

## Twin mode warning

**MÔ HÌNH / TWIN MODE**

`Dữ liệu hiện tại không phải silicon evidence.`

Never allow twin sessions to visually masquerade as board evidence.

## Build identity

Show:

- bitstream SHA;
- source SHA;
- model version;
- learning-law ID;
- memory-law ID;
- clock;
- timing status.

---

# 22. GLOBAL “GIẢI THÍCH DỄ HIỂU” FEATURE

Every technical metric has a contextual explanation action.

Button:

**Giải thích**

Examples:

## Effective rank = 3/32

`32 chiều nội bộ của AI đang trở nên quá giống nhau. Khi số chiều hiệu dụng giảm mạnh, AI khó phân biệt các input khác nhau.`

## Margin = -1258

`Ví dụ sai đang gần Anchor hơn ví dụ đúng. Đây là dấu hiệu phân biệt chưa tốt.`

## Hidden saturation = 100%

`Các giá trị bên trong đã chạm giới hạn số học. Khi điều này xảy ra trên quá nhiều chiều, representation có thể mất thông tin.`

## WNS = +0.312 ns

`Tín hiệu có đủ thời gian ổn định trước cạnh clock kế tiếp theo phân tích timing hiện tại.`

Prefer a frozen glossary or deterministic explanation rules to free-form model interpretation.

---

# 23. CAUSAL TRACE MODEL

Every interaction maintains a causal chain:

`Interaction #1842`

→ Input

→ Encoder state

→ Comparison

→ Learning decision

→ Weight writes

→ Memory operation

→ Retrieved episode

→ Model context

→ Token selection

→ Output

Each event must have:

- interaction ID;
- event ID;
- phase;
- timestamp;
- cycle range if available;
- source;
- evidence type.

The user can click from high-level events down to raw waveform.

---

# 24. GLASSBOX COMPLETENESS CONTRACT

An interaction is marked:

**FULLY TRACEABLE**

only if the system can answer all eight:

1. What input did the user provide?
2. What representation did FPGA create?
3. What metric or state led to the decision?
4. Did learning occur, and why?
5. Which learned values changed?
6. Which memory entries were read/written?
7. What information entered the model-processing path?
8. Which output token was selected and at what cycle?

If evidence is missing:

**PARTIALLY TRACEABLE**

Never infer missing hardware evidence merely to complete the visual story.

---

# 25. DATA AUTHORITY RULES

## BOARD

Physical FPGA measurement.

Highest authority for:

- silicon behavior;
- runtime timing;
- physical throughput;
- actual waveforms.

## XSIM

RTL simulation.

Useful for exact logic regression.

Not board evidence.

## TWIN

Host-side model/reference.

Useful for illustration, replay and ablation.

Not silicon evidence.

## DERIVED

Calculated from raw authoritative values.

Examples:

- margin;
- cosine;
- latency aggregation;
- AUC/AP.

The UI must show provenance on demand.

---

# 26. LOADING, EMPTY AND ERROR STATES

## FPGA disconnected

**FPGA chưa kết nối**

`Bạn vẫn có thể mở các session đã lưu hoặc chạy dữ liệu mô phỏng.`

Buttons:

`Mở session`

`Dùng Twin`

No fake live values.

## No interaction selected

**Chọn một tương tác để xem bên trong**

## No waveform available

**Không có waveform cho tương tác này**

`Capture không được bật khi sự kiện xảy ra.`

Button:

`Bật capture cho lần sau`

## Partial trace

**Trace chưa đầy đủ**

## Capture overflow

**Capture vượt dung lượng**

`Một phần dữ liệu waveform đã bị mất.`

## Timing-invalid build

**BUILD KHÔNG ĐẠT TIMING**

The UI must not present measurements as reliable board evidence.

---

# 27. RESPONSIVE BEHAVIOR

## Desktop ≥ 1440 px

Full three-column layouts.

## Laptop 1280–1439 px

Collapse side inspectors into drawers.

## Tablet landscape

Two-pane maximum.

## Mobile

Not a primary analysis target.

Mobile may support:

- chat;
- overview;
- health;
- replay summary.

Raw waveform and matrix analysis should direct users to desktop.

---

# 28. ACCESSIBILITY

Minimum requirements:

- keyboard navigation;
- visible focus state;
- no information encoded by color alone;
- high contrast;
- reduced-motion mode;
- chart values accessible as tables;
- waveform cursor keyboard support;
- screen-reader-friendly Vietnamese labels;
- colorblind-safe semantic distinctions.

---

# 29. PERFORMANCE UX

The UI must remain responsive while FPGA runs.

Rules:

- throttle telemetry for display;
- do not repaint at FPGA clock rate;
- aggregate graphs intelligently;
- virtualize off-screen waveform rows;
- represent 800k episodes as density/index summaries;
- use progressive loading for long history;
- chunk session data.

User-visible lag must not be confused with FPGA processing latency.

---

# 30. REALISTIC PRODUCT COPY

Good:

- `AI vừa học từ tương tác này`
- `Không cần học thêm`
- `Tìm thấy Episode #512`
- `Representation đang ổn định`
- `Có dấu hiệu saturation`
- `Mô hình đang tạo token`
- `FPGA đang xử lý`
- `Xem waveform`
- `Replay tương tác`
- `Giải thích`

Avoid:

- `Neuron này hiểu FPGA`
- `AI đang suy nghĩ như con người`
- `AI biết chắc`
- `Bộ não AI`
- `Ý thức`
- `Suy nghĩ nội tâm`

---

# 31. DUMMY DATA FOR PRODUCT DESIGN

Use realistic sample content.

User:

`Board hiện tại dùng chip gì?`

AI:

`Arty A7 sử dụng FPGA Artix-7.`

Metrics:

`Interaction #1842`

`10:32:15.481`

`d_pos = 1320`

`d_neg = 4810`

`M_L1 = +3490`

`effective_rank = 19/32`

`hidden saturation = 2.1%`

`286 learned values changed`

`Episode #488271`

`92 ms`

`7 tokens`

`100 MHz`

`BOARD`

Values used in pure marketing/mockup mode must be identified as synthetic outside scientific sessions.

---

# 32. ABSOLUTE NEGATIVE CONSTRAINTS FOR UI GENERATION

When an AI or designer generates final UI screens, the following are forbidden:

1. No tutorial annotations floating outside the product.
2. No arrows explaining where a feature “would be.”
3. No `Feature 1 / Feature 2` placeholders.
4. No Lorem Ipsum.
5. No empty wireframes.
6. No developer notes.
7. No design rationale inside app screens.
8. No huge explanatory paragraphs.
9. No fake AI-brain illustration replacing real data.
10. No invented neural semantics.
11. No fake gradient if no gradient was measured.
12. No fake probability derived from arbitrary logits.
13. No TWIN data visually presented as BOARD.
14. No giant 800k-node memory visualization.
15. No decorative 3D charts.
16. No evidence claim without provenance.
17. No UI event implying a board event occurred if telemetry did not record it.
18. No `BOARD_PASS` generated from UI state alone.
19. No scientific status inferred merely from green styling.
20. No change to frozen Native AI behavior solely to make the UI prettier.

---

# 33. PRODUCT DESIGN PROMPT FOR UI GENERATORS

Use this prompt with a UI-generation model:

> You are a senior Product Designer designing a production-ready desktop web application named **Native AI GlassBox Studio**.
>
> Design the interface as a real product used by end users, not as a concept board, wireframe, documentation page or annotated mockup.
>
> The product lets a user chat with a small Native AI running on FPGA and visually inspect the full processing chain:
>
> **Input → Representation → Comparison → Learning → Memory → Model Processing → Output → FPGA Waveform → Health → Replay → Evidence**
>
> The primary user may know nothing about AI or FPGA. They should understand the main process visually within seconds, while advanced users can progressively open research metrics and exact RTL waveform evidence.
>
> Use a persistent `interaction_id` so every screen refers to the same user interaction.
>
> Provide three presentation levels: **Dễ hiểu**, **Research**, **RTL**. These views show the same underlying evidence at different technical depths.
>
> Create a polished dark-first scientific interface with these tabs: Tổng quan, Tương tác, Dữ liệu vào, Biểu diễn, So sánh, Học, Bộ nhớ, Mô hình, Đầu ra, Sóng FPGA, Sức khỏe, Replay, Bằng chứng.
>
> Use natural Vietnamese and realistic sample data such as: `Board hiện tại dùng chip gì?`, `Arty A7 sử dụng FPGA Artix-7.`, `Interaction #1842`, `d_pos 1320`, `d_neg 4810`, `M_L1 +3490`, `Effective rank 19/32`, `Hidden saturation 2.1%`, `286 giá trị thay đổi`, `Episode #488271`, `92 ms`, `7 token`, `100 MHz`, `BOARD`.
>
> Required visualizations: process pipeline, stage waterfall, token strip, hidden-state heatmap, 2D representation projection explicitly marked illustrative, distance bars, margin gauge, weight-delta heatmap, update histogram, long-horizon learning line chart, memory retrieval funnel, DDR density map, model-layer waterfall, next-token ranked bars, digital FPGA waveform and before/after comparison.
>
> Clearly distinguish **BOARD**, **XSIM**, **TWIN**, **DERIVED**.
>
> Never visually imply TWIN is FPGA evidence. Never invent semantic meaning for hidden dimensions. Never describe raw activation as human thought.
>
> Do not place design notes, feature explanations, arrows, mockup labels, placeholders, Lorem Ipsum, implementation instructions or tutorial callouts outside the actual application. Do not draw a rough wireframe. Do not add floating annotations saying what components are for. Do not use meaningless 3D neural-network graphics. Do not use radar charts for 32-dimensional hidden state. Do not create a giant node graph for 800,000 memory episodes.
>
> The final result must look like a polished production application ready to be handed to a frontend engineering team and tested with real users.

---

# 34. FRONTEND IMPLEMENTATION HANDOFF

Recommended architecture:

- React / Next.js or equivalent
- WebSocket/SSE telemetry
- WebWorker for waveform/large-data parsing
- Canvas/WebGL for large waveforms
- SVG/Canvas for charts
- IndexedDB for local session replay
- deterministic evidence metadata attached to every event

Suggested data model:

```text
Session
 ├── BuildIdentity
 ├── Interaction[]
 │    ├── InputEvent[]
 │    ├── RepresentationSnapshot[]
 │    ├── CompareEvent[]
 │    ├── LearningEvent[]
 │    ├── WeightDelta[]
 │    ├── MemoryEvent[]
 │    ├── ModelEvent[]
 │    ├── OutputEvent[]
 │    ├── WaveformCapture[]
 │    └── EvidenceMetadata[]
 └── HealthSeries[]
```

The frontend must never generate missing evidence as if it came from FPGA.

---

# 35. GLASSBOX HARDWARE/UX CONTRACT

The UI should consume three planes.

## 35.1 Telemetry plane

Low-rate continuous state:

- interaction ID;
- phase;
- token ID;
- d_pos;
- d_neg;
- margin;
- update count;
- saturation;
- rank proxy;
- episode;
- candidate count;
- output token.

## 35.2 Snapshot plane

On-demand state:

- hidden vector;
- selected Wh tile;
- embedding row;
- before/after weight;
- episode header;
- model-state tile.

## 35.3 LiteScope plane

Cycle-accurate capture:

- INPUT
- FORWARD
- LEARNING
- DDR/MEMORY
- OUTPUT

The product merges them only by explicit timestamps, cycle IDs and interaction IDs.

---

# 36. FINAL PRODUCT ACCEPTANCE CRITERIA

The UX/UI is complete only when:

1. A first-time user can follow the AI process without knowing FPGA terminology.
2. A researcher can inspect exact numeric states.
3. An FPGA engineer can open exact waveform evidence.
4. Every screen stays linked to one interaction.
5. Every important metric has evidence provenance.
6. Before/after learning is visually comparable.
7. Representation collapse is visible and understandable.
8. Memory retrieval is understandable without an unreadable giant graph.
9. Output tokens can be traced back to memory/model events.
10. The interface never claims unmeasured semantics.
11. The interface never treats TWIN as BOARD.
12. Raw waveform remains available below simplified explanations.
13. Normal product screens contain no design annotations or mockup instructions.
14. The UI looks like a finished application, not research documentation.
15. GlassBox visualization does not alter the frozen Native AI learning behavior.

---

# 37. ONE-SENTENCE PRODUCT DEFINITION

> **Native AI GlassBox Studio is a user-facing FPGA AI observatory that lets anyone follow one interaction from text input to learned state, memory, model output and cycle-accurate silicon waveform without hiding the underlying scientific evidence.**
