#!/usr/bin/env python3
"""U5 host golden: traffic vs N (spread/collide) + sentinel 799999.

Does not fill 800k DRAM. Host-model occupancy only at large N.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U4 = BAG.parent / "U4-MEM02-AXI-DIRECTORY-00"
BAG_U3Q = BAG.parent / "U3Q-R3-STRUCTURED-QUERY-FEATURE-00"
sys.path.insert(0, str(BAG_U4))
sys.path.insert(0, str(BAG_U3Q))
from host_u4 import (  # noqa: E402
    CAND_CAP,
    ENTRY,
    EPOCH,
    HEAD_CAP,
    INDEX_BASE,
    N_BUCKETS,
    N_TABLES,
    POST_HEAP,
    build_docs,
    dir_addr,
    dir_pack,
    feat,
    index_docs,
    pack_post_beat,
    word_of,
)

SENTINEL = 799999  # 20'hC34FF
LADDER = [42, 256, 4096, 16384, 65536, 262144, 800000]
CHILLER = "chiller"


def occupancy_spread(n: int, base_occ: int) -> dict:
    """Extra records in other buckets: probed occupancy unchanged."""
    return {
        "N": n,
        "mode": "SPREAD",
        "probed_occ": base_occ,
        "emit": min(base_occ, CAND_CAP),
        "dir_ar": 2,  # chiller T0+T2
        "bytes_dir": 2 * 16,
        "post_ids": min(base_occ, HEAD_CAP),
        "full_scan": False,
    }


def occupancy_collide(n: int) -> dict:
    """n records all land in the same two probed buckets (same nid both tables)."""
    occ = min(n, HEAD_CAP)
    ovf = 1 if n > HEAD_CAP else 0
    predup = occ * 2  # T0 and T2 same ids
    emit = min(occ, CAND_CAP)
    trunc = max(0, occ - CAND_CAP)  # after first table fills cap; second all dups
    # first table contributes emit, second all duplicates
    ndup = occ  # all T2 copies are dups if T0 already inserted occ
    if occ <= CAND_CAP:
        trunc = 0
        ndup = occ
        emit = occ
    else:
        # T0 emits 64, trunc occ-64; T2 all dups occ
        trunc = occ - CAND_CAP
        ndup = occ
        emit = CAND_CAP
    post_beats = 2 * ((occ + 3) // 4)
    return {
        "N": n,
        "mode": "COLLIDE",
        "probed_occ": occ,
        "overflow": ovf,
        "emit": emit,
        "n_dup": ndup,
        "n_trunc": trunc,
        "dir_ar": 2,
        "post_beats": post_beats,
        "bytes": 2 * 16 + post_beats * 16,
        "full_scan": False,
        "linear_in_N": False,
    }


def main() -> int:
    docs = build_docs()
    heads, ovf = index_docs(docs)
    q = feat(CHILLER)
    base_ids = []
    for t in range(N_TABLES):
        if q["v"][t]:
            b = q["k"][t] & 0xFFF
            for nid in heads[t][b]:
                if nid not in base_ids:
                    base_ids.append(nid)
    base_occ = len(base_ids)

    spread = [occupancy_spread(n, base_occ) for n in LADDER]
    collide = [occupancy_collide(n) for n in LADDER]

    fail = []
    spread_bytes = [s["bytes_dir"] + ((s["post_ids"] + 3) // 4) * 16 * 2 for s in spread]
    if len(set(spread_bytes)) != 1:
        fail.append("SPREAD_TRAFFIC_GROWS_WITH_N")
    if any(s["emit"] != min(base_occ, CAND_CAP) for s in spread):
        fail.append("SPREAD_EMIT_CHANGED")
    if any(c["dir_ar"] > 4 for c in collide + spread):
        fail.append("DIR_AR_GT_4")
    if any(c["emit"] > CAND_CAP for c in collide):
        fail.append("CAP_BROKEN")
    # collide bytes must saturate, not track N after HEAD_CAP
    c800 = next(c for c in collide if c["N"] == 800000)
    c64k = next(c for c in collide if c["N"] == 65536)
    if c800["bytes"] != c64k["bytes"]:
        fail.append("COLLIDE_BYTES_STILL_GROW_AFTER_HEAD_CAP")
    if c800["emit"] != 64:
        fail.append("COLLIDE_800K_EMIT")

    # RTL image: U4 corpus + sentinel + collide-200 + 256 T3 dummies
    writes = {}
    # corpus occupied buckets
    post_ptr = POST_HEAP
    loc = {}
    for t in range(N_TABLES):
        for b in range(N_BUCKETS):
            ids = heads[t][b]
            if not ids:
                continue
            n = len(ids)
            nbeats = (n + 3) // 4
            base = post_ptr
            post_ptr += nbeats * ENTRY
            loc[(t, b)] = (base, n)
            writes[word_of(dir_addr(t, b))] = dir_pack(base, n, 0, EPOCH)
            for i in range(nbeats):
                writes[word_of(base + i * ENTRY)] = pack_post_beat(ids[i * 4 : i * 4 + 4])

    sent_key = 0x0FD0
    sent_post = INDEX_BASE + 0x00060000
    writes[word_of(dir_addr(0, sent_key))] = dir_pack(sent_post, 1, 0, EPOCH)
    writes[word_of(sent_post)] = pack_post_beat([SENTINEL])

    col_key = 0x0FC0
    col_n = 200
    col_ids = list(range(3000, 3000 + col_n))
    col_post = INDEX_BASE + 0x00050000
    nbeats = (col_n + 3) // 4
    writes[word_of(dir_addr(0, col_key))] = dir_pack(col_post, col_n, 1, EPOCH)
    for i in range(nbeats):
        writes[word_of(col_post + i * ENTRY)] = pack_post_beat(col_ids[i * 4 : i * 4 + 4])

    dummy_addrs = []
    dummy_post = INDEX_BASE + 0x00058000
    for i in range(256):
        b = (0x800 + i) & 0xFFF
        da = dir_addr(3, b)
        dummy_addrs.append(da)
        writes[word_of(da)] = dir_pack(dummy_post + i * ENTRY, 1, 0, EPOCH)
        writes[word_of(dummy_post + i * ENTRY)] = pack_post_beat([4000 + i])

    ch_dir = [dir_addr(t, q["k"][t]) for t in range(4) if q["v"][t]]
    dummy_overlap = [a for a in dummy_addrs if a in ch_dir]
    if dummy_overlap:
        fail.append("DUMMY_OVERLAP_CHILLER")

    result = "PASS" if not fail else "FAIL"
    out = {
        "gate": "U5-MEM02-SPARSE-800K-00",
        "sentinel": SENTINEL,
        "sentinel_hex": hex(SENTINEL),
        "base_chiller_emit": base_occ,
        "spread": spread,
        "collide": collide,
        "spread_bytes_constant": len(set(spread_bytes)) == 1,
        "spread_bytes": spread_bytes[0],
        "chiller_dir": [hex(a) for a in ch_dir],
        "n_dummy_t3": 256,
        "n_writes": len(writes),
        "result": result,
        "fail_reasons": fail,
    }
    (BAG / "GOLDEN.json").write_text(json.dumps(out, indent=2), encoding="utf-8")

    wr_i = sorted(writes)

    def hx128(v: int) -> str:
        return f"128'h{v:032X}"

    lines = [
        "// generated by host_u5.py",
        f"localparam int unsigned G_N_WR = {len(wr_i)};",
        "localparam int G_WR_I [0:G_N_WR-1] = '{" + ", ".join(str(i) for i in wr_i) + "};",
        "localparam logic [127:0] G_WR_D [0:G_N_WR-1] = '{"
        + ", ".join(hx128(writes[i]) for i in wr_i)
        + "};",
        f"localparam logic [19:0] G_SENTINEL = 20'h{SENTINEL:05X};",
        f"localparam logic [15:0] G_SENT_K = 16'h{sent_key:04X};",
        f"localparam logic [27:0] G_SENT_DIR = 28'h{dir_addr(0, sent_key):08X};",
        f"localparam logic [27:0] G_SENT_POST = 28'h{sent_post:08X};",
        f"localparam logic [15:0] G_COL_K = 16'h{col_key:04X};",
        f"localparam int unsigned G_COL_N = {col_n};",
        f"localparam logic [27:0] G_COL_DIR = 28'h{dir_addr(0, col_key):08X};",
        "localparam int unsigned G_N_DUMMY = 256;",
        "localparam logic [27:0] G_DUMMY [0:G_N_DUMMY-1] = '{"
        + ", ".join(f"28'h{a:08X}" for a in dummy_addrs)
        + "};",
        f"localparam int unsigned G_CH_NDIR = {len(ch_dir)};",
        "localparam logic [27:0] G_CH_DIR [0:G_CH_NDIR-1] = '{"
        + ", ".join(f"28'h{a:08X}" for a in ch_dir)
        + "};",
        f"localparam int unsigned G_CH_EMIT = {base_occ};",
        "localparam logic [19:0] G_CH_ID [0:G_CH_EMIT-1] = '{"
        + ", ".join(f"20'h{i:05X}" for i in base_ids)
        + "};",
        f"localparam int unsigned G_CH_LEN = {len(CHILLER)};",
        "localparam logic [8*48-1:0] G_CH_BYTES = 384'h"
        + f"{int.from_bytes(CHILLER.encode('latin1')[::-1], 'big'):096X};",
    ]
    # byte pack little-endian like U4: byte0 in [7:0]
    v = 0
    for i, x in enumerate(CHILLER.encode("latin1")):
        v |= x << (8 * i)
    lines[-1] = f"localparam logic [8*48-1:0] G_CH_BYTES = 384'h{v:096X};"
    (BAG / "u5_gold.svh").write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("BASE_CHILLER_EMIT", base_occ)
    print("SPREAD_BYTES", spread_bytes[0], "constant", len(set(spread_bytes)) == 1)
    print("COLLIDE_800K", c800)
    print("SENTINEL", hex(SENTINEL), "dir", hex(dir_addr(0, sent_key)))
    print("WRITES", len(writes))
    print("RESULT", result, fail)
    print("U5_HOST_GOLDEN_DONE")
    return 0 if result == "PASS" else 7


if __name__ == "__main__":
    raise SystemExit(main())
