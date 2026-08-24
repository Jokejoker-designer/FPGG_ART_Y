"""15-byte UART helpers for A5 5A/5C/5D/5E/5F."""
from __future__ import annotations

FRAME_LEN = 15


def xor14(payload: bytes) -> int:
    chk = 0
    for b in payload[:14]:
        chk ^= b
    return chk & 0xFF


def pack15(kind: int, body12: bytes) -> bytes:
    if len(body12) != 12:
        raise ValueError("body must be 12 bytes")
    head = bytes([0xA5, kind]) + body12
    return head + bytes([xor14(head)])


def session_frame(seed: int, perm: tuple[int, ...] | list[int]) -> bytes:
    body = seed.to_bytes(4, "little") + bytes(perm)
    return pack15(0x5E, body)


def command_frame(cmd: int) -> bytes:
    return pack15(0x5F, bytes([cmd]) + bytes(11))


def dense_sample_frame(stim: int, teacher: int, lr: int = 8) -> bytes:
    return pack15(0x60, bytes([stim & 0xFF, teacher & 0xFF, lr & 0xFF]) + bytes(9))


def temporal_sample_frame(a: int, b: int, c: int, x: int, hold: int = 0) -> bytes:
    return pack15(0x62, bytes([a & 0xFF, b & 0xFF, c & 0xFF, x & 0xFF, hold & 1]) + bytes(7))


def temporal_probe_frame(n: int, s0: int, s1: int, s2: int = 0, hold: int = 0) -> bytes:
    return pack15(0x63, bytes([n & 0xFF, s0 & 0xFF, s1 & 0xFF, s2 & 0xFF, hold & 1]) + bytes(7))


def phrase_sample_frame(
    tokens: tuple[int, int, int] | list[int], basin: int, hold: int = 0
) -> bytes:
    s0, s1, s2 = tokens
    return temporal_sample_frame(s0, s1, s2, basin, hold)


def phrase_probe_frame(tokens: tuple[int, int, int] | list[int], hold: int = 0) -> bytes:
    s0, s1, s2 = tokens
    return temporal_probe_frame(3, s0, s1, s2, hold)


def token_pair_frame(src: int, dst: int) -> bytes:
    return pack15(0x67, bytes([src & 7, dst & 7]) + bytes(10))


def token_gen_frame(start: int, max_len: int = 8, eos: int = 6) -> bytes:
    return pack15(0x65, bytes([start & 7, max_len & 0xFF, eos & 7]) + bytes(9))


def lm02_write_frame(bank: int, addr: int, data: bytes) -> bytes:
    chunk = bytes(data)
    if not 1 <= len(chunk) <= 8:
        raise ValueError("data 1..8")
    body = bytes([bank & 3, addr & 0xFF, (addr >> 8) & 1, len(chunk)]) + chunk + bytes(8 - len(chunk))
    return pack15(0x70, body)


def lm03_write_frame(bank: int, addr: int, data: bytes) -> bytes:
    chunk = bytes(data)
    if not 1 <= len(chunk) <= 8:
        raise ValueError("data 1..8")
    body = bytes([bank & 15, addr & 0xFF, (addr >> 8) & 15, len(chunk)]) + chunk + bytes(8 - len(chunk))
    return pack15(0x70, body)


def lm02_ctx_frame(tokens: list[int]) -> bytes:
    n = min(8, len(tokens))
    pad = [t & 31 for t in tokens[:n]] + [0] * (8 - n)
    return pack15(0x71, bytes([n] + pad + [0, 0, 0]))


def lm02_cmd_frame(op: int, a: int = 0, b: int = 0) -> bytes:
    return pack15(0x72, bytes([op & 0xFF, a & 0xFF, b & 0xFF]) + bytes(9))


def lm03_payload_frame(payload12: bytes) -> bytes:
    body = bytes(payload12)
    if len(body) != 12:
        raise ValueError("payload12")
    return pack15(0x73, body)


