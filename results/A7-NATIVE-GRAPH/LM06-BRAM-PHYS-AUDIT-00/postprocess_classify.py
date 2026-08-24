import csv
import hashlib
from collections import Counter
from pathlib import Path

out = Path(r"d:/Jetking_sem4/SEM_4/arty-a7-online-lm/results/A7-NATIVE-GRAPH/LM06-BRAM-PHYS-AUDIT-00")
dcp = Path(r"d:/Jetking_sem4/SEM_4/arty-a7-online-lm/build/out/a7lm06_post_route.dcp")
h = hashlib.sha256(dcp.read_bytes()).hexdigest().upper()
(out / "DCP_SHA256.txt").write_text(h + "\n", encoding="utf-8")
print("DCP_SHA", h)

rows = list(csv.DictReader((out / "BRAM_PHYSICAL.tsv").open(encoding="utf-8"), delimiter="\t"))


def reclass(r):
    mode = r["ram_mode"]
    rwa = int(r["READ_WIDTH_A"] or 0)
    dip = int(r["dip_signal"] or 0)
    dop = int(r["dop_signal"] or 0)
    di = int(r["di_signal_count"] or 0)
    do = int(r["do_signal_count"] or 0)
    if int(r["EN_ECC_READ"] or 0) or int(r["EN_ECC_WRITE"] or 0):
        return "ECC_RESERVED"
    if mode == "SDP" and rwa == 72:
        if dip >= 8 and (dop >= 8 or do >= 32):
            return "FULL_X72_PAYLOAD"
        if dip == 0 and di >= 24:
            return "WIDTH_BOUND"
        return "UNKNOWN"
    if rwa == 9:
        if dip > 0 or dop > 0:
            return "PARITY_USED"
        return "UNKNOWN"
    if rwa == 1:
        return "BIT_SLICED_PORT_BOUND"
    return "UNKNOWN"


for r in rows:
    r["classification"] = reclass(r)
    tags = []
    if r["classification"] == "WIDTH_BOUND" and int(r["dip_signal"] or 0) == 0:
        tags.append("PARITY_UNUSED_NO_TILE_GAIN")
        tags.append("TAIL_FRAGMENT_32b_IN_X72_SHELL")
    if r["classification"] == "BIT_SLICED_PORT_BOUND":
        tags.append("PARITY_UNUSED_NO_TILE_GAIN")
    if r["classification"] == "FULL_X72_PAYLOAD":
        tags.append("PARITY_USED_AS_PAYLOAD")
    if r["classification"] == "PARITY_USED":
        tags.append("X9_ASPECT")
    r["tags"] = ";".join(tags)

print("class", Counter(r["classification"] for r in rows))

fields = list(rows[0].keys())
with (out / "BRAM_PHYSICAL.tsv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=fields, delimiter="\t", lineterminator="\n")
    w.writeheader()
    w.writerows(rows)

banks = []


def add_bank(**kw):
    banks.append(kw)


uw_sdp = [r for r in rows if r["owner"] == "u_w" and r["ram_mode"] == "SDP"]
add_bank(
    bank_id="u_w.SDP_CH_ram_104b",
    owner="u_w",
    members=str(len(uw_sdp)),
    topology="8 CH x {ram0,ram1} x {reg_0:FULL_X72, reg_1:32b-in-x72-shell} => 104-bit logical word",
    physical_tiles="32",
    physical_bits=str(32 * 36864),
    logical_width_bits="104",
    classification_mix=str(dict(Counter(r["classification"] for r in uw_sdp))),
    parity_bits_used_as_payload="128",
    parity_bits_unused="128",
    limiting_dimension="width+banking",
    estimated_removable_tiles="0",
    notes="reg_1 DIP tied const1; waste inside tile; no proven N->N-1 remap",
)

uw_tdp = [r for r in rows if r["owner"] == "u_w" and r["ram_mode"] == "TDP"]
add_bank(
    bank_id="u_w.TILE.u_bank_bitsliced",
    owner="u_w",
    members=str(len(uw_tdp)),
    topology="TILE.u_bank mem_reg_{0..3}_{0..7}; TDP width=1 bit-slices",
    physical_tiles="32",
    physical_bits=str(32 * 36864),
    logical_width_bits="32",
    classification_mix=str(dict(Counter(r["classification"] for r in uw_tdp))),
    parity_bits_used_as_payload="0",
    parity_bits_unused="DIP mostly const/unconnected",
    limiting_dimension="port",
    estimated_removable_tiles="0",
    notes="BIT_SLICED_PORT_BOUND; parity pack cannot drop a tile without port/banking change",
)

ua_sdp = [r for r in rows if r["owner"] == "u_a" and r["ram_mode"] == "SDP"]
add_bank(
    bank_id="u_a.SDP_104b_pair",
    owner="u_a",
    members="2",
    topology="mem_reg_0 FULL_X72 + mem_reg_1 32b-in-x72-shell => 104-bit",
    physical_tiles="2",
    physical_bits=str(2 * 36864),
    logical_width_bits="104",
    classification_mix=str(dict(Counter(r["classification"] for r in ua_sdp))),
    parity_bits_used_as_payload="8",
    parity_bits_unused="8",
    limiting_dimension="width",
    estimated_removable_tiles="0",
    notes="Same split pattern as u_w SDP",
)

ua_tdp = [r for r in rows if r["owner"] == "u_a" and r["ram_mode"] == "TDP"]
add_bank(
    bank_id="u_a.core_bitsliced_4x16",
    owner="u_a",
    members="64",
    topology="u_core/u_a mem_reg_{0..3}_{0..15}; shared ADDR/clk; TDP w=1",
    physical_tiles="64",
    physical_bits=str(64 * 36864),
    logical_width_bits="16",
    classification_mix=str(dict(Counter(r["classification"] for r in ua_tdp))),
    parity_bits_used_as_payload="0",
    parity_bits_unused="DIP tied const on probed slice",
    limiting_dimension="port",
    estimated_removable_tiles="0",
    notes="Shared ADDRARDADDR nets across slices (probe); dominant consumer",
)

snap = [r for r in rows if r["owner"] == "u_snap"]
add_bank(
    bank_id="u_snap.TDP_x9",
    owner="u_snap",
    members="2",
    topology="TDP READ_WIDTH=9; DIP[0]/DOP[0] carry 9th bit on mem_reg_0",
    physical_tiles="2",
    physical_bits=str(2 * 36864),
    logical_width_bits="9",
    classification_mix=str(dict(Counter(r["classification"] for r in snap))),
    parity_bits_used_as_payload="1",
    parity_bits_unused="other DIP lanes const",
    limiting_dimension="aspect",
    estimated_removable_tiles="0",
    notes="x9 aspect uses one parity lane as payload; cannot free a whole tile",
)

fields = [
    "bank_id",
    "owner",
    "members",
    "topology",
    "physical_tiles",
    "physical_bits",
    "logical_width_bits",
    "classification_mix",
    "parity_bits_used_as_payload",
    "parity_bits_unused",
    "limiting_dimension",
    "estimated_removable_tiles",
    "notes",
]
with (out / "LOGICAL_BANKS.tsv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=fields, delimiter="\t", lineterminator="\n")
    w.writeheader()
    w.writerows(banks)

print("banks", len(banks))
print("any_removable", any(int(b["estimated_removable_tiles"]) > 0 for b in banks))
