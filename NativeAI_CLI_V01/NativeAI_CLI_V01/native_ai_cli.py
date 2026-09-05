#!/usr/bin/env python3
from __future__ import annotations
import argparse
import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path

APP = "Native AI V3.1 Development Console"
VERSION = "0.2.7"

RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
BLUE = "\033[34m"


def c(s, col=""):
    return f"{col}{s}{RESET}" if sys.stdout.isatty() else s


def load_config():
    p = Path(__file__).with_name("config.json")
    if p.exists():
        return json.loads(p.read_text(encoding="utf-8"))
    return {}


CFG = load_config()


def repo_root() -> Path:
    here = Path(__file__).resolve().parent
    for p in [here, *here.parents]:
        if (p / "rtl" / "native_graph").exists() and (p / "results" / "A7-NATIVE-GRAPH").exists():
            return p
    return here.parents[2]


def u6_bag() -> Path:
    return repo_root() / "results" / "A7-NATIVE-GRAPH" / "GROK-ORCH-00" / "U6-TYPECLASS-UNIFIED-RETRIEVAL-00"


def load_u6_gold():
    bag = u6_bag()
    cand_p = bag / "GOLDEN_TYPECLASS_CANDIDATES.json"
    top_p = bag / "GOLDEN_TYPECLASS_TOPK.json"
    if not cand_p.exists() or not top_p.exists():
        return {}, {}
    cands = json.loads(cand_p.read_text(encoding="utf-8"))
    top = json.loads(top_p.read_text(encoding="utf-8"))
    by_text = {}
    for row in cands:
        by_text[row["text"].strip().lower()] = row
    top_by_name = {row["name"]: row for row in top.get("confirm", [])}
    return by_text, top_by_name


U6_CAND, U6_TOP = load_u6_gold()


def fmt_ms(x):
    return f"{x:.2f} ms"


def print_rule(ch="─", n=78):
    print(ch * n)


def banner(state):
    print()
    print(c("┌" + "─" * 76 + "┐", CYAN))
    print(c("│", CYAN) + c(f"  {APP}  v{VERSION}".ljust(76), BOLD) + c("│", CYAN))
    print(c("│", CYAN) + f"  Branch : {state['branch']}".ljust(76) + c("│", CYAN))
    print(c("│", CYAN) + f"  Backend: {state['backend']}   Mode: {state['mode']}   Trace: {state['trace']}".ljust(76) + c("│", CYAN))
    print(c("│", CYAN) + f"  Model  : {state['model_state']}".ljust(76) + c("│", CYAN))
    print(c("└" + "─" * 76 + "┘", CYAN))
    print(c("Type /help. Demo replays frozen U6 gold. Never a Native-AI final answer. BIT=NO.", DIM))
    print()


def help_text():
    print("""
Commands
  /help                  Show this help
  /status                Show model/backend/gate status
  /trace off|compact|full
  /mode debug|chat        chat is blocked until an authoritative LM chain exists
  /backend demo|xsim|uart
  /metrics               Show session counters
  /reset                 Reset session counters
  /export [file.json]    Export current session trace
  /clear                 Clear terminal
  /exit                  Quit

Normal text is treated as a user query.
Frozen demo traces: chiller, water chiller, leak chiller, leak check,
payroll tax form, soccer match score, piano lesson, install chiller,
air condenser, supply duct.
""".strip())


