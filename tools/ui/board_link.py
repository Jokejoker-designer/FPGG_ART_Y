"""Serial transport for the A7-EAM-03E-A0 bitstream.

Frame law (``rtl/eam/eam03e_uart.sv``)::

    host -> FPGA :  A5 | cmd | len | payload[len] | xor(all previous)
    FPGA -> host :  5A | kind | ... 20 bytes total ... | xor(bytes 0..18)

The host may only ever send UTF-8 bytes, a SAME/DIFF label, a seed, and the
learn/freeze flags. It must never send a hash, a gradient, a weight, an address
or a winner — see ``docs/contracts/A7-EAM-03E-A.md``. :func:`pack` enforces the
same forbidden-substring guard as ``tools/a7eam03e_a0_silicon.py``.
"""
from __future__ import annotations

import time

try:
    import serial  # type: ignore
except ImportError:  # pragma: no cover - reported through the UI instead
    serial = None

MAGIC_TX = 0xA5
MAGIC_RX = 0x5A
RLEN = 20
MAXP = 48
TMAX = 46
DEFAULT_BAUD = 115200

CMD_PING = 0x01
CMD_RESEED_DEFAULT = 0x04
CMD_TEACHER_OFF = 0x13
CMD_MODE = 0x20
CMD_SEED = 0x21
CMD_BUF = 0x22
CMD_PAIR = 0x23
CMD_ENC = 0x24
CMD_IO = 0x2F        # only on arty_a7_eam03e_io.bit (UI support build)

KIND_PONG = 0x81
KIND_ACK = 0x83
KIND_BUF = 0x82
KIND_ERR = 0x8E
KIND_FREEZE = 0x93
KIND_PAIR = 0xA3
KIND_ENC = 0xA4
KIND_IO = 0xAF

IDENT_A0 = b"3A0"
FORBIDDEN = (b"WAY", b"BRAM", b"GRAD")


class BoardError(RuntimeError):
    pass


def xor_bytes(data: bytes) -> int:
    x = 0
    for b in data:
        x ^= b
    return x


def pack(cmd: int, payload: bytes = b"") -> bytes:
    if len(payload) > MAXP:
        raise ValueError(f"payload {len(payload)} > MAXP {MAXP}")
    for bad in FORBIDDEN:
        if bad in payload:
            raise ValueError(f"forbidden field {bad!r} in payload")
    head = bytes([MAGIC_TX, cmd & 0xFF, len(payload)]) + payload
    return head + bytes([xor_bytes(head)])


def parse(rep: bytes) -> dict:
    if len(rep) != RLEN:
        raise BoardError(f"short reply {len(rep)}B: {rep.hex()}")
    if rep[0] != MAGIC_RX:
        raise BoardError(f"bad magic {rep.hex()}")
    if xor_bytes(rep[:19]) != rep[19]:
        raise BoardError(f"bad xor {rep.hex()}")
    return {
        "kind": rep[1],
        "flags": rep[2],
        "learn": bool(rep[2] & 0x01),
        "freeze": bool(rep[2] & 0x02),
        "updated": bool(rep[2] & 0x04),
        "dH": rep[3] & 0x7F,
        "d1": int.from_bytes(rep[4:6], "little"),
        "cue": int.from_bytes(rep[6:14], "little"),
        "nA": rep[14],
        "nB": rep[15],
        "seed_lo": rep[16],
        "raw": rep.hex(),
    }


def parse_io(rep: bytes) -> dict:
    """``CMD 0x2F`` reply from the UI-support build. Not on the A0.1-T bit."""
    base = parse(rep)
    if base["kind"] != KIND_IO:
        raise BoardError(f"not an IO reply: kind 0x{base['kind']:02X}")
    return {
        "sw": [(rep[3] >> i) & 1 for i in range(4)],
        "btn": [(rep[4] >> i) & 1 for i in range(4)],
        "led": [(rep[5] >> i) & 1 for i in range(4)],
        "btn_sticky": [(rep[6] >> i) & 1 for i in range(4)],
        "sw_changes": rep[7],
        "raw": base["raw"],
    }


def list_ports() -> list[dict]:
    if serial is None:
        return []
    try:
        from serial.tools import list_ports as lp  # type: ignore
    except ImportError:
        return []
    return [{"device": p.device, "description": p.description or "",
             "hwid": p.hwid or ""} for p in lp.comports()]


