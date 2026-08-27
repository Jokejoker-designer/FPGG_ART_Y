"""Host golden for graph_late_materialize_00 (law a7ng-late-mat-v0).

FPGA owns AR address. This module only *checks* the same stride as
mem_schema_v1 — it must never be used as a host address/winner path.
"""

from __future__ import annotations

from native_graph.mem_schema_v1 import NODE_REC_BYTES, node_byte_addr

# Matches a7ng_pkg NG_DDR_NODE_BASE
NG_DDR_NODE_BASE = 0x0100_0000
K_DEFAULT = 8


def popcount_mask(valid_mask: int, k: int = K_DEFAULT) -> int:
    return bin(valid_mask & ((1 << k) - 1)).count("1")


def late_payload_bytes(valid_mask: int, k: int = K_DEFAULT) -> int:
    """Late materialize: survivors only. Early would be k * NODE_REC_BYTES."""
    return popcount_mask(valid_mask, k) * NODE_REC_BYTES


def early_payload_bytes(k: int = K_DEFAULT) -> int:
    return k * NODE_REC_BYTES


def n_skip(valid_mask: int, k: int = K_DEFAULT) -> int:
    return k - popcount_mask(valid_mask, k)


def late_ar_addrs(ids: list[int], valid_mask: int, *, base: int = NG_DDR_NODE_BASE) -> list[int]:
    """FPGA-owned addresses for valid slots only. Caller must not treat this as a host poke."""
    if len(ids) < 1:
        return []
    out: list[int] = []
    k = len(ids)
    for i, nid in enumerate(ids):
        if valid_mask & (1 << i):
            out.append(node_byte_addr(base, nid))
    assert len(out) == popcount_mask(valid_mask, k)
    return out
