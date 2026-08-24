"""A7 Native-AI Studio — end-user UI server for the A7-EAM-03E-A0 encoder.

Stdlib HTTP + Server-Sent Events. The only third-party import is pyserial, and
only when a board is actually connected.

    python tools/ui/a7_studio.py                 # twin only, no board needed
    python tools/ui/a7_studio.py --port COM12    # attach the Arty A7
    python tools/ui/a7_studio.py --host 0.0.0.0 --http-port 8080

Two independent tracks run for every training step:

    TWIN   python/eam/eam03e_twin.py, integer-exact against all seven A0.1-T
           goldens and against the A0.2-L seed-0x22222222 numbers. It is the
           only source that can show h, gradients and weight deltas, because
           the 20-byte UART reply does not carry them.
    BOARD  arty_a7_eam03e*.bit over UART. The only authority for evidence.

When both are attached the server compares them per pair and raises
``divergence`` the moment silicon and twin disagree. That comparison is the
point of the UI: the host never computes anything the board then consumes.

What the host is allowed to send is fixed by contract: UTF-8 bytes, a SAME/DIFF
label, a 32-bit seed, and the learn/freeze flags. Nothing else. Weight editing
therefore exists on the twin only and is labelled as such everywhere.
"""
from __future__ import annotations

import argparse
import json
import mimetypes
import queue
import sys
import threading
import time
import traceback
from collections import deque
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

REPO = Path(__file__).resolve().parents[2]
STATIC = Path(__file__).resolve().parent / "static"
sys.path.insert(0, str(REPO))

from python.eam import eam03e_bench as bench  # noqa: E402
from python.eam import eam03e_twin as twinmod  # noqa: E402
from python.eam.eam03e_twin import (  # noqa: E402
    E3_D,
    E3_MARG,
    E3_TMAX,
    Eam03eTwin,
    PairTrace,
    golden_check,
    triplet_report,
)
from tools.ui import board_link as bl  # noqa: E402

SESSION_DIR = REPO / "results" / "A7-EAM-03E" / "ui_sessions"

DEFAULT_CURRICULUM = [
    {"a": "ALPHA", "b": "BETA.", "same": True,
     "note": "golden SAME pair from tb_a7eam03e.sv"},
    {"a": "ALPHA", "b": "OMEGA", "same": False,
     "note": "golden DIFF pair from tb_a7eam03e.sv"},
]


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


# --------------------------------------------------------------------------- #
# studio state
# --------------------------------------------------------------------------- #

