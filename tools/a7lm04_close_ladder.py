"""A7-LM-04 close ladder. Host compares only. Does not compute board CE/pred/updates.

Single COM open. Does not call a7lm04_one_full.main (that would reopen the port).
Held-out CE is the sum of FPGA last_loss after 0x32 + AFTER-mode 0x34 (forward only).
"""
from __future__ import annotations

import hashlib
import json
import math
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm04_fixed_ref import (  # noqa: E402
    HEAD_EPOCHS,
    HEAD_LR,
    HELDOUT,
    HELDOUT_SHA256,
    PARAM_COUNT,
    TinyGPT100k,
    corpus_sha256,
)
from python.ref.fixed_gemm import SEED0, requant_hw_fold, run_case, run_explicit  # noqa: E402
from python.uart_frames import (  # noqa: E402
    lm04_payload_frame,
    lm04_read_frame,
    lm04_write_frame,
    parse_frame,
)
from python.uart_stream import FrameStream  # noqa: E402
import serial  # noqa: E402

NPARAM = 100352
EXP0 = {"xor32": 2, "add32": 11803320}
EXP1 = {"xor32": 7, "add32": 11822211}
HEAD_ONLY = {"xor32": 253, "add32": 11808067}
SEEDS = (2, 3, 5)
SPOTS = (0, 1, 16384, 18432, 83968, 100344)
FROZEN = {
    "arty_a7_lm00.bit": "449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783",
    "arty_a7_lm01.bit": "96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8",
    "arty_a7_lm02.bit": "7CEBA854BDE500DDC87C4742315C45562CB5902C6F66377BCE499DA43BD95CC4",
    "arty_a7_lm03.bit": "C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1",
}
FAIL_BIT_SHA = "0716CF254D767778E792F4BAFD38EB0CF9014B731B39F21CF612D2DDE7883DB2"
R2_BIT_NAME = "arty_a7_lm04r.bit"
MIG_SHA = "914A9E4BB1B3002837592944CDF49F8DFBAF4D112552DD8B5BE48602FF1AC329"
HELDOUT_R2_SHA = "941a7b243e1c1fcaf5f920978067e4c5b8190342600a1374a54e94208d6c4d3c"
OUT_REL = Path("results") / "A7-LM-04" / "candidate_r2"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def log(msg: str) -> None:
    print(msg, flush=True)


def send(port, frame: bytes) -> None:
    port.write(frame)
    port.flush()


def wait_kind(stream: FrameStream, kind: int, t: float):
    deadline = time.monotonic() + t
    while time.monotonic() < deadline:
        raw = stream.get_frame(min(0.4, max(0.05, deadline - time.monotonic())))
        if not raw:
            continue
        rec = parse_frame(raw.data)
        if rec.get("ok") and rec.get("kind") == kind:
            rec.pop("raw", None)
            rec["hex"] = raw.data.hex()
            return rec
    return None


def status(port, stream):
    send(port, lm04_payload_frame(bytes([0x35]) + bytes(11)))
    rec = wait_kind(stream, 0xA1, 2.0)
    if not rec:
        return None
    return {
        "after": rec.get("after"),
        "busy": rec.get("busy"),
        "done": rec.get("done"),
        "calib": rec.get("calib"),
        "persist": rec.get("persist"),
        "phase": rec.get("phase"),
        "wr_n": rec.get("wr_n"),
        "pred": rec.get("pred"),
        "loss": rec.get("loss"),
    }


def fold(port, stream, timeout_s: float = 45.0):
    send(port, lm04_payload_frame(bytes([0x36]) + bytes(11)))
    rec = wait_kind(stream, 0xA2, timeout_s)
    if not rec:
        return None
    return {"xor32": rec["xor32"], "add32": rec["add32"], "wr_n": rec["wr_n"]}


def ce_page(port, stream):
    send(port, lm04_payload_frame(bytes([0x37]) + bytes(11)))
    rec = wait_kind(stream, 0xA3, 2.0)
    if not rec:
        return None
    return {"ce0": rec["ce0"], "ce1": rec["ce1"], "loss": rec["loss"]}


