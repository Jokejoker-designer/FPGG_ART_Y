"""Create the immutable A7-LM-04 R5 BOARD_PASS release bundle once."""
from __future__ import annotations

import hashlib
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "releases" / "A7-LM-04-BOARD-PASS-20260818"

FILES = [
    "build/out/arty_a7_lm04r5.bit",
    "build/out/a7lm04r5_timing_route.rpt",
    "docs/contracts/A7-LM-04.md",
    "docs/contracts/A7-LM-04-R5-CONFIRMATION.md",
    "results/A7-LM-04/candidate_r5/CLOSEOUT.md",
    "results/A7-LM-04/candidate_r5/preregister.json",
    "results/A7-LM-04/candidate_r5/oracle_confirmation.json",
    "results/A7-LM-04/candidate_r5/build_manifest.json",
    "results/A7-LM-04/candidate_r5/board/ladder.json",
    "results/A7-LM-04/candidate_r5/board/MANIFEST.json",
    "rtl/control/tensor_microseq.sv",
    "rtl/lm/tiny_gpt100k_core.sv",
    "vivado/tcl/build_a7lm04r5.tcl",
    "vivado/tcl/finalize_a7lm04r5_from_route.tcl",
    "vivado/tcl/program_a7lm04r5.tcl",
    "tools/a7lm04_close_ladder_r5.py",
    "VALIDATION.json",
]


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def main() -> int:
    if DEST.exists():
        raise RuntimeError(f"release already exists; refuse overwrite: {DEST}")
    for rel in FILES:
        if not (ROOT / rel).is_file():
            raise RuntimeError(f"release input missing: {rel}")
    DEST.mkdir(parents=True)
    copied = []
    for rel in FILES:
        source = ROOT / rel
        target = DEST / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        copied.append(target)
    lines = []
    for path in sorted(copied, key=lambda p: p.as_posix()):
        rel = path.relative_to(DEST).as_posix()
        lines.append(f"{sha(path)}  {rel}")
    manifest = DEST / "MANIFEST.sha256"
    manifest.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"A7_LM04_R5_RELEASE_FROZEN path={DEST} files={len(copied)} manifest_sha256={sha(manifest)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