class Studio:
    def __init__(self, seed: int = 0x11111111) -> None:
        self.lock = threading.RLock()
        self.seed = seed
        self.twin = Eam03eTwin()
        self.twin.reseed(seed)
        self.board: bl.BoardLink | None = None
        self.board_error: str | None = None
        self.curriculum = [dict(c) for c in DEFAULT_CURRICULUM]
        self.history: deque[dict] = deque(maxlen=4000)
        self.last_trace: PairTrace | None = None
        self.subs: list[queue.Queue] = []
        self.step_no = 0
        self.trainer: threading.Thread | None = None
        self.stop_flag = threading.Event()
        self.divergences = 0
        self.in_sync = False
        self.session_id = datetime.now().strftime("%Y%m%dT%H%M%S")
        self.log_path = SESSION_DIR / f"session_{self.session_id}.jsonl"
        self.sweep: dict | None = None
        self.bench: dict | None = None
        self.bench_running = False

    # ----------------------------------------------------------- event bus

    def subscribe(self) -> queue.Queue:
        q: queue.Queue = queue.Queue(maxsize=512)
        with self.lock:
            self.subs.append(q)
        return q

    def unsubscribe(self, q: queue.Queue) -> None:
        with self.lock:
            if q in self.subs:
                self.subs.remove(q)

    def publish(self, kind: str, data: dict) -> None:
        msg = json.dumps({"kind": kind, "ts": now_iso(), **data})
        with self.lock:
            subs = list(self.subs)
        for q in subs:
            try:
                q.put_nowait(msg)
            except queue.Full:
                pass

    def log(self, record: dict) -> None:
        try:
            SESSION_DIR.mkdir(parents=True, exist_ok=True)
            with self.log_path.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(record) + "\n")
        except OSError:
            pass

    # -------------------------------------------------------------- board

    def connect(self, port: str, baud: int) -> dict:
        with self.lock:
            self.disconnect()
            link = bl.BoardLink(port, baud)
            try:
                ping = link.ping()
                link.probe_io()
            except Exception:
                link.close()
                raise
            self.board = link
            self.board_error = None
            self.in_sync = False
            info = {
                "port": port,
                "baud": baud,
                "ident": ping.get("ident"),
                "ident_ok": ping.get("ident_ok"),
                "has_io": link.has_io,
            }
            self.publish("board", {"connected": True, **info})
            return info

    def disconnect(self) -> None:
        with self.lock:
            if self.board is not None:
                self.board.close()
                self.board = None
                self.in_sync = False
                self.publish("board", {"connected": False})

    def resync(self) -> dict:
        """Put twin and board into the same state, then burn one prime pair.

        The RTL never resets ``e_ra`` and ``S_SEED`` does not touch it, so the
        first pair after power-on reads an undefined address. One discarded pair
        pins ``e_ra`` on both sides; after that they run in lockstep.
        """
        with self.lock:
            self.twin.reseed(self.seed)
            self.twin.mode(learn=False, freeze=False)
            if self.board is not None:
                self.board.reseed(self.seed)
                self.board.set_mode(False, False)
            prime = self.curriculum[0] if self.curriculum else DEFAULT_CURRICULUM[0]
            rec = self.run_pair(prime["a"], prime["b"], bool(prime["same"]),
                                prime_step=True)
            self.in_sync = rec.get("agree") is not False
            return {"in_sync": self.in_sync, "prime": rec}

    # --------------------------------------------------------------- steps

    def run_pair(self, text_a: str, text_b: str, same: bool,
                 prime_step: bool = False, source: str = "manual") -> dict:
        """One PAIR on the twin and, if attached, on the board. Never in parallel."""
        with self.lock:
            tw = self.twin.measure(text_a, text_b, same)
            self.last_trace = tw
            board_rep = None
            board_err = None
            if self.board is not None:
                try:
                    board_rep = self.board.measure(text_a, text_b, same)
                except Exception as exc:
                    board_err = str(exc)
                    self.board_error = board_err

            agree = None
            if board_rep is not None:
                agree = (board_rep["d1"] == tw.d1
                         and board_rep["updated"] == tw.updated)
                if not agree and not prime_step:
                    self.divergences += 1
            if board_err and self.trainer and self.trainer.is_alive():
                # A dead link means the remaining steps are twin-only, which is
                # not what the operator asked for. Stop rather than silently
                # degrade for twenty minutes.
                self.stop_flag.set()

            self.step_no += 1
            record = {
                "step": self.step_no,
                "ts": now_iso(),
                "source": source,
                "prime": bool(prime_step or tw.prime),
                "a": text_a,
                "b": text_b,
                "same": bool(same),
                "verdict": "reward" if same else "punish",
                "learn": tw.learn,
                "freeze": tw.freeze,
                "seed": f"0x{self.twin.seed:08X}",
                "twin": {
                    "d1": tw.d1,
                    "dH": tw.dH,
                    "cue": f"0x{tw.b.cue:016X}",
                    "updated": tw.updated,
                    "gate_open": tw.diff_gate_open,
                    "e_writes": tw.e_writes,
                    "wh_writes": tw.wh_writes,
                    "h_a": tw.a.h_final,
                    "h_b": tw.b.h_final,
                    "g_a": tw.gA,
                    "g_b": tw.gB,
                    "sat_a": tw.a.h_saturated,
                    "sat_b": tw.b.h_saturated,
                    "tel_a": self.twin.eval_telemetry(tw.a.h_final),
                    "tel_b": self.twin.eval_telemetry(tw.b.h_final),
                    "cos": round(twinmod.cosine(tw.a.h_final, tw.b.h_final), 6),
                },
                "board": None if board_rep is None else {
                    "d1": board_rep["d1"],
                    "dH": board_rep["dH"],
                    "cue": f"0x{board_rep['cue']:016X}",
                    "updated": board_rep["updated"],
                    "learn": board_rep["learn"],
                    "freeze": board_rep["freeze"],
                },
                "board_error": board_err,
                "agree": agree,
                "weights": self.twin.weight_stats(),
            }
            self.history.append(record)
            self.log(record)
            self.publish("step", {"record": record})
            if agree is False and not prime_step:
                self.publish("divergence", {
                    "step": self.step_no,
                    "twin_d1": tw.d1,
                    "board_d1": board_rep["d1"] if board_rep else None,
                    "twin_dH": tw.dH,
                    "board_dH": board_rep["dH"] if board_rep else None,
                })
            return record

    def set_mode(self, learn: bool, freeze: bool) -> dict:
        with self.lock:
            self.twin.mode(learn, freeze)
            board = None
            if self.board is not None:
                try:
                    rep = self.board.set_mode(learn, freeze)
                    board = {"learn": rep["learn"], "freeze": rep["freeze"]}
                except Exception as exc:
                    self.board_error = str(exc)
            state = {"learn": learn, "freeze": freeze, "board": board}
            self.publish("mode", state)
            return state

    def reseed(self, seed: int) -> dict:
        with self.lock:
            self.seed = seed & 0xFFFFFFFF
            self.twin.reseed(self.seed)
            board = False
            if self.board is not None:
                try:
                    self.board.reseed(self.seed)
                    board = True
                except Exception as exc:
                    self.board_error = str(exc)
            self.in_sync = False
            self.divergences = 0
            state = {"seed": f"0x{self.seed:08X}", "board": board}
            self.publish("seed", state)
            return state

    # ------------------------------------------------------------ training

    def start_training(self, steps: int, delay_ms: int) -> dict:
        with self.lock:
            if self.trainer and self.trainer.is_alive():
                raise RuntimeError("a training run is already active")
            if not self.curriculum:
                raise RuntimeError("curriculum is empty")
            self.stop_flag.clear()
            self.twin.mode(learn=True, freeze=False)
            if self.board is not None:
                try:
                    self.board.set_mode(True, False)
                except Exception as exc:
                    self.board_error = str(exc)
            plan = [dict(c) for c in self.curriculum]
        self.trainer = threading.Thread(
            target=self._train_loop, args=(steps, delay_ms, plan), daemon=True)
        self.trainer.start()
        self.publish("training", {"active": True, "steps": steps})
        return {"active": True, "steps": steps, "pairs": len(plan)}

    def _train_loop(self, steps: int, delay_ms: int, plan: list[dict]) -> None:
        try:
            for epoch in range(steps):
                if self.stop_flag.is_set():
                    break
                for item in plan:
                    if self.stop_flag.is_set():
                        break
                    self.run_pair(item["a"], item["b"], bool(item["same"]),
                                  source=f"train:{epoch + 1}")
                    if delay_ms:
                        time.sleep(delay_ms / 1000.0)
                self.publish("epoch", {"epoch": epoch + 1, "of": steps})
        except Exception:
            self.publish("error", {"where": "train_loop",
                                   "detail": traceback.format_exc(limit=3)})
        finally:
            self.publish("training", {"active": False})

    def stop_training(self) -> dict:
        self.stop_flag.set()
        return {"active": False}

    # ---------------------------------------------------------------- ping

    def ping(self) -> dict:
        """A real PING (opcode 0x01) with a measured round trip.

        The old button only read cached state and reported success for a board
        that had been unplugged an hour earlier, which is disqualifying in a tool
        whose job is silicon conformance.
        """
        with self.lock:
            if self.board is None:
                raise RuntimeError("chưa kết nối board")
            t0 = time.perf_counter()
            rep = self.board.ping()
            rtt = (time.perf_counter() - t0) * 1000.0
            return {
                "ident": rep.get("ident"),
                "ident_ok": rep.get("ident_ok"),
                "rtt_ms": round(rtt, 1),
                "xfers": self.board.xfers,
                "errors": self.board.errors,
                "kind": f"0x{rep['kind']:02X}",
            }

    # ------------------------------------------------------------ benchmark

    def start_bench(self, entities: int, seeds: int, epochs: int, vn: bool) -> dict:
        if self.bench_running:
            raise RuntimeError("một lần quét benchmark đang chạy")

        def work() -> None:
            self.bench_running = True
            try:
                ds = bench.build_name_dataset(n_entities=entities, seed=0, vn=vn)
                leak = bench.assert_no_leakage(ds)
                seed_list = bench.frozen_seeds(seeds)
                runs = []
                for i, sd in enumerate(seed_list):
                    if self.stop_flag.is_set():
                        break
                    runs.append(bench.bench_seed(ds, sd, epochs=epochs))
                    self.publish("bench", {"done": i + 1, "of": len(seed_list)})
                if runs:
                    self.bench = {
                        "bench_id": bench.BENCH_ID,
                        "dataset": {"name": ds.name, "note": ds.note,
                                    "counts": ds.counts(), "leakage": leak,
                                    "epochs": epochs, "vn": bool(vn)},
                        "seeds": [f"0x{s:08X}" for s in seed_list],
                        "runs": runs,
                        "report": bench.evaluate_gates(runs),
                    }
                    self.publish("bench_done", {"result": self.bench})
            except Exception:
                self.publish("error", {"where": "bench",
                                       "detail": traceback.format_exc(limit=3)})
                self.publish("bench_done", {"result": self.bench or {}})
            finally:
                self.bench_running = False

        self.stop_flag.clear()
        threading.Thread(target=work, daemon=True).start()
        return {"started": True, "seeds": seeds}

    # --------------------------------------------------------------- sweep

    def start_sweep(self, seeds: list[int], steps: int, strings: list[str]) -> dict:
        def work() -> None:
            rows = []
            for idx, sd in enumerate(seeds):
                if self.stop_flag.is_set():
                    break
                rep = triplet_report(sd, strings[0], strings[1], strings[2], steps)
                row = {
                    "seed": rep["seed"],
                    "d1_pos": rep["post"]["d1_pos"],
                    "d1_neg": rep["post"]["d1_neg"],
                    "M_L1": rep["post"]["M_L1"],
                    "M_cos": rep["post"]["M_cos"],
                    "gates": rep["gates"],
                    "pass": all(rep["gates"].values()),
                }
                rows.append(row)
                self.publish("sweep", {"done": idx + 1, "of": len(seeds), "row": row})
            self.sweep = {"strings": strings, "steps": steps, "rows": rows}
            self.publish("sweep_done", {"rows": rows})

        self.stop_flag.clear()
        threading.Thread(target=work, daemon=True).start()
        return {"started": len(seeds)}

    # -------------------------------------------------------------- twin IO

    def twin_edit(self, kind: str, index: int, value: int) -> dict:
        """Direct weight write. TWIN ONLY — the 03E UART has no weight command."""
        with self.lock:
            value = max(-128, min(127, int(value)))
            if kind == "E":
                if not 0 <= index < len(self.twin.E):
                    raise ValueError("E index out of range")
                self.twin.E[index] = value
            elif kind == "Wh":
                if not 0 <= index < len(self.twin.Wh):
                    raise ValueError("Wh index out of range")
                self.twin.Wh[index] = value
            else:
                raise ValueError("kind must be E or Wh")
            self.in_sync = False
            return {"kind": kind, "index": index, "value": value,
                    "silicon": False, "in_sync": False}

    # -------------------------------------------------------------- reports

    def snapshot(self) -> dict:
        with self.lock:
            board = None
            if self.board is not None:
                board = {
                    "port": self.board.port_name,
                    "baud": self.board.baud,
                    "ident": (self.board.ident or b"").decode("ascii", "replace"),
                    "has_io": self.board.has_io,
                    "xfers": self.board.xfers,
                    "errors": self.board.errors,
                }
            return {
                "law": self.twin.law,
                "seed": f"0x{self.twin.seed:08X}",
                "learn": self.twin.learn,
                "freeze": self.twin.freeze,
                "pairs_run": self.twin.pair_count,
                "updates_applied": self.twin.update_count,
                "step_no": self.step_no,
                "divergences": self.divergences,
                "in_sync": self.in_sync,
                "training": bool(self.trainer and self.trainer.is_alive()),
                "board": board,
                "board_error": self.board_error,
                "curriculum": self.curriculum,
                "weights": self.twin.weight_stats(),
                "session_log": str(self.log_path),
                "limits": {"E3_D": E3_D, "E3_TMAX": E3_TMAX, "E3_MARG": E3_MARG},
            }

    def inspect(self) -> dict:
        with self.lock:
            tr = self.last_trace
            if tr is None:
                return {"available": False}
            e_rows = {}
            for b in sorted(set(tr.a.tokens) | set(tr.b.tokens)):
                e_rows[str(b)] = {
                    "char": bytes([b]).decode("latin-1"),
                    "values": self.twin.E[b * E3_D:(b + 1) * E3_D],
                    "delta": tr.e_delta_by_byte.get(b, [0] * E3_D),
                }
            wh_sign = [(1 if v > 0 else (-1 if v < 0 else 0))
                       for v in (tr.wh_delta or [0] * (E3_D * E3_D))]
            return {
                "available": True,
                "same": tr.same,
                "updated": tr.updated,
                "d1": tr.d1,
                "dH": tr.dH,
                "gate_open": tr.diff_gate_open,
                "margin": E3_MARG,
                "a": {
                    "text": tr.a.text, "tokens": tr.a.tokens,
                    "states": tr.a.states, "embeds": tr.a.embeds,
                    "h": tr.a.h_final, "cue": f"0x{tr.a.cue:016X}",
                    "proj": tr.a.proj_margins,
                },
                "b": {
                    "text": tr.b.text, "tokens": tr.b.tokens,
                    "states": tr.b.states, "embeds": tr.b.embeds,
                    "h": tr.b.h_final, "hprev": tr.b.hprev,
                    "cue": f"0x{tr.b.cue:016X}", "proj": tr.b.proj_margins,
                },
                "g_a": tr.gA,
                "g_b": tr.gB,
                "e_rows": e_rows,
                "wh_delta_sign": wh_sign,
                "wh_now": self.twin.Wh,
            }

    def board_io(self) -> dict:
        """Live SW/BTN/LED if the UI-support build is loaded, else the model."""
        with self.lock:
            if self.board is not None and self.board.has_io:
                try:
                    io = self.board.io_status()
                    io["mode"] = "live"
                    return io
                except Exception as exc:
                    return {"mode": "error", "detail": str(exc)}
            last = self.history[-1] if self.history else None
            busy = False
            upd = bool(last and last["twin"]["updated"])
            return {
                "mode": "model",
                "why": ("no board attached" if self.board is None else
                        "this bitstream has no CMD 0x2F; build "
                        "arty_a7_eam03e_io.bit to read SW/BTN"),
                "sw": [0, 0, 0, 0],
                "btn": [0, 0, 0, 0],
                "led": [1 if not busy else 0, 1 if upd else 0, 0, 0],
                "led_meaning": ["idle", "last_upd", "~rst_n", "heartbeat hb[23]"],
                "sw_meaning": ["unused on 03E (tied into `unused`)"] * 4,
                "btn_meaning": ["reset (POR)", "unused", "unused", "unused"],
            }


