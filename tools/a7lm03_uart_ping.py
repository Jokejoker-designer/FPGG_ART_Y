"""Raw UART ping for A7-LM-03. Prints hex; does not interpret CE/pred/updates."""
from __future__ import annotations

import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from python.uart_frames import lm03_payload_frame, parse_frame
from python.uart_stream import FrameStream
import serial


def ping(port_name: str, baud: int, settle: float = 0.4) -> dict:
    frame = lm03_payload_frame(bytes([0x35]) + bytes(11))
    rec: dict = {"port": port_name, "baud": baud, "tx": frame.hex()}
    try:
        port = serial.Serial(port_name, baud, timeout=0.05)
    except Exception as exc:
        rec["open"] = False
        rec["error"] = str(exc)
        return rec
    rec["open"] = True
    time.sleep(settle)
    port.reset_input_buffer()
    port.reset_output_buffer()
    port.write(frame)
    port.flush()
    time.sleep(0.25)
    raw = port.read(64)
    rec["n"] = len(raw)
    rec["rx_hex"] = raw.hex()
    stream = FrameStream(port)
    stream.feed(raw)
    rec["bytes_rx"] = stream.bytes_rx
    rec["good"] = stream.good_frames
    rec["bad_crc"] = stream.bad_crc
    rec["resync"] = stream.resync_bytes
    rec["frames"] = []
    while stream.frames:
        fr = stream.frames.popleft()
        rec["frames"].append({"hex": fr.data.hex(), "parse": parse_frame(fr.data)})
    # second ping after extra settle
    port.write(frame)
    port.flush()
    time.sleep(0.25)
    raw2 = port.read(64)
    rec["n2"] = len(raw2)
    rec["rx_hex2"] = raw2.hex()
    port.close()
    return rec


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    bauds = [int(x) for x in sys.argv[2].split(",")] if len(sys.argv) > 2 else [115200, 230400, 57600]
    out = [ping(port_name, b) for b in bauds]
    import json

    print(json.dumps(out, indent=2))
    return 0 if any(r.get("n", 0) or r.get("n2", 0) for r in out) else 3


if __name__ == "__main__":
    raise SystemExit(main())