def status(state):
    print_rule()
    print(c("STATUS", BOLD))
    gold_ok = "YES" if U6_CAND else "MISSING (embedded fallback unused)"
    fields = [
        ("cli", f"{VERSION}"),
        ("branch", state["branch"]),
        ("head", CFG.get("head", "?")),
        ("backend", state["backend"]),
        ("mode", state["mode"]),
        ("trace", state["trace"]),
        ("model_state", state["model_state"]),
        ("retrieval_object", "TYPE_CLASS = (eid,iid,rid,xid)"),
        ("query_law", "qse-v1-lexicon-hdc-00"),
        ("retrieval_law", "masked-conjunctive"),
        ("topk_identity", "CLASS_ID (not raw NID)"),
        ("U6 gold bag", str(u6_bag())),
        ("U6 gold loaded", gold_ok),
        ("U5Q raw", "FAIL immutable"),
        ("T2", "PASS (FPGA RTL / XSim / OOC)"),
        ("U6 typeclass", "PASS XSim; OOC recorded; NOT silicon"),
        ("U6 candidate owner", "a7ng_typeclass_scan"),
        ("legacy NID", "DISCONNECTED from U6 typeclass top"),
        ("U7A", "FAIL immutable (store-full persist_done)"),
        ("U7A-R1", "PASS XSim: persist_nak on full; persist_done only if wrote"),
        ("U7A-R2", "PASS closure matrix; persist_gen_fast DISCONNECTED from graph"),
        ("U7A-R3A", "MEASURE_PASS; OWNER_LOCK LEARN_KEY_CLASS_CONTEXT_V1"),
        ("U7A-R3B", "PASS XSim: TYPE_CLASS Top-K → V1 key → G1/G2/store/lookup/scorer"),
        ("LEARNED_STATE_IDENTITY", "TYPE_CLASS × QUERY_CONTEXT"),
        ("TYPE_CLASS→learn", "REACHABLE in R3B XSim wrapper; not silicon"),
        ("U7", "PASS XSim: V1 prior causally changes TYPE_CLASS ranking; DEPTH=32"),
        ("QHEAD", "NO — baseline contextual prior only; rival not opened"),
        ("U8", "CLOSED"),
        ("minheap timing", "OPEN OOC WNS=-4.103ns"),
        ("learn store depth", "32 OPEN HIGH_RISK — no product-scale claim"),
        ("board", "U6B substrate PASS; U6 TYPE_CLASS silicon NOT PROVEN"),
        ("bit / program", "NO / NO"),
        ("teacher", "0 in final target; this console does not inject semantics"),
    ]
    for k, v in fields:
        print(f"  {k:22} {v}")
    print_rule()


def gold_result(text: str):
    t = text.strip().lower()
    row = U6_CAND.get(t)
    if row is None:
        return None
    name = row["name"]
    top_row = U6_TOP.get(name, {})
    topk = [x["id"] for x in top_row.get("topk", []) if x.get("v")]
    scores = [x["s"] for x in top_row.get("topk", []) if x.get("v")]
    in_bytes = len(text.encode("utf-8"))
    n = int(row["n"])
    return {
        "source": "U6_FROZEN_GOLD_REPLAY",
        "qse": {"eid": row["eid"], "iid": row["iid"], "rid": row["rid"], "xid": row["xid"]},
        "candidate_ids": list(row["class_ids"]),
        "topk": topk,
        "scores": scores,
        "overflow": bool(row.get("ovf")),
        "trunc": int(row.get("trunc") or 0),
        "host_semantic": 0,
        "latency_ms": {
            "input_codec": 0.05,
            "qse": 0.08 + in_bytes * 0.002,
            "typeclass_scan": 0.45,
            "materialize_score_topk": 0.18 + n * 0.003,
            "lm": 0.00,
        },
        "lm_authoritative": False,
        "output_token_ids": [],
        "answer_text": None,
        "note": "Replay of independent host gold that XSim matched. Not board. Not LM.",
    }


def demo_backend(text):
    g = gold_result(text)
    if g is not None:
        g["source"] = "DEMO_UI_ONLY/U6_GOLD"
        return g
    in_bytes = len(text.encode("utf-8"))
    return {
        "source": "DEMO_UI_ONLY/NO_GOLD_HIT",
        "qse": {"eid": 0, "iid": 0, "rid": 0, "xid": 0},
        "candidate_ids": [],
        "topk": [],
        "scores": [],
        "overflow": False,
        "trunc": 0,
        "host_semantic": 0,
        "latency_ms": {
            "input_codec": 0.05,
            "qse": 0.08 + in_bytes * 0.002,
            "typeclass_scan": 0.45,
            "materialize_score_topk": 0.18,
            "lm": 0.00,
        },
        "lm_authoritative": False,
        "output_token_ids": [],
        "answer_text": None,
    }


