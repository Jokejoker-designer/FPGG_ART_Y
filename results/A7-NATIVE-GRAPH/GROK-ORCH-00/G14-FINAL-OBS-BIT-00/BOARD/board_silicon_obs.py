#!/usr/bin/env python3
"""G14-EPOCH-REBIRTH-BIT-00 silicon. Arm COM12, program 1F0F2ABB once, E0-E5.
Do not reprogram. Do not retarget oracle. GATE14_PASS stays NO.
Stop at first divergence. Same command gaps as BIT-07 exam.
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import threading
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
BAG = HERE.parent
REPO = BAG
while not (REPO / "python" / "gate14_uart.py").is_file():
    if REPO.parent == REPO:
        raise SystemExit("REFUSE cannot find python/gate14_uart.py")
    REPO = REPO.parent
sys.path.insert(0, str(REPO))
from python.gate14_uart import (  # noqa: E402
    CMD_BRAM_KILL,
    CMD_EXAM_QUERY,
    CMD_FLUSH,
    CMD_FREEZE,
    CMD_QUERY_COMMIT,
    CMD_QUERY_TOKEN,
    CMD_RELOAD,
    CMD_TRAIN_BEGIN,
    CMD_TRAIN_RESET,
    CMD_STATUS,
    c0_id,
    c1_mode,
    c5_fields,
    c6_txn,
    c7_fields,
    c8_fields,
    c9_fields,
    c10_fields,
    c11_fields,
    c12_fields,
    decode_cframe,
    frame,
    reward_frame,
)

WANT = "F24150BDE6F69080B3C5865386C49F6F02300782FFB4037FAF044BB2099840F7"
REFUSE = {
    "3A7EF2044CD92730F048032ABF9E9CC914461EE7CE767745089CD082CC31A00B",
    "7ECCA0E21BF27DD13451F3EFB4F180A7B15627B610D81BECAE07CA9FFA12E219",
    "A0B338E0AF8836056574913B40106D2DA4DE388686067E7EDEF4D009D57F7E2B",
    "B0F64E6C37F6BDB428FAB18CD6EEDD191C389AC3EE9FFB4D23B641B5D289A0A1",
    "1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9",
    "9CA2B30DCCD8A7AA2F348C3C4E2BDFCDAF9A9A67CBE0956EB0A8EBB532BADC80",
}
BIT = BAG / "arty_a7_ng_native_v1_g14_final_obs_00.bit"
C0_WANT = bytes([0x34, 0x31, 0x43, 0x47, 0xC0, 0x01, 0x14, 0xA7])
N_A = N_B = 20
T_HOLD_A, T_UNREL, T_CONTRA, T_HOLD_B = 0xA2, 0xA3, 0xA4, 0xB2
ORACLE = {
    "HOLD_A": {"out": 653, "pack": 0x8382238122802120},
    "UNREL": {"out": 689, "pack": 0x8786858483828180},
    "CONTRA": {"out": 237, "pack": 0x2322832182208180},
    "HOLD_B": {"out": 60, "pack": 0x8382438142804140},
}
WRAP_LIMIT = 6
TZ = timezone(timedelta(hours=7))
REW = 3
VIVADO = r"C:\2026.1\Vivado\bin\vivado.bat"


def gen_legal(g) -> bool:
    if g is None:
        return False
    g = int(g)
    if g in (0, 0xFFFFFFFF):
        return False
    return 1 <= g <= WRAP_LIMIT


class Divergence(Exception):
    def __init__(self, why: str, row: dict | None = None, ckpt: str = "") -> None:
        super().__init__(why)
        self.why = why
        self.row = row or {}
        self.ckpt = ckpt


class Cap:
    def __init__(self, ser) -> None:
        self.ser = ser
        self.buf = bytearray()
        self.lock = threading.Lock()
        self.stop = threading.Event()
        self.th = threading.Thread(target=self._run, daemon=True)

    def _run(self) -> None:
        while not self.stop.is_set():
            chunk = self.ser.read(256)
            if chunk:
                with self.lock:
                    self.buf.extend(chunk)

    def start(self) -> None:
        self.th.start()

    def snap(self) -> bytes:
        with self.lock:
            return bytes(self.buf)


def latest(frames, ckpt):
    hits = [f for f in frames if f["ckpt"] == ckpt]
    return hits[-1] if hits else None


def hx(v) -> str:
    if v is None:
        return "None"
    return format(int(v), "X")


def main() -> int:
    import serial

    h = hashlib.sha256(BIT.read_bytes()).hexdigest().upper()
    if h != WANT:
        print("REFUSE SHA %s want %s" % (h, WANT), file=sys.stderr)
        return 3
    if h in REFUSE:
        print("REFUSE frozen/rejected SHA", file=sys.stderr)
        return 3
    lock = HERE / "PROGRAMMED_ONCE.txt"
    if lock.is_file():
        print("REFUSE already programmed once", file=sys.stderr)
        return 3

    utc = datetime.now(timezone.utc).isoformat(timespec="seconds")
    local = datetime.now(TZ).isoformat(timespec="seconds")

    ser = serial.Serial()
    ser.port, ser.baudrate, ser.timeout = "COM12", 115200, 0.2
    ser.dtr = False
    ser.rts = False
    try:
        ser.open()
    except Exception as e:
        print("WAIT_COM12 or COM12_BUSY %s" % e, file=sys.stderr)
        return 12
    ser.dtr = False
    ser.rts = False
    cap = Cap(ser)
    cap.start()
    (HERE / "LISTEN_START.txt").write_text(
        "gate=G14-EPOCH-REBIRTH-BIT-00\n"
        "mode=ARMED_BEFORE_PROGRAM\n"
        "port=COM12\n"
        "baud=115200\n"
        "bit_path=%s\n" % BIT
        + "bit_sha256=%s\n" % h
        + "started_utc=%s\n" % utc
        + "started_local=%s\n" % local
        + "PROGRAM=ONCE\nGATE14_PASS=NO\nBOARD_PASS=not_claimed\n",
        encoding="utf-8",
    )
    print("LISTEN ARMED COM12 BEFORE PROGRAM sha=%s utc=%s" % (h, utc), flush=True)

    env = os.environ.copy()
    env["XILINXD_LICENSE_FILE"] = r"D:\Xilinx\licenses\vivado_basic.lic"
    cmd = [VIVADO, "-mode", "batch", "-notrace", "-source", str(HERE / "program_once_excl.tcl")]
    print("PROGRAM_START", flush=True)
    pr = subprocess.run(cmd, cwd=str(HERE), env=env, capture_output=True, text=True)
    (HERE / "vivado_program_stdout.txt").write_text(pr.stdout or "", encoding="utf-8")
    (HERE / "vivado_program_stderr.txt").write_text(pr.stderr or "", encoding="utf-8")
    (HERE / "vivado_program.log").write_text(
        (pr.stdout or "") + "\n--- STDERR ---\n" + (pr.stderr or ""), encoding="utf-8"
    )
    if pr.returncode != 0:
        print("PROGRAM_FAIL rc=%s" % pr.returncode, file=sys.stderr)
        cap.stop.set()
        ser.close()
        return 5
    if "OBS_PROGRAM_DONE" not in (pr.stdout or ""):
        print("PROGRAM_FAIL missing DONE marker", file=sys.stderr)
        cap.stop.set()
        ser.close()
        return 5
    done_utc = datetime.now(timezone.utc).isoformat(timespec="seconds")
    done_local = datetime.now(TZ).isoformat(timespec="seconds")
    (HERE / "JTAG_DONE.txt").write_text(
        "done_utc=%s\ndone_local=%s\nsha=%s\nprogram_count=1\n" % (done_utc, done_local, h),
        encoding="utf-8",
    )
    print("PROGRAM_OK JTAG_DONE utc=%s" % done_utc, flush=True)
    time.sleep(2.5)

    seq = 1
    log: list[dict] = []
    last: dict = {}
    host_forbidden = 0
    first_div = "NONE"
    first_ckpt = "NONE"
    a_graph = a_rew = b_graph = b_rew = 0
    exam_out: dict = {}
    exam_pack: dict = {}
    reached = "E0"

    def tx(typ: int, payload: bytes = b"", gap: float = 0.25) -> None:
        nonlocal seq, host_forbidden
        if typ < 0x01 or typ > 0x0D:
            host_forbidden += 1
            raise Divergence("illegal TYPE %s" % typ, ckpt="HOST")
        if payload and typ == CMD_QUERY_TOKEN:
            t = payload[0]
            if t not in set(range(0x10, 0x24)) | set(range(0x30, 0x44)) | {
                T_HOLD_A, T_UNREL, T_CONTRA, T_HOLD_B
            }:
                host_forbidden += 1
                raise Divergence("illegal token %02X" % t, ckpt="HOST")
        ser.write(frame(typ, seq, payload))
        ser.flush()
        seq += 1
        time.sleep(gap)

    def sample(tag: str) -> dict:
        nonlocal last
        fr = decode_cframe(cap.snap())
        tail = fr[-16:] if len(fr) >= 16 else fr
        c0 = latest(fr, 0)
        c1 = latest(fr, 1)
        c5 = latest(fr, 5)
        c6 = latest(fr, 6)
        c7 = latest(fr, 7)
        c8 = latest(fr, 8)
        c9 = latest(fr, 9)
        c10 = latest(fr, 10)
        c11 = latest(fr, 11)
        c12 = latest(fr, 12)
        row = {
            "tag": tag,
            "n": len(fr),
            "ckpts": sorted({f["ckpt"] for f in fr}),
            "dump_ckpts": sorted({f["ckpt"] for f in tail}),
            "c0": c0_id(c0["payload"]).hex().upper() if c0 else None,
            "mode": c1_mode(c1["payload"]) if c1 else None,
            **(c5_fields(c5["payload"]) if c5 else {}),
            "txn": c6_txn(c6["payload"]) if c6 else None,
            **(c7_fields(c7["payload"]) if c7 else {}),
            **(c8_fields(c8["payload"]) if c8 else {}),
            **(c9_fields(c9["payload"]) if c9 else {}),
            **(c10_fields(c10["payload"]) if c10 else {}),
            **(c11_fields(c11["payload"]) if c11 else {}),
            **(c12_fields(c12["payload"]) if c12 else {}),
        }
        last = row
        log.append({k: row[k] for k in row if k != "ckpts"})
        keys = (
            "tag", "n", "mode", "cons", "txn", "addr", "busy", "ack", "gen",
            "lmst", "lmdn", "out", "pack", "x", "adig", "bdig", "afor", "bvis",
        )
        printable = {k: row.get(k) for k in keys if k in row}
        if "pack" in printable and printable["pack"] is not None:
            printable["pack"] = hx(printable["pack"])
        print("SAMPLE %s" % json.dumps(printable), flush=True)
        return row

    def dump(tag: str, gap: float = 1.05) -> dict:
        tx(CMD_STATUS, gap=gap)
        time.sleep(0.12)
        return sample(tag)

    def wait_idle(tag: str, timeout: float = 40.0, require_busy_seen: bool = False) -> dict:
        t0 = time.monotonic()
        row: dict = {}
        saw_busy = False
        while time.monotonic() - t0 < timeout:
            row = dump(tag)
            if row.get("busy") is True:
                saw_busy = True
            if row.get("busy") is False and row.get("mode") is not None:
                if require_busy_seen and not saw_busy:
                    time.sleep(0.2)
                    continue
                return row
            time.sleep(0.25)
        raise Divergence("persist_busy_timeout " + tag, row, ckpt="E2")

    def require_live_dump(row: dict, tag: str) -> None:
        got = set(row.get("dump_ckpts") or [])
        if not set(range(12)).issubset(got):
            raise Divergence("missing_c0_c11 %s dump_ckpts=%s" % (tag, sorted(got)), row, ckpt="E0")
        if row.get("c0") != C0_WANT.hex().upper():
            raise Divergence("C0 drift %s c0=%s" % (tag, row.get("c0")), row, ckpt="E0")

    def require_gen_legal(row: dict, tag: str) -> None:
        g = row.get("gen")
        if not gen_legal(g):
            raise Divergence(
                "E1 GEN illegal tag=%s gen=%s (FFFFFFFF/0/out-of-WRAP_LIMIT)"
                % (tag, hx(g) if g is not None else None),
                row,
                ckpt="E1",
            )

    def lesson(tok: int, i: int, tagp: str) -> dict:
        nonlocal a_graph, b_graph, a_rew, b_rew, seq
        cons0 = last.get("cons")
        txn0 = last.get("txn")
        if cons0 is None:
            raise Divergence("no_cons_baseline", last, ckpt="E2")
        tx(CMD_QUERY_TOKEN, bytes([tok]), gap=0.2)
        tx(CMD_QUERY_COMMIT, gap=0.55)
        t1 = time.monotonic()
        txn = None
        r = last
        while time.monotonic() - t1 < 12.0:
            r = dump("%s_txn_%02d" % (tagp, i))
            if r.get("busy") is False and r.get("txn") is not None:
                if txn0 is None or r["txn"] != txn0 or r.get("cons") is not None:
                    txn = r["txn"]
                    break
            time.sleep(0.15)
        if txn is None:
            raise Divergence("%s lesson %d no C6 txn" % (tagp, i), last, ckpt="E2")
        if tagp == "A":
            a_graph += 1
        else:
            b_graph += 1
        ser.write(reward_frame(seq, REW, int(txn) & 0xFFFF))
        seq += 1
        print("REWARD %s i=%d tok=%02X txn=%s" % (tagp, i, tok, txn), flush=True)
        time.sleep(0.3)
        t1 = time.monotonic()
        while time.monotonic() - t1 < 25.0:
            r = dump("%s_c5c7_%02d" % (tagp, i))
            cons = r.get("cons")
            if cons is None:
                continue
            if cons > cons0 + 1:
                raise Divergence("%s lesson %d C5 jumped %s→%s" % (tagp, i, cons0, cons), r, ckpt="E2")
            if cons == cons0 + 1 and r.get("busy") is False:
                if tagp == "A":
                    a_rew += 1
                else:
                    b_rew += 1
                print(
                    "LESSON_OK %s i=%d tok=%02X txn=%s cons=%s→%s addr=%s ack=%s gen=%s"
                    % (tagp, i, tok, txn, cons0, cons, r.get("addr"), r.get("ack"), hx(r.get("gen"))),
                    flush=True,
                )
                return r
            if cons < cons0:
                raise Divergence("%s lesson %d C5 decreased" % (tagp, i), r, ckpt="E2")
            time.sleep(0.2)
        raise Divergence(
            "%s lesson %d no C5+1 cons=%s want=%s" % (tagp, i, r.get("cons"), cons0 + 1),
            r,
            ckpt="E2",
        )

    def exam(tok: int, name: str, timeout: float = 120.0) -> dict:
        tx(CMD_EXAM_QUERY, bytes([tok]), gap=0.45)
        t0 = time.monotonic()
        r = last
        while time.monotonic() - t0 < timeout:
            r = dump("exam_%s" % name, gap=0.85)
            if r.get("x") not in (None, 0):
                raise Divergence("C10 X nonzero %s x=%s" % (name, r.get("x")), r, ckpt="E4")
            if r.get("lmdn"):
                want = ORACLE[name]
                pack_ckpt = "E3" if name == "HOLD_A" else "E5"
                out_ckpt = "E4" if name == "HOLD_A" else "E5"
                if r.get("pack") != want["pack"]:
                    raise Divergence(
                        "%s C9=%s want=%s OUT=%s" % (
                            name, hx(r.get("pack")), hx(want["pack"]), r.get("out")),
                        r,
                        ckpt=pack_ckpt,
                    )
                if r.get("out") != want["out"]:
                    raise Divergence(
                        "%s OUT=%s want=%s pack=%s" % (
                            name, r.get("out"), want["out"], hx(r.get("pack"))),
                        r,
                        ckpt=out_ckpt,
                    )
                if r.get("mode") != 8:
                    raise Divergence("%s mode=%s" % (name, r.get("mode")), r, ckpt=out_ckpt)
                if not r.get("lmst"):
                    raise Divergence("%s LMST=0" % name, r, ckpt=out_ckpt)
                exam_out[name] = r.get("out")
                exam_pack[name] = r.get("pack")
                print(
                    "EXAM_OK %s out=%s pack=%s lmst=%s lmdn=%s"
                    % (name, r.get("out"), hx(r.get("pack")), r.get("lmst"), r.get("lmdn")),
                    flush=True,
                )
                return r
            time.sleep(0.7)
        raise Divergence(
            "%s LMDN timeout out=%s pack=%s" % (name, r.get("out"), hx(r.get("pack"))),
            r,
            ckpt="E3" if name == "HOLD_A" else "E5",
        )

    rc = 0
    try:
        tboot = time.monotonic()
        row = {}
        while time.monotonic() - tboot < 45.0:
            row = dump("boot", gap=1.2)
            if row.get("c0") == C0_WANT.hex().upper() and row.get("mode") is not None:
                break
            time.sleep(0.4)
        if row.get("c0") != C0_WANT.hex().upper():
            raise Divergence("BOOT C0 missing c0=%s" % row.get("c0"), row, ckpt="E0")
        if row.get("mode") not in (5, 8):
            raise Divergence("BOOT mode=%s" % row.get("mode"), row, ckpt="E0")
        require_live_dump(row, "boot")
        reached = "E0"
        (HERE / "BOOT_OK.txt").write_text(
            "c0=%s mode=%s gen=%s cons=%s\n" % (
                row.get("c0"), row.get("mode"), row.get("gen"), row.get("cons")),
            encoding="utf-8",
        )
        print("BOOT_OK mode=%s cons=%s gen=%s" % (row.get("mode"), row.get("cons"), hx(row.get("gen"))), flush=True)
        require_gen_legal(row, "boot")
        reached = "E1"
        print("E1_GEN_LEGAL gen=%s" % hx(row.get("gen")), flush=True)

        wait_idle("pre_train")
        tx(CMD_TRAIN_RESET, gap=0.6)
        time.sleep(0.4)
        rst = dump("after_treset")
        require_gen_legal(rst, "after_treset")
        tx(CMD_TRAIN_BEGIN, gap=0.5)
        row = wait_idle("train_begin")
        if row.get("mode") != 5:
            raise Divergence("TRAIN_BEGIN mode=%s want=5" % row.get("mode"), row, ckpt="E2")
        require_gen_legal(row, "train_begin")

        cons_start = last.get("cons") or 0
        for i in range(N_A):
            lesson(0x10 + i, i, "A")
            require_gen_legal(last, "A_lesson_%02d" % i)
        if a_graph != 20 or a_rew != 20:
            raise Divergence("A counts graph=%s rew=%s" % (a_graph, a_rew), last, ckpt="E2")
        if last.get("cons") != cons_start + N_A:
            raise Divergence(
                "A cons_last=%s want=%s" % (last.get("cons"), cons_start + N_A), last, ckpt="E2"
            )
        reached = "E2"
        print("E2_COMMITS_OK graph=20 rew=20 cons=%s gen=%s" % (last.get("cons"), hx(last.get("gen"))), flush=True)

        tx(CMD_FLUSH, gap=0.5)
        wait_idle("after_flush_a", timeout=45.0)
        tx(CMD_BRAM_KILL, gap=0.4)
        time.sleep(0.3)
        dump("after_kill_a")
        tx(CMD_RELOAD, gap=0.5)
        row = wait_idle("after_reload_a", timeout=60.0)
        require_gen_legal(row, "after_reload_a")
        tx(CMD_FREEZE, gap=0.8)
        frozen_a = wait_idle("freeze_a")
        if frozen_a.get("mode") != 8:
            raise Divergence("FREEZE A mode=%s" % frozen_a.get("mode"), frozen_a, ckpt="E2")
        require_live_dump(frozen_a, "freeze_a")
        require_gen_legal(frozen_a, "freeze_a")

        cons_fz = frozen_a.get("cons")
        ser.write(reward_frame(seq, REW, int(frozen_a.get("txn") or 0) & 0xFFFF))
        seq += 1
        time.sleep(0.5)
        blk = dump("freeze_block")
        if blk.get("cons") not in (cons_fz, None) and blk.get("cons") != cons_fz:
            raise Divergence("FREEZE_BLOCK cons moved %s→%s" % (cons_fz, blk.get("cons")), blk, ckpt="E2")
        print("FREEZE_BLOCK_OK cons=%s" % blk.get("cons"), flush=True)

        exam(T_HOLD_A, "HOLD_A")
        reached = "E4"
        print("E3_E4_HOLD_A_OK C9=%s OUT=653" % hx(exam_pack.get("HOLD_A")), flush=True)
        c12 = last
        print("C12 teacher=%s ext_llm=%s mode=%s n_cue=%s n_win=%s n_addr=%s n_next=%s n_wren=%s" % (
            c12.get("teacher"), c12.get("ext_llm"), c12.get("mode"),
            c12.get("n_cue"), c12.get("n_win"), c12.get("n_addr"),
            c12.get("n_next"), c12.get("n_wren")), flush=True)
        if c12.get("teacher") not in (0, None) or c12.get("ext_llm") not in (0, None):
            raise Divergence("C12 teacher/ext_llm live nonzero", c12, ckpt="C12")
        if c12.get("mode") not in (8, None):
            raise Divergence("C12 MODE=%s want=8" % c12.get("mode"), c12, ckpt="C12")
        for k in ("n_cue", "n_win", "n_addr", "n_next", "n_wren"):
            if c12.get(k) not in (0, None):
                raise Divergence("C12 %s=%s want=0" % (k, c12.get(k)), c12, ckpt="C12")
        if c12.get("teacher") is None:
            raise Divergence("C12 missing from UART dump", c12, ckpt="C12")
        exam(T_UNREL, "UNREL")
        exam(T_CONTRA, "CONTRA")

        tx(CMD_TRAIN_RESET, gap=0.7)
        time.sleep(0.5)
        rst = dump("treset_forget")
        tx(CMD_EXAM_QUERY, bytes([T_HOLD_A]), gap=0.45)
        t0 = time.monotonic()
        forgot = last
        while time.monotonic() - t0 < 90.0:
            forgot = dump("forget_HOLD_A", gap=0.85)
            if forgot.get("lmdn"):
                break
            time.sleep(0.7)
        if not forgot.get("lmdn"):
            raise Divergence("forget HOLD_A LMDN timeout", forgot, ckpt="E5")
        if (
            forgot.get("out") == ORACLE["HOLD_A"]["out"]
            and forgot.get("pack") == ORACLE["HOLD_A"]["pack"]
        ):
            raise Divergence("A not forgotten still HOLD_A oracle", forgot, ckpt="E5")
        print(
            "A_FORGOTTEN out=%s pack=%s afor=%s"
            % (forgot.get("out"), hx(forgot.get("pack")), forgot.get("afor")),
            flush=True,
        )

        tx(CMD_TRAIN_BEGIN, gap=0.5)
        row = wait_idle("b_train")
        if row.get("mode") != 5:
            raise Divergence("B TRAIN mode=%s" % row.get("mode"), row, ckpt="E5")
        cons_b0 = last.get("cons") or 0
        for i in range(N_B):
            lesson(0x30 + i, i, "B")
        if b_graph != 20 or b_rew != 20:
            raise Divergence("B counts graph=%s rew=%s" % (b_graph, b_rew), last, ckpt="E5")
        if last.get("cons") != cons_b0 + N_B:
            raise Divergence("B cons_last=%s want=%s" % (last.get("cons"), cons_b0 + N_B), last, ckpt="E5")

        tx(CMD_FLUSH, gap=0.5)
        wait_idle("after_flush_b", timeout=45.0)
        tx(CMD_RELOAD, gap=0.5)
        wait_idle("after_reload_b", timeout=60.0)
        tx(CMD_FREEZE, gap=0.8)
        frozen_b = wait_idle("freeze_b")
        if frozen_b.get("mode") != 8:
            raise Divergence("FREEZE B mode=%s" % frozen_b.get("mode"), frozen_b, ckpt="E5")
        require_live_dump(frozen_b, "freeze_b")
        exam(T_HOLD_B, "HOLD_B")
        reached = "E5"
        print("E5_UCB_OK 689/237/60", flush=True)
        print("SILICON_SEQUENCE_COMPLETE", flush=True)
        print("EPOCH_CHAIN_CLOSED_ON_BOARD=YES GATE14_PASS=NO", flush=True)
    except Divergence as e:
        first_div = e.why
        first_ckpt = e.ckpt or "UNKNOWN"
        rc = 7
        print("FIRST_DIVERGENCE=%s CKPT=%s row=%s" % (e.why, first_ckpt, json.dumps({
            k: e.row.get(k) for k in (
                "tag", "mode", "cons", "txn", "out", "pack", "lmst", "lmdn", "gen", "afor",
            ) if k in e.row
        }, default=str)), flush=True)
    except Exception as e:
        first_div = "EXC %s" % e
        first_ckpt = reached
        rc = 8
        print("FIRST_DIVERGENCE=%s" % first_div, flush=True)
    finally:
        time.sleep(0.3)
        cap.stop.set()
        raw = cap.snap()
        try:
            ser.close()
        except Exception:
            pass
        (HERE / "uart_raw.bin").write_bytes(raw)
        (HERE / "uart_raw.txt").write_text(raw.decode("latin-1", errors="replace"), encoding="latin-1")
        usha = hashlib.sha256(raw).hexdigest().upper()
        (HERE / "UART_RAW_SHA256.txt").write_text(usha + "\n", encoding="utf-8")
        (HERE / "exam_log.json").write_text(json.dumps(log, indent=2, default=str), encoding="utf-8")
        e0e5 = (
            rc == 0
            and a_graph == 20 and a_rew == 20
            and exam_out.get("HOLD_A") == 653
            and exam_out.get("UNREL") == 689
            and exam_out.get("CONTRA") == 237
            and exam_out.get("HOLD_B") == 60
            and exam_pack.get("HOLD_A") == ORACLE["HOLD_A"]["pack"]
            and host_forbidden == 0
        )
        summary = {
            "gate": "G14-EPOCH-REBIRTH-BIT-00",
            "CLASS": "EPOCH_CHAIN_CLOSED_ON_BOARD" if e0e5 else "SILICON_FAIL_DIVERGENCE",
            "COM12": "PRESENT",
            "BIT_SHA256": h,
            "PROGRAM_ATTEMPTS": 1,
            "PROGRAM_RESULT": "OK" if (HERE / "PROGRAMMED_ONCE.txt").is_file() else "FAIL",
            "UART_RAW_SHA256": usha,
            "uart_bytes": len(raw),
            "cframe_n": len(decode_cframe(raw)),
            "REACHED": reached,
            "FIRST_CHECKPOINT": first_ckpt,
            "A_FACTS_ACCEPTED": a_graph,
            "A_REWARD_COMMITS": a_rew,
            "B_FACTS_ACCEPTED": b_graph,
            "B_REWARD_COMMITS": b_rew,
            "C9": {k: hx(exam_pack.get(k)) for k in ("HOLD_A", "UNREL", "CONTRA", "HOLD_B")},
            "OUT": exam_out,
            "HOST_FORBIDDEN_COUNTERS": host_forbidden,
            "FIRST_DIVERGENCE": first_div,
            "GATE14_PASS": "NO",
            "BOARD_PASS": "not_claimed",
            "oracle_retarget": False,
            "run_40": False,
            "reprogram": False,
        }
        (HERE / "silicon_result.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        print("SUMMARY %s" % json.dumps(summary), flush=True)
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