class BoardLink:
    """Stop-and-wait link. One transaction at a time; the caller holds the lock."""

    def __init__(self, port: str, baud: int = DEFAULT_BAUD,
                 timeout: float = 0.35) -> None:
        if serial is None:
            raise BoardError("pyserial is not installed: pip install pyserial")
        self.port_name = port
        self.baud = baud
        self.timeout = timeout
        self.ser = serial.Serial(port, baud, timeout=timeout, write_timeout=2.0)
        self.ident: bytes | None = None
        self.has_io = False
        self.xfers = 0
        self.errors = 0

    def close(self) -> None:
        try:
            self.ser.close()
        except Exception:
            pass

    # ------------------------------------------------------------------ wire

    def xfer(self, cmd: int, payload: bytes = b"", wait: float = 1.5) -> dict:
        frame = pack(cmd, payload)
        self.ser.reset_input_buffer()
        self.ser.write(frame)
        self.ser.flush()
        deadline = time.time() + wait
        buf = bytearray()
        while len(buf) < RLEN and time.time() < deadline:
            chunk = self.ser.read(RLEN - len(buf))
            if chunk:
                buf.extend(chunk)
        self.xfers += 1
        if len(buf) < RLEN:
            self.errors += 1
            raise BoardError(
                f"timeout on cmd 0x{cmd:02X}: got {len(buf)}/{RLEN}B "
                f"({bytes(buf).hex() or 'nothing'})")
        rep = parse(bytes(buf))
        if rep["kind"] == KIND_ERR:
            self.errors += 1
            raise BoardError(f"FPGA rejected cmd 0x{cmd:02X} (kind 0x8E, busy or bad xor)")
        return rep

    def xfer_retry(self, cmd: int, payload: bytes = b"", tries: int = 3) -> dict:
        last: Exception | None = None
        for attempt in range(tries):
            try:
                return self.xfer(cmd, payload)
            except BoardError as exc:
                last = exc
                time.sleep(0.02 * (attempt + 1))
        raise last if last else BoardError("xfer failed")

    # -------------------------------------------------------------- commands

    def ping(self) -> dict:
        """PING. Bytes 3..5 of the reply carry the build identity, not dH."""
        rep = self.xfer(CMD_PING)
        raw = bytes.fromhex(rep["raw"])
        self.ident = raw[3:6]
        rep["ident"] = self.ident.decode("ascii", errors="replace")
        rep["ident_ok"] = self.ident == IDENT_A0
        return rep

    def probe_io(self) -> bool:
        """Does this build answer CMD 0x2F? Sets :attr:`has_io`."""
        try:
            rep = self.xfer(CMD_IO)
            self.has_io = rep["kind"] == KIND_IO
        except BoardError:
            self.has_io = False
        return self.has_io

    def io_status(self) -> dict:
        raw = bytes.fromhex(self.xfer(CMD_IO)["raw"])
        return parse_io(raw)

    def reseed(self, seed: int) -> dict:
        seed &= 0xFFFFFFFF
        return self.xfer(CMD_SEED, seed.to_bytes(4, "little"))

    def set_mode(self, learn: bool, freeze: bool) -> dict:
        return self.xfer(CMD_MODE, bytes([(1 if learn else 0) | (2 if freeze else 0)]))

    def teacher_off(self) -> dict:
        return self.xfer(CMD_TEACHER_OFF)

    def buf(self, slot: int, data: bytes | str) -> dict:
        if isinstance(data, str):
            data = data.encode("utf-8")
        data = data[:TMAX]
        if len(data) < 2:
            raise ValueError("FPGA rejects a sequence shorter than 2 bytes")
        return self.xfer_retry(CMD_BUF, bytes([slot & 1, len(data)]) + data)

    def pair(self, same: bool) -> dict:
        return self.xfer_retry(CMD_PAIR, bytes([1 if same else 0]))

    def enc(self, slot: int) -> dict:
        return self.xfer_retry(CMD_ENC, bytes([slot & 1]))

    def measure(self, text_a: str, text_b: str, same: bool) -> dict:
        self.buf(0, text_a)
        self.buf(1, text_b)
        return self.pair(same)
