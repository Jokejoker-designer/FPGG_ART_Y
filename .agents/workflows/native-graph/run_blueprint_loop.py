#!/usr/bin/env python3
"""Blueprint loop tick — next unresolved gate until Native V1 GOAL.

Usage (from repo root):
  python .agents/workflows/native-graph/run_blueprint_loop.py --tick
  python .agents/workflows/native-graph/run_blueprint_loop.py --assert-not-done

Does not declare BOARD_PASS. Does not run RTL. Prints the gate Cursor must start now.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PIPE = Path(__file__).resolve().parent / "pipeline.json"
STATE = ROOT / "results" / "A7-NATIVE-GRAPH" / "STATUS" / "LOOP_STATE.json"
COMPLETE = ROOT / "results" / "A7-NATIVE-GRAPH" / "PROJECT_COMPLETE.md"
DISPATCH_LOG = ROOT / "results" / "A7-NATIVE-GRAPH" / "STATUS" / "DISPATCH_LOG.jsonl"

FALLBACK_AGENT = {
    "ng05_persist": "a7-ng-memory-arch",
    "ng02_ng03_silicon_log": "a7-vivado-gate",
    "ng02r_flow": "a7-ng-topk-frontier",
    "ng06": "a7-ng-scientific",
    "ng06_wide_dispatch": "a7-ng-scientific",
    "ng06_epoch": "a7-ng-scientific",
    "ng04_stale_event": "a7-ng-scientific",
    "ng07": "a7-ng-scientific",
    "ng08": "a7-ng-teacher-protocol",
    "ng09": "a7-ng-teacher-protocol",
    "mem00": "a7-ng-memory-arch",
    "mem01_mem02": "a7-ng-memory-arch",
    "lm_compose": "a7-ng-orchestrator",
    "termgen": "a7-ng-rtl-scorer",
    "perfmon": "a7-ng-scientific",
    "mem_schema_v1": "a7-ng-memory-arch",
    "ddr_feed": "a7-ng-memory-arch",
    "frontier_shootout": "a7-ng-topk-frontier",
    "bram_wm_00": "a7-ng-memory-arch",
    "reset_00": "a7-ng-memory-arch",
    "integrate_fit": "a7-vivado-gate",
    "train_v2": "a7-ng-teacher-protocol",
    "lm06_soc_path": "a7-vivado-gate",
    "lm06_ua_core": "a7-vivado-gate",
    "hs02_lm_path": "a7-vivado-gate",
    "wm00_timing": "a7-ng-memory-arch",
    "mig_h_rival": "a7-ng-memory-arch",
    "hs02_semantic": "a7-hlb-auditor",
    "tinygpt_soc": "a7-vivado-gate",
    "bram_consolidate": "a7-ng-memory-arch",
    "tinygpt_consol": "a7-vivado-gate",
    "mig_board": "a7-ng-memory-arch",
    "mig_board_r2": "a7-ng-memory-arch",
    "mig_metric_00": "a7-ng-memory-arch",
    "ddr_wavefront_00": "a7-ng-memory-arch",
    "lm06_wm_00": "a7-ng-memory-arch",
    "wf_global_topk_00": "a7-ng-topk-frontier",
    "wf_global_topk_integrated_00": "a7-ng-topk-frontier",
    "descriptor_contract_00": "a7-hlb-auditor",
    "ddr_cue_soa_00": "a7-ng-memory-arch",
    "ddr_cue_soa_00r_axi_liveness": "a7-ng-memory-arch",
    "lm06_wm_ladder": "a7-ng-memory-arch",
    "bram_owner_00": "a7-ng-memory-arch",
    "teacher_off_exam": "a7-hlb-auditor",
    "section14_all": "a7-evidence-auditor",
}

VERIFY_AFTER = [
    "a7-ng-xsim-verify",
    "a7-vivado-gate",
    "a7-evidence-auditor",
]
REREAD = [
    "docs/NATIVE_AI_ARTY_A7_BLUEPRINT/15_CURSOR_BLUEPRINT_LOOP.md",
    "docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md",
    "docs/NATIVE_AI_ARTY_A7_BLUEPRINT/14_FINAL_ACCEPTANCE_CHECKLIST.md",
    "docs/NATIVE_AI_ARTY_A7_BLUEPRINT/02_IMPLEMENTATION_ROADMAP.md",
    "results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json",
]


def load_state() -> dict:
    if not STATE.exists():
        print("MISSING LOOP_STATE.json — Next=ng05_persist", file=sys.stderr)
        return {"next": "ng05_persist", "queue": [], "goal": "NATIVE_V1_MINI_AI_BOARD_PASS"}
    return json.loads(STATE.read_text(encoding="utf-8"))


def first_open(st: dict) -> dict | None:
    for item in st.get("queue", []):
        if str(item.get("status", "OPEN")).startswith("OPEN"):
            return item
    return None


def cmd_tick() -> int:
    st = load_state()
    nxt = first_open(st) or {"id": st.get("next", "?"), "from_roadmap": ""}
    print("BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=" + nxt.get("id", "?"))
    print("goal_authority: docs/NATIVE_AI_ARTY_A7_BLUEPRINT/14_FINAL_ACCEPTANCE_CHECKLIST.md")
    print("reread:")
    for p in REREAD:
        ok = (ROOT / p).exists()
        print(f"  [{'OK' if ok else 'MISSING'}] {p}")
    print("GATE:", nxt.get("id"))
    print("WHY:", nxt.get("from_roadmap") or nxt.get("from_audit") or nxt.get("from_checklist") or nxt.get("from_blueprint") or "")
    print("DO_NOT_STOP: PASS must start the following OPEN queue item in the same session.")
    print("ILLEGAL_STOP: NG-05 XSim, status table, handshake, GlassBox, encoder twin.")
    print("LEGAL_YIELD: board unplugged AFTER xsim+impl+archive; write WAITING_BOARD.md")
    if COMPLETE.exists():
        print("NOTE: PROJECT_COMPLETE.md exists — verify §14 table is file-backed, then human BOARD_PASS only.")
    return 0


def pipeline_agent(sid: str) -> str:
    if PIPE.exists():
        pipe = json.loads(PIPE.read_text(encoding="utf-8"))
        for n in pipe.get("nodes", []):
            if n.get("id") == sid:
                return str(n.get("character_id") or FALLBACK_AGENT.get(sid, "a7-ng-orchestrator"))
    return FALLBACK_AGENT.get(sid, "a7-ng-orchestrator")


def cmd_dispatch() -> int:
    st = load_state()
    nxt = first_open(st) or {"id": st.get("next", "?")}
    sid = str(nxt.get("id", "?"))
    agent = pipeline_agent(sid)
    why = (
        nxt.get("from_roadmap")
        or nxt.get("from_audit")
        or nxt.get("from_checklist")
        or nxt.get("from_blueprint")
        or ""
    )
    print("BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=" + sid)
    print("PARENT_ROLE: orchestrator-only")
    print("FORBIDDEN_PARENT: edit rtl/** tests/** vivado/tcl/** (except STATUS/)")
    print("MUST_INVOKE_TASK:")
    print(f"  1. subagent_type={agent}")
    print(f"     gate={sid}")
    print(f"     why={why.encode('ascii', 'replace').decode('ascii')}")
    print("  2. After implement PASS, SAME TURN, parallel Task:")
    for v in VERIFY_AFTER:
        print(f"     subagent_type={v}  (VERIFY_ONLY, gate={sid})")
    print("  3. a7-evidence-auditor must refuse PASS if DISPATCH_LOG.jsonl last line.gate != " + sid)
    print("CURSOR_TASK_PROMPT:")
    print("-----")
    print(f"You are Cursor subagent `{agent}` for pipeline gate `{sid}`.")
    print("Re-read docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md and 02_IMPLEMENTATION_ROADMAP.md.")
    print("Re-read docs/NATIVE_AI_ARTY_A7_BLUEPRINT/15_CURSOR_BLUEPRINT_LOOP.md.")
    print(f"Do ONLY `{sid}`. One unknown. Stay in your owned paths from .agents/workflows/native-graph/registry.yaml.")
    print("Do not overwrite frozen 01R/02M/LM-06/A0.3 bits. Do not declare BOARD_PASS.")
    print("Append one JSON line to results/A7-NATIVE-GRAPH/STATUS/DISPATCH_LOG.jsonl:")
    print(f'  {{"gate":"{sid}","agent":"{agent}","result":"PASS|FAIL","artifact":"<path>"}}')
    print("Return GATE/CHANGED/TESTS/PASS-FAIL/ARTIFACT/SHA256/NEXT to parent.")
    print("-----")
    print("THEN_PARENT: if PASS, run this script --tick again and Task the next implementer immediately.")
    print("STOP_ONLY: PROJECT_COMPLETE.md with file-backed §14 table (human BOARD_PASS).")
    DISPATCH_LOG.parent.mkdir(parents=True, exist_ok=True)
    return 0


def cmd_assert_not_done() -> int:
    if COMPLETE.exists():
        text = COMPLETE.read_text(encoding="utf-8")
        if "NATIVE_V1_MINI_AI_BOARD_PASS" in text and "NOT_CLAIMED" not in text:
            print("COMPLETE file present — still HUMAN declares BOARD_PASS")
            return 0
        print("PROJECT_COMPLETE.md exists but is not a §14 evidence table — LOOP continues")
        return 2
    print("GOAL not met. Continue LOOP. Next from --tick.")
    return 2


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tick", action="store_true")
    ap.add_argument("--dispatch", action="store_true")
    ap.add_argument("--assert-not-done", action="store_true")
    args = ap.parse_args()
    if args.tick:
        return cmd_tick()
    if args.dispatch:
        return cmd_dispatch()
    if args.assert_not_done:
        return cmd_assert_not_done()
    ap.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