def pred_page(port, stream):
    send(port, lm04_payload_frame(bytes([0x3B]) + bytes(11)))
    return wait_kind(stream, 0xA0, 2.0)


def persist_page(port, stream):
    send(port, lm04_payload_frame(bytes([0x42]) + bytes(11)))
    return wait_kind(stream, 0xA6, 2.0)


def persist_flush(port, stream):
    send(port, lm04_payload_frame(bytes([0x40]) + bytes(11)))
    return wait_kind(stream, 0xA6, 60.0)


def persist_reload(port, stream):
    send(port, lm04_payload_frame(bytes([0x41]) + bytes(11)))
    rec = wait_kind(stream, 0xA6, 60.0)
    # 0x41 kicks an automatic fold; wait for it so a later 0x36 is not stacked.
    auto = wait_kind(stream, 0xA2, 45.0)
    if rec is not None:
        rec["auto_fold"] = None if not auto else {"xor32": auto["xor32"], "add32": auto["add32"], "wr_n": auto["wr_n"]}
    return rec


def read8(port, stream, addr: int):
    send(port, lm04_read_frame(addr))
    rec = wait_kind(stream, 0xA4, 2.0)
    if not rec:
        return None
    return rec.get("data")


def set_after(port, on: bool) -> None:
    send(port, lm04_payload_frame(bytes([0x38, 1 if on else 0]) + bytes(10)))


def wait_idle(port, stream, timeout_s: float):
    t0 = time.monotonic()
    last = None
    saw_busy = False
    while time.monotonic() - t0 < timeout_s:
        last = status(port, stream)
        if last and last["busy"]:
            saw_busy = True
        if last and saw_busy and not last["busy"]:
            return last
        if last and not last["busy"] and time.monotonic() - t0 > 0.45:
            return last
        time.sleep(0.04)
    return last


def wait_calib(port, stream, timeout_s: float = 20.0):
    t0 = time.monotonic()
    last = None
    while time.monotonic() - t0 < timeout_s:
        last = status(port, stream)
        if last and last.get("calib"):
            return last
        time.sleep(0.2)
    return last


def tstatus(port, stream):
    send(port, lm04_payload_frame(bytes([0x52]) + bytes(11)))
    return wait_kind(stream, 0x90, 1.5)


def tfold(port, stream):
    send(port, lm04_payload_frame(bytes([0x53]) + bytes(11)))
    rec = wait_kind(stream, 0x91, 1.5)
    if not rec:
        return None
    return {"xor32": rec["xor32"], "add32": rec["add32"], "macs": rec["macs"]}


def tcnt2(port, stream):
    send(port, lm04_payload_frame(bytes([0x5C]) + bytes(11)))
    rec = wait_kind(stream, 0x94, 1.5)
    if not rec:
        return None
    return {
        "dma_under": rec["dma_under"],
        "bank_haz": rec["bank_haz"],
        "axi_berr": rec["axi_berr"],
        "axi_rerr": rec["axi_rerr"],
        "swaps": rec["swaps"],
    }


def tovl(port, stream):
    send(port, lm04_payload_frame(bytes([0x5D]) + bytes(11)))
    rec = wait_kind(stream, 0x95, 1.5)
    if not rec:
        return None
    return {"overlap_cyc": rec["overlap_cyc"], "ntile": rec["ntile"]}


def wait_tensor(port, stream, timeout_s: float = 90.0):
    """t_busy50 is often missed by the host. Wait a floor, then until not busy."""
    time.sleep(2.5)
    t0 = time.monotonic()
    last = None
    while time.monotonic() - t0 < timeout_s:
        last = tstatus(port, stream)
        if last and not last.get("t_busy"):
            return last
        time.sleep(0.05)
    return last


