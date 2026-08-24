#!/usr/bin/env python3
"""Dispatch A7-NATIVE-GRAPH pipeline stages to Cursor Task subagents / local gates.

Usage:
  python .agents/workflows/native-graph/run_pipeline.py --status
  python .agents/workflows/native-graph/run_pipeline.py --stage ng04
  python .agents/workflows/native-graph/run_pipeline.py --from ng04

This is the missing glue: pipeline.json was declarative only; this runner
records stage intent + local pass gates so the crew is actually driven.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PIPE = Path(__file__).resolve().parent / "pipeline.json"
STATUS = ROOT / "results" / "A7-NATIVE-GRAPH" / "STATUS" / "PIPELINE_RUN.json"

STAGE_GATES = {
    "ng00": ["pytest", "tests/native_graph/test_ng00_anti_leak.py", "-q"],
    "ng01_xsim": None,  # archived A7NG01_XSIM_PASS
    "ng03": None,
    "ng04": [
        r"C:\2026.1\Vivado\bin\vivado.bat",
        "-mode",
        "batch",
        "-source",
        str(ROOT / "tests/xsim/run_a7ng04_prune.tcl"),
    ],
    "ng05": [
        r"C:\2026.1\Vivado\bin\vivado.bat",
        "-mode",
        "batch",
        "-source",
        str(ROOT / "tests/xsim/run_a7ng05_learn.tcl"),
    ],
}

CURSOR_AGENT = {
    "audit": "a7-evidence-auditor",
    "ng00": "a7-ng-teacher-protocol",
    "hlb": "a7-hlb-auditor",
    "ng01": "a7-ng-rtl-scorer",
    "ng01_xsim": "a7-ng-xsim-verify",
    "ng01_impl": "a7-vivado-gate",
    "ng02": "a7-ng-topk-frontier",
    "ng03": "a7-ng-memory-arch",
    "ng04": "a7-ng-scientific",
    "ng05": "a7-ng-scientific",
    "ng05_persist": "a7-ng-memory-arch",
    "ng06": "a7-ng-scientific",
    "ng07": "a7-ng-scientific",
    "ng08": "a7-ng-teacher-protocol",
    "ng09": "a7-ng-teacher-protocol",
    "mem00": "a7-ng-memory-arch",
    "lm_compose": "a7-ng-orchestrator",
    "teacher_off_exam": "a7-hlb-auditor",
    "section14": "a7-evidence-auditor",
    "hitl": "HUMAN",
}


def load_pipe() -> dict:
    return json.loads(PIPE.read_text(encoding="utf-8"))


def load_status() -> dict:
    if STATUS.exists():
        return json.loads(STATUS.read_text(encoding="utf-8"))
    return {"stages": {}, "updated": None}


def save_status(st: dict) -> None:
    STATUS.parent.mkdir(parents=True, exist_ok=True)
    st["updated"] = datetime.now(timezone.utc).isoformat()
    STATUS.write_text(json.dumps(st, indent=2), encoding="utf-8")


def run_gate(cmd: list[str] | None) -> tuple[bool, str]:
    if cmd is None:
        return True, "no local gate (use archived evidence)"
    try:
        p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=600)
        out = (p.stdout or "") + (p.stderr or "")
        return p.returncode == 0, out[-4000:]
    except Exception as e:
        return False, str(e)


def cmd_status() -> int:
    pipe = load_pipe()
    st = load_status()
    print(f"pipeline={pipe['id']} nodes={len(pipe['nodes'])}")
    for n in pipe["nodes"]:
        sid = n["id"]
        agent = CURSOR_AGENT.get(sid, n.get("character_id", "?"))
        prev = st["stages"].get(sid, {})
        print(f"  {sid:12} agent={agent:24} status={prev.get('status','OPEN')}")
    print(f"status_file={STATUS}")
    return 0


def cmd_stage(sid: str) -> int:
    st = load_status()
    agent = CURSOR_AGENT.get(sid, "?")
    print(f"DISPATCH stage={sid} cursor_agent={agent}")
    print(f"  -> Invoke Cursor Task subagent_type={agent} (parent must launch Task tool)")
    ok, log = run_gate(STAGE_GATES.get(sid))
    st["stages"][sid] = {
        "status": "PASS" if ok else "FAIL",
        "agent": agent,
        "gate_ok": ok,
        "log_tail": log[-1500:],
    }
    save_status(st)
    print(f"GATE {'PASS' if ok else 'FAIL'} stage={sid}")
    if log:
        print(log[-800:])
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--status", action="store_true")
    ap.add_argument("--stage", type=str, default="")
    ap.add_argument("--from", dest="from_stage", type=str, default="")
    args = ap.parse_args()
    if args.status:
        return cmd_status()
    if args.stage:
        return cmd_stage(args.stage)
    if args.from_stage:
        pipe = load_pipe()
        ids = [n["id"] for n in pipe["nodes"]]
        if args.from_stage not in ids:
            print("unknown stage", args.from_stage)
            return 2
        i0 = ids.index(args.from_stage)
        rc = 0
        for sid in ids[i0:]:
            if sid == "hitl":
                print("STOP at HITL — human BOARD_PASS required")
                break
            r = cmd_stage(sid)
            if r != 0:
                rc = r
                if load_pipe().get("stop_on_fail", True):
                    break
        return rc
    ap.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