def lm04_payload_frame(payload12: bytes) -> bytes:
    body = bytes(payload12)
    if len(body) != 12:
        raise ValueError("payload12")
    return pack15(0x84, body)


def lm04_write_frame(addr: int, data: bytes) -> bytes:
    chunk = bytes(data)
    if not 1 <= len(chunk) <= 8:
        raise ValueError("data 1..8")
    n = len(chunk) | (((addr >> 16) & 1) << 4)
    body = bytes([0x30, addr & 0xFF, (addr >> 8) & 0xFF, n]) + chunk + bytes(8 - len(chunk))
    return pack15(0x84, body)


def lm04_read_frame(addr: int) -> bytes:
    body = bytes([0x31, addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 1]) + bytes(8)
    return pack15(0x84, body)


def lm05_write_frame(addr: int, data: bytes) -> bytes:
    """Write 1..8 bytes to the LM-05 19-bit parameter address space."""
    chunk = bytes(data)
    if not 1 <= len(chunk) <= 8:
        raise ValueError("data 1..8")
    if not 0 <= addr < (1 << 19):
        raise ValueError("LM-05 address must be 19-bit")
    n = len(chunk) | (((addr >> 16) & 0x7) << 4)
    body = bytes([0x30, addr & 0xFF, (addr >> 8) & 0xFF, n]) + chunk + bytes(8 - len(chunk))
    return pack15(0x84, body)


def lm05_read_frame(addr: int) -> bytes:
    """Read eight bytes from the LM-05 19-bit parameter address space."""
    if not 0 <= addr < (1 << 19):
        raise ValueError("LM-05 address must be 19-bit")
    body = bytes([0x31, addr & 0xFF, (addr >> 8) & 0xFF, ((addr >> 16) & 0x7) << 4]) + bytes(8)
    return pack15(0x84, body)


def lm06_write_frame(addr: int, data: bytes) -> bytes:
    """Write 1..8 bytes to the LM-06 20-bit parameter address space."""
    chunk = bytes(data)
    if not 1 <= len(chunk) <= 8:
        raise ValueError("data 1..8")
    if not 0 <= addr < (1 << 20):
        raise ValueError("LM-06 address must be 20-bit")
    n = len(chunk) | (((addr >> 16) & 0xF) << 4)
    body = bytes([0x30, addr & 0xFF, (addr >> 8) & 0xFF, n]) + chunk + bytes(8 - len(chunk))
    return pack15(0x84, body)


def lm06_read_frame(addr: int) -> bytes:
    """Read eight bytes from the LM-06 20-bit parameter address space."""
    if not 0 <= addr < (1 << 20):
        raise ValueError("LM-06 address must be 20-bit")
    body = bytes([0x31, addr & 0xFF, (addr >> 8) & 0xFF, ((addr >> 16) & 0xF) << 4]) + bytes(8)
    return pack15(0x84, body)


def lm02_payload_frame(payload12: bytes) -> bytes:
    body = bytes(payload12)
    if len(body) != 12:
        raise ValueError("payload12")
    return pack15(0x72, body)