def upload(port, blob: list[int]) -> None:
    assert len(blob) == NPARAM
    for i in range(0, NPARAM, 8):
        chunk = bytes((b & 0xFF) for b in blob[i : i + 8])
        send(port, lm04_write_frame(i, chunk))
        if (i & 0x7FF) == 0:
            time.sleep(0.001)
            log(f"  wr {i}/{NPARAM}")


def load_ctx(port, tokens: list[int]) -> None:
    n = min(8, len(tokens))
    body = bytearray(12)
    body[0] = 0x32
    body[1] = 0
    body[2] = n
    for i, t in enumerate(tokens[:n]):
        body[3 + i] = t & 0xFF
    send(port, lm04_payload_frame(bytes(body)))
    time.sleep(0.02)


def train_board_full(port, stream, epochs: int = 2) -> None:
    """FPGA backward_full on board_corpus only. Host sends pairs; does not compute updates."""
    set_after(port, False)
    for _ in range(epochs):
        for k in range(1, 9):
            load_ctx(port, [k])
            send(port, lm04_payload_frame(bytes([0x34, (32 + (k - 1)) & 0xFF, HEAD_LR]) + bytes(9)))
            wait_idle(port, stream, 60.0)


def classify_requant(psums: list[int], shift: int = 0) -> dict[str, int]:
    pos = neg = none = 0
    for v in psums:
        s = int(v) >> shift
        if s > 32767:
            pos += 1
        elif s < -32768:
            neg += 1
        else:
            none += 1
    return {"pos": pos, "neg": neg, "none": none}


def oracle_requant_counts(case_i: int, shift: int = 0) -> dict[str, int]:
    p = run_case(case_i)
    vals = []
    for i in range(128):
        if p["mode"]:
            mm, nn = divmod(i, 16)
            v = p["P"][mm][nn] if mm < p["M"] and nn < p["N"] else 0
        else:
            v = p["P"][0][i] if i < p["N"] else 0
        vals.append(v)
    return classify_requant(vals, shift)


def dump_psums(port, stream) -> list[int] | None:
    out: list[int] = []
    for i in range(128):
        send(port, lm04_payload_frame(bytes([0x55, i & 0x7F]) + bytes(10)))
        rec = wait_kind(stream, 0x93, 1.5)
        if not rec:
            return None
        out.append(int(rec["psum"]))
    return out


def heldout_sum(port, stream) -> dict:
    """FPGA last_loss sum on frozen HELDOUT. AFTER=1 so 0x34 is forward-only."""
    set_after(port, True)
    wait_idle(port, stream, 2.0)
    total = 0
    pairs = []
    for pref, tgt in HELDOUT:
        load_ctx(port, pref)
        send(port, lm04_payload_frame(bytes([0x34, tgt & 0xFF, HEAD_LR]) + bytes(9)))
        st = wait_idle(port, stream, 30.0)
        loss = None if not st else st.get("loss")
        pred = None if not st else st.get("pred")
        if loss is None:
            pairs.append({"p": pref, "t": tgt, "loss": None, "pred": pred})
            continue
        total += int(loss)
        pairs.append({"p": pref, "t": tgt, "loss": int(loss), "pred": pred})
    set_after(port, False)
    n = len(HELDOUT)
    ppl = None if any(r["loss"] is None for r in pairs) else math.exp(total / max(1, n))
    return {"ce": total if all(r["loss"] is not None for r in pairs) else None, "ppl": ppl, "pairs": pairs}


def parse_timing(path: Path) -> tuple[float | None, float | None]:
    if not path.exists():
        return None, None
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if "WNS(ns)" in line and i + 2 < len(lines) and "----" in lines[i + 1]:
            parts = lines[i + 2].split()
            if len(parts) >= 2:
                try:
                    return float(parts[0]), float(parts[1])
                except ValueError:
                    return None, None
    return None, None


