"""Deterministic tensor dump / SHA for LM checkpoints."""
from __future__ import annotations

import hashlib
import struct
from typing import Iterable


def pack_i8(values: Iterable[int]) -> bytes:
    return b"".join(struct.pack("<b", int(v)) for v in values)


def pack_i16(values: Iterable[int]) -> bytes:
    return b"".join(struct.pack("<h", int(v)) for v in values)


def sha256_bytes(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()


def sha256_i8(values: Iterable[int]) -> str:
    return sha256_bytes(pack_i8(values))
