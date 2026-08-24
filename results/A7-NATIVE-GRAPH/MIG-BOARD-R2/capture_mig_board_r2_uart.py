# capture_mig_board_r2_uart.py — parse BOARD_MIG_R2_ROW CSV from Arty UART (COM12)
# Host derives stall_frac from integer pe_stall/pe_busy — does NOT invent GB/s.
# RTL prints burst as decimal digits: burst=16 appears as field "10" — normalize to 16.
import argparse
import json
import re
import sys
import time
from pathlib import Path

try:
    import serial
except ImportError:
    serial = None  # offline --from-uart only

ROW_RE = re.compile(
    r"^BOARD_MIG_R2_ROW,(\d+),(\d+),"
    r"([0-9A-Fa-f]+(?:,[0-9A-Fa-f]+){12})\s*$"
)
MARK = "A7NG_MIG_BOARD_R2_OK"
GRID = [(b, o) for b in (1, 4, 8, 16) for o in (1, 2, 4, 8)]


def normalize_burst(raw: int) -> int:
    """RTL UART emits burst=16 as decimal field '10' (tens digit + ones digit)."""
    return 16 if raw == 10 else raw


def stall_frac(pe_st: int, pe_bs: int) -> float:
    den = pe_st + pe_bs
    return 0.0 if den == 0 else pe_st / den


def parse_line(line: str) -> dict | None:
    m = ROW_RE.match(line.strip())
    if not m:
        return None
    burst_raw, outst = int(m.group(1)), int(m.group(2))
    vals = [int(x, 16) for x in m.group(3).split(",")]
    if len(vals) != 13:
        return None
    (
        axi_b,
        axi_br,
        axi_bt,
        data_mm,
        rresp,
        rlast,
        exp,
        rcv,
        cons,
        rid,
        r_bp,
        pe_st,
        pe_bs,
    ) = vals
    burst = normalize_burst(burst_raw)
    return {
        "burst": burst,
        "burst_uart_raw": burst_raw,
        "out": outst,
        "axi_read_bytes": axi_b,
        "axi_read_bursts": axi_br,
        "axi_read_beats": axi_bt,
        "data_mismatch_count": data_mm,
        "rresp_error_count": rresp,
        "rlast_error_count": rlast,
        "expected_records": exp,
        "received_records": rcv,
        "consumed_records": cons,
        "rid_observed": rid,
        "r_backpressure_cycles": r_bp,
        "pe_stall": pe_st,
        "pe_busy": pe_bs,
        "stall_frac": stall_frac(pe_st, pe_bs),
    }


def parse_uart_file(path: Path) -> tuple[list[str], list[dict], bool]:
    lines = [ln.strip("\r") for ln in path.read_text(encoding="utf-8").splitlines() if ln.strip()]
    rows = []
    got_mark = False
    for line in lines:
        row = parse_line(line)
        if row:
            rows.append(row)
        if MARK in line:
            got_mark = True
    return lines, rows, got_mark


def write_payload(out: Path, rows: list[dict], got_mark: bool, raw_path: Path, port: str = "COM12") -> int:
    seen = {(r["burst"], r["out"]) for r in rows}
    missing = [c for c in GRID if c not in seen]
    payload = {
        "port": port,
        "marker": got_mark,
        "rows": rows,
        "grid_complete": len(rows) == 16 and not missing,
        "missing_cells": missing,
        "raw": str(raw_path).replace("\\", "/"),
        "evidence_class": "BOARD_MIG",
        "invent_gbs": False,
        "board_pass_native_v1": False,
        "hs02": False,
    }
    out.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(json.dumps({"rows": len(rows), "marker": got_mark, "missing": missing, "grid_complete": payload["grid_complete"], "out": str(out)}, indent=2))
    return 0 if (got_mark and len(rows) >= 16 and not missing) else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--seconds", type=float, default=300.0)
    ap.add_argument("--out", required=True)
    ap.add_argument("--from-uart", help="Parse existing .uart.txt (no serial / no board)")
    args = ap.parse_args()

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    raw_path = Path(args.from_uart) if args.from_uart else out.with_suffix(".uart.txt")

    if args.from_uart:
        _, rows, got_mark = parse_uart_file(raw_path)
        return write_payload(out, rows, got_mark, raw_path)

    if serial is None:
        print("NEED: pip install pyserial", file=sys.stderr)
        return 2

    ser = serial.Serial(args.port, args.baud, timeout=0.2)
    t0 = time.time()
    buf = ""
    lines: list[str] = []
    rows = []
    got_mark = False

    while time.time() - t0 < args.seconds:
        chunk = ser.read(512)
        if chunk:
            text = chunk.decode("ascii", errors="replace")
            buf += text
            while "\n" in buf:
                line, buf = buf.split("\n", 1)
                line = line.strip("\r")
                if line:
                    lines.append(line)
                row = parse_line(line)
                if row:
                    rows.append(row)
                if MARK in line:
                    got_mark = True
        if got_mark and len(rows) >= 16:
            break

    ser.close()
    raw_path.write_text("\n".join(lines) + ("\n" + buf if buf else ""), encoding="utf-8")
    return write_payload(out, rows, got_mark, raw_path, port=args.port)


if __name__ == "__main__":
    sys.exit(main())
