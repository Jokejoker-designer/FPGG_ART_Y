# Phương án đóng A7-LM-00 trên Arty A7-100T

## Kết luận nghiên cứu

A7-LM-00 hiện **rất gần PASS**. Tôi không thấy bằng chứng đủ mạnh để mở lại `tiny_gpt05_core`, thay learning law, thay arithmetic hay chuyển sang A7-LM-01. Blocker duy nhất có ý nghĩa kỹ thuật hiện nay vẫn là:

```text
Forward logits 1000-case:
950 / 1000 exact

Required:
1000 / 1000 exact
```

Trong khi các cổng độc lập với burst `0x75` đều đã đạt: 128/128 gradient packs, 20/20 generation, CE `512 → 304`, cả 9 bank thay đổi, AFTER write = 0 và timing `WNS +72.324 ns / TNS 0`. Quan trọng hơn, các case lỗi trong burst lại **bit-exact khi chạy isolated**, bao gồm case `[2]`; vì vậy evidence hiện tại chống lại giả thuyết “Arty tính sai 50 vector logits cố định”. fileciteturn0file0 fileciteturn0file1

Tôi sẽ sửa cách diễn đạt blocker một chút. Hiện chưa đủ bằng chứng để kết luận chính xác là **“FTDI FIFO overflow”**. Kết luận được dữ liệu hỗ trợ tốt hơn là:

> **A7-LM-00 đang có lỗi ở đường thu/ghép transaction telemetry khi chạy continuous `dumpz`; arithmetic datapath chưa bị chứng minh là lỗi.**

Điều này quan trọng vì nó quyết định phạm vi sửa: **host transport/parser trước, RTL sau cùng**. FTDI lưu ý rằng UART không có flow control có thể mất dữ liệu khi host/driver không được schedule kịp; đồng thời USB receive latency/buffering làm dữ liệu đến userspace theo các block không nhất thiết trùng với ranh giới frame của protocol. citeturn4search0turn4search4

Tôi đánh giá xác suất nguyên nhân theo evidence hiện có như sau:

| Giả thuyết | Đánh giá hiện tại | Hành động |
|---|---:|---|
| Host parser xử lý partial-read/chunk boundary không an toàn | **Rất cao** | sửa đầu tiên |
| Case boundary bị lẫn do thiếu transaction barrier | **Cao** | sửa cùng parser |
| FTDI/VCP/Windows buffering/latency góp phần gây lỗi | **Trung bình–cao** | đo, không đoán |
| FPGA UART TX làm rơi frame | **Thấp nhưng chưa loại hoàn toàn** | chỉ điều tra nếu host fix thất bại |
| Transformer arithmetic khác Basys | **Rất thấp** | chưa mở core |
| Golden sai 50 case | **Đã bị evidence phản bác mạnh** | không sửa golden |

Arty A7-100T chính thức có USB-UART bridge; master XDC của Digilent chỉ đưa ra hai tín hiệu UART dữ liệu `uart_rxd_out` và `uart_txd_in`, không có một cặp RTS/CTS FPGA-side trong interface USB-UART chuẩn đó. Vì vậy đối với bitstream hiện tại, cách an toàn nhất không phải dựa vào hardware flow-control mà là **protocol-level stop-and-wait ở host**. citeturn1search1turn6view0

## Chẩn đoán kỹ thuật: vì sao 950/1000 rất giống lỗi transport/parser

Dữ liệu hiện tại có ba đặc điểm rất đáng chú ý. Cùng 50 case lỗi lặp lại qua các burst với delay 1 ms, 6 ms và 20 ms; phần lớn prediction vẫn đúng; còn case lỗi chạy một mình lại bit-exact. Hai case đầu chạy cùng nhau cũng đúng. Đây không phải pattern tự nhiên của một lỗi multiply/MAC hoặc quantization cố định theo input; nó phù hợp hơn với một failure phụ thuộc **lịch phát/thu stream dài**. Đây là inference từ evidence của project, chưa phải kết luận bằng logic analyzer. fileciteturn0file0

Một dump có 16 frame `0x75`; 1.000 case tạo khoảng 16.000 frame. Với protocol 15 byte/frame hiện tại và UART 115200 8N1, một frame chiếm khoảng 1,302 ms trên dây, một dump 16 frame chiếm tối thiểu khoảng 20,83 ms, và riêng 16.000 frame đã là khoảng 240 KB / 20,83 giây wire-time, chưa kể command/context/result traffic. Vì vậy đây không còn là một transaction nhỏ; nó là một continuous serial-stream test. fileciteturn0file0

