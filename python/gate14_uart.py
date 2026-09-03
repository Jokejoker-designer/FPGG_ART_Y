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
    """SOF C1 11 | VER | CKPT | SEQ u16 LE | LEN u16 LE | PAY | CRC16 LE.

    Header is 8 bytes (not 9). CRC covers VERSION..PAYLOAD.
    """
    out = []
    i = 0
    while i + 10 <= len(buf):
        if buf[i:i + 2] != CSOF:
            i += 1
            continue
        if buf[i + 2] != VER:
            i += 1
            continue
        ckpt = buf[i + 3]
        seq, ln = struct.unpack_from("<HH", buf, i + 4)
        pay_off = i + 8
        crc_off = pay_off + ln
        if crc_off + 2 > len(buf):
            break
        body = buf[i + 2:crc_off]
        crc = struct.unpack_from("<H", buf, crc_off)[0]
        if crc != crc16(body):
            i += 1
            continue
        out.append({"ckpt": ckpt, "seq": seq, "payload": buf[pay_off:crc_off]})
        i = crc_off + 2
    return out


def c1_mode(payload: bytes) -> int | None:
    if not payload:
        return None
    return payload[0] & 0x0F


def c5_fields(payload: bytes) -> dict:
    if len(payload) < 9:
        return {}
    cons, rej = struct.unpack_from("<II", payload, 0)
    return {"cons": cons, "rej": rej, "ack": payload[8]}


def c6_txn(payload: bytes) -> int | None:
    if len(payload) < 2:
        return None
    return int.from_bytes(payload[:2], "little")


def c7_fields(payload: bytes) -> dict:
    if len(payload) < 6:
        return {}
    return {
        "addr": int.from_bytes(payload[0:4], "little"),
        "ack": payload[4],
        "err": payload[5],
        "busy": bool(payload[5] & 1),
    }


def c8_fields(payload: bytes) -> dict:
    if len(payload) < 12:
        return {}
    return {
        "gen": int.from_bytes(payload[0:4], "little"),
        "sdig": int.from_bytes(payload[4:12], "little"),
    }


def c0_id(payload: bytes) -> bytes:
    return bytes(payload[:8]) if len(payload) >= 8 else b""


def c9_fields(payload: bytes) -> dict:
    if len(payload) < 42:
        return {}
    return {
        "ids": int.from_bytes(payload[0:8], "little"),
        "pack": int.from_bytes(payload[24:32], "little"),
        "poison": payload[32] & 1,
        "r1s": int.from_bytes(payload[33:37], "little"),
        "r1r": payload[37],
        "r1o": int.from_bytes(payload[38:42], "little"),
    }


def c10_fields(payload: bytes) -> dict:
    if len(payload) < 4:
        return {}
    out = {
        "lmst": payload[0],
        "lmdn": payload[1],
        "out": int.from_bytes(payload[2:4], "little"),
    }
    if len(payload) >= 6:
        out["x"] = int.from_bytes(payload[4:6], "little")
    return out


def c11_fields(payload: bytes) -> dict:
    if len(payload) < 18:
        return {}
    return {
        "adig": int.from_bytes(payload[0:8], "little"),
        "bdig": int.from_bytes(payload[8:16], "little"),
        "afor": payload[16] & 1,
        "bvis": payload[17] & 1,
    }


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
