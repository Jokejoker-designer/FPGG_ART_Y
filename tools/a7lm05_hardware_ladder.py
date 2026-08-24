"""Conjunctive hardware-only A7-LM-05 board ladder.

This is not the LM-05 quality confirmation.  It validates the 399,360-byte
image, exact one-step FPGA update, four-layer movement, DDR persistence,
AFTER write blocking, and first-try sequential K=257/511/513 in one program.
The host supplies stimuli and compares FPGA results with the fixed oracle; it
does not compute updates for the board.
"""
from __future__ import annotations

import hashlib
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

import serial  # noqa: E402
import a7lm04_close_ladder as L04  # noqa: E402
import a7lm04_close_ladder_r3 as R3  # noqa: E402
from python.ref.a7lm05_fixed_ref import (  # noqa: E402
    L,
    LAYER_WORDS,
    OFF_L0,
    PARAM_COUNT,
    TinyGPT399k,
    fold_bytes,
)
from python.uart_frames import (  # noqa: E402
    lm04_payload_frame,
    lm05_read_frame,
    lm05_write_frame,
)
from python.uart_stream import FrameStream  # noqa: E402

BIT_NAME = "arty_a7_lm05.bit"
BIT_MANIFEST = ROOT / "results" / "A7-LM-05" / "build_manifest.json"
OUT_DIR = ROOT / "results" / "A7-LM-05" / "hardware_candidate_02"
OUT_PATH = OUT_DIR / "ladder.json"
EXPECTED_FROZEN = {
    "arty_a7_lm00.bit": "449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783",
    "arty_a7_lm01.bit": "96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8",
    "arty_a7_lm02.bit": "7CEBA854BDE500DDC87C4742315C45562CB5902C6F66377BCE499DA43BD95CC4",
    "arty_a7_lm03.bit": "C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1",
    "arty_a7_lm04r5.bit": "A177E0989956DF08C7150E451984C914E1D53B1FCF96A49EBEC68CE8497A55F8",
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def static_checks() -> dict:
    manifest = json.loads(BIT_MANIFEST.read_text(encoding="utf-8"))
    bit = ROOT / manifest["bit"]
    frozen = {}
    for name, expected in EXPECTED_FROZEN.items():
        path = ROOT / "build" / "out" / name
        got = sha256(path)
        frozen[name] = {"expected": expected, "got": got, "match": got == expected}
    bit_sha = sha256(bit)
    return {
        "manifest": manifest,
        "bit_sha256": bit_sha,
        "bit_match": bit_sha == manifest["sha256"],
        "timing_close": manifest["wns_ns"] >= 0.0 and manifest["tns_ns"] == 0.0,
        "lm06_timing_authorized": manifest["wns_ns"] >= 0.20 and manifest["tns_ns"] == 0.0,
        "frozen": frozen,
        "frozen_ok": all(row["match"] for row in frozen.values()),
    }


def wait_kind(stream: FrameStream, kind: int, timeout_s: float):
    return L04.wait_kind(stream, kind, timeout_s)


def read8(port, stream: FrameStream, addr: int):
    L04.send(port, lm05_read_frame(addr))
    rec = wait_kind(stream, 0xA4, 10.0)
    if not rec or rec.get("addr") != addr:
        return None
    return rec.get("data")


def wait_write_idle(port, stream: FrameStream, timeout_s: float = 10.0, offset: int | None = None):
    last = L04.wait_idle(port, stream, timeout_s)
    if not last or last.get("busy"):
        where = "end" if offset is None else str(offset)
        raise RuntimeError(f"UPLOAD_STALL_AT_OFFSET {where}: {last}")
    return last


def wait_idle_logged(port, stream: FrameStream, timeout_s: float, label: str):
    t0 = time.monotonic()
    last = None
    saw_busy = False
    last_print = -10.0
    while time.monotonic() - t0 < timeout_s:
        last = L04.status(port, stream)
        elapsed = time.monotonic() - t0
        if elapsed - last_print >= 10.0:
            last_print = elapsed
            print(
                f"{label} t={elapsed:.0f}s busy={None if not last else last.get('busy')} "
                f"wr_n={None if not last else last.get('wr_n')} pred={None if not last else last.get('pred')}",
                flush=True,
            )
        if last and last.get("busy"):
            saw_busy = True
        if last and saw_busy and not last.get("busy"):
            return last
        if last and not last.get("busy") and elapsed > 0.45:
            return last
        time.sleep(0.2)
    return last


def upload(port, stream: FrameStream, blob: list[int]) -> None:
    if len(blob) != PARAM_COUNT:
        raise ValueError("wrong LM-05 image length")
    layer_boundaries = {OFF_L0 + li * LAYER_WORDS for li in range(1, L)}
    for addr in range(0, PARAM_COUNT, 8):
        chunk = bytes((v & 0xFF) for v in blob[addr : addr + 8])
        try:
            L04.send(port, lm05_write_frame(addr, chunk))
        except Exception as exc:
            raise RuntimeError(f"UPLOAD_STALL_AT_OFFSET {addr}: serial {exc}") from exc
        if addr in layer_boundaries or addr == PARAM_COUNT - 8 or addr % 4096 == 0:
            wait_write_idle(port, stream, 10.0, addr)
        if addr % 32768 == 0:
            print(f"upload {addr}/{PARAM_COUNT}", flush=True)
    print("upload frames sent; final idle wait", flush=True)
    wait_write_idle(port, stream, 10.0, PARAM_COUNT)


def target_frame(target: int, lr: int = 3) -> bytes:
    if not 0 <= target < 512:
        raise ValueError("target must be 9-bit")
    return lm04_payload_frame(
        bytes([0x34, target & 0xFF, (lr & 0xF) | (((target >> 8) & 1) << 4)]) + bytes(9)
    )


def layer_probe_rows(before: list[int], after: list[int]) -> list[dict]:
    rows = []
    for li in range(L):
        lo = OFF_L0 + li * LAYER_WORDS
        hi = lo + LAYER_WORDS
        changed = next((idx for idx in range(lo, hi) if before[idx] != after[idx]), None)
        if changed is None:
            raise RuntimeError(f"oracle says layer {li} did not move")
        addr = changed & ~7
        rows.append(
            {
                "layer": li,
                "changed_index": changed,
                "addr": addr,
                "before": [v & 0xFF for v in before[addr : addr + 8]],
                "expected_after": [v & 0xFF for v in after[addr : addr + 8]],
            }
        )
    return rows


def persist_cmd(port, stream: FrameStream, opcode: int, timeout_s: float = 300.0):
    L04.send(port, lm04_payload_frame(bytes([opcode]) + bytes(11)))
    rec = wait_kind(stream, 0xA6, timeout_s)
    if opcode == 0x41:
        auto = wait_kind(stream, 0xA2, 180.0)
        if rec is not None:
            rec["auto_fold"] = auto
    return rec


def tensor_counters(port, stream: FrameStream):
    L04.send(port, lm04_payload_frame(bytes([0x54]) + bytes(11)))
    rec = wait_kind(stream, 0x92, 3.0)
    if not rec:
        return None
    return {k: rec[k] for k in ("cycles", "stalls", "hazards")}


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    if OUT_PATH.exists():
        raise RuntimeError(f"hardware candidate already recorded; refuse overwrite: {OUT_PATH}")
    checks = static_checks()
    if not (checks["bit_match"] and checks["timing_close"] and checks["frozen_ok"]):
        raise RuntimeError(f"static gate failed: {checks}")

    model0 = TinyGPT399k(2)
    blob0 = model0.flat_i8()
    expected0 = fold_bytes(blob0)
    model1 = TinyGPT399k(2)
    before_rec = model1.backward_full([1], 32, lr=3, apply=False)
    model1.backward_full([1], 32, lr=3, apply=True)
    blob1 = model1.flat_i8()
    expected1 = fold_bytes(blob1)
    probes = layer_probe_rows(blob0, blob1)

    summary = {
        "revision": "A7-LM-05-HW-CANDIDATE-02",
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "law_id": "lm05-signsgd-v1",
        "port": port_name,
        "static": checks,
        "quality_confirmation_run": False,
        "hardware_pass": False,
        "contract_status": "OPEN",
    }

    port = serial.Serial(port_name, 115200, timeout=0.05, write_timeout=2.0)
    time.sleep(0.5)
    stream = FrameStream(port)
    try:
        print("phase calib", flush=True)
        summary["calib"] = L04.wait_calib(port, stream, 30.0)
        if not summary["calib"] or not summary["calib"].get("calib"):
            raise RuntimeError("DDR calibration failed")

        command_log = []
        summary["tensor"] = {}
        for k in (257, 511, 513):
            print(f"phase tensor K={k}", flush=True)
            row = R3.k_run(port, stream, k, command_log)
            row["roofline"] = tensor_counters(port, stream)
            summary["tensor"][str(k)] = row

        print("phase upload", flush=True)
        upload(port, stream, blob0)
        print("phase spots", flush=True)
        spot_addrs = [0, 49152, OFF_L0, OFF_L0 + LAYER_WORDS, OFF_L0 + 2 * LAYER_WORDS,
                      OFF_L0 + 3 * LAYER_WORDS, 350208, PARAM_COUNT - 8]
        summary["upload_spots"] = []
        for addr in spot_addrs:
            got = read8(port, stream, addr)
            expected = [v & 0xFF for v in blob0[addr : addr + 8]]
            row = {"addr": addr, "expected": expected, "got": got, "match": got == expected}
            summary["upload_spots"].append(row)
            print(f"spot {addr} match={row['match']} got={got}", flush=True)

        print("phase fold0", flush=True)
        summary["fold0"] = L04.fold(port, stream, 180.0)
        print(f"fold0={summary['fold0']}", flush=True)
        summary["expected_fold0"] = expected0
        L04.load_ctx(port, [1])
        L04.send(port, target_frame(32, 3))
        print("phase one_full", flush=True)
        summary["one_full_status"] = wait_idle_logged(port, stream, 600.0, "one_full")
        print("phase fold1", flush=True)
        summary["fold1"] = L04.fold(port, stream, 180.0)
        print(f"fold1={summary['fold1']}", flush=True)
        summary["expected_fold1"] = expected1
        summary["expected_forward"] = {
            "pred": before_rec["pred"],
            "loss": before_rec["loss"],
            "wr_n": 344256,
        }

        for row in probes:
            row["got"] = read8(port, stream, row["addr"])
            row["match_after"] = row["got"] == row["expected_after"]
            row["moved"] = row["before"] != row["expected_after"]
        summary["layer_probes"] = probes

        print("phase persist_flush", flush=True)
        summary["persist_flush"] = persist_cmd(port, stream, 0x40)
        print("phase persist_reload", flush=True)
        summary["persist_reload"] = persist_cmd(port, stream, 0x41)
        summary["fold_reload"] = L04.fold(port, stream, 180.0)

        L04.set_after(port, True)
        before_after = L04.status(port, stream)
        L04.load_ctx(port, [1])
        L04.send(port, target_frame(32, 3))
        after_status = L04.wait_idle(port, stream, 600.0)
        L04.set_after(port, False)
        summary["after_gate"] = {"before": before_after, "after": after_status}

        f0 = summary["fold0"] or {}
        f1 = summary["fold1"] or {}
        fr = summary["fold_reload"] or {}
        st = summary["one_full_status"] or {}
        pf = summary["persist_flush"] or {}
        pr = summary["persist_reload"] or {}
        summary["gates"] = {
            "calib": bool(summary["calib"] and summary["calib"].get("calib")),
            "tensor_sequence": all(summary["tensor"][str(k)].get("ok") for k in (257, 511, 513)),
            "roofline_logged": all(summary["tensor"][str(k)].get("roofline") for k in (257, 511, 513)),
            "upload_spots": all(row["match"] for row in summary["upload_spots"]),
            "fold0_exact": f0.get("xor32") == expected0["xor32"] and f0.get("add32") == expected0["add32"],
            "one_full_exact": bool(
                st.get("pred") == before_rec["pred"]
                and st.get("loss") == before_rec["loss"]
                and st.get("wr_n") == 344256
                and f1.get("xor32") == expected1["xor32"]
                and f1.get("add32") == expected1["add32"]
            ),
            "all_four_layers_moved": all(row["moved"] and row["match_after"] for row in probes),
            "persist_399360": bool(
                pf.get("bytes") == PARAM_COUNT
                and pr.get("bytes") == PARAM_COUNT
                and not any(pf.get(k) for k in ("under", "berr", "rerr"))
                and not any(pr.get(k) for k in ("under", "berr", "rerr"))
                and fr.get("xor32") == f1.get("xor32")
                and fr.get("add32") == f1.get("add32")
            ),
            "after_zero_writes": bool(
                before_after and after_status and before_after.get("wr_n") == after_status.get("wr_n")
            ),
        }
        summary["hardware_pass"] = all(summary["gates"].values())
    except Exception as exc:
        summary["exception"] = f"{type(exc).__name__}: {exc}"
    finally:
        port.close()
        summary["finished_utc"] = datetime.now(timezone.utc).isoformat()
        OUT_DIR.mkdir(parents=True, exist_ok=True)
        OUT_PATH.write_text(json.dumps(summary, indent=2), encoding="utf-8")
        print(json.dumps(summary, indent=2), flush=True)

    return 0 if summary["hardware_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