def xsim_backend(text):
    bag = u6_bag()
    g = gold_result(text)
    if g is None:
        return {
            "source": "XSIM_ADAPTER_NOT_LIVE",
            "error": (
                "No live xvlog/xelab/xsim launch in CLI v0.2. "
                f"Frozen U6 bag: {bag}  Marker: U6_TYPECLASS_UNIFIED_RETRIEVAL_PASS. "
                "Query not in confirmation gold."
            ),
        }
    g["source"] = "XSIM_BAG_REPLAY_NOT_LIVE_SIM"
    g["note"] = (
        f"Does not invoke Vivado. Replays gold that XSim already matched. bag={bag}"
    )
    return g


def uart_backend(text):
    return {
        "source": "UART_ADAPTER_LOCKED",
        "error": (
            "UART chat is locked until an authorized bit/LM chain exists. "
            "U6B substrate PASS is not U6 TYPE_CLASS silicon. BIT=NO PROGRAM=NO."
        ),
    }


def run_backend(state, text):
    if state["backend"] == "demo":
        return demo_backend(text)
    if state["backend"] == "xsim":
        return xsim_backend(text)
    return uart_backend(text)


def render_trace(text, res, trace):
    if "error" in res:
        print(c(f"[backend] {res['source']}", YELLOW))
        print(c(res["error"], YELLOW))
        return

    q = res["qse"]
    cand = res["candidate_ids"]
    top = res["topk"]
    scores = res.get("scores") or []
    l = res["latency_ms"]
    total = sum(l.values())

    if trace == "off":
        return

    print(c("┌─ EXECUTION TRACE ───────────────────────────────────────────────────────┐", BLUE))
    print(f"│ 01 INPUT       utf8_bytes={len(text.encode('utf-8')):<4} display_words={len(text.split()):<4}                    │")
    print(f"│ 02 QSE         eid={q['eid']:<3} iid={q['iid']:<3} rid={q['rid']:<3} xid={q['xid']:<3}                          │")
    print(f"│ 03 RETRIEVE    object=TYPE_CLASS  candidates={len(cand):<3} overflow={int(res['overflow'])} trunc={res['trunc']:<3} │")
    print(f"│ 04 SCORE/TOPK  scored={len(cand):<3} class_ids={top[:8]}".ljust(77) + "│")
    print(f"│ 05 LEARNING    disabled / U7 not open".ljust(77) + "│")
    print(f"│ 06 LM          authoritative={str(res['lm_authoritative']).lower()} output_tokens={len(res['output_token_ids'])}".ljust(77) + "│")
    print(c("└────────────────────────────────────────────────────────────────────────┘", BLUE))

    if trace == "full":
        print(c("  Stage timing (host wall for demo; FPGA cycles are in the U6 bag)", BOLD))
        for k, v in l.items():
            print(f"    {k:28} {fmt_ms(v)}")
        print(f"    {'total':28} {fmt_ms(total)}")
        print(c("  Decision summary (auditable trace, not hidden chain-of-thought)", BOLD))
        if not cand:
            print("    Q_BOUND empty or no TYPE_CLASS hit. Top-K is pad-only in RTL.")
        else:
            print(f"    Masked-conjunctive scan selected {len(cand)} CLASS_ID(s);")
            print(f"    production minheap retained {min(8, len(top))} CLASS_ID(s). Identity is CLASS_ID, not NID.")
            if scores:
                print(f"    Top-K scores (U6 law, +8 per bound match): {scores[:8]}")
        if res.get("note"):
            print(c(f"    {res['note']}", DIM))
        print(c("  Candidate CLASS_IDs", BOLD))
        print("   ", cand[:64])


def render_answer(state, res):
    if "error" in res:
        print(c("NATIVE_AI> RESPONSE_UNAVAILABLE", YELLOW))
        return
    if res["answer_text"] is not None:
        print(c(f"NATIVE_AI> {res['answer_text']}", GREEN))
    else:
        reason = "LM_CHAIN_NOT_AUTHORIZED"
        if state["mode"] == "debug":
            print(c(f"NATIVE_AI> [{reason}]  (debug CLASS_ID trace above; not an answer)", YELLOW))
        else:
            print(c(f"NATIVE_AI> [{reason}]", YELLOW))