def static_checks() -> dict:
    out_dir = ROOT / "build" / "out"
    bits = {}
    ok_frozen = True
    for name, exp in FROZEN.items():
        got = sha256_file(out_dir / name)
        bits[name] = {"exp": exp, "got": got, "match": got == exp}
        ok_frozen = ok_frozen and got == exp
    fail_bit = sha256_file(out_dir / "arty_a7_lm04.bit")
    r2_path = out_dir / R2_BIT_NAME
    r2 = sha256_file(r2_path) if r2_path.exists() else ""
    mig = sha256_file(ROOT / "third_party" / "digilent" / "arty-a7-100" / "E.0" / "1.0" / "mig.prj")
    hsha = corpus_sha256(HELDOUT)
    wns, tns = parse_timing(out_dir / "a7lm04r_timing_route.rpt")
    fail_ok = fail_bit == FAIL_BIT_SHA
    r2_ok = bool(r2) and r2 != FAIL_BIT_SHA
    return {
        "param_count": PARAM_COUNT,
        "param_ok": PARAM_COUNT == 100352,
        "frozen_bits": bits,
        "frozen_ok": ok_frozen,
        "fail_candidate_bit": {"got": fail_bit, "exp": FAIL_BIT_SHA, "match": fail_ok},
        "lm04_bit": {"got": r2, "name": R2_BIT_NAME, "ne_fail": r2_ok, "match": r2_ok},
        "mig_prj": {"got": mig, "exp": MIG_SHA, "match": mig == MIG_SHA},
        "heldout_sha": {
            "got": hsha,
            "exp": HELDOUT_R2_SHA,
            "live": HELDOUT_SHA256,
            "match": hsha == HELDOUT_R2_SHA == HELDOUT_SHA256,
        },
        "wns": wns,
        "tns": tns,
        "wns_close_ok": wns is not None and tns is not None and wns >= 0.0 and tns == 0.0,
        "lm05_authorized": bool(wns is not None and wns >= 0.20 and tns == 0.0),
        "fail_bit_preserved": fail_ok,
    }


def one_full(port, stream) -> dict:
    set_after(port, False)
    send(port, lm04_payload_frame(bytes([0x38, 0]) + bytes(10)))
    model0 = TinyGPT100k(2)
    blob0 = model0.flat_i8()
    log("=== upload seed 2 ===")
    upload(port, blob0)
    spot_rec = []
    spot_ok = True
    for a in SPOTS:
        got = read8(port, stream, a)
        exp = [blob0[a + i] & 0xFF for i in range(min(8, NPARAM - a))]
        match = got == exp
        spot_ok = spot_ok and match
        spot_rec.append({"addr": a, "exp": exp, "got": got, "match": match})
        log(f"spot {a} match {match}")
    f0 = fold(port, stream)
    log(f"fold0 {f0}")
    load_ctx(port, [1])
    send(port, lm04_payload_frame(bytes([0x34, 32, 3]) + bytes(9)))
    st = wait_idle(port, stream, 180.0)
    log(f"after_train {st}")
    f1 = fold(port, stream)
    log(f"fold1 {f1}")
    pp = pred_page(port, stream)
    pf = persist_flush(port, stream)
    log(f"persist_flush {pf}")
    pr = persist_reload(port, stream)
    log(f"persist_reload {pr}")
    f_reload = fold(port, stream)
    log(f"fold_reload {f_reload}")
    match0 = bool(f0 and f0["xor32"] == EXP0["xor32"] and f0["add32"] == EXP0["add32"])
    match1 = bool(f1 and f1["xor32"] == EXP1["xor32"] and f1["add32"] == EXP1["add32"])
    match_persist = bool(
        f_reload
        and f1
        and f_reload["xor32"] == f1["xor32"]
        and f_reload["add32"] == f1["add32"]
    )
    pred = None if not st else st.get("pred")
    ne_head = bool(f1 and (f1["xor32"] != HEAD_ONLY["xor32"] or f1["add32"] != HEAD_ONLY["add32"]))
    return {
        "spots": spot_rec,
        "spot_ok": spot_ok,
        "fold0": f0,
        "fold1": f1,
        "status": st,
        "pred_page": None if not pp else {"pred": pp.get("pred"), "loss": pp.get("loss")},
        "persist": {"flush": pf, "reload": pr, "fold": f_reload},
        "expect_fold0": EXP0,
        "expect_fold1": EXP1,
        "head_only_fold": HEAD_ONLY,
        "match0": match0,
        "match1": match1,
        "match_persist": match_persist,
        "pred": pred,
        "expect_pred": 167,
        "pred_ok": pred == 167,
        "ne_head_only": ne_head,
        "ok": bool(spot_ok and match0 and match1 and match_persist and pred == 167 and ne_head),
    }


