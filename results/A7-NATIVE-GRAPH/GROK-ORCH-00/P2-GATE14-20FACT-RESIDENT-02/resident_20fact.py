#!/usr/bin/env python3
"""P2-GATE14-20FACT-RESIDENT-02. PROGRAM=NO. One COM12. Stop on first divergence."""
from __future__ import annotations

import hashlib
import json
import sys
import threading
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
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
    decode_cframe,
    frame,
    reward_frame,
)

RESIDENT = "A0B338E0AF8836056574913B40106D2DA4DE388686067E7EDEF4D009D57F7E2B"
CORPUS = REPO / "results" / "A7-NATIVE-GRAPH" / "TRAIN-V2" / "corpus_20.json"
CORPUS_SHA = "23A4B5039CB80FECC338DF26BAB4E31EC8B314F7DBC178AD3AA572EA06963F8E"
C0_WANT = bytes([0x34, 0x31, 0x43, 0x47, 0xC0, 0x01, 0x14, 0xA7])
N_A = 20
N_B = 20
T_PRE_A, T_HOLD_A, T_UNREL = 0xA1, 0xA2, 0xA3
T_CONTRA, T_PRE_B, T_HOLD_B = 0xA4, 0xB1, 0xB2
ORACLE = {
    "HOLD_A": {"out": 549, "pack": 0x0706050403010002},
    "UNREL": {"out": 861, "pack": 0x0F0E0D0C0B0A0908},
    "CONTRA": {"out": 549, "pack": 0x0706050403010002},
    "HOLD_B": {"out": 237, "pack": 0x0F0E0D0C090B080A},
}
TZ = timezone(timedelta(hours=7))
REW = 3


class Divergence(Exception):
    def __init__(self, why: str, row: dict | None = None) -> None:
        super().__init__(why)
        self.why = why
        self.row = row or {}


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