def parse_frame(frame: bytes) -> dict:
    if len(frame) != FRAME_LEN or frame[0] != 0xA5 or xor14(frame) != frame[14]:
        return {"ok": False}
    kind = frame[1]
    rec: dict = {"ok": True, "kind": kind, "raw": frame}
    if kind == 0x5A:
        rec.update(
            tick=frame[2] | (frame[3] << 8),
            updates=frame[4] | (frame[5] << 8),
            mismatch=frame[6] | (frame[7] << 8),
            weight=int.from_bytes(frame[8:10], "little", signed=True),
            inp=frame[10],
            out=frame[11],
            phase=frame[12] & 0xF,
            flags=frame[13],
        )
    elif kind == 0x5C:
        rec.update(
            before_mis=frame[2] | (frame[3] << 8),
            after_mis=frame[4] | (frame[5] << 8),
            before_hits=frame[6],
            after_hits=frame[7],
            routes=frame[8],
            final=(frame[9] >> 7) & 1,
            freeze=(frame[9] >> 6) & 1,
            phase=frame[9] & 0xF,
        )
    elif kind == 0x5D:
        rec.update(
            snapshot=frame[2],
            seq=frame[3],
            page=frame[4],
            weights=[
                int.from_bytes(frame[5:7], "little", signed=True),
                int.from_bytes(frame[7:9], "little", signed=True),
                int.from_bytes(frame[9:11], "little", signed=True),
                int.from_bytes(frame[11:13], "little", signed=True),
            ],
            phase=frame[13] & 0xF,
        )
    elif kind == 0x5E:
        rec.update(
            seed=int.from_bytes(frame[2:6], "little"),
            perm=list(frame[6:14]),
        )
    elif kind == 0x60:
        rec.update(stim=frame[2], teacher=frame[3], lr=frame[4])
    elif kind == 0x62:
        rec.update(a=frame[2], b=frame[3], c=frame[4], x=frame[5], hold=frame[6] & 1)
    elif kind == 0x63:
        rec.update(n=frame[2], s0=frame[3], s1=frame[4], s2=frame[5], hold=frame[6] & 1)
    elif kind == 0x64:
        rec.update(
            ctx=frame[2],
            out=frame[3],
            target=frame[4],
            match=frame[5] & 1,
            phase=frame[6] & 0xF,
            snapshot=frame[7],
        )
    elif kind == 0x66:
        rec.update(
            step=frame[2],
            pred=frame[3],
            out=frame[4],
            writes=frame[5],
            last=bool(frame[6] & 2),
        )
    elif kind == 0x65:
        rec.update(start=frame[2], max_len=frame[3], eos=frame[4])
    elif kind == 0x67:
        rec.update(src=frame[2], dst=frame[3])
    elif kind == 0x61:
        rec.update(
            stim=frame[2],
            teacher=frame[3],
            changed_cell_count=frame[4],
            learn=frame[5] & 1,
            freeze=(frame[5] >> 1) & 1,
            tick=frame[6] | (frame[7] << 8),
            updates=frame[8] | (frame[9] << 8),
            phase=frame[10] & 0xF,
            flags=frame[11],
            snapshot=frame[12],
        )
    elif kind == 0x74:
        rec.update(
            pred=frame[2] & 31,
            flags=frame[5],
            loss=int.from_bytes(frame[3:5], "little"),
        )
    elif kind == 0x75:
        rec.update(
            idx=frame[2],
            z0=int.from_bytes(frame[3:7], "little", signed=True),
            z1=int.from_bytes(frame[7:11], "little", signed=True),
        )
    elif kind == 0x76:
        rec.update(
            pos=frame[2] & 7,
            page=frame[3] & 3,
            h=[
                int.from_bytes(frame[4:6], "little", signed=True),
                int.from_bytes(frame[6:8], "little", signed=True),
                int.from_bytes(frame[8:10], "little", signed=True),
                int.from_bytes(frame[10:12], "little", signed=True),
            ],
        )
    elif kind == 0x77:
        rec.update(qi=frame[2] & 7, w=list(frame[3:11]))
    elif kind == 0x78:
        rec.update(
            idx=frame[2],
            g=[
                int.from_bytes(frame[3:5], "little", signed=True),
                int.from_bytes(frame[5:7], "little", signed=True),
                int.from_bytes(frame[7:9], "little", signed=True),
                int.from_bytes(frame[9:11], "little", signed=True),
            ],
        )
    elif kind == 0x7A:
        rec.update(
            wr_tok=int.from_bytes(frame[2:4], "little"),
            wr_pos=int.from_bytes(frame[4:6], "little"),
            wr_head=int.from_bytes(frame[6:8], "little"),
            wr_frz=int.from_bytes(frame[8:10], "little"),
            loss=int.from_bytes(frame[10:12], "little"),
        )
    elif kind == 0x79:
        rec.update(
            bank=frame[2] & 3,
            addr=frame[3] | ((frame[4] & 1) << 8),
            data=list(frame[6:14]),
        )
    elif kind == 0x90:
        rec.update(
            t_pass=bool(frame[2] & 0x80),
            t_busy=bool(frame[2] & 0x40),
            calib=bool(frame[2] & 0x20),
            t_done=bool(frame[2] & 0x10),
            phase=frame[3],
            cases=int.from_bytes(frame[4:8], "little"),
        )
    elif kind == 0x91:
        rec.update(
            xor32=int.from_bytes(frame[2:6], "little"),
            add32=int.from_bytes(frame[6:10], "little"),
            macs=int.from_bytes(frame[10:14], "little"),
        )
    elif kind == 0x92:
        rec.update(
            cycles=int.from_bytes(frame[2:6], "little"),
            stalls=int.from_bytes(frame[6:10], "little"),
            hazards=int.from_bytes(frame[10:14], "little"),
        )
    elif kind == 0x93:
        rec.update(psum=int.from_bytes(frame[2:6], "little", signed=True))
    elif kind == 0x94:
        rec.update(
            dma_under=int.from_bytes(frame[2:6], "little"),
            bank_haz=int.from_bytes(frame[6:8], "little"),
            axi_berr=frame[8],
            axi_rerr=frame[9],
            swaps=int.from_bytes(frame[10:12], "little"),
        )
    elif kind == 0x95:
        rec.update(
            overlap_cyc=int.from_bytes(frame[2:6], "little"),
            ntile=int.from_bytes(frame[6:8], "little"),
        )
    elif kind == 0xA0:
        rec.update(
            pred=frame[2] | ((frame[5] & 3) << 8),
            loss=int.from_bytes(frame[3:5], "little"),
        )
    elif kind == 0xA1:
        rec.update(
            after=bool(frame[2] & 0x80),
            busy=bool(frame[2] & 0x40),
            done=bool(frame[2] & 0x20),
            calib=bool(frame[2] & 0x10),
            persist=bool(frame[2] & 0x08),
            phase=frame[3],
            wr_n=int.from_bytes(frame[4:8], "little"),
            pred=frame[8] | ((frame[11] & 3) << 8),
            loss=int.from_bytes(frame[9:11], "little"),
        )
    elif kind == 0xA2:
        rec.update(
            xor32=int.from_bytes(frame[2:6], "little"),
            add32=int.from_bytes(frame[6:10], "little"),
            wr_n=int.from_bytes(frame[10:14], "little"),
        )
    elif kind == 0xA3:
        rec.update(
            ce0=int.from_bytes(frame[2:6], "little"),
            ce1=int.from_bytes(frame[6:10], "little"),
            loss=int.from_bytes(frame[10:12], "little"),
        )
    elif kind == 0xA4:
        rec.update(
            addr=frame[2] | (frame[3] << 8) | ((frame[12] & 0xF) << 16),
            data=list(frame[4:12]),
        )
    elif kind == 0xA6:
        rec.update(
            calib=bool(frame[2] & 0x80),
            persist=bool(frame[2] & 0x40),
            under=bool(frame[2] & 0x20),
            berr=bool(frame[2] & 0x10),
            rerr=bool(frame[2] & 0x08),
            bytes=int.from_bytes(frame[4:8], "little"),
            xor32=int.from_bytes(frame[8:12], "little"),
        )
    elif kind == 0xA8:
        rec.update(dbg=int.from_bytes(frame[2:10], "little"))
    return rec


def matrix_from_pages(pages: dict[int, list[int]]) -> list[list[int]]:
    cells = [0] * 64
    for page, ws in pages.items():
        for i, w in enumerate(ws):
            cells[page * 4 + i] = w
    return [cells[d * 8 : (d + 1) * 8] for d in range(8)]
