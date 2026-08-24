"""Report sequential read/write/mixed GB/s from last BIST counters. ui_clk=83.333 MHz."""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from python.uart_stream import FrameStream
from tools.ddr_bist import counters, status
import serial

port = serial.Serial(sys.argv[1] if len(sys.argv) > 1 else "COM12", 115200, timeout=0.05)
time.sleep(0.2)
stream = FrameStream(port)
st = status(port, stream)
cnt = counters(port, stream)
out = {
    "status": st,
    "counters": cnt,
    "min_release_gbps": 0.85,
    "hit": bool(cnt and cnt["rd_gbps"] >= 0.85),
}
print(json.dumps(out, indent=2))
port.close()