Điểm đặc biệt cần kiểm tra trong scorer là **partial reads**. pySerial quy định rõ rằng khi `timeout` hữu hạn, `read(size)` có quyền trả về **ít byte hơn `size`** nếu timeout hết. Vì vậy parser không được giả định rằng một lần gọi `read(13)` sẽ luôn lấy đủ 13 byte còn lại của một frame; mọi byte đã đọc một phần phải được giữ lại để ghép với lần đọc tiếp theo. citeturn2view0

Đây là chỗ tôi coi là **ưu tiên số một**. Parser đúng cho serial stream phải hiểu rằng:

```text
USB packet boundary
≠
Windows ReadFile boundary
≠
pySerial read() boundary
≠
FPGA A5-frame boundary
```

FTDI cũng mô tả rằng latency timer và USB block size có thể làm thay đổi thời điểm data được giao lên ứng dụng; do đó correctness không được phụ thuộc vào việc từng call `read()` vô tình align với frame. citeturn4search4turn4search5

Một điểm khác dễ gây nhầm là `port.flush()`: trong pySerial nó chỉ chờ **outgoing data được write xong**; nó không drain RX. Ngược lại, `reset_input_buffer()` thực sự **discard toàn bộ receive-buffer contents**. Vì vậy không được dùng `flush()` như một RX barrier, và cũng không được `reset_input_buffer()` giữa các dump khi chưa chứng minh FPGA đã hoàn tất transaction, vì chính thao tác đó có thể xóa frame hợp lệ. citeturn2view0

### Tôi sẽ biến transport thành transaction protocol

Hiện acceptance logic nên trở thành:

```text
CASE n
│
├─ send context
│
├─ send FWD
│
├─ WAIT exact valid 0x74
│
├─ send DUMPZ
│
├─ collect 0x75
│    idx = 0
│    idx = 2
│    idx = 4
│    ...
│    idx = 30
│
├─ verify:
│    16 valid frames
│    16 unique expected indices
│    checksum all valid
│    no missing index
│    no duplicate index
│
├─ reconstruct 32 logits
│
├─ compare golden
│
└─ ONLY NOW start CASE n+1
```

Không dùng:

```text
sleep(20 ms)
→ chắc là FPGA xong
```

mà dùng:

```text
completion condition
→ FPGA transaction chắc chắn xong
```

Sleep có thể giữ làm back-off nhỏ, nhưng **không phải correctness mechanism**. FTDI có receive latency có thể điều chỉnh và Windows scheduling không deterministic, nên elapsed-time gating vốn yếu hơn response-driven gating. citeturn4search0turn4search5

## Host scorer nên sửa như thế nào

Tôi đề xuất **không rebuild bitstream** ở lần sửa đầu. Giữ nguyên:

```text
build/out/arty_a7_lm00.bit

SHA-256
449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783
```

để nếu 950/1000 trở thành 1000/1000 chỉ nhờ sửa host, ta có bằng chứng cực mạnh rằng arithmetic image ban đầu đã đúng. fileciteturn0file0

### Thay parser byte-at-a-time bằng persistent stream buffer

Core của parser nên giống thế này:

```python
from __future__ import annotations

import time
from collections import deque
from dataclasses import dataclass

FRAME_LEN = 15
SYNC = 0xA5


@dataclass(frozen=True)
class RawFrame:
    data: bytes


class FrameStream:
    """Lossless streaming parser for fixed 15-byte A5 frames."""

    def __init__(self, port):
        self.port = port
        self.buf = bytearray()
        self.frames: deque[RawFrame] = deque()

        self.bytes_rx = 0
        self.good_frames = 0
        self.bad_crc = 0
        self.resync_bytes = 0

    @staticmethod
    def checksum_ok(frame: bytes) -> bool:
        if len(frame) != FRAME_LEN:
            return False

        x = 0
        for b in frame[:14]:
            x ^= b
        return x == frame[14]

    def _parse_buffer(self) -> None:
        while True:
            # Find frame sync but NEVER discard an incomplete valid candidate.
            try:
                sync_pos = self.buf.index(SYNC)
            except ValueError:
                self.resync_bytes += len(self.buf)
                self.buf.clear()
                return

            if sync_pos:
                self.resync_bytes += sync_pos
                del self.buf[:sync_pos]

            if len(self.buf) < FRAME_LEN:
                return

            candidate = bytes(self.buf[:FRAME_LEN])

            if self.checksum_ok(candidate):
                del self.buf[:FRAME_LEN]
                self.frames.append(RawFrame(candidate))
                self.good_frames += 1
            else:
                # Shift only one byte and search again.
                del self.buf[0]
                self.bad_crc += 1
                self.resync_bytes += 1

    def pump(self) -> None:
        # Read whatever the OS currently has, but preserve every byte.
        n = max(1, int(self.port.in_waiting))
        chunk = self.port.read(n)

        if chunk:
            self.bytes_rx += len(chunk)
            self.buf.extend(chunk)
            self._parse_buffer()

    def get_frame(self, timeout_s: float) -> RawFrame | None:
        deadline = time.monotonic() + timeout_s

        while time.monotonic() < deadline:
            if self.frames:
                return self.frames.popleft()

            self.pump()

        return self.frames.popleft() if self.frames else None
```

