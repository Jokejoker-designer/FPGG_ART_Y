"""Authoritative Node/Edge/EpisodeRecordV1 serdes (law: a7ng-mem-schema-v1).

Must stay byte-identical to:
  rtl/native_graph/memory/a7ng_mem_schema_v1.{sv,svh,h,md}
"""

from __future__ import annotations

import struct
import zlib
from dataclasses import dataclass
from typing import Final

SCHEMA_VERSION: Final[int] = 1
NODE_REC_BYTES: Final[int] = 16
EDGE_REC_BYTES: Final[int] = 32
EPISODE_REC_BYTES: Final[int] = 32

ENDIAN: Final[str] = "<"  # little-endian


@dataclass(frozen=True)
class NodeRecordV1:
    node_id: int
    node_type: int
    topic_id: int
    cue: int
    confidence: int
    degree_sat: int
    version: int = SCHEMA_VERSION

    def serialize(self) -> bytes:
        if not (0 <= self.degree_sat <= 255):
            raise ValueError("degree_sat out of u8")
        if self.version != SCHEMA_VERSION:
            raise ValueError("node version must be SCHEMA_VERSION")
        raw = struct.pack(
            ENDIAN + "IHHIHBB",
            self.node_id & 0xFFFFFFFF,
            self.node_type & 0xFFFF,
            self.topic_id & 0xFFFF,
            self.cue & 0xFFFFFFFF,
            self.confidence & 0xFFFF,
            self.degree_sat & 0xFF,
            self.version & 0xFF,
        )
        if len(raw) != NODE_REC_BYTES:
            raise RuntimeError("NodeRecordV1 size drift")
        return raw

    @classmethod
    def deserialize(cls, blob: bytes) -> NodeRecordV1:
        if len(blob) != NODE_REC_BYTES:
            raise ValueError(f"NodeRecordV1 needs {NODE_REC_BYTES} bytes")
        node_id, node_type, topic_id, cue, confidence, degree_sat, version = struct.unpack(
            ENDIAN + "IHHIHBB", blob
        )
        if version != SCHEMA_VERSION:
            raise ValueError(f"bad node version {version}")
        return cls(node_id, node_type, topic_id, cue, confidence, degree_sat, version)


@dataclass(frozen=True)
class EdgeRecordV1:
    src_node: int
    dst_node: int
    relation_type: int
    learned_weight: int
    teacher_prior: int
    positive_count: int
    negative_count: int
    last_update_epoch: int
    flags: int = 0
    checksum: int = 0
    pad0: int = 0
    version: int = SCHEMA_VERSION

    def serialize(self) -> bytes:
        if self.version != SCHEMA_VERSION:
            raise ValueError("edge version must be SCHEMA_VERSION")
        if self.pad0 != 0:
            raise ValueError("edge pad0 must be 0")
        body = struct.pack(
            ENDIAN + "IIHHhHHHIHH",
            self.src_node & 0xFFFFFFFF,
            self.dst_node & 0xFFFFFFFF,
            self.relation_type & 0xFFFF,
            self.pad0 & 0xFFFF,
            self.learned_weight,
            self.teacher_prior,
            self.positive_count & 0xFFFF,
            self.negative_count & 0xFFFF,
            self.last_update_epoch & 0xFFFFFFFF,
            self.version & 0xFFFF,
            self.flags & 0xFFFF,
        )
        if len(body) != 28:
            raise RuntimeError("EdgeRecordV1 body size drift")
        csum = self.checksum
        if csum != 0:
            csum = zlib.crc32(body) & 0xFFFFFFFF
        raw = body + struct.pack(ENDIAN + "I", csum)
        if len(raw) != EDGE_REC_BYTES:
            raise RuntimeError("EdgeRecordV1 size drift")
        return raw

    @classmethod
    def deserialize(cls, blob: bytes) -> EdgeRecordV1:
        if len(blob) != EDGE_REC_BYTES:
            raise ValueError(f"EdgeRecordV1 needs {EDGE_REC_BYTES} bytes")
        body, csum = blob[:28], struct.unpack(ENDIAN + "I", blob[28:32])[0]
        (
            src,
            dst,
            rel,
            pad0,
            lw,
            tp,
            pos,
            neg,
            epoch,
            ver,
            flags,
        ) = struct.unpack(ENDIAN + "IIHHhHHHIHH", body)
        if ver != SCHEMA_VERSION:
            raise ValueError(f"bad edge version {ver}")
        if pad0 != 0:
            raise ValueError("edge pad0 must be 0")
        if csum != 0 and csum != (zlib.crc32(body) & 0xFFFFFFFF):
            raise ValueError("edge checksum mismatch")
        return cls(src, dst, rel, lw, tp, pos, neg, epoch, flags, csum, pad0, ver)