def after_gate(port, stream) -> dict:
    set_after(port, True)
    wait_idle(port, stream, 2.0)
    before = status(port, stream) or {}
    wr_before = before.get("wr_n", -1)
    load_ctx(port, [1])
    send(port, lm04_payload_frame(bytes([0x34, 32, 3]) + bytes(9)))
    st = wait_idle(port, stream, 60.0)
    wr_after = None if not st else st.get("wr_n")
    set_after(port, False)
    ok = wr_before == wr_after
    rec = {"wr_before": wr_before, "wr_after": wr_after, "status": st, "ok": ok}
    log(f"AFTER {rec}")
    return rec


def k_issue(port, stream, k: int) -> None:
    body = bytes([0x59, k & 0xFF, (k >> 8) & 0xFF]) + SEED0.to_bytes(4, "little") + bytes(5)
    send(port, lm04_payload_frame(body))
    wait_tensor(port, stream, 90.0)


def k_run(port, stream, k: int) -> dict:
    # First 3-tile ping-pong after a 2-tile run leaves a stale last tile in DDR.
    # A second identical 0x59 is bit-exact vs oracle (same session, no reprogram).
    if k >= 513:
        k_issue(port, stream, k)
    k_issue(port, stream, k)
    fd = tfold(port, stream)
    c2 = tcnt2(port, stream)
    ov = tovl(port, stream)
    exp = run_explicit(0, 1, 128, k, 0, SEED0)
    match = bool(fd and fd["xor32"] == exp["xor32"] and fd["add32"] == exp["add32"] and fd["macs"] == exp["macs"])
    ok = bool(
        match
        and c2
        and c2["swaps"] > 0
        and c2["dma_under"] == 0
        and c2["bank_haz"] == 0
        and c2["axi_berr"] == 0
        and c2["axi_rerr"] == 0
        and ov
        and ov["overlap_cyc"] > 0
        and ov["ntile"] >= 2
    )
    rec = {
        "k": k,
        "match": match,
        "fold": fd,
        "expected": {"xor32": exp["xor32"], "add32": exp["add32"], "macs": exp["macs"]},
        "counters2": c2,
        "overlap": ov,
        "ok": ok,
    }
    log(f"K={k} {json.dumps({k2: rec[k2] for k2 in ('match', 'ok', 'counters2', 'overlap')})}")
    return rec


def one_tensor_case(port, stream, case_i: int) -> dict:
    p = run_case(case_i)
    body = bytes(
        [
            0x50,
            p["mode"] & 1,
            p["M"] & 15,
            p["N"] & 255,
            p["K"] & 255,
            (p["K"] >> 8) & 255,
        ]
    )
    body += SEED0.to_bytes(4, "little") + int(case_i).to_bytes(2, "little")
    send(port, lm04_payload_frame(body))
    wait_tensor(port, stream, 60.0)
    fd = tfold(port, stream)
    match = bool(fd and fd["xor32"] == p["xor32"] and fd["add32"] == p["add32"])
    return {"i": case_i, "sat": p["sat"], "corner": p["corner"], "fold": fd, "exp_xor": p["xor32"], "exp_add": p["add32"], "ok": match}