# --------------------------------------------------------------------------- #
# static analysis payloads for the teaching tabs
# --------------------------------------------------------------------------- #

def math_curves() -> dict:
    """Sample the twin's own arithmetic so the plots cannot drift from the model."""
    xs = list(range(-160, 161, 2))
    e_range = list(range(-128, 128))
    d_range = list(range(-2048, 2049, 16))
    hinge_x = list(range(-6000, 6001, 100))
    return {
        "sign": {"x": xs, "y": [twinmod.sgn8(x) for x in xs],
                 "title": "sign(g) — the whole optimiser",
                 "note": "SignSGD only uses the sign. Step size is always 1 LSB."},
        "sat8": {"x": xs, "y": [twinmod.sat8(x) for x in xs],
                 "title": "sat8(x) — INT8 weight clamp",
                 "note": "A weight that hits ±127 stops learning in that direction."},
        "abs_shift": {"x": d_range,
                      "y": [twinmod.abs16(x) >> 5 for x in d_range],
                      "title": "|Δ| >> 5 — one d1 term",
                      "note": "The >>5 makes d1 a staircase: differences under 32 read as 0."},
        "h_update": {"x": e_range,
                     "y": [twinmod.h_update(0, e) for e in e_range],
                     "title": "state update at acc=0, as built",
                     "note": ("The SV concat is unsigned, so every negative embedding "
                              "jumps to 32767. This is quirk 2 and it is baked into "
                              "the frozen goldens.")},
        "h_update_intended": {"x": e_range,
                              "y": [twinmod.sat16((0 + (e << 8)) >> 8) for e in e_range],
                              "title": "state update if the concat were signed",
                              "note": "What the law text describes. Not what the bit does."},
        "hinge": {"x": hinge_x,
                  "y": [max(0, -x + E3_MARG) for x in hinge_x],
                  "title": f"hinge  max(0, m − M_L1),  m = {E3_MARG}",
                  "note": ("A0 has no hinge: DIFF is a hard gate at d1 < m. "
                           "A0.2-L L1 replaces the gate with this ramp.")},
        "diff_gate": {"x": d_range, "y": [1 if abs(x) < E3_MARG else 0 for x in d_range],
                      "title": f"DIFF gate: update only if d1 < {E3_MARG}",
                      "note": "Above the margin a DIFF pair produces exactly zero gradient."},
    }