def token_panel(state, text, res):
    in_b = len(text.encode("utf-8"))
    out_n = 0 if "error" in res else len(res.get("output_token_ids", []))
    state["session"]["queries"] += 1
    state["session"]["input_bytes"] += in_b
    state["session"]["output_tokens"] += out_n

    print(c("TOKENS / USAGE", BOLD))
    print(f"  input transport units : {in_b} UTF-8 byte(s)")
    print(f"  output LM token IDs   : {out_n}")
    print(f"  session queries       : {state['session']['queries']}")
    print(f"  session input bytes   : {state['session']['input_bytes']}")
    print(f"  session output tokens : {state['session']['output_tokens']}")
    print(c("  Note: transport/token-ID counters, not billing tokens. host_semantic=0.", DIM))


def export_session(state, path=None):
    if path is None:
        path = f"native_ai_session_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    p = Path(path)
    p.write_text(json.dumps(state["session"], indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Exported: {p.resolve()}")


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--backend", choices=["demo", "xsim", "uart"], default=CFG.get("default_backend", "demo"))
    ap.add_argument("--mode", choices=["debug", "chat"], default="debug")
    ap.add_argument("--trace", choices=["off", "compact", "full"], default=CFG.get("default_trace", "full"))
    args, _ = ap.parse_known_args()

    state = {
        "branch": CFG.get("branch", "grok-orch/v31-canonical-00"),
        "backend": args.backend,
        "mode": args.mode,
        "trace": args.trace,
        "model_state": CFG.get("model_state", "PRE-GATE14 / U6-TYPECLASS XSim PASS / U7A NEXT"),
        "session": {"queries": 0, "input_bytes": 0, "output_tokens": 0, "events": []},
    }

    banner(state)
    while True:
        try:
            text = input(c("USER> ", CYAN)).strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if not text:
            continue
        if text.startswith("/"):
            parts = text.split()
            cmd = parts[0].lower()
            if cmd in ("/exit", "/quit"):
                break
            elif cmd == "/help":
                help_text()
            elif cmd == "/status":
                status(state)
            elif cmd == "/clear":
                os.system("cls" if os.name == "nt" else "clear")
                banner(state)
            elif cmd == "/trace" and len(parts) == 2 and parts[1] in ("off", "compact", "full"):
                state["trace"] = parts[1]
                print(f"trace={state['trace']}")
            elif cmd == "/mode" and len(parts) == 2 and parts[1] in ("debug", "chat"):
                state["mode"] = parts[1]
                print(f"mode={state['mode']}")
            elif cmd == "/backend" and len(parts) == 2 and parts[1] in ("demo", "xsim", "uart"):
                state["backend"] = parts[1]
                print(f"backend={state['backend']}")
            elif cmd == "/metrics":
                print(json.dumps(state["session"], indent=2, ensure_ascii=False))
            elif cmd == "/reset":
                state["session"] = {"queries": 0, "input_bytes": 0, "output_tokens": 0, "events": []}
                print("session counters reset")
            elif cmd == "/export":
                export_session(state, parts[1] if len(parts) > 1 else None)
            else:
                print("Unknown command. Type /help.")
            continue

        t0 = time.perf_counter()
        res = run_backend(state, text)
        elapsed = (time.perf_counter() - t0) * 1000.0
        print()
        print(c(f"[source={res.get('source', 'unknown')} backend={state['backend']}]", DIM))
        render_trace(text, res, state["trace"])
        render_answer(state, res)
        token_panel(state, text, res)
        print(f"  host wall time        : {elapsed:.2f} ms")
        hs = 0 if "error" in res else res.get("host_semantic", 0)
        print(f"  host_semantic         : {hs}")
        state["session"]["events"].append({
            "ts": datetime.now().isoformat(timespec="seconds"),
            "query": text,
            "backend": state["backend"],
            "source": res.get("source"),
            "result": res,
        })
        print()


if __name__ == "__main__":
    main()
