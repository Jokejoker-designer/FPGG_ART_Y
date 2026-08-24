"""T0: parser must survive arbitrary USB/OS chunk boundaries. No board."""
from __future__ import annotations

import random

from python.uart_frames import pack15
from python.uart_stream import FRAME_LEN, FrameStream


class FakePort:
    def __init__(self, blob: bytes):
        self.blob = blob
        self.off = 0
        self.in_waiting = 0

    def read(self, n: int) -> bytes:
        chunk = self.blob[self.off : self.off + n]
        self.off += len(chunk)
        self.in_waiting = max(0, len(self.blob) - self.off)
        return chunk


def xor_frame(kind: int, body12: bytes) -> bytes:
    return pack15(kind, body12)


def many_frames(n: int = 40) -> list[bytes]:
    out = []
    for i in range(n):
        body = bytes([(i + k) & 0xFF for k in range(12)])
        out.append(xor_frame(0x75, body))
    return out


def replay(blob: bytes, chunker) -> FrameStream:
    stream = FrameStream(FakePort(b""))
    off = 0
    while off < len(blob):
        n = chunker(off, len(blob) - off)
        stream.feed(blob[off : off + n])
        off += n
    return stream


def test_chunk_patterns_recover_all():
    frames = many_frames(32)
    blob = b"".join(frames)
    patterns = [
        lambda _o, rem: rem if rem < 15 else 15,
        lambda _o, rem: min(7, rem),
        lambda _o, rem: 1,
        lambda _o, rem: min(14, rem),
        lambda _o, rem: min(30, rem),
        lambda _o, rem: min(47, rem),
    ]
    for fn in patterns:
        st = replay(blob, fn)
        assert st.good_frames == 32
        assert len(st.frames) == 32
        assert st.bad_crc == 0


def test_random_chunks():
    rng = random.Random(7)
    frames = many_frames(50)
    blob = b"".join(frames)
    st = replay(blob, lambda _o, rem: max(1, rng.randint(1, min(20, rem))))
    assert st.good_frames == 50
    assert bytes(st.frames[0].data) == frames[0]


def test_garbage_and_bad_crc_then_recover():
    good = many_frames(3)
    bad = bytearray(good[1])
    bad[14] ^= 0xFF
    blob = b"\x00\x11" + good[0] + bytes(bad) + b"\xa5\x00" + good[2]
    st = replay(blob, lambda _o, rem: min(5, rem))
    recovered = [f.data for f in st.frames]
    assert good[0] in recovered
    assert good[2] in recovered
    assert bytes(bad) not in recovered


def test_partial_tail_not_lost():
    full = many_frames(1)[0]
    st = FrameStream(FakePort(b""))
    st.feed(full[:9])
    assert st.good_frames == 0
    assert len(st.buf) == 9
    st.feed(full[9:])
    assert st.good_frames == 1
    assert st.frames[0].data == full