@dataclass(frozen=True)
class EpisodeRecordV1:
    episode_id: int
    subject: int
    relation: int
    object: int
    context: int
    source_ref: int
    answer_payload_ref: int
    confidence: int
    flags: int = 0
    version: int = SCHEMA_VERSION

    def serialize(self) -> bytes:
        if self.version != SCHEMA_VERSION:
            raise ValueError("episode version must be SCHEMA_VERSION")
        raw = struct.pack(
            ENDIAN + "IIIIIIIHBB",
            self.episode_id & 0xFFFFFFFF,
            self.subject & 0xFFFFFFFF,
            self.relation & 0xFFFFFFFF,
            self.object & 0xFFFFFFFF,
            self.context & 0xFFFFFFFF,
            self.source_ref & 0xFFFFFFFF,
            self.answer_payload_ref & 0xFFFFFFFF,
            self.confidence & 0xFFFF,
            self.version & 0xFF,
            self.flags & 0xFF,
        )
        if len(raw) != EPISODE_REC_BYTES:
            raise RuntimeError("EpisodeRecordV1 size drift")
        return raw

    @classmethod
    def deserialize(cls, blob: bytes) -> EpisodeRecordV1:
        if len(blob) != EPISODE_REC_BYTES:
            raise ValueError(f"EpisodeRecordV1 needs {EPISODE_REC_BYTES} bytes")
        (
            eid,
            subj,
            rel,
            obj,
            ctx,
            src,
            ans,
            conf,
            ver,
            flags,
        ) = struct.unpack(ENDIAN + "IIIIIIIHBB", blob)
        if ver != SCHEMA_VERSION:
            raise ValueError(f"bad episode version {ver}")
        return cls(eid, subj, rel, obj, ctx, src, ans, conf, flags, ver)


def node_byte_addr(base: int, node_id: int) -> int:
    return (base + node_id * NODE_REC_BYTES) & 0xFFFFFFF


def edge_byte_addr(base: int, edge_id: int) -> int:
    return (base + edge_id * EDGE_REC_BYTES) & 0xFFFFFFF


def episode_byte_addr(base: int, episode_id: int) -> int:
    return (base + episode_id * EPISODE_REC_BYTES) & 0xFFFFFFF


# Golden vectors (record instances — not clock cycles as queries).
GOLDEN_NODE = NodeRecordV1(
    node_id=0x00000007,
    node_type=0x0002,
    topic_id=0x0011,
    cue=0xA7C0E001,
    confidence=0x0100,
    degree_sat=3,
)
GOLDEN_NODE_HEX = GOLDEN_NODE.serialize().hex()

GOLDEN_EDGE = EdgeRecordV1(
    src_node=0x10,
    dst_node=0x20,
    relation_type=0x0005,
    learned_weight=-3,
    teacher_prior=2,
    positive_count=4,
    negative_count=1,
    last_update_epoch=0x0000002A,
    flags=0,
    checksum=0,
)
GOLDEN_EDGE_HEX = GOLDEN_EDGE.serialize().hex()

GOLDEN_EPISODE = EpisodeRecordV1(
    episode_id=0x00000007,
    subject=0x100,
    relation=0x200,
    object=0x300,
    context=0x400,
    source_ref=0x500,
    answer_payload_ref=0x600,
    confidence=0x00C0,
    flags=0x00,
)
GOLDEN_EPISODE_HEX = GOLDEN_EPISODE.serialize().hex()