Điểm cốt lõi không nằm ở cú pháp Python mà ở invariant:

```text
partial data is never discarded
```

`in_waiting` trong pySerial cho biết số byte đang chờ trong receive buffer, và Windows cũng cung cấp `COMSTAT.cbInQue` cho chính loại telemetry này ở mức serial provider; đây là hai metric hữu ích để log khi test. citeturn2view0turn5search3

### Collector `dumpz` phải kiểm tra set index, không chỉ đếm frame

Tôi sẽ không viết:

```python
for _ in range(16):
    receive_one_0x75()
```

rồi mặc định đủ 16 frame nghĩa là dump hợp lệ.

Phải là:

```python
EXPECTED_Z_IDX = set(range(0, 32, 2))


def collect_dumpz(stream, send_dump_cmd, parse_frame, timeout_s=2.0):
    send_dump_cmd()

    logits: list[int | None] = [None] * 32
    seen: set[int] = set()
    duplicates: list[int] = []
    unexpected: list[int] = []

    deadline = time.monotonic() + timeout_s

    while seen != EXPECTED_Z_IDX and time.monotonic() < deadline:
        raw = stream.get_frame(deadline - time.monotonic())
        if raw is None:
            break

        rec = parse_frame(raw.data)

        # Other telemetry may exist; don't reinterpret it as dumpz.
        if rec.get("kind") != 0x75:
            continue

        idx = int(rec["idx"])

        if idx not in EXPECTED_Z_IDX:
            unexpected.append(idx)
            continue

        if idx in seen:
            duplicates.append(idx)
            continue

        seen.add(idx)
        logits[idx] = int(rec["z0"])
        logits[idx + 1] = int(rec["z1"])

    missing = sorted(EXPECTED_Z_IDX - seen)

    return {
        "complete": not missing,
        "logits": logits,
        "seen": sorted(seen),
        "missing": missing,
        "duplicates": duplicates,
        "unexpected": unexpected,
        "bad_crc_total": stream.bad_crc,
        "resync_bytes_total": stream.resync_bytes,
    }
```

Acceptance của **một case** phải là:

```text
seen ==
{0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30}
```

không phải đơn giản:

```text
received_count == 16
```

Điều này giúp phân biệt được ngay:

```text
missing frame
duplicate frame
bad checksum
wrong-kind frame
desync
```

thay vì tất cả biến thành một logits vector có một vài số 0 rồi bị chấm là “FPGA arithmetic mismatch”.

### Retry nên là diagnostic, không phải cách làm đẹp PASS

Blocker hiện cho phép retry case thiếu index. fileciteturn0file0 Tôi đồng ý dùng retry để chẩn đoán, nhưng acceptance mạnh nhất nên ghi **hai con số riêng**:

```text
logical_exact = 1000 / 1000
first_attempt_complete = 1000 / 1000
transport_retries = 0
```

Mục tiêu đóng milestone của tôi là:

```text
1000/1000
AND
retry_count == 0
```

Nếu đạt 1000/1000 nhưng có 2 retry, arithmetic gate có thể đã pass về mặt logic, nhưng tôi vẫn chưa đóng ngay. Tôi sẽ tìm nguyên nhân transport để tránh mang một protocol không ổn định sang A7-LM-01, nơi lượng telemetry và DDR diagnostics sẽ còn lớn hơn.

### Không chỉnh FTDI latency timer ngay

FTDI cho phép chỉnh receive latency timer và tài liệu cho thấy latency/buffer size ảnh hưởng mạnh tới cách data block được chuyển lên ứng dụng. Tuy nhiên tôi coi latency tuning là **performance optimization**, không phải correctness fix. Parser phải đúng ở latency 2 ms, 16 ms hay ở bất kỳ USB chunk boundary hợp lệ nào. citeturn4search4turn4search5