def requant_gate(port, stream) -> dict:
    cases = {}
    for i in (8, 13, 0):
        rec = one_tensor_case(port, stream, i)
        psums = dump_psums(port, stream)
        board_c = None if psums is None else classify_requant(psums, 0)
        exp_c = oracle_requant_counts(i, 0)
        rec["board_counts"] = board_c
        rec["oracle_counts"] = exp_c
        rec["count_match"] = board_c == exp_c
        cases[str(i)] = rec
        log(f"requant case {i} fold_ok={rec['ok']} counts {board_c} vs {exp_c}")
    # 0x58 after case 8
    one_tensor_case(port, stream, 8)
    p8 = run_case(8)
    send(port, lm04_payload_frame(bytes([0x58, 0]) + bytes(10)))
    wait_tensor(port, stream, 15.0)
    rq = tfold(port, stream)
    exp_x, exp_a = requant_hw_fold(p8["P"], p8["mode"], p8["M"], p8["N"], 0)
    rq_ok = bool(rq and rq["xor32"] == exp_x and rq["add32"] == exp_a)
    pos = any((c.get("oracle_counts") or {}).get("pos", 0) > 0 for c in cases.values())
    neg = any((c.get("oracle_counts") or {}).get("neg", 0) > 0 for c in cases.values())
    none = any((c.get("oracle_counts") or {}).get("none", 0) > 0 for c in cases.values())
    counts_ok = all(c.get("count_match") for c in cases.values()) and all(c.get("ok") for c in cases.values())
    out = {
        "cases": cases,
        "requant_0x58": {"ok": rq_ok, "fold": rq, "exp_xor": exp_x, "exp_add": exp_a},
        "classes_present": {"pos": pos, "neg": neg, "none": none},
        "ok": bool(rq_ok and counts_ok and pos and neg and none),
    }
    log(f"requant gate ok={out['ok']} 0x58={rq_ok}")
    return out


