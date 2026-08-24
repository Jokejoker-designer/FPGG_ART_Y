"""Freeze the first accepted A7-LM-04 R5 implementation before board use.

Run after Vivado succeeds:
  python tools/a7lm04_freeze_r5_build.py

Writes exactly one file: results/A7-LM-04/candidate_r5/build_manifest.json.
The script refuses to replace an existing manifest or accept WNS < 0/TNS != 0.
WNS >= +0.20 is recorded separately and is not an LM-04 close requirement.
Next: program build/out/arty_a7_lm04r5.bit and run a7lm04_close_ladder_r5.py.
"""
from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results" / "A7-LM-04" / "candidate_r5"
DEST = OUT / "build_manifest.json"
BIT = ROOT / "build" / "out" / "arty_a7_lm04r5.bit"
TIMING = ROOT / "build" / "out" / "a7lm04r5_timing_route.rpt"

IMMUTABLE = {
    "arty_a7_lm00.bit": "449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783",
    "arty_a7_lm01.bit": "96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8",
    "arty_a7_lm02.bit": "7CEBA854BDE500DDC87C4742315C45562CB5902C6F66377BCE499DA43BD95CC4",
    "arty_a7_lm03.bit": "C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1",
    "arty_a7_lm04.bit": "0716CF254D767778E792F4BAFD38EB0CF9014B731B39F21CF612D2DDE7883DB2",
    "arty_a7_lm04r.bit": "6BED0DE83922B45BABBD8D2DD0F46F0F469474CB9F0A8A1DF96D1421817EF6B9",
    "arty_a7_lm04r3.bit": "FAC912B3DB543C312565FAA58A457A568E091F156592E4DC82987E92FB8E0318",
}
FROZEN_INPUTS = {
    "results/A7-LM-04/candidate_r5/preregister.json": "28073459CAC369E0FBC73A7B93CA1D79A983E2CDF481B57B76CBB532F0A595A2",
    "results/A7-LM-04/candidate_r5/oracle_confirmation.json": "CB4DE357C7D5CAD596F07466959AC3AE2F9EF55890462BA830BF7CFAEB4C0DBB",
    "rtl/control/tensor_microseq.sv": "2C3A3EF52FB8C7DDC2B2CF4808A62EB0B0BBFB0ECAF46B72BE260F6AA370C996",
    "rtl/lm/tiny_gpt100k_core.sv": "D5B23E12772A95B36759AB90123B555B11100B50103F49234FAA56DCAF91706C",
    "third_party/digilent/arty-a7-100/E.0/1.0/mig.prj": "914A9E4BB1B3002837592944CDF49F8DFBAF4D112552DD8B5BE48602FF1AC329",
}


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def timing(path: Path) -> tuple[float, float]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    for i, line in enumerate(lines):
        if "WNS(ns)" in line and i + 2 < len(lines) and "----" in lines[i + 1]:
            fields = lines[i + 2].split()
            return float(fields[0]), float(fields[1])
    raise RuntimeError(f"cannot parse timing summary: {path}")


def main() -> int:
    if DEST.exists():
        raise RuntimeError(f"R5 build already frozen; refuse overwrite: {DEST}")
    if not BIT.exists() or not TIMING.exists():
        raise RuntimeError("R5 bitstream or timing report is missing")

    old = {}
    for name, expected in IMMUTABLE.items():
        path = ROOT / "build" / "out" / name
        got = sha(path)
        if got != expected:
            raise RuntimeError(f"immutable artifact mismatch: {name} got={got} expected={expected}")
        old[name] = got

    frozen = {}
    for rel, expected in FROZEN_INPUTS.items():
        got = sha(ROOT / rel)
        if got != expected:
            raise RuntimeError(f"frozen input mismatch: {rel} got={got} expected={expected}")
        frozen[rel] = got

    oracle = json.loads((OUT / "oracle_confirmation.json").read_text(encoding="utf-8"))
    if not oracle.get("pass"):
        raise RuntimeError("R5 oracle confirmation is not PASS")
    wns, tns = timing(TIMING)
    if wns < 0.0 or tns != 0.0:
        raise RuntimeError(f"timing gate failed: WNS={wns} TNS={tns}")
    bit_sha = sha(BIT)
    if bit_sha in set(IMMUTABLE.values()):
        raise RuntimeError("R5 bit SHA collides with an immutable historical artifact")

    record = {
        "revision": "A7-LM-04-R5",
        "frozen_utc": datetime.now(timezone.utc).isoformat(),
        "vivado_version": "2026.1",
        "target_part": "xc7a100tcsg324-1",
        "bit": str(BIT.relative_to(ROOT)).replace("\\", "/"),
        "bit_sha256": bit_sha,
        "timing_report": str(TIMING.relative_to(ROOT)).replace("\\", "/"),
        "wns_ns": wns,
        "tns_ns": tns,
        "lm05_timing_authorized": wns >= 0.20 and tns == 0.0,
        "law_id": "lm05-signsgd-v1",
        "frozen_inputs": frozen,
        "immutable_artifacts": old,
        "oracle_confirmation_pass": True,
        "claim_scope": oracle["claim_scope"],
    }
    OUT.mkdir(parents=True, exist_ok=True)
    DEST.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"R5_BUILD_FROZEN bit_sha256={bit_sha} WNS={wns} TNS={tns}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
