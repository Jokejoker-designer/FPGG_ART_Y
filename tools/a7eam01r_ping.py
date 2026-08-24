"""01R UART PING smoke. Host sends A5 01 00 xor only. Expects 5A 81 ... 'R1R'."""
from __future__ import annotations

import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import serial  # noqa: E402

PORT = "COM12"
BAUD = 115200
RLEN = 20


def xor_bytes(data: bytes) -> int:
    x = 0
    for b in data:
        x ^= b
    return x & 0xFF


def main() -> int:
    pkt = bytes([0xA5, 0x01, 0x00])
    pkt += bytes([xor_bytes(pkt)])
    ser = serial.Serial(PORT, BAUD, timeout=2.0)
    try:
        ser.reset_input_buffer()
        ser.write(pkt)
        ser.flush()
        time.sleep(0.05)
        rep = ser.read(RLEN)
    finally:
        ser.close()
    print("TX", pkt.hex())
    print("RX", rep.hex() if rep else "<empty>")
    if len(rep) != RLEN or rep[0] != 0x5A or xor_bytes(rep[:19]) != rep[19]:
        print("A7EAM01R_PING_FAIL frame")
        return 2
    if rep[1] != 0x81 or rep[3:6] != b"R1R":
        print("A7EAM01R_PING_FAIL ident", rep[1:6].hex())
        return 3
    print("A7EAM01R_PING_PASS kind=81 R1R")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