Tương tự, Windows cho phép ứng dụng đề xuất input/output queue size bằng `SetupComm`, nhưng Microsoft lưu ý driver có quyền dùng buffering scheme của riêng nó. Vì vậy tăng buffer có thể tăng margin, nhưng không thay thế transaction-safe parser. citeturn5search2

## Chuỗi thử nghiệm để đóng blocker mà không đụng RTL

Tôi không chạy thẳng full 1000 sau khi sửa code. Tôi sẽ đóng transport theo tầng để khi fail ta biết fail ở đâu.

### Parser test không cần board

Trước tiên lấy một stream gồm nhiều frame hợp lệ rồi chia byte theo các pattern cực xấu:

```text
15
7 + 8
1 + 14
14 + 1
1 + 1 + ... + 1
30
47
random chunks
```

Sau đó inject:

```text
garbage byte
partial final frame
A5 trong payload
bad checksum frame
```

Parser phải luôn recover đúng các frame hoàn chỉnh phía sau. Lý do phải test như vậy là pySerial không đảm bảo một `read(size)` hữu hạn-timeout luôn trả đủ `size`; frame parser phải chịu được arbitrary fragmentation. citeturn2view0

PASS:

```text
valid frames recovered: 100%
false valid frames:      0
partial bytes lost:      0
```

### Transport-only board test

Giữ một prefix duy nhất đã biết bit-exact, ví dụ case `[2]`, không reload model giữa từng dump:

```text
load seed-2
fwd [2]
dumpz
compare

repeat 1000 times
```

Hiện `[2]` isolated đã bit-exact. fileciteturn0file0

Nếu:

```text
1000/1000 same-case PASS
```

thì long-stream transport về cơ bản ổn.

Nếu vẫn mất frame:

```text
arithmetics không còn là nghi phạm hợp lý,
vì logits state không hề thay đổi giữa các iteration.
```

Lúc đó xem:

```text
missing idx distribution
bad CRC
resync count
max in_waiting
raw capture
```

### Alternating-case test

Tiếp:

```text
case 0
case 1
case 0
case 1
...
500 cycles
```

Tổng:

```text
1000 dumps
```

Hai-case test ngắn hiện đã pass, nên bước này kiểm tra liệu lỗi chỉ xuất hiện khi cùng protocol kéo dài hàng chục giây hay không. fileciteturn0file0

### Full golden 1000

Chỉ sau hai bài trên:

```text
seed-2
same law
1000 golden prefixes
```

Acceptance:

```text
cases_exact          1000 / 1000
dump_complete        1000 / 1000
missing_idx          0
duplicate_idx        0
checksum_fail        0
parser_resync_error  0
transport_retry      0
```

Host golden đã khóa 1000/1000 với cùng `lm05-signsgd-v1`, nên không thay golden trong bước này. fileciteturn0file0turn0file1

### Chạy lại toàn contract một lần cuối

Sau khi logits 1000/1000, tôi **không dùng các kết quả cũ ghép với logits mới** để tạo closeout. Tôi chạy một final board session sạch:

```text
PROGRAM same bit SHA

HOST GOLDEN
1000/1000

BOARD LOGITS
1000/1000

BOARD GRADS
128/128

BANK MOVEMENT
9/9

FIRST STEP
wr_head = 512
wr_blk  = 2048

CE
512 → 304
40.625%

GENERATE
20/20

AFTER
writes = 0

TIMING
WNS +72.324
TNS 0
```

Các giá trị reference phía trên là những gate hiện đã đạt trên image hiện tại. fileciteturn0file0turn0file1

Tôi đặc biệt muốn giữ **cùng bitstream SHA** trong final run. Nếu cùng `449A330B…34783` chuyển từ 950/1000 sang 1000/1000 chỉ sau host parser fix, closeout sẽ rất sạch: silicon arithmetic không đổi, learning law không đổi, chỉ verification transport được sửa. fileciteturn0file0

## Nếu vẫn fail sau parser mới

Đây là decision tree tôi đề nghị khóa vào contract để không debug lan man:

```text
                robust parser
                     │
                     ▼
              full 1000 test
               /          \
          1000/1000       FAIL
             │              │
             ▼              ▼
       final contract   same-case 1000
                           /    \
                        PASS    FAIL
                         │       │
                         │       ▼
                         │   inspect raw UART
                         │   checksum / missing bytes
                         │
                         ▼
                 full-case problem
                 transaction/state
```

