"""A7-EAM-00G Hamming generalization sweep. Development, not a close."""
from __future__ import annotations

import argparse
import json
import secrets
import statistics
import sys
import time
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

HIT_MAXS = (0, 1, 2, 4, 8)
FLIPS = (0, 1, 2, 4, 8)
MODES = ("any", "tag", "set")


def pop64(x: int) -> int:
    return int(x & ((1 << 64) - 1)).bit_count()


def flip_bits(key: int, k: int, mode: str, rng: secrets.SystemRandom) -> int:
    if k <= 0:
        return key
    if mode == "set":
        pool = list(range(8))
    elif mode == "tag":
        pool = list(range(8, 64))
    else:
        pool = list(range(64))
    k = min(k, len(pool))
    pos = rng.sample(pool, k)
    out = key
    for p in pos:
        out ^= 1 << p
    return out & ((1 << 64) - 1)


class Twin:
    """Same geometry as eam_core: set=key[7:0], 16 ways, first-invalid else min-conf."""

    def __init__(self) -> None:
        self.sets: dict[int, list[tuple[int, int]]] = defaultdict(list)

    def map(self, key: int, tok: int) -> bool:
        s = key & 0xFF
        ways = self.sets[s]
        for i, (k, t) in enumerate(ways):
            if k == key:
                ways[i] = (key, t)
                return True
        if len(ways) < 16:
            ways.append((key, tok))
            return False
        ways[0] = (key, tok)
        return False

    def probe(self, key: int) -> dict:
        ways = self.sets.get(key & 0xFF, [])
        if not ways:
            return {"best": 64, "second": 64, "token": 0, "ok": False, "occ": 0}
        ds = sorted((pop64(key ^ k), t) for k, t in ways)
        best, tok = ds[0]
        second = ds[1][0] if len(ds) > 1 else 64
        return {"best": best, "second": second, "token": tok, "ok": True, "occ": len(ways)}

    def occupancy(self) -> dict:
        occ = [len(v) for v in self.sets.values() if v]
        return {
            "sets_used": len(occ),
            "entries": sum(occ),
            "colliding_sets": sum(1 for n in occ if n >= 2),
            "max_occ": max(occ) if occ else 0,
            "mean_occ": (sum(occ) / len(occ)) if occ else 0.0,
        }


def qv(key: int, vec: int = 0, tok: int = 0) -> bytes:
    return key.to_bytes(8, "little") + vec.to_bytes(16, "little") + bytes([tok & 0xFF])


def xor_bytes(data: bytes) -> int:
    x = 0
    for b in data:
        x ^= b
    return x & 0xFF


def pack(cmd: int, payload: bytes = b"") -> bytes:
    head = bytes([0xA5, cmd & 0xFF, len(payload) & 0xFF]) + payload
    return head + bytes([xor_bytes(head)])


def parse(rep: bytes) -> dict:
    if len(rep) != 20 or rep[0] != 0x5A or xor_bytes(rep[:19]) != rep[19]:
        raise RuntimeError(f"bad reply {rep.hex()}")
    return {
        "kind": rep[1],
        "hit": bool(rep[2] & 1),
        "token": rep[3],
        "best": rep[4],
        "second": rep[5],
        "epoch": rep[18],
    }


class Board:
    def __init__(self, port: str) -> None:
        import serial

        self.ser = serial.Serial(port, 115200, timeout=0.05)
        time.sleep(0.3)
        self.ser.reset_input_buffer()

    def close(self) -> None:
        self.ser.close()

    def xact(self, cmd: int, payload: bytes = b"", timeout: float = 2.0) -> dict:
        self.ser.write(pack(cmd, payload))
        self.ser.flush()
        buf = bytearray()
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline and len(buf) < 20:
            chunk = self.ser.read(20 - len(buf))
            if chunk:
                buf.extend(chunk)
        if len(buf) != 20:
            raise TimeoutError(f"short reply {bytes(buf).hex()} cmd={cmd:#x}")
        return parse(bytes(buf))


def empty_cell() -> dict:
    return {
        "n": 0,
        "tp": 0,
        "wrong": 0,
        "miss": 0,
        "fp": 0,
        "ambiguous": 0,
        "best": [],
        "second": [],
        "margin": [],
    }


