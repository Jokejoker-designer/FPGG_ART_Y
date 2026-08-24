"""Golden serialize/deserialize for mem_schema_v1 (UNIT=record instance)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "python"))

from native_graph.mem_schema_v1 import (  # noqa: E402
    EDGE_REC_BYTES,
    EPISODE_REC_BYTES,
    GOLDEN_EDGE,
    GOLDEN_EDGE_HEX,
    GOLDEN_EPISODE,
    GOLDEN_EPISODE_HEX,
    GOLDEN_NODE,
    GOLDEN_NODE_HEX,
    NODE_REC_BYTES,
    SCHEMA_VERSION,
    EdgeRecordV1,
    EpisodeRecordV1,
    NodeRecordV1,
    edge_byte_addr,
    episode_byte_addr,
    node_byte_addr,
)

SV_PKG = ROOT / "rtl" / "native_graph" / "memory" / "a7ng_mem_schema_v1.sv"
C_HDR = ROOT / "rtl" / "native_graph" / "memory" / "a7ng_mem_schema_v1.h"
PKG_SV = ROOT / "rtl" / "native_graph" / "pkg" / "a7ng_pkg.sv"


def test_sizes_pinned():
    assert SCHEMA_VERSION == 1
    assert NODE_REC_BYTES == 16
    assert EDGE_REC_BYTES == 32
    assert EPISODE_REC_BYTES == 32
    assert len(GOLDEN_NODE.serialize()) == 16
    assert len(GOLDEN_EDGE.serialize()) == 32
    assert len(GOLDEN_EPISODE.serialize()) == 32


def test_node_roundtrip_golden():
    blob = GOLDEN_NODE.serialize()
    assert blob.hex() == GOLDEN_NODE_HEX
    assert NodeRecordV1.deserialize(blob) == GOLDEN_NODE


def test_edge_roundtrip_golden():
    blob = GOLDEN_EDGE.serialize()
    assert blob.hex() == GOLDEN_EDGE_HEX
    assert EdgeRecordV1.deserialize(blob) == GOLDEN_EDGE


def test_episode_roundtrip_golden():
    blob = GOLDEN_EPISODE.serialize()
    assert blob.hex() == GOLDEN_EPISODE_HEX
    assert EpisodeRecordV1.deserialize(blob) == GOLDEN_EPISODE


def test_edge_checksum_policy():
    edged = EdgeRecordV1(
        src_node=1,
        dst_node=2,
        relation_type=3,
        learned_weight=0,
        teacher_prior=0,
        positive_count=0,
        negative_count=0,
        last_update_epoch=9,
        checksum=1,  # request compute
    )
    blob = edged.serialize()
    assert EdgeRecordV1.deserialize(blob).checksum != 0
    bad = bytearray(blob)
    bad[0] ^= 0xFF
    with pytest.raises(ValueError, match="checksum"):
        EdgeRecordV1.deserialize(bytes(bad))


def test_address_helpers_match_shift_law():
    base = 0x0100_0000
    assert node_byte_addr(base, 7) == base + (7 << 4)
    assert edge_byte_addr(0x0200_0000, 7) == 0x0200_0000 + (7 << 5)
    assert episode_byte_addr(0x0400_0000, 7) == 0x0400_0000 + (7 << 5)


def test_sv_pkg_constants_match_python():
    text = SV_PKG.read_text(encoding="utf-8")
    assert "A7NG_MEM_SCHEMA_VERSION = 1" in text
    assert "A7NG_NODE_REC_BYTES    = 16" in text
    assert "A7NG_EDGE_REC_BYTES    = 32" in text
    assert "A7NG_EPISODE_REC_BYTES = 32" in text


def test_c_header_constants_match_python():
    text = C_HDR.read_text(encoding="utf-8")
    assert "#define A7NG_MEM_SCHEMA_VERSION 1u" in text
    assert "#define A7NG_NODE_REC_BYTES    16u" in text
    assert "#define A7NG_EDGE_REC_BYTES    32u" in text
    assert "#define A7NG_EPISODE_REC_BYTES 32u" in text


def test_a7ng_pkg_aliases_schema_sizes():
    text = PKG_SV.read_text(encoding="utf-8")
    assert "NG_NODE_REC_BYTES" in text
    assert "NG_EDGE_REC_BYTES" in text
    assert "NG_EPISODE_REC_BYTES" in text
    # Must not leave a divergent magic size for node
    m = re.search(r"NG_NODE_REC_BYTES\s*=\s*(\d+)", text)
    assert m and int(m.group(1)) == NODE_REC_BYTES


def test_reject_bad_version():
    blob = bytearray(GOLDEN_NODE.serialize())
    blob[15] = 2
    with pytest.raises(ValueError, match="version"):
        NodeRecordV1.deserialize(bytes(blob))
