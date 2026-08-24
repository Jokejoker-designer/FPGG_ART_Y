"""Lossless 15-byte A5 frame stream. Partial reads are never discarded."""
from __future__ import annotations

from collections import deque
from dataclasses import dataclass

FRAME_LEN = 15
SYNC = 0xA5


@dataclass(frozen=True)
class RawFrame:
    data: bytes


class FrameStream:
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
                del self.buf[0]
                self.bad_crc += 1
                self.resync_bytes += 1

    def feed(self, chunk: bytes) -> None:
        if not chunk:
            return
        self.bytes_rx += len(chunk)
        self.buf.extend(chunk)
        self._parse_buffer()

    def pump(self) -> None:
        n = max(1, int(getattr(self.port, "in_waiting", 0) or 0))
        chunk = self.port.read(n)
        self.feed(chunk)

    def get_frame(self, timeout_s: float) -> RawFrame | None:
        import time

        deadline = time.monotonic() + timeout_s
        while time.monotonic() < deadline:
            if self.frames:
                return self.frames.popleft()
            self.pump()
        return self.frames.popleft() if self.frames else None