def add_probe(cell: dict, best: int, second: int, tok: int, expect: int | None, t: int) -> None:
    cell["n"] += 1
    cell["best"].append(best)
    cell["second"].append(second)
    cell["margin"].append((second - best) if second < 64 else (64 - best))
    accept = best <= t
    amb = accept and second <= t
    if amb:
        cell["ambiguous"] += 1
    if expect is None:
        if accept:
            cell["fp"] += 1
        else:
            cell["miss"] += 1
        return
    if not accept:
        cell["miss"] += 1
    elif tok == expect:
        cell["tp"] += 1
    else:
        cell["wrong"] += 1


def summarize(cell: dict) -> dict:
    n = max(1, cell["n"])
    def mean(xs: list[int]) -> float:
        return float(statistics.fmean(xs)) if xs else 0.0

    return {
        "n": cell["n"],
        "tp_rate": cell["tp"] / n,
        "wrong_hit_rate": cell["wrong"] / n,
        "miss_rate": cell["miss"] / n,
        "fp_rate": cell["fp"] / n,
        "collision_rate": cell["ambiguous"] / n,
        "best_hamming_mean": mean(cell["best"]),
        "second_hamming_mean": mean(cell["second"]),
        "margin_mean": mean(cell["margin"]),
    }


def run(n_map: int, repeats: int, port: str | None) -> dict:
    rng = secrets.SystemRandom()
    twin = Twin()
    keys = [rng.getrandbits(64) for _ in range(n_map)]
    toks = [rng.randrange(1, 255) for _ in range(n_map)]
    board = Board(port) if port else None
    disagree = 0
    probes = 0

    if board:
        board.xact(0x01)
        board.xact(0x05)
        board.xact(0x07, bytes([8]))  # FPGA accept up to 8; host slices T

    for k, t in zip(keys, toks, strict=True):
        twin.map(k, t)
        if board:
            r = board.xact(0x02, qv(k, rng.getrandbits(128), t))
            if r["hit"]:
                # exact collision with an already-stored key of same bits — rare
                pass

    table: dict[str, dict] = {}
    for mode in (*MODES, "unrelated"):
        for kflip in FLIPS if mode != "unrelated" else (None,):
            label = f"{mode}:{kflip if kflip is not None else 'rand'}"
            table[label] = {str(t): empty_cell() for t in HIT_MAXS}

    def record(label: str, best: int, second: int, tok: int, expect: int | None) -> None:
        for t in HIT_MAXS:
            add_probe(table[label][str(t)], best, second, tok, expect, t)

    for i, (k, tok) in enumerate(zip(keys, toks, strict=True)):
        for mode in MODES:
            for kflip in FLIPS:
                for _ in range(repeats if kflip else 1):
                    q = flip_bits(k, kflip, mode, rng)
                    tw = twin.probe(q)
                    if board:
                        br = board.xact(0x03, qv(q, 0, 0))
                        probes += 1
                        if br["best"] != tw["best"]:
                            disagree += 1
                        best, second, wtok = br["best"], br["second"], br["token"]
                    else:
                        best, second, wtok = tw["best"], tw["second"], tw["token"]
                    record(f"{mode}:{kflip}", best, second, wtok, tok)

        u = rng.getrandbits(64)
        while u in set(keys):
            u = rng.getrandbits(64)
        tw = twin.probe(u)
        if board:
            br = board.xact(0x03, qv(u, 0, 0))
            probes += 1
            if br["best"] != tw["best"]:
                disagree += 1
            best, second, wtok = br["best"], br["second"], br["token"]
        else:
            best, second, wtok = tw["best"], tw["second"], tw["token"]
        record("unrelated:rand", best, second, wtok, None)

    if board:
        board.close()

    out_table = {
        lab: {t: summarize(cell) for t, cell in cells.items()} for lab, cells in table.items()
    }
    return {
        "candidate": "00g",
        "development": True,
        "n_map": n_map,
        "repeats": repeats,
        "hit_max": list(HIT_MAXS),
        "board": bool(port),
        "port": port,
        "fpga_twin_best_disagree": disagree,
        "board_probes": probes,
        "occupancy": twin.occupancy(),
        "table": out_table,
        "utc": datetime.now(timezone.utc).isoformat(),
    }


