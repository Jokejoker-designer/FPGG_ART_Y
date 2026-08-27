#!/usr/bin/env python3
"""Inventory existing LM-06 working-set reports for gate lm06_wm_trace_00.

Reads files already in the repo. Does not invent M_peak, MRC, or reuse-distance.
Does not treat WM-00 port-demand (max_live_per_cycle) as working-set size
(binding: results/A7-NATIVE-GRAPH/STATUS/VERDICT_lm06_wm_00_BINDING.md).

Usage:
  python tools/lm06_wm_trace_parse.py
  python tools/lm06_wm_trace_parse.py --out results/A7-NATIVE-GRAPH/LM06-WM-TRACE-00/INVENTORY.json
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]

GATE = "lm06_wm_trace_00"
ONE_UNKNOWN = (
    "What is u_a M_peak lifetime and tile residency under frozen LM-06 law?"
)

# Future TRACE sink (PLAN.md §7.2). Not present this wave.
WMTR_RE = re.compile(
    r"^WMTR_REC\s+"
    r"cyc=(?P<cyc>\d+)\s+seq=(?P<seq>\d+)\s+ph=(?P<ph>\S+)\s+"
    r"st=(?P<st>\d+)\s+ntok=(?P<ntok>\d+)\s+owner=(?P<owner>\S+)\s+"
    r"tile=(?P<tile>\d+)\s+port=(?P<port>\S+)\s+we=(?P<we>\d+)\s+"
    r"addr=(?P<addr>\d+)"
)

WM00_WS_RE = re.compile(
    r"WM00_WS\s+(?P<who>w|act|snp)\s+"
    r"pp_swaps=(?P<pp>\d+)\s+"
    r"live_pair_events=(?P<live>\d+)\s+"
    r"max_live_per_cycle=(?P<mx>\d+)"
)
WM00_CNT_ACT_RE = re.compile(
    r"WM00_CNT\s+wr_act\s+"
    r"upload=(?P<upload>\d+)\s+eval=(?P<eval>\d+)\s+train=(?P<train>\d+)\s+"
    r"after=(?P<after>\d+)\s+fold=(?P<fold>\d+)\s+reload=(?P<reload>\d+)"
)
RESULTS_UA_ROW_RE = re.compile(
    r"`u_a` activation scratch\s*\|[^|]*\|\s*(?P<pp>[\d,]+)\s*\|"
    r"\s*(?P<live>[\d,]+)\s*\|\s*\*\*(?P<mx>\d+)\*\*"
)
RESULTS_WR_ACT_RE = re.compile(
    r"`wr_act` \(activation scratch\)\s*\|[^|]*\|\s*(?P<eval>\d+)\s*\|"
    r"\s*(?P<train>\d+)\s*\|\s*(?P<after>\d+)\s*\|\s*(?P<fold>\d+)"
)


def _sha256(path: Path) -> str | None:
    if not path.is_file():
        return None
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def _rel(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def _read_text(path: Path) -> str | None:
    if not path.is_file():
        return None
    return path.read_text(encoding="utf-8", errors="replace")


def _file_rec(path: Path, role: str) -> dict[str, Any]:
    exists = path.is_file()
    rec: dict[str, Any] = {
        "path": _rel(path),
        "role": role,
        "exists": exists,
        "bytes": path.stat().st_size if exists else 0,
        "sha256": _sha256(path) if exists else None,
    }
    return rec


def _int_commas(s: str) -> int:
    return int(s.replace(",", ""))


def parse_logical_banks(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    with path.open(encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh, delimiter="\t"))
    out: dict[str, Any] = {"rows": [], "u_a_tiles": 0, "u_w_tiles": 0, "u_snap_tiles": 0}
    for r in rows:
        owner = r.get("owner", "")
        tiles = int(r.get("physical_tiles") or 0)
        rec = {
            "bank_id": r.get("bank_id"),
            "owner": owner,
            "physical_tiles": tiles,
            "limiting_dimension": r.get("limiting_dimension"),
            "estimated_removable_tiles": r.get("estimated_removable_tiles"),
        }
        out["rows"].append(rec)
        if owner == "u_a":
            out["u_a_tiles"] += tiles
        elif owner == "u_w":
            out["u_w_tiles"] += tiles
        elif owner == "u_snap":
            out["u_snap_tiles"] += tiles
    out["sum_named"] = out["u_a_tiles"] + out["u_w_tiles"] + out["u_snap_tiles"]
    return out


def parse_bram_physical(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    with path.open(encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh, delimiter="\t"))
    counts: dict[str, int] = {}
    for r in rows:
        owner = r.get("owner") or "UNKNOWN"
        counts[owner] = counts.get(owner, 0) + 1
    return {"n_rows": len(rows), "by_owner": counts}


def parse_wm00_results(path: Path) -> dict[str, Any] | None:
    txt = _read_text(path)
    if txt is None:
        return None
    out: dict[str, Any] = {"source": _rel(path), "u_a": {}, "wr_act": {}}
    m = RESULTS_UA_ROW_RE.search(txt)
    if m:
        out["u_a"] = {
            "pp_swaps": _int_commas(m.group("pp")),
            "live_pair_events": _int_commas(m.group("live")),
            "max_live_per_cycle": int(m.group("mx")),
            "class": "L2_port_demand_NOT_M_peak",
        }
    m2 = RESULTS_WR_ACT_RE.search(txt)
    if m2:
        out["wr_act"] = {k: int(m2.group(k)) for k in ("eval", "train", "after", "fold")}
        out["wr_act"]["class"] = "write_count_NOT_live_set"
    return out


def parse_wm00_logs(raw_dir: Path) -> dict[str, Any]:
    found: dict[str, Any] = {}
    if not raw_dir.is_dir():
        return {"logs_present": False, "by_tag": found}
    for log in sorted(raw_dir.glob("xsim_*.log")):
        txt = _read_text(log) or ""
        rec: dict[str, Any] = {"path": _rel(log), "ws": [], "wr_act": None}
        for m in WM00_WS_RE.finditer(txt):
            rec["ws"].append(
                {
                    "who": m.group("who"),
                    "pp_swaps": int(m.group("pp")),
                    "live_pair_events": int(m.group("live")),
                    "max_live_per_cycle": int(m.group("mx")),
                    "class": "L2_port_demand_NOT_M_peak",
                }
            )
        m2 = WM00_CNT_ACT_RE.search(txt)
        if m2:
            rec["wr_act"] = {k: int(m2.group(k)) for k in m2.groupdict()}
        found[log.name] = rec
    return {"logs_present": bool(found), "by_tag": found}


def parse_sha256_manifest(path: Path) -> dict[str, Any] | None:
    txt = _read_text(path)
    if txt is None:
        return None
    listed_logs: list[dict[str, Any]] = []
    for line in txt.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 3:
            continue
        sha, nbytes, rel = parts[0], parts[1], parts[-1]
        if "xsim_" in rel and rel.endswith(".log"):
            p = ROOT / rel.replace("\\", "/")
            listed_logs.append(
                {
                    "manifest_path": rel.replace("\\", "/"),
                    "manifest_sha256": sha,
                    "manifest_bytes": int(nbytes),
                    "on_disk": p.is_file(),
                    "on_disk_sha256": _sha256(p) if p.is_file() else None,
                }
            )
    return {"listed_xsim_logs": listed_logs}


def parse_bank_summary(path: Path) -> dict[str, Any] | None:
    txt = _read_text(path)
    if txt is None:
        return None
    kv: dict[str, Any] = {"source": _rel(path), "lines": {}}
    for line in txt.splitlines():
        if not line.strip():
            continue
        kv["lines"][line.split("=")[0] if "=" in line else line[:40]] = line
    m = re.search(r"busy_cycles=(\d+)", txt)
    if m:
        kv["busy_cycles"] = int(m.group(1))
        kv["busy_cycles_class"] = "duration_NOT_sample_size"
    m = re.search(r"act_diff_addr=(\d+)", txt)
    if m:
        kv["act_diff_addr"] = int(m.group(1))
        kv["act_diff_addr_class"] = "address_inequality_NOT_M_peak"
    m = re.search(r"max_act_ports=(\d+)", txt)
    if m:
        kv["max_act_ports"] = int(m.group(1))
        kv["max_act_ports_class"] = "L2_port_demand_NOT_M_peak"
    m = re.search(r"act_wr=(\d+)", txt)
    if m:
        kv["act_wr"] = int(m.group(1))
    m = re.search(r"workload=(\S+)", txt)
    if m:
        kv["workload"] = m.group(1)
    return kv


def parse_bank_lifetimes(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    with path.open(encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh, delimiter="\t"))
    act = next((r for r in rows if "act" in (r.get("logical_bank_id") or "").lower()), None)
    rec: dict[str, Any] = {"n_rows": len(rows), "core_act": None}
    if act:
        notes = act.get("notes") or ""
        mpeak_cell = act.get("M_peak_bits") or ""
        rec["core_act"] = {
            "logical_bank_id": act.get("logical_bank_id"),
            "M_peak_bits_cell": mpeak_cell,
            "notes": notes,
            "peak_live_measured": (
                "UNKNOWN" not in notes.upper() and "unknown" not in mpeak_cell.lower()
            ),
        }
        # Capacity text such as "2097152 (full array capacity; peak-live UNKNOWN)"
        # must never become m_peak_u_a.value.
        rec["core_act"]["treat_cell_as_measured_m_peak"] = False
    return rec


def parse_wmtr_files(trace_dir: Path) -> dict[str, Any]:
    files = sorted(trace_dir.glob("**/WMTR_REC*.txt")) + sorted(
        trace_dir.glob("**/*wmtr*.log")
    )
    units: dict[str, dict[str, Any]] = {}
    n_rec = 0
    for fp in files:
        txt = _read_text(fp) or ""
        for line in txt.splitlines():
            m = WMTR_RE.match(line.strip())
            if not m:
                continue
            n_rec += 1
            g = m.groupdict()
            if g["owner"] != "u_a":
                continue
            key = f"seq{g['seq']}_{g['ph']}"
            u = units.setdefault(
                key,
                {
                    "seq": int(g["seq"]),
                    "ph": g["ph"],
                    "ntok": int(g["ntok"]),
                    "refs": 0,
                    "tiles_touched": set(),
                    "live_by_cyc": {},
                    "birth": {},
                    "last_acc": {},
                },
            )
            cyc = int(g["cyc"])
            tile = int(g["tile"])
            we = int(g["we"])
            u["refs"] += 1
            u["tiles_touched"].add(tile)
            # Incarnation: write to a new or previously dead slot = birth.
            # Death-by-overlay: write to a live slot starts a new incarnation
            # after closing the old (PLAN.md §7.3). Track live from birth to
            # next birth-or-end.
            live = set(u["live_by_cyc"].get(cyc - 1, set()))
            if we:
                live.add(tile)
                u["birth"][tile] = cyc
            live.add(tile)  # access implies the slot is in the reference set
            u["live_by_cyc"][cyc] = set(live)
            u["last_acc"][tile] = cyc
    # Convert sets; compute M_peak only if records exist.
    measured: list[dict[str, Any]] = []
    for key, u in units.items():
        peaks = [len(s) for s in u["live_by_cyc"].values()]
        measured.append(
            {
                "unit": key,
                "seq": u["seq"],
                "ph": u["ph"],
                "ntok": u["ntok"],
                "refs": u["refs"],
                "unique_slots_touched": sorted(u["tiles_touched"]),
                "M_peak_slots_access_union": max(peaks) if peaks else None,
                "note": (
                    "access-union peak from WMTR_REC; idle-live (true lifetime) "
                    "requires filling cycles between birth and death — "
                    "parser reports access-union only, LIMIT vs PLAN L1"
                ),
            }
        )
    return {
        "wmtr_files": [_rel(p) for p in files],
        "n_records": n_rec,
        "units": measured,
    }


def build_inventory() -> dict[str, Any]:
    mem00 = ROOT / "results/A7-NATIVE-GRAPH/MEM-00"
    phys = ROOT / "results/A7-NATIVE-GRAPH/LM06-BRAM-PHYS-AUDIT-00"
    wm00 = ROOT / "results/A7-NATIVE-GRAPH/LM06-WM-00"
    bank = ROOT / "results/A7-NATIVE-GRAPH/LM06-BANK-CONCURRENCY-00"
    trace = ROOT / "results/A7-NATIVE-GRAPH/LM06-WM-TRACE-00"
    q0 = ROOT / "results/A7-NATIVE-V1/LM06_Q0_BRAM/LM06_BRAM_OWNERSHIP.md"
    util_candidates = [
        ROOT / "build/out/a7lm06_utilization_route.rpt",
        ROOT / "results/A7-NATIVE-GRAPH/TINYGPT-SOC/frozen_lm06_utilization_route.rpt",
    ]
    dcp = ROOT / "build/out/a7lm06_post_route.dcp"

    files = [
        _file_rec(trace / "GATE.md", "gate"),
        _file_rec(trace / "PLAN.md", "this_plan"),
        _file_rec(mem00 / "BRAM_OWNERSHIP.md", "mem00_ownership"),
        _file_rec(mem00 / "LM06_BRAM_OWNERSHIP_SOURCE.md", "mem00_source"),
        _file_rec(q0, "q0_ownership"),
        _file_rec(phys / "LOGICAL_BANKS.tsv", "phys_logical_banks"),
        _file_rec(phys / "BRAM_PHYSICAL.tsv", "phys_cells"),
        _file_rec(wm00 / "RESULTS.md", "wm00_results"),
        _file_rec(wm00 / "CLOSEOUT.md", "wm00_closeout"),
        _file_rec(wm00 / "SHA256.txt", "wm00_sha_manifest"),
        _file_rec(bank / "BANK_ACCESS_TRACE_SUMMARY.txt", "bank_summary"),
        _file_rec(bank / "BANK_LIFETIMES.tsv", "bank_lifetimes"),
        _file_rec(bank / "ACCESS_TRACE_SCHEMA.md", "bank_schema"),
        _file_rec(bank / "PHYSICAL_TO_LOGICAL_BANKS.tsv", "core_vs_board"),
        _file_rec(
            ROOT / "rtl/native_graph/memory/a7ng_lm06_wm_act.sv", "wm_act_rtl"
        ),
        _file_rec(
            ROOT / "rtl/native_graph/memory/a7ng_lm06_wm_wbank.sv", "wm_wbank_rtl"
        ),
        _file_rec(
            ROOT / "rtl/native_graph/memory/a7ng_lm06_wm_snap.sv", "wm_snap_rtl"
        ),
        _file_rec(ROOT / "tests/xsim/tb_a7ng_lm06_wm.sv", "wm00_tb"),
        _file_rec(ROOT / "tests/xsim/run_a7ng_lm06_wm.ps1", "wm00_runner"),
        _file_rec(
            ROOT / "results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md",
            "doctrine",
        ),
        _file_rec(
            ROOT / "results/A7-NATIVE-GRAPH/STATUS/VERDICT_lm06_wm_00_BINDING.md",
            "wm00_binding",
        ),
        _file_rec(dcp, "frozen_lm06_dcp"),
    ]
    for u in util_candidates:
        files.append(_file_rec(u, "lm06_util_route"))

    logical = parse_logical_banks(phys / "LOGICAL_BANKS.tsv")
    physical = parse_bram_physical(phys / "BRAM_PHYSICAL.tsv")
    wm00_res = parse_wm00_results(wm00 / "RESULTS.md")
    wm00_logs = parse_wm00_logs(wm00 / "raw")
    sha_man = parse_sha256_manifest(wm00 / "SHA256.txt")
    bank_sum = parse_bank_summary(bank / "BANK_ACCESS_TRACE_SUMMARY.txt")
    bank_lt = parse_bank_lifetimes(bank / "BANK_LIFETIMES.tsv")
    wmtr = parse_wmtr_files(trace)

    m_peak: dict[str, Any] = {
        "status": "MISSING",
        "value_slots": None,
        "value_bits": None,
        "units": [],
        "reason": (
            "No WMTR_REC tile-id lifetime stream on disk. "
            "L0 instantiated u_a=66 is occupancy of the frozen array, not M_peak. "
            "L2 max_live_per_cycle is simultaneous port demand (WM-00 L11). "
            "BANK_LIFETIMES CORE_act M_peak_bits cell is capacity / peak-live UNKNOWN."
        ),
    }
    if wmtr["n_records"] > 0 and wmtr["units"]:
        m_peak = {
            "status": "PARTIAL_ACCESS_UNION",
            "value_slots": None,
            "value_bits": None,
            "units": wmtr["units"],
            "reason": (
                "WMTR_REC present but parser reports access-union peak only; "
                "true idle-inclusive lifetime still LIMIT vs PLAN L1."
            ),
        }

    missing = [
        "tile-id WMTR_REC journal (PLAN.md §7.2)",
        "per-UNIT M_peak_slots including idle-live",
        "MRC(C) / reuse-distance histogram",
        "EVAL vs TRAIN live-set table",
        "ntok scaling of M_peak (seq 0 vs seq 8)",
        "overlay last-read vs ah/ay write",
        "A7NG_WM_ENFORCE_ACT run (WM-00 L5 NOT RUN)",
    ]
    if not wm00_logs["logs_present"]:
        missing.append(
            "LM06-WM-00/raw/xsim_*.log on disk (listed in SHA256.txt; RESULTS.md is the surviving extract)"
        )

    do_not = [
        "max_live_per_cycle",
        "pp_swaps",
        "live_pair_events",
        "act_diff_addr",
        "busy_cycles as N",
        "LOGICAL_BANKS physical_tiles as M_peak",
        "BANK_LIFETIMES M_peak_bits capacity cell",
        "INTEGRATE 130-tile cut proposal",
    ]

    return {
        "gate": GATE,
        "one_unknown": ONE_UNKNOWN,
        "evidence_class": "TRACE / POST_ROUTE_PROXY",
        "board": False,
        "ladder_opened": False,
        "m_peak_u_a": m_peak,
        "files": files,
        "extracted": {
            "logical_banks": logical,
            "bram_physical": physical,
            "wm00_results": wm00_res,
            "wm00_logs": {
                "logs_present": wm00_logs["logs_present"],
                "n_logs": len(wm00_logs["by_tag"]),
                "by_tag": wm00_logs["by_tag"],
            },
            "wm00_sha_manifest_logs": sha_man,
            "bank_access_summary": bank_sum,
            "bank_lifetimes": bank_lt,
            "wmtr": {
                "n_records": wmtr["n_records"],
                "files": wmtr["wmtr_files"],
            },
        },
        "missing_for_unknown": missing,
        "do_not_treat_as_m_peak": do_not,
        "next": (
            "research-only WMTR_REC for UNIT in "
            "{(0,EVAL),(0,TRAIN),(8,EVAL),(8,TRAIN)}; not lm06_wm_ladder"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--out",
        default=str(
            ROOT / "results/A7-NATIVE-GRAPH/LM06-WM-TRACE-00/INVENTORY.json"
        ),
        help="JSON inventory path",
    )
    args = ap.parse_args()
    inv = build_inventory()
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(inv, indent=2) + "\n", encoding="utf-8")
    mp = inv["m_peak_u_a"]
    print(f"gate={inv['gate']}")
    print(f"m_peak_u_a.status={mp['status']}")
    print(f"files_exist={sum(1 for f in inv['files'] if f['exists'])}/{len(inv['files'])}")
    lb = inv["extracted"]["logical_banks"]
    if lb:
        print(
            f"L0_tiles u_a={lb['u_a_tiles']} u_w={lb['u_w_tiles']} "
            f"u_snap={lb['u_snap_tiles']} sum={lb['sum_named']}"
        )
    ua = (inv["extracted"]["wm00_results"] or {}).get("u_a") or {}
    if ua:
        print(
            f"L2_u_a pp_swaps={ua.get('pp_swaps')} "
            f"max_live_per_cycle={ua.get('max_live_per_cycle')} (NOT M_peak)"
        )
    print(f"wrote={_rel(out)}")
    print("NEXT=WMTR_REC research TB; NOT lm06_wm_ladder")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
