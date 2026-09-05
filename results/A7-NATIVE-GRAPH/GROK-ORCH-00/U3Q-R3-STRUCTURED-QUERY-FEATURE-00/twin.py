#!/usr/bin/env python3
"""Bit-exact twin of a7ng_query_struct_extract, law qse-v1-lexicon-hdc-00."""
from __future__ import annotations
from lexicon import LEX, MAX_WORD

def crc16_byte(crc: int, b: int) -> int:
    crc ^= (b << 8)
    for _ in range(8):
        if crc & 0x8000:
            crc = ((crc << 1) & 0xFFFF) ^ 0x1021
        else:
            crc = (crc << 1) & 0xFFFF
    return crc


def rotl1(c: int) -> int:
    c &= (1 << 64) - 1
    return ((c << 1) | (c >> 63)) & ((1 << 64) - 1)


def bindb(c: int, b: int) -> int:
    return rotl1(c) ^ b


def fold_word(word: str, eid, iid, rid, xid, ec, ic, rc, xc, eh, ih, rh, xh):
    w = word.encode("latin1")
    hit = False
    hcls = hid = 0
    try:
        ascii_w = w.decode("ascii")
    except UnicodeDecodeError:
        ascii_w = None
    if ascii_w is not None:
        for ww, cls, iid_ in LEX:
            if ww == ascii_w:
                if not hit:
                    hit, hcls, hid = True, cls, iid_
                elif cls == hcls and iid_ < hid:
                    hid = iid_
    bcue = 0
    for x in w:
        bcue = bindb(bcue, x)
    if hit and hcls == 1:
        if eid == 0 or hid < eid:
            eid = hid
        ec ^= bcue
        eh = 1
    elif hit and hcls == 2:
        if iid == 0 or hid < iid:
            iid = hid
        ic ^= bcue
        ih = 1
    elif hit and hcls == 3:
        if rid == 0 or hid < rid:
            rid = hid
        rc ^= bcue
        rh = 1
    elif hit and hcls == 4:
        if xid == 0 or hid < xid:
            xid = hid
        xc ^= bcue
        xh = 1
    else:
        xc ^= bcue
        # unmatched: cue binds into context, but context-class bind flag stays 0
    return eid, iid, rid, xid, ec, ic, rc, xc, eh, ih, rh, xh


def extract_bytes(raw: list[int]) -> dict:
    """RTL-faithful ingest: CRC every accepted byte; words split on 0x20; lc A-Z."""
    raw = [int(b) & 0xFF for b in raw[:48]]
    crc = 0xFFFF
    for b in raw:
        crc = crc16_byte(crc, b)
    eid = iid = rid = xid = 0
    ec = ic = rc = xc = 0
    eh = ih = rh = xh = 0
    n_words = 0
    cur: list[int] = []
    def flush():
        nonlocal eid, iid, rid, xid, ec, ic, rc, xc, eh, ih, rh, xh, n_words, cur
        if not cur or n_words >= 8:
            cur = []
            return
        w = bytes(cur).decode("latin1")
        eid, iid, rid, xid, ec, ic, rc, xc, eh, ih, rh, xh = fold_word(
            w, eid, iid, rid, xid, ec, ic, rc, xc, eh, ih, rh, xh
        )
        n_words += 1
        cur = []

    for b in raw:
        if b == 0x20:
            flush()
        else:
            lc = b + 32 if 65 <= b <= 90 else b
            if len(cur) < MAX_WORD:
                cur.append(lc)
    flush()
    k0 = ((eid & 0xFF) << 8) | (iid & 0xFF)
    k1 = ((rid & 0xFF) << 8) | (xid & 0xFF)
    k2 = ec & 0xFFFF
    k3 = ic & 0xFFFF
    # Validity from bind/hit state, NOT from key != 0.
    v0 = 1 if (eh or ih) else 0
    v1 = 1 if (rh or xh) else 0
    v2 = 1 if eh else 0
    v3 = 1 if ih else 0
    return {
        "entity_id": eid, "intent_id": iid, "relation_id": rid, "context_id": xid,
        "entity_cue": ec, "intent_cue": ic, "relation_cue": rc, "context_cue": xc,
        "crc16_dbg": crc, "k0": k0, "k1": k1, "k2": k2, "k3": k3,
        "k0_valid": v0, "k1_valid": v1, "k2_valid": v2, "k3_valid": v3,
        "entity_bind": eh, "intent_bind": ih, "relation_bind": rh, "context_bind": xh,
        "n_host": 0,
    }


def extract(text: str) -> dict:
    raw = text.encode("latin1", "ignore")[:48]
    return extract_bytes(list(raw))
