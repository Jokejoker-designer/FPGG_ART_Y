"""Gate14 binary UART helper. Legal commands only. PROGRAM=NO."""
from __future__ import annotations
import struct
from typing import Any

SOF = b"\xa7\x14"
CSOF = b"\xc1\x11"
VER = 0x01
FORBIDDEN = {
    "idx", "winner", "way", "address", "delta", "gradient", "weight",
    "subject", "relation", "object", "confidence", "cue", "anchor",
    "topk", "score", "next_token", "answer", "mode", "gen", "sdig",
    "adig", "bdig", "contradiction", "semantic",
}


def crc16(data: bytes) -> int:
    c = 0xFFFF
    for b in data:
        c ^= b << 8
        for _ in range(8):
            c = ((c << 1) ^ 0x1021) & 0xFFFF if c & 0x8000 else (c << 1) & 0xFFFF
    return c


def frame(typ: int, seq: int, payload: bytes = b"") -> bytes:
    if typ < 0x01 or typ > 0x0D:
        raise ValueError("illegal TYPE")
    if len(payload) > 8:
        raise ValueError("payload too long")
    body = bytes([VER, typ]) + struct.pack("<HH", seq, len(payload)) + payload
    return SOF + body + struct.pack("<H", crc16(body))


def reward_frame(seq: int, reward: int, txn: int) -> bytes:
    if reward < -3 or reward > 3:
        raise ValueError("reward out of range")
    return frame(0x05, seq, struct.pack("<bH", reward, txn & 0xFFFF))


def refuse_corpus(obj: Any) -> None:
    if isinstance(obj, dict):
        for k, v in obj.items():
            lk = str(k).lower()
            if lk in FORBIDDEN:
                raise ValueError(f"forbidden field {k}")
            refuse_corpus(v)
    elif isinstance(obj, (list, tuple)):
        for v in obj:
            refuse_corpus(v)


def decode_cframe(buf: bytes) -> list[dict]:
    out = []
    i = 0
    while i + 9 <= len(buf):
        if buf[i:i + 2] != CSOF:
            i += 1
            continue
        if buf[i + 2] != VER:
            i += 1
            continue
        ckpt = buf[i + 3]
        seq, ln = struct.unpack_from("<HH", buf, i + 4)
        end = i + 9 + ln
        if end + 2 > len(buf):
            break
        body = buf[i + 2:end]
        crc = struct.unpack_from("<H", buf, end)[0]
        if crc != crc16(body):
            i += 1
            continue
        out.append({"ckpt": ckpt, "seq": seq, "payload": buf[i + 9:end]})
        i = end + 2
    return out


CMD_RESET_LEARNED = 0x01
CMD_TRAIN_BEGIN = 0x02
CMD_QUERY_TOKEN = 0x03
CMD_QUERY_COMMIT = 0x04
CMD_REWARD = 0x05
CMD_FLUSH = 0x06
CMD_BRAM_KILL = 0x07
CMD_RELOAD = 0x08
CMD_FREEZE = 0x09
CMD_TRAIN_RESET = 0x0A
CMD_SNAPSHOT = 0x0B
CMD_EXAM_QUERY = 0x0C
CMD_STATUS = 0x0D
