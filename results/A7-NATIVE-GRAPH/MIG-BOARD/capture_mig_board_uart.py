# capture_mig_board_uart.py — parse BOARD_MIG_SWEEP_ROW CSV from Arty UART (COM12)
# Host derives stall_frac from integer pe_stall/pe_busy — does NOT invent GB/s.
import argparse
import hashlib
import json
import re
import sys
import time
from pathlib import Path

try:
    import serial
except ImportError:
    print("NEED: pip install pyserial", file=sys.stderr)
    sys.exit(2)

ROW_RE = re.compile(
    r"^BOARD_MIG_SWEEP_ROW,(\d+),(\d+),([0-9A-Fa-f]+),([0-9A-Fa-f]+),([0-9A-Fa-f]+),"
    r"([0-9A-Fa-f]+),([0-9A-Fa-f]+),([0-9A-Fa-f]+),([0-9A-Fa-f]+)\s*$"
)
MARK = "A7NG_MIG_BOARD_ROW_OK"


def stall_frac(pe_st: int, pe_bs: int) -> float:
    den = pe_st + pe_bs
    return 0.0 if den == 0 else pe_st / den


def recs_per_cyc(cons: int, cyc: int) -> float:
    return 0.0 if cyc == 0 else cons / cyc


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--seconds", type=float, default=90.0)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    raw_path = out.with_suffix(".uart.txt")

    ser = serial.Serial(args.port, args.baud, timeout=0.2)
    t0 = time.time()
    buf = ""
    lines: list[str] = []
    rows = []
    got_mark = False

    while time.time() - t0 < args.seconds:
        chunk = ser.read(256)
        if chunk:
            text = chunk.decode("ascii", errors="replace")
            buf += text
            while "\n" in buf:
                line, buf = buf.split("\n", 1)
                line = line.strip("\r")
                lines.append(line)
                m = ROW_RE.match(line)
                if m:
                    burst, outst = int(m.group(1)), int(m.group(2))
                    vals = [int(m.group(i), 16) for i in range(3, 10)]
                    pe_st, pe_bs, cyc, cons, drop, rdb, br = vals
                    rows.append(
                        {
                            "burst": burst,
                            "out": outst,
                            "stall_frac": stall_frac(pe_st, pe_bs),
                            "recs_per_cyc": recs_per_cyc(cons, cyc),
                            "pe_stall": pe_st,
                            "pe_busy": pe_bs,
                            "cycles": cyc,
                            "cons": cons,
                            "drop": drop,
                            "ddr_rd_bytes": rdb,
                            "ddr_bursts": br,
                        }
                    )
                if MARK in line:
                    got_mark = True
        if got_mark and len(rows) >= 1:
            break

    ser.close()
    raw_path.write_text("\n".join(lines) + ("\n" + buf if buf else ""), encoding="utf-8")

    payload = {
        "port": args.port,
        "marker": got_mark,
        "rows": rows,
        "raw": str(raw_path).replace("\\", "/"),
        "evidence_class": "BOARD_MIG",
        "invent_gbs": False,
        "board_pass_native_v1": False,
        "hs02": False,
    }
    out.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(json.dumps({"rows": len(rows), "marker": got_mark, "out": str(out)}, indent=2))
    return 0 if (got_mark and len(rows) >= 1) else 1


if __name__ == "__main__":
    sys.exit(main())