def twinmod_epoch_sweep() -> list[dict]:
    """Epoch-budget sensitivity on the golden triplet. See bench.epoch_sensitivity."""
    return bench.epoch_sensitivity()


def evidence() -> dict:
    gc = golden_check()
    return {
        "law": twinmod.LAW,
        "twin_golden": gc,
        "milestone": "A7-EAM-03E-A0 / A0.1-T",
        "status": {
            "A0 xsim": "XSIM_PASS",
            "A0 silicon": "SILICON_FUNCTIONAL_PASS_WITH_NOTES",
            "A0.1-T timing": "TIMING_FAIL (WNS -0.119, TNS -0.407 before the S_DADD patch)",
            "A0 seed robustness": "SEED_ROBUSTNESS_FAIL (0x22222222 inverts)",
            "A1": "CLOSED",
        },
        "quirks": [
            {"id": 1, "where": "S_EISS / S_ELAT",
             "what": "forward embedding read is off by one; e_lat[j] = E[b][j-1], "
                     "e_lat[0] is a stale read of E[b_prev][31], E[b][31] is never used",
             "impact": "part of the frozen goldens; the update path reads correctly"},
            {"id": 2, "where": "S_HWR",
             "what": "acc + {{8{e[7]}}, e, 8'd0} is an unsigned add, >>> becomes a "
                     "logical shift, so h is never negative and saturates at 32767",
             "impact": "30-31 of 32 coordinates pin at 32767; this is the mechanism "
                       "behind DIFF collapse, not a metric footnote"},
            {"id": 3, "where": "S_PACC",
             "what": "(psum ± concat) > 32'sd0 is an unsigned compare, so it means != 0 "
                     "— PREDICTION, not pinned by any golden",
             "impact": "predicts cue = all-ones and dH = 0, which would make dH unusable. "
                       "A single board PAIR read can falsify it: any dH != 0 means the "
                       "twin is wrong here and must be corrected"},
        ],
        "ablation": ("quirks 1 and 2 were confirmed by ablation — of the four "
                     "combinations of {aligned, off-by-one} x {signed, unsigned}, "
                     "only off-by-one + unsigned reproduces the goldens, and the "
                     "other three miss all seven integers"),
        "host_may_send": ["UTF-8 bytes (<= 46)", "SAME / DIFF label",
                          "32-bit seed", "learn and freeze flags"],
        "host_may_not_send": ["gradients", "weights", "hashes", "addresses",
                              "winners", "precomputed cosine", "CE or next-token"],
        "twin_authority": "ILLUSTRATION ONLY — never quote twin numbers as silicon evidence",
        "gates_a02l": ["d_pos_post < d_pos_pre", "M_L1_post > 0", "M_cos_post > 0",
                       "d_neg_post >= d_pos_post", "reseed erases geometry",
                       "swapped labels create new geometry", "clean host trace"],
    }


