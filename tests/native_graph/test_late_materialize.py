"""Golden + HS-01 anti-leak for a7ng-late-mat-v0 (no host address port)."""

from __future__ import annotations

import inspect
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "python"))

from native_graph.late_materialize import (  # noqa: E402
    NG_DDR_NODE_BASE,
    early_payload_bytes,
    late_ar_addrs,
    late_payload_bytes,
    n_skip,
    popcount_mask,
)
from native_graph.mem_schema_v1 import NODE_REC_BYTES, node_byte_addr  # noqa: E402

RTL = ROOT / "rtl" / "native_graph" / "memory" / "a7ng_late_materialize.sv"


def test_tb_vector_3_of_8():
    mask = 0b0010_0101
    ids = [3, 99, 7, 11, 13, 21, 22, 23]
    assert popcount_mask(mask) == 3
    assert n_skip(mask) == 5
    assert late_payload_bytes(mask) == 48
    assert early_payload_bytes() == 128
    addrs = late_ar_addrs(ids, mask)
    assert addrs == [
        node_byte_addr(NG_DDR_NODE_BASE, 3),
        node_byte_addr(NG_DDR_NODE_BASE, 7),
        node_byte_addr(NG_DDR_NODE_BASE, 21),
    ]
    assert 99 not in [a >> 4 for a in addrs]  # loser id 99 not fetched


def test_empty_and_full_mask():
    ids = list(range(8))
    assert late_payload_bytes(0) == 0
    assert n_skip(0) == 8
    assert late_ar_addrs(ids, 0) == []
    assert late_payload_bytes(0xFF) == 128
    assert n_skip(0xFF) == 0
    assert len(late_ar_addrs(ids, 0xFF)) == 8


def test_rtl_has_no_host_address_port():
    text = RTL.read_text(encoding="utf-8")
    assert "commit_i" in text
    assert "id_i" in text
    assert "addr_i" not in text
    assert "address_i" not in text
    # FPGA computes AR from schema; host must not drive it
    assert "a7ng_node_byte_addr" in text
    assert "NG_DDR_NODE_BASE" in text


def test_golden_module_has_no_winner_api():
    src = inspect.getsource(late_ar_addrs)
    assert "winner" not in src
    assert "gradient" not in src