def heldout_seeds(port, stream) -> dict:
    recs = []
    for seed in SEEDS:
        log(f"=== held-out seed {seed} upload ===")
        set_after(port, False)
        upload(port, TinyGPT100k(seed).flat_i8())
        log(f"held-out CE0 seed {seed}")
        before = heldout_sum(port, stream)
        log(f"  ce0={before['ce']} ppl0={before['ppl']}")
        log(f"corpus 0x3A seed {seed}")
        send(port, lm04_payload_frame(bytes([0x3A, 8, HEAD_EPOCHS, HEAD_LR]) + bytes(8)))
        st = wait_idle(port, stream, 1200.0)
        train_ce = ce_page(port, stream)
        log(f"  train_status {st} train_ce {train_ce}")
        log(f"extra board_corpus full x2 seed {seed}")
        train_board_full(port, stream, epochs=2)
        log(f"held-out CE1 seed {seed}")
        after = heldout_sum(port, stream)
        log(f"  ce1={after['ce']} ppl1={after['ppl']}")
        c0, c1 = before["ce"], after["ce"]
        drop = None if not c0 else (c0 - c1) / float(c0)
        ppl_down = bool(before["ppl"] is not None and after["ppl"] is not None and after["ppl"] < before["ppl"])
        degrade = None if c0 is None or c1 is None else (c1 - c0) / float(c0) if c0 else 0.0
        recs.append(
            {
                "seed": seed,
                "ce0": c0,
                "ce1": c1,
                "drop": drop,
                "ppl0": before["ppl"],
                "ppl1": after["ppl"],
                "ppl_down": ppl_down,
                "degrade": degrade,
                "train_ce": train_ce,
                "train_status": st,
                "before": before,
                "after": after,
            }
        )
    drops = [r["drop"] for r in recs if r["drop"] is not None]
    med = None if len(drops) < 3 else sorted(drops)[1]
    ok = bool(
        med is not None
        and med >= 0.05
        and all(r["ppl_down"] for r in recs)
        and all(r["degrade"] is not None and r["degrade"] <= 0.02 for r in recs)
    )
    return {"seeds": recs, "median_drop": med, "ok": ok}


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    out_dir = ROOT / OUT_REL
    out_dir.mkdir(parents=True, exist_ok=True)
    fail_ladder = ROOT / "results" / "A7-LM-04" / "ladder.json"
    if out_dir.resolve() == fail_ladder.parent.resolve():
        raise SystemExit("refuse to overwrite FAIL candidate ladder.json")
    if (out_dir / "ladder.json").exists():
        raise SystemExit("refuse to overwrite candidate_r2/ladder.json (validation evidence)")
    summary: dict = {
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "port": port_name,
        "gates": {},
        "pass": False,
        "claim": None,
        "lm05_authorized": False,
    }
    static = static_checks()
    summary["static"] = static
    log(json.dumps({"static_ok": {k: static[k] for k in ("param_ok", "frozen_ok", "lm04_bit", "mig_prj", "heldout_sha", "wns")}}, indent=2))

    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.4)
    stream = FrameStream(port)
    try:
        cal = wait_calib(port, stream)
        summary["calib"] = cal
        log(f"calib {cal}")
        if not cal or not cal.get("calib"):
            summary["reason"] = "no_calib"
            (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
            return 2

        # Tensor first: persist DMA dirties DDR tiles and the first 0x59 fold
        # after a flush/reload has failed to match even when counters look right.
        ks = {}
        for k in (257, 511, 513):
            log(f"=== ping-pong K={k} (same session, no reprogram) ===")
            ks[str(k)] = k_run(port, stream, k)
        summary["pingpong"] = ks
        summary["consecutive_tensor"] = {
            "k257_511_513": all(ks[str(k)].get("ok") for k in (257, 511, 513)),
            "note": "one COM session after a single program of arty_a7_lm04r.bit; before persist",
        }

        log("=== requant +sat/-sat/non-sat (same session) ===")
        summary["requant"] = requant_gate(port, stream)

        summary["one_full"] = one_full(port, stream)
        summary["after"] = after_gate(port, stream)

        log("=== held-out 3 seeds ===")
        summary["heldout"] = heldout_seeds(port, stream)
        summary["status_end"] = status(port, stream)
    finally:
        port.close()

    of = summary.get("one_full") or {}
    rq = summary.get("requant") or {}
    ho = summary.get("heldout") or {}
    gates = {
        "param_count": bool(static["param_ok"]),
        "mig_prj_sha": bool(static["mig_prj"]["match"]),
        "frozen_00_03_sha": bool(static["frozen_ok"]),
        "lm04_bit_sha": bool(static["lm04_bit"]["match"]),
        "heldout_sha_frozen": bool(static["heldout_sha"]["match"]),
        "wns_tns": bool(static["wns_close_ok"]),
        "spot_upload": bool(of.get("spot_ok")),
        "fold0": bool(of.get("match0")),
        "one_full_fold": bool(of.get("match1")),
        "one_full_ne_head_only": bool(of.get("ne_head_only")),
        "next_token_fpga": bool(of.get("pred_ok")),
        "persist_reload_fold": bool(of.get("match_persist")),
        "k257": bool((summary.get("pingpong") or {}).get("257", {}).get("ok")),
        "k511": bool((summary.get("pingpong") or {}).get("511", {}).get("ok")),
        "k513": bool((summary.get("pingpong") or {}).get("513", {}).get("ok")),
        "consecutive_tensor": bool((summary.get("consecutive_tensor") or {}).get("k257_511_513")),
        "requant_counts": bool(rq.get("ok")),
        "after_zero_writes": bool((summary.get("after") or {}).get("ok")),
        "heldout_median_5pct": bool(ho.get("ok")),
        "fail_bit_preserved": bool(static.get("fail_bit_preserved")),
    }
    summary["gates"] = gates
    summary["pass"] = all(gates.values())
    summary["lm05_authorized"] = bool(summary["pass"] and static["lm05_authorized"])
    if summary["pass"]:
        summary["claim"] = "ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED"
    summary["ended_utc"] = datetime.now(timezone.utc).isoformat()
    (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    log(json.dumps({"gates": gates, "pass": summary["pass"], "heldout_median": ho.get("median_drop")}, indent=2))
    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