def main() -> int:
    import serial

    ch = hashlib.sha256(CORPUS.read_bytes()).hexdigest().upper()
    if ch != CORPUS_SHA:
        print("REFUSE corpus SHA", ch, file=sys.stderr)
        return 3
    corpus = json.loads(CORPUS.read_text(encoding="utf-8"))
    if int(corpus.get("n_facts", 0)) != 20:
        print("REFUSE n_facts", file=sys.stderr)
        return 3
    lock = HERE.parent / "P2-GATE14-LM-START-WIRE-01" / "PROGRAMMED_ONCE.txt"
    if not lock.is_file() or RESIDENT not in lock.read_text(encoding="utf-8").upper():
        print("REFUSE resident lock", file=sys.stderr)
        return 3

    ser = serial.Serial()
    ser.port, ser.baudrate, ser.timeout = "COM12", 115200, 0.2
    ser.dtr = False
    ser.rts = False
    ser.open()
    ser.dtr = False
    ser.rts = False
    cap = Cap(ser)
    cap.start()
    (HERE / "LISTEN_START.txt").write_text(
        "gate=P2-GATE14-20FACT-RESIDENT-02\n"
        "mode=RESIDENT_ONLY PROGRAM=NO\n"
        f"bit_sha256={RESIDENT}\n"
        f"corpus_sha256={CORPUS_SHA}\n"
        f"started_local={datetime.now(TZ).isoformat(timespec='seconds')}\n",
        encoding="utf-8",
    )
    print("LISTEN ARMED RESIDENT_20FACT PROGRAM=NO", flush=True)

    seq = 1
    log: list[dict] = []
    last: dict = {}

    def tx(typ: int, payload: bytes = b"", gap: float = 0.25) -> None:
        nonlocal seq
        ser.write(frame(typ, seq, payload))
        ser.flush()
        seq += 1
        time.sleep(gap)

    def sample(tag: str) -> dict:
        nonlocal last
        fr = decode_cframe(cap.snap())
        tail = fr[-12:] if len(fr) >= 12 else fr
        c0 = latest(fr, 0)
        c1 = latest(fr, 1)
        c5 = latest(fr, 5)
        c6 = latest(fr, 6)
        c7 = latest(fr, 7)
        c8 = latest(fr, 8)
        c9 = latest(fr, 9)
        c10 = latest(fr, 10)
        c11 = latest(fr, 11)
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
        }
        last = row
        log.append(row)
        keys = (
            "tag", "n", "mode", "cons", "txn", "addr", "busy", "ack", "gen",
            "lmst", "lmdn", "out", "pack", "x", "adig", "bdig", "afor", "bvis",
        )
        print("SAMPLE %s" % json.dumps({k: row.get(k) for k in keys if k in row}), flush=True)
        return row

    def dump(tag: str, gap: float = 1.05) -> dict:
        tx(CMD_STATUS, gap=gap)
        time.sleep(0.12)
        return sample(tag)

    def wait_idle(tag: str, timeout: float = 40.0) -> dict:
        t0 = time.monotonic()
        row: dict = {}
        while time.monotonic() - t0 < timeout:
            row = dump(tag)
            if row.get("busy") is False and row.get("mode") is not None:
                return row
            time.sleep(0.25)
        raise Divergence("persist_busy_timeout " + tag, row)

    def require_live_dump(row: dict, tag: str) -> None:
        got = set(row.get("dump_ckpts") or [])
        if not set(range(12)).issubset(got):
            raise Divergence("missing_c0_c11 %s dump_ckpts=%s" % (tag, sorted(got)), row)
        if row.get("c0") != C0_WANT.hex().upper():
            raise Divergence("C0 drift %s c0=%s" % (tag, row.get("c0")), row)

    def save_raw(suffix: str) -> bytes:
        raw = cap.snap()
        (HERE / ("uart_raw" + suffix + ".bin")).write_bytes(raw)
        (HERE / ("uart_raw" + suffix + ".txt")).write_text(
            raw.decode("latin-1", errors="replace"), encoding="latin-1"
        )
        sha = hashlib.sha256(raw).hexdigest().upper()
        n = len(decode_cframe(raw))
        (HERE / ("UART_CFRAME_SHA" + suffix + ".txt")).write_text(
            "uart_sha256=%s\ncframe_n=%d\nbytes=%d\n" % (sha, n, len(raw)),
            encoding="utf-8",
        )
        return raw

    def lesson(tok: int, i: int, tagp: str) -> dict:
        nonlocal seq
        cons0 = last.get("cons")
        if cons0 is None:
            raise Divergence("no_cons_baseline", last)
        tx(CMD_QUERY_TOKEN, bytes([tok]), gap=0.2)
        tx(CMD_QUERY_COMMIT, gap=0.55)
        t1 = time.monotonic()
        txn = None
        r = last
        while time.monotonic() - t1 < 12.0:
            r = dump("%s_txn_%02d" % (tagp, i))
            if r.get("busy") is False and r.get("txn") is not None:
                txn = r["txn"]
                break
            time.sleep(0.15)
        if txn is None:
            raise Divergence("%s lesson %d no C6 txn" % (tagp, i), last)
        ser.write(reward_frame(seq, REW, int(txn) & 0xFFFF))
        ser.flush()
        seq += 1
        print("REWARD %s i=%d txn=%s" % (tagp, i, txn), flush=True)
        time.sleep(0.3)
        t1 = time.monotonic()
        saw_busy = False
        while time.monotonic() - t1 < 20.0:
            r = dump("%s_c5c7_%02d" % (tagp, i))
            if r.get("busy") is True:
                saw_busy = True
            cons = r.get("cons")
            if cons is None:
                continue
            if cons > cons0 + 1:
                raise Divergence("%s lesson %d C5 jumped %s→%s" % (tagp, i, cons0, cons), r)
            if cons == cons0 + 1 and r.get("busy") is False:
                if r.get("addr") in (None, 0):
                    raise Divergence("%s lesson %d C7 addr=0 after consume" % (tagp, i), r)
                print(
                    "LESSON_OK %s i=%d txn=%s cons=%s→%s addr=%s busy_seen=%s ack=%s"
                    % (tagp, i, txn, cons0, cons, r.get("addr"), saw_busy, r.get("ack")),
                    flush=True,
                )
                log.append({
                    "tag": "%s_lesson_ok" % tagp,
                    "lesson": i,
                    "txn_used": txn,
                    "cons0": cons0,
                    "cons": cons,
                    "c7_addr": r.get("addr"),
                    "saw_busy": saw_busy,
                    "c5_ack": r.get("ack"),
                })
                return r
            if cons < cons0:
                raise Divergence("%s lesson %d C5 decreased" % (tagp, i), r)
            time.sleep(0.2)
        raise Divergence(
            "%s lesson %d no C5+1/C7 settle cons=%s want=%s" % (tagp, i, r.get("cons"), cons0 + 1),
            r,
        )

    def exam(tok: int, name: str, timeout: float = 90.0) -> dict:
        tx(CMD_EXAM_QUERY, bytes([tok]), gap=0.45)
        t0 = time.monotonic()
        r = last
        while time.monotonic() - t0 < timeout:
            r = dump("exam_%s" % name, gap=0.85)
            if r.get("x") not in (None, 0):
                raise Divergence("C10 X nonzero %s x=%s" % (name, r.get("x")), r)
            if r.get("lmdn"):
                want = ORACLE[name]
                if r.get("out") != want["out"]:
                    raise Divergence("%s OUT=%s want=%s" % (name, r.get("out"), want["out"]), r)
                if r.get("pack") != want["pack"]:
                    raise Divergence(
                        "%s pack=%s want=%s" % (name, r.get("pack"), hex(want["pack"])), r
                    )
                if r.get("mode") != 8:
                    raise Divergence("%s mode=%s" % (name, r.get("mode")), r)
                print(
                    "EXAM_OK %s out=%s pack=%s" % (name, r.get("out"), hex(r.get("pack") or 0)),
                    flush=True,
                )
                return r
            time.sleep(0.7)
        raise Divergence("%s LMDN timeout out=%s" % (name, r.get("out")), r)

    try:
        time.sleep(0.4)
        row = dump("resident_status", gap=1.4)
        c0 = bytes.fromhex(row["c0"]) if row.get("c0") else b""
        if c0 != C0_WANT:
            raise Divergence(
                "CONFIG_LOST c0=%s want=%s" % (row.get("c0"), C0_WANT.hex().upper()), row
            )
        if row.get("mode") not in (5, 8):
            raise Divergence("CONFIG_LOST mode=%s" % row.get("mode"), row)
        require_live_dump(row, "resident")
        (HERE / "RESIDENT_OK.txt").write_text(
            "c0=%s mode=%s gen=%s cons=%s PROGRAM=NO\n"
            % (row.get("c0"), row.get("mode"), row.get("gen"), row.get("cons")),
            encoding="utf-8",
        )
        print("RESIDENT_OK C0 MATCH mode=%s cons=%s" % (row.get("mode"), row.get("cons")), flush=True)

        wait_idle("pre_train")
        tx(CMD_TRAIN_RESET, gap=0.6)
        wait_idle("after_treset_boot")
        tx(CMD_TRAIN_BEGIN, gap=0.5)
        row = wait_idle("train_begin")
        if row.get("mode") != 5:
            raise Divergence("TRAIN_BEGIN mode=%s want=5" % row.get("mode"), row)

        cons_start = last.get("cons") or 0
        for i in range(N_A):
            lesson(T_PRE_A, i, "A")
        if last.get("cons") != cons_start + N_A:
            raise Divergence("A cons_last=%s want=%s" % (last.get("cons"), cons_start + N_A), last)

        tx(CMD_FLUSH, gap=0.5)
        wait_idle("after_flush_a", timeout=45.0)
        tx(CMD_BRAM_KILL, gap=0.4)
        wait_idle("after_kill_a")
        tx(CMD_RELOAD, gap=0.5)
        row = wait_idle("after_reload_a", timeout=60.0)
        if not row.get("gen"):
            raise Divergence("A reload GEN==0", row)
        tx(CMD_FREEZE, gap=0.8)
        frozen_a = wait_idle("freeze_a")
        if frozen_a.get("mode") != 8:
            raise Divergence("FREEZE A mode=%s" % frozen_a.get("mode"), frozen_a)
        if not frozen_a.get("gen"):
            raise Divergence("FREEZE A GEN==0", frozen_a)
        require_live_dump(frozen_a, "freeze_a")

        ha = exam(T_HOLD_A, "HOLD_A")
        un = exam(T_UNREL, "UNREL")
        co = exam(T_CONTRA, "CONTRA")

        tx(CMD_TRAIN_RESET, gap=0.7)
        rst = wait_idle("treset_forget")
        if not rst.get("afor"):
            raise Divergence("TRAIN_RESET a_for=0 (A not marked forgotten)", rst)
        tx(CMD_EXAM_QUERY, bytes([T_HOLD_A]), gap=0.45)
        t0 = time.monotonic()
        forgot = last
        while time.monotonic() - t0 < 90.0:
            forgot = dump("forget_HOLD_A", gap=0.85)
            if forgot.get("lmdn"):
                break
            time.sleep(0.7)
        if not forgot.get("lmdn"):
            raise Divergence("forget HOLD_A LMDN timeout", forgot)
        if (
            forgot.get("out") == ORACLE["HOLD_A"]["out"]
            and forgot.get("pack") == ORACLE["HOLD_A"]["pack"]
        ):
            raise Divergence("A not forgotten OUT/pack still HOLD_A oracle", forgot)
        print(
            "A_FORGOTTEN out=%s pack=%s afor=%s"
            % (forgot.get("out"), hex(forgot.get("pack") or 0), forgot.get("afor")),
            flush=True,
        )

        tx(CMD_TRAIN_BEGIN, gap=0.5)
        row = wait_idle("b_train")
        if row.get("mode") != 5:
            raise Divergence("B TRAIN mode=%s" % row.get("mode"), row)

        cons_b0 = last.get("cons") or 0
        for i in range(N_B):
            lesson(T_PRE_B, i, "B")
        if last.get("cons") != cons_b0 + N_B:
            raise Divergence("B cons_last=%s want=%s" % (last.get("cons"), cons_b0 + N_B), last)

        tx(CMD_FLUSH, gap=0.5)
        wait_idle("after_flush_b", timeout=45.0)
        tx(CMD_BRAM_KILL, gap=0.4)
        wait_idle("after_kill_b")
        tx(CMD_RELOAD, gap=0.5)
        wait_idle("after_reload_b", timeout=60.0)
        tx(CMD_FREEZE, gap=0.8)
        frozen_b = wait_idle("freeze_b")
        if frozen_b.get("mode") != 8:
            raise Divergence("FREEZE B mode=%s" % frozen_b.get("mode"), frozen_b)
        if not frozen_b.get("gen"):
            raise Divergence("FREEZE B GEN==0", frozen_b)
        require_live_dump(frozen_b, "freeze_b")
        if not frozen_b.get("bvis"):
            raise Divergence("C11 b_vis=0 after B FREEZE", frozen_b)
        if frozen_b.get("adig") == frozen_b.get("bdig"):
            raise Divergence("ADIG==BDIG %s" % frozen_b.get("adig"), frozen_b)
        if (frozen_b.get("adig") or 0) == 0 or (frozen_b.get("bdig") or 0) == 0:
            raise Divergence(
                "ADIG/BDIG zero adig=%s bdig=%s" % (frozen_b.get("adig"), frozen_b.get("bdig")),
                frozen_b,
            )

        hb = exam(T_HOLD_B, "HOLD_B")
        tx(CMD_EXAM_QUERY, bytes([T_HOLD_A]), gap=0.45)
        t0 = time.monotonic()
        ba = last
        while time.monotonic() - t0 < 90.0:
            ba = dump("blindB_HOLD_A", gap=0.85)
            if ba.get("lmdn"):
                break
            time.sleep(0.7)
        if not ba.get("lmdn"):
            raise Divergence("blind-B HOLD_A LMDN timeout", ba)
        if ba.get("out") == ORACLE["HOLD_A"]["out"] and ba.get("pack") == ORACLE["HOLD_A"]["pack"]:
            raise Divergence("blind-B retains A OUT/pack", ba)
        print("BLIND_B_OK HOLD_B=%s HOLD_A_now=%s" % (hb.get("out"), ba.get("out")), flush=True)

        raw = save_raw("")
        summary = {
            "gate": "P2-GATE14-20FACT-RESIDENT-02",
            "PROGRAM": "NO",
            "RESIDENT_ONLY": True,
            "bit_sha256": RESIDENT,
            "corpus_sha256": CORPUS_SHA,
            "n_facts": 20,
            "lessons_A": N_A,
            "lessons_B": N_B,
            "cons_start": cons_start,
            "cons_after_A": cons_start + N_A,
            "cons_after_B": last.get("cons"),
            "HOLD_A": {"out": ha.get("out"), "pack": ha.get("pack")},
            "UNREL": {"out": un.get("out"), "pack": un.get("pack")},
            "CONTRA": {"out": co.get("out"), "pack": co.get("pack")},
            "HOLD_B": {"out": hb.get("out"), "pack": hb.get("pack")},
            "A_forgotten_out": forgot.get("out"),
            "blindB_HOLD_A_out": ba.get("out"),
            "gen": frozen_b.get("gen"),
            "adig": frozen_b.get("adig"),
            "bdig": frozen_b.get("bdig"),
            "afor": frozen_b.get("afor"),
            "bvis": frozen_b.get("bvis"),
            "oracle": {k: {"out": v["out"], "pack": hex(v["pack"])} for k, v in ORACLE.items()},
            "uart_bytes": len(raw),
            "uart_sha256": hashlib.sha256(raw).hexdigest().upper(),
            "cframe_n": len(decode_cframe(raw)),
            "run_40": False,
            "two_lesson_surrogate": False,
            "TEACHER_OFF": "not_claimed",
            "GATE14_PASS": "not_claimed",
            "BOARD_PASS": "not_claimed",
            "CLASS": "PASS_20FACT_RESIDENT_C0C11_G5",
        }
        (HERE / "exam_log.json").write_text(json.dumps(log, indent=2, default=str), encoding="utf-8")
        (HERE / "gate14_20fact_result.json").write_text(
            json.dumps(summary, indent=2, default=str), encoding="utf-8"
        )
        print(
            "DONE class=%s cons=%s A=%s/%s/%s B=%s"
            % (summary["CLASS"], last.get("cons"), ha.get("out"), un.get("out"), co.get("out"), hb.get("out")),
            flush=True,
        )
        cap.stop.set()
        ser.close()
        return 0

    except Divergence as e:
        print("STOP_DIVERGENCE %s" % e.why, flush=True)
        raw = save_raw("_stop")
        (HERE / "STOP.txt").write_text(
            e.why + "\n" + json.dumps(e.row, default=str, indent=2), encoding="utf-8"
        )
        (HERE / "exam_log.json").write_text(json.dumps(log, indent=2, default=str), encoding="utf-8")
        klass = "WAIT_NEW_TOKEN" if "CONFIG_LOST" in e.why else "FAIL_DIVERGENCE"
        summary = {
            "gate": "P2-GATE14-20FACT-RESIDENT-02",
            "PROGRAM": "NO",
            "CLASS": klass,
            "stop": e.why,
            "last": e.row,
            "bit_sha256": RESIDENT,
            "corpus_sha256": CORPUS_SHA,
            "uart_bytes": len(raw),
            "uart_sha256": hashlib.sha256(raw).hexdigest().upper(),
            "cframe_n": len(decode_cframe(raw)),
            "run_40": False,
            "TEACHER_OFF": "not_claimed",
            "GATE14_PASS": "not_claimed",
            "BOARD_PASS": "not_claimed",
        }
        (HERE / "gate14_20fact_result.json").write_text(
            json.dumps(summary, indent=2, default=str), encoding="utf-8"
        )
        cap.stop.set()
        ser.close()
        return 4 if klass == "WAIT_NEW_TOKEN" else 5


if __name__ == "__main__":
    raise SystemExit(main())
