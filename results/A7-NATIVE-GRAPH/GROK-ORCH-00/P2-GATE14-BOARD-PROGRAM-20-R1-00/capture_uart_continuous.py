#!/usr/bin/env python3
"""Arm COM12 BEFORE program. Continuous capture. DTR/RTS off. Flush stale RX.
Stay open across program. Stop on max-seconds or STOP.txt. Never programs.
"""
from __future__ import annotations
import argparse, hashlib, sys, time
from datetime import datetime, timezone, timedelta
from pathlib import Path

TZ = timezone(timedelta(hours=7))
HERE = Path(__file__).resolve().parent
BIT = Path(
    r"D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\results\A7-NATIVE-GRAPH\GROK-ORCH-00\P2-WDMA-RELEASE-CDC-AUDIT-03\arty_a7_ng_native_v1_grok_orch_p2_wdma_release_cdc_audit_03.bit"
)
WANT = "6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A"


def open_com(port, baud):
    import serial
    ser = serial.Serial()
    ser.port = port
    ser.baudrate = baud
    ser.timeout = 0.25
    ser.dtr = False
    ser.rts = False
    ser.open()
    ser.dtr = False
    ser.rts = False
    return ser


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--max-seconds", type=float, default=480.0)
    ap.add_argument("--pnp", default="")
    args = ap.parse_args()
    if args.port != "COM12":
        print("REFUSE port", args.port, file=sys.stderr)
        return 3
    h = hashlib.sha256(BIT.read_bytes()).hexdigest().upper()
    if h != WANT:
        print("REFUSE SHA", h, file=sys.stderr)
        return 3
    raw_path = HERE / "uart_raw.bin"
    txt_path = HERE / "uart_raw.txt"
    stop_path = HERE / "STOP.txt"
    alive_path = HERE / "LISTENER_ALIVE.txt"
    ser = open_com(args.port, args.baud)
    stale = b""
    try:
        ser.reset_input_buffer()
        time.sleep(0.05)
        stale = ser.read(4096) or b""
    except Exception:
        stale = b""
    (HERE / "uart_stale_flush.bin").write_bytes(stale)
    started = datetime.now(TZ).isoformat(timespec="seconds")
    (HERE / "LISTEN_START.txt").write_text(
        "gate=P2-GATE14-BOARD-PROGRAM-20-R1-00\n"
        "mode=ARMED_BEFORE_PROGRAM_CONTINUOUS\n"
        f"port={args.port}\n"
        f"baud={args.baud}\n"
        "dtr=0\nrts=0\n"
        f"pnp={args.pnp}\n"
        f"bit_sha256={h}\n"
        f"stale_flush_bytes={len(stale)}\n"
        f"started_local={started}\n"
        "accept_pred=249\n"
        "historical_664=observe_not_accept\n"
        "TEACHER_OFF=not_claimed\n"
        "BOARD_PASS=not_claimed\n"
        "GATE14_PASS=not_claimed\n",
        encoding="utf-8",
    )
    alive_path.write_text(f"alive=1 pid_start={started}\n", encoding="utf-8")
    print("GATE14_LISTEN ARMED", flush=True)
    t0 = time.monotonic()
    n = 0
    raw_f = open(raw_path, "wb")
    try:
        while True:
            alive_path.write_text(
                f"alive=1 bytes={n} t={time.monotonic()-t0:.1f}\n", encoding="utf-8"
            )
            if stop_path.exists():
                print("\nSTOP_FILE", flush=True)
                break
            chunk = ser.read(256)
            if chunk:
                n += len(chunk)
                raw_f.write(chunk)
                raw_f.flush()
                sys.stdout.write(chunk.decode("ascii", errors="replace"))
                sys.stdout.flush()
            if time.monotonic() - t0 >= args.max_seconds:
                print("\nMAX_SECONDS", flush=True)
                break
    finally:
        ser.close()
        raw_f.close()
    data = raw_path.read_bytes() if raw_path.exists() else b""
    txt_path.write_text(data.decode("ascii", errors="replace"), encoding="utf-8")
    print(f"\nCAPTURE_DONE bytes={len(data)}", flush=True)
    print("TEACHER_OFF: not_claimed", flush=True)
    print("BOARD_PASS: not_claimed", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
