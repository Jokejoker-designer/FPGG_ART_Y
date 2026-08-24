"""AFTER / FREEZE: require FPGA weight writes = 0. Board path is A7-LM-00 later."""
from __future__ import annotations

import argparse
import json
import sys


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", required=True)
    ap.add_argument("--generate-tokens", type=int, default=1000)
    ap.add_argument("--require-weight-writes", type=int, default=0)
    args = ap.parse_args()
    print(
        json.dumps(
            {
                "status": "NOT_WIRED",
                "port": args.port,
                "reason": "A7-LM-00 Arty UART / wr counters not ported yet",
                "require_weight_writes": args.require_weight_writes,
            },
            indent=2,
        )
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