# --------------------------------------------------------------------------- #
# HTTP layer
# --------------------------------------------------------------------------- #

class Handler(BaseHTTPRequestHandler):
    server_version = "A7Studio/1.0"
    studio: Studio

    def log_message(self, fmt, *args):  # quieter console
        if "--verbose" in sys.argv:
            super().log_message(fmt, *args)

    # ------------------------------------------------------------- helpers

    def _send(self, code: int, body: bytes, ctype: str,
              extra: dict | None = None) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def _json(self, obj, code: int = 200) -> None:
        self._send(code, json.dumps(obj).encode("utf-8"), "application/json")

    def _body(self) -> dict:
        n = int(self.headers.get("Content-Length") or 0)
        if not n:
            return {}
        try:
            return json.loads(self.rfile.read(n).decode("utf-8"))
        except (ValueError, UnicodeDecodeError):
            return {}

    def _static(self, path: str) -> None:
        rel = "index.html" if path in ("/", "") else path.lstrip("/")
        target = (STATIC / rel).resolve()
        if not str(target).startswith(str(STATIC.resolve())) or not target.is_file():
            self._json({"error": "not found", "path": path}, 404)
            return
        ctype = mimetypes.guess_type(target.name)[0] or "application/octet-stream"
        if ctype.startswith("text/") or ctype in ("application/javascript",):
            ctype += "; charset=utf-8"
        self._send(200, target.read_bytes(), ctype)

    def _sse(self) -> None:
        st = self.studio
        q = st.subscribe()
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Connection", "keep-alive")
        self.send_header("X-Accel-Buffering", "no")
        self.end_headers()
        try:
            self.wfile.write(b": open\n\n")
            self.wfile.flush()
            while True:
                try:
                    msg = q.get(timeout=15)
                except queue.Empty:
                    self.wfile.write(b": ping\n\n")
                    self.wfile.flush()
                    continue
                self.wfile.write(b"data: " + msg.encode("utf-8") + b"\n\n")
                self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError, OSError):
            pass
        finally:
            st.unsubscribe(q)

    # --------------------------------------------------------------- verbs

    def do_GET(self) -> None:  # noqa: N802
        route = urlparse(self.path).path
        st = self.studio
        try:
            if route == "/api/events":
                self._sse()
            elif route == "/api/state":
                self._json(st.snapshot())
            elif route == "/api/history":
                self._json({"records": list(st.history)[-400:]})
            elif route == "/api/inspect":
                self._json(st.inspect())
            elif route == "/api/math":
                self._json(math_curves())
            elif route == "/api/evidence":
                self._json(evidence())
            elif route == "/api/ports":
                self._json({"ports": bl.list_ports()})
            elif route == "/api/board/io":
                self._json(st.board_io())
            elif route == "/api/sweep":
                self._json(st.sweep or {"rows": []})
            elif route == "/api/bench":
                self._json(st.bench or {"runs": []})
            elif route.startswith("/api/"):
                self._json({"error": "unknown endpoint", "route": route}, 404)
            else:
                self._static(route)
        except Exception as exc:
            self._json({"error": str(exc),
                        "trace": traceback.format_exc(limit=4)}, 500)

    def do_POST(self) -> None:  # noqa: N802
        route = urlparse(self.path).path
        st = self.studio
        body = self._body()
        try:
            if route == "/api/seed":
                seed = body.get("seed", 0x11111111)
                if isinstance(seed, str):
                    seed = int(seed, 0)
                self._json(st.reseed(int(seed)))
            elif route == "/api/mode":
                self._json(st.set_mode(bool(body.get("learn")),
                                       bool(body.get("freeze"))))
            elif route == "/api/step":
                a = str(body.get("a", ""))
                b = str(body.get("b", ""))
                if len(a.encode()) < 2 or len(b.encode()) < 2:
                    raise ValueError("each side needs at least 2 bytes "
                                     "(the FPGA rejects shorter sequences)")
                verdict = body.get("verdict")
                same = bool(body.get("same")) if verdict is None else verdict == "reward"
                self._json(st.run_pair(a, b, same, source="manual"))
            elif route == "/api/curriculum":
                items = body.get("items") or []
                clean = []
                for it in items:
                    a, b = str(it.get("a", "")), str(it.get("b", ""))
                    if len(a.encode()) >= 2 and len(b.encode()) >= 2:
                        clean.append({"a": a[:E3_TMAX], "b": b[:E3_TMAX],
                                      "same": bool(it.get("same")),
                                      "note": str(it.get("note", ""))[:120]})
                with st.lock:
                    st.curriculum = clean
                st.publish("curriculum", {"items": clean})
                self._json({"items": clean})
            elif route == "/api/train/start":
                self._json(st.start_training(int(body.get("steps", 32)),
                                             int(body.get("delay_ms", 60))))
            elif route == "/api/train/stop":
                self._json(st.stop_training())
            elif route == "/api/board/connect":
                self._json(st.connect(str(body.get("port", "COM12")),
                                      int(body.get("baud", bl.DEFAULT_BAUD))))
            elif route == "/api/board/disconnect":
                st.disconnect()
                self._json({"connected": False})
            elif route == "/api/board/resync":
                self._json(st.resync())
            elif route == "/api/board/ping":
                self._json(st.ping())
            elif route == "/api/bench/start":
                self._json(st.start_bench(
                    max(40, min(600, int(body.get("entities", 160)))),
                    max(1, min(10, int(body.get("seeds", 3)))),
                    max(1, min(40, int(body.get("epochs", 4)))),
                    bool(body.get("vn"))))
            elif route == "/api/bench/stop":
                st.stop_flag.set()
                self._json({"stopped": True})
            elif route == "/api/bench/epochs":
                self._json({"rows": twinmod_epoch_sweep()})
            elif route == "/api/twin/weight":
                self._json(st.twin_edit(str(body.get("kind", "E")),
                                        int(body.get("index", 0)),
                                        int(body.get("value", 0))))
            elif route == "/api/sweep/start":
                seeds = body.get("seeds") or []
                parsed = [int(s, 0) if isinstance(s, str) else int(s) for s in seeds]
                strings = body.get("strings") or ["ALPHA", "BETA.", "OMEGA"]
                self._json(st.start_sweep(parsed[:64], int(body.get("steps", 32)),
                                          [str(x) for x in strings[:3]]))
            elif route == "/api/sweep/stop":
                st.stop_flag.set()
                self._json({"stopped": True})
            else:
                self._json({"error": "unknown endpoint", "route": route}, 404)
        except Exception as exc:
            self._json({"error": str(exc)}, 400)