def verdict(doc: dict) -> list[str]:
    notes = []
    t8 = doc["table"]["any:8"]["8"]
    t0 = doc["table"]["any:0"]["0"]
    u8 = doc["table"]["unrelated:rand"]["8"]
    u0 = doc["table"]["unrelated:rand"]["0"]
    tag8 = doc["table"]["tag:8"]["8"]
    set1 = doc["table"]["set:1"]["8"]
    notes.append(
        f"exact T=0: TP={t0['tp_rate']:.3f} (must be ~1 if store held)"
    )
    notes.append(
        f"any 8-flip T=8: TP={t8['tp_rate']:.3f} wrong={t8['wrong_hit_rate']:.3f} "
        f"miss={t8['miss_rate']:.3f} collision={t8['collision_rate']:.3f} "
        f"best~{t8['best_hamming_mean']:.2f} margin~{t8['margin_mean']:.2f}"
    )
    notes.append(
        f"tag 8-flip T=8 (same set): TP={tag8['tp_rate']:.3f} "
        f"best~{tag8['best_hamming_mean']:.2f} margin~{tag8['margin_mean']:.2f}"
    )
    notes.append(
        f"set 1-flip T=8 (wrong set): TP={set1['tp_rate']:.3f} "
        f"— set bits are the index; a flip is a different table"
    )
    notes.append(
        f"unrelated T=0 FP={u0['fp_rate']:.4f}; T=8 FP={u8['fp_rate']:.4f} "
        f"best~{u8['best_hamming_mean']:.2f} margin~{u8['margin_mean']:.2f}"
    )
    occ = doc["occupancy"]
    notes.append(
        f"occupancy: {occ['entries']} entries in {occ['sets_used']} sets, "
        f"{occ['colliding_sets']} colliding, max={occ['max_occ']}"
    )
    # Reject quality: need high TP on small noise in-set AND low FP on unrelated.
    reject_ok = u8["fp_rate"] <= 0.02 and tag8["tp_rate"] >= 0.9 and tag8["collision_rate"] <= 0.05
    notes.append(
        "REJECT_BEHAVIOR: "
        + (
            "usable for a small in-set Hamming ball; still not a reason to scale "
            "this metric to 256 MB without a better key / extra check"
            if reject_ok
            else "weak — Hamming ball at T=8 either misses A' or accepts strangers / collisions"
        )
    )
    if occ["colliding_sets"] and u8["fp_rate"] > 0.01:
        notes.append(
            "Collision + T=8 FP: random 64-bit keys in a 16-way set sit near d≈32; "
            "T=8 is far from that mean, so FP should stay rare unless occupancy explodes."
        )
    return notes


def to_md(doc: dict, notes: list[str]) -> str:
    lines = [
        "# A7-EAM-00G sweep (development)",
        "",
        f"- n_map={doc['n_map']} repeats={doc['repeats']} board={doc['board']}",
        f"- twin/FPGA best disagree={doc['fpga_twin_best_disagree']}",
        "",
        "## Occupancy",
        "",
        "```json",
        json.dumps(doc["occupancy"], indent=2),
        "```",
        "",
        "## Notes",
        "",
    ]
    lines += [f"- {n}" for n in notes]
    lines += ["", "## Table (TP / FP / miss / collision / best / margin)", ""]
    hdr = "| cond | T | tp | fp | wrong | miss | coll | best | 2nd | margin |"
    lines += [hdr, "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for lab, ts in doc["table"].items():
        for t, c in ts.items():
            lines.append(
                f"| {lab} | {t} | {c['tp_rate']:.3f} | {c['fp_rate']:.3f} | "
                f"{c['wrong_hit_rate']:.3f} | {c['miss_rate']:.3f} | "
                f"{c['collision_rate']:.3f} | {c['best_hamming_mean']:.2f} | "
                f"{c['second_hamming_mean']:.2f} | {c['margin_mean']:.2f} |"
            )
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=256)
    ap.add_argument("--repeats", type=int, default=2)
    ap.add_argument("--port", default="")
    ap.add_argument("--offline", action="store_true")
    args = ap.parse_args()
    port = None if args.offline or not args.port else args.port
    doc = run(args.n, args.repeats, port)
    notes = verdict(doc)
    doc["notes"] = notes
    outj = ROOT / "results" / "A7-EAM-00" / "sweep_00g.json"
    outm = ROOT / "results" / "A7-EAM-00" / "sweep_00g.md"
    outj.parent.mkdir(parents=True, exist_ok=True)
    outj.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    outm.write_text(to_md(doc, notes), encoding="utf-8")
    print(outm.read_text(encoding="utf-8"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