### Trường hợp full golden fail nhưng same-case stress pass

Khi đó nghi phạm chuyển từ generic serial loss sang:

```text
case transition
context/fwd/dump ordering
stale 0x74
stale 0x75
wrong transaction association
```

Host cần ghi cho từng case:

```json
{
  "case": 46,
  "prefix": [ ... ],
  "fwd_pred": 0,
  "dump_indices": [0, 2, 4, "...", 30],
  "rx_bytes_before": 0,
  "rx_bytes_peak": 87,
  "duplicates": [],
  "checksum_errors": 0,
  "retry": false
}
```

`in_waiting` có thể được dùng như một observable của host RX queue trong pySerial; Windows có observable tương ứng là `cbInQue`. citeturn2view0turn5search3

### Trường hợp same-case 1000 cũng fail

Khi đó cần phân biệt:

```text
FPGA UART TX
vs
FTDI/VCP/Windows
vs
host parser
```

Lưu raw binary stream **trước parse**:

```text
uart_raw.bin
uart_frames.jsonl
uart_stats.json
```

pySerial còn cung cấp `spy://` handler để log raw serial traffic và buffer-related operations, nên có thể dùng làm một cross-check độc lập cho host tooling. citeturn0search0

Nếu raw stream từ OS thực sự thiếu một frame, host parser đã được loại. Khi đó mới xét USB-UART/driver hoặc FPGA TX scheduling. FTDI chính thức lưu ý no-flow-control UART có khả năng mất dữ liệu khi host driver bị starve; do đó transport loss là một failure mode có thật, không nên gán ngay cho model arithmetic. citeturn4search0

### Chỉ mở RTL arithmetic khi isolated cũng sai

Ngưỡng mở `tiny_gpt05_core` nên giữ đúng như tài liệu hiện tại:

```text
paced / transaction-safe still fails
AND
same failing case isolated also fails
AND
raw telemetry is complete and checksum-valid
```

Hiện điều kiện cuối này **chưa xảy ra**: isolated check đang đúng. fileciteturn0file0

Nếu đến đó mới mở:

```text
dump_z register lifetime
LM-head output latch
cmd3 start/done handshake
idx counter
tx_valid/tx_ready
UART TX FIFO
```

chứ vẫn chưa sửa Q/K/V/FFN trước.

## Closeout package và tiêu chuẩn PASS cuối

Sau khi final run đạt 1000/1000, tôi sẽ không chỉ sửa `A7-LM-00_CLOSEOUT.md`; tôi sẽ tạo immutable release riêng.

Cấu trúc nên là:

```text
releases/
└── A7-LM-00-BOARD-PASS-20260816/
    ├── RELEASE_MANIFEST.json
    ├── CLOSEOUT.md
    ├── CONTRACT.md
    ├── SHA256SUMS.txt
    │
    ├── bitstream/
    │   └── arty_a7_lm00.bit
    │
    ├── reports/
    │   ├── timing_route.rpt
    │   └── utilization_route.rpt
    │
    ├── golden/
    │   ├── golden_1000.json
    │   ├── grad_128.json
    │   └── generation_20.json
    │
    ├── board/
    │   ├── final_score.json
    │   ├── logits_1000.jsonl
    │   ├── gradients_128.json
    │   ├── ce_before_after.json
    │   ├── bank_sha.json
    │   └── after_freeze.json
    │
    └── transport/
        ├── uart_stats.json
        ├── parser_stats.json
        └── scorer_sha256.txt
```

`RELEASE_MANIFEST.json` nên chứa ít nhất:

```json
{
  "milestone": "A7-LM-00",
  "status": "BOARD_PASS",
  "date": "2026-08-16",

  "board": "Arty A7-100T",
  "fpga": "xc7a100t_0",
  "jtag_serial": "210319BE776EA",
  "uart": "COM12",
  "baud": 115200,

  "law_id": "lm05-signsgd-v1",

  "bitstream_sha256":
    "449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783",

  "host_golden": "1000/1000",
  "board_logits": "1000/1000",
  "gradients": "128/128",
  "generation": "20/20",

  "ce_before": 512,
  "ce_after": 304,
  "ce_drop": 0.40625,

  "banks_changed": 9,
  "after_writes": 0,

  "wns_ns": 72.324,
  "tns_ns": 0,

  "transport_missing_frames": 0,
  "transport_bad_checksum": 0,
  "transport_retries": 0,

  "git_dirty": false
}
```