def main() -> int:
    ap = argparse.ArgumentParser(description="A7 Native-AI Studio (A7-EAM-03E-A0)")
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--http-port", type=int, default=8770)
    ap.add_argument("--port", default=None, help="serial port, e.g. COM12")
    ap.add_argument("--baud", type=int, default=bl.DEFAULT_BAUD)
    ap.add_argument("--seed", default="0x11111111")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    st = Studio(seed=int(args.seed, 0))
    if args.port:
        try:
            info = st.connect(args.port, args.baud)
            print(f"[board] {info}")
        except Exception as exc:
            print(f"[board] could not attach {args.port}: {exc}")
            print("[board] continuing in twin-only mode")

    gc = golden_check()
    print(f"[twin] law {twinmod.LAW} golden {'PASS' if gc['pass'] else 'FAIL'} "
          f"({len(gc['expected'])} integers)")
    if not gc["pass"]:
        print(f"[twin] MISMATCH {gc['mismatch']} — twin no longer mirrors the RTL")

    Handler.studio = st
    httpd = ThreadingHTTPServer((args.host, args.http_port), Handler)
    url = f"http://{args.host}:{args.http_port}/"
    print(f"[http] A7 Native-AI Studio on {url}")
    print("[http] Ctrl+C to stop")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[http] stopping")
    finally:
        st.stop_flag.set()
        st.disconnect()
        httpd.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