Các giá trị board/reference trong manifest trên tương ứng với những gate đã được ghi nhận trong blocker và status hiện tại; chỉ `board_logits=1000/1000` cùng các transport counters bằng zero là phần chưa được chứng minh ở thời điểm hiện tại. fileciteturn0file0turn0file1

Tôi cũng sẽ hash **host scorer mới**. Đây là điểm quan trọng: lần này blocker nằm ở verification transport, nên closeout phải khóa không chỉ bitstream mà cả phiên bản scorer đã tạo evidence.

Git gate cuối:

```text
git status --porcelain
→ empty

git rev-parse HEAD
→ recorded

SHA256(bitstream)
→ recorded

SHA256(scorer)
→ recorded

SHA256(final_score.json)
→ recorded
```

Sau đó mới tạo tag kiểu:

```text
A7-LM-00-BOARD-PASS-20260816
```

Không nên copy claim Basys:

```text
FULL_TINY_TRANSFORMER_BACKPROP_FPGA_BOARD_VALIDATED
```

sang A7-LM-00, đúng như closeout hiện tại đã cấm. fileciteturn0file1

Claim tốt nhất là **không phát minh claim mới nếu contract chưa định nghĩa**. Closeout chỉ cần ghi:

```text
A7-LM-00 — BOARD PASS

Basys LM-05 arithmetic/training law
ported to Arty A7-100T with
bit-exact forward regression,
gradient regression,
training-state regression,
generation regression,
freeze integrity,
and positive timing.
```

Đây là **port-validation milestone**, không phải một scientific capability mới.

## Go/no-go để thực sự mở A7-LM-01

Tôi sẽ đặt barrier cuối như sau:

```text
A7-LM-00 CLOSE =
    host golden               1000/1000
AND board logits              1000/1000
AND dump completeness         1000/1000
AND transport retry count     0
AND checksum failures         0
AND gradients                 128/128
AND generate                  20/20
AND CE                        512 → 304
AND all banks moved           9/9
AND AFTER writes              0
AND WNS                       >= 0
AND TNS                       == 0
AND same law                  lm05-signsgd-v1
AND same accepted bit SHA
AND git dirty                 false
AND immutable release         written
```

Điều này hơi mạnh hơn blocker hiện tại ở chỗ tôi thêm `dump completeness`, `transport retry=0` và `checksum failure=0`. Tôi cho rằng nên làm vậy, vì A7-LM-01 chính là milestone DDR/MIG; nếu UART verification layer vẫn thỉnh thoảng làm rơi/lẫn frame, khi bắt đầu test DDR burst, checkpoint SHA và memory tiles ta sẽ không biết lỗi nằm ở DDR hay telemetry.

Thứ tự hành động tối ưu vì thế là:

```text
             CURRENT 950/1000
                    │
                    ▼
       Freeze RTL + same bitstream SHA
                    │
                    ▼
       Replace host RX with persistent
        lossless byte-stream parser
                    │
                    ▼
       Parser fragmentation unit tests
                    │
                    ▼
       [2] × 1000 same-logit stress
                    │
                    ▼
       case0/case1 alternating ×1000
                    │
                    ▼
       full golden 1000-case run
                    │
          ┌─────────┴─────────┐
          │                   │
      1000/1000             failure
          │                   │
          ▼                   ▼
 full contract rerun       raw capture /
          │                classify layer
          ▼
  transport counters = 0
          │
          ▼
  git dirty = false
          │
          ▼
 immutable release
          │
          ▼
       A7-LM-00
       BOARD PASS
          │
          ▼
       A7-LM-01
       DDR / MIG
```

**Tôi đánh giá đây là con đường ngắn nhất và khoa học nhất để đóng A7-LM-00.** Evidence hiện tại đã đủ mạnh để không động vào Transformer core: board đúng ở gradient, training behavior, generation, CE, isolated logits và timing; phần chưa được chứng minh chỉ là khả năng thu **16.000 frame `0x75` liên tục thành 1.000 transaction hoàn chỉnh**. fileciteturn0file0turn0file1

Nếu host parser transaction-safe đưa cùng bitstream `449A330B…34783` từ **950/1000 lên 1000/1000**, đó thực ra là kết quả closeout đẹp nhất có thể: **không sửa model, không sửa law, không sửa arithmetic, không rebuild silicon image — chỉ sửa verification transport rồi chứng minh Arty port bit-exact.**