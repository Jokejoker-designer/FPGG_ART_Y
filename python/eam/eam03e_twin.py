"""A7-EAM-03E-A0 host twin — arithmetic mirror of ``rtl/eam/eam03e_core.sv``.

Law ``eam03e-a0-signsgd-v1``. This module exists so a UI can *show* the internal
state (h, gradients, weight deltas) that the 20-byte UART reply does not carry.

AUTHORITY: ILLUSTRATION ONLY.

    The board is the only authority for evidence. This twin never talks to the
    FPGA, never uploads weights, and must not be quoted as silicon evidence.
    Host-computed gradients are legal here *because* nothing is sent to the
    board; the contract forbids the host computing the update inside an
    evidence run, not inside a teaching visualiser.

The twin reproduces five quirks of the frozen RTL on purpose. Quirks 1, 2, 4 and 5
are pinned by :func:`golden_check`: ablating any of them misses all seven A0.1-T
integers, so removing them is a law change, not a cleanup. Quirk 3 is a
*prediction* — no golden constrains ``dH``, so silicon can falsify it:

1. **Forward embedding read is off by one.** ``S_EISS`` latches ``e_ra`` at the
   end of its cycle while ``e_q`` still holds the previous address, so
   ``e_lat[j] == E[b][j-1]`` for j>=1 and ``e_lat[0]`` is a leftover read of
   ``E[b_prev][31]``. ``E[b][31]`` is never consumed by the forward pass. The
   update path reads correctly because ``S_ELAT2`` acts as the wait state.
2. **The state update is unsigned.** In
   ``e3_sat16((acc + {{8{e[7]}}, e, 8'd0}) >>> 8)`` the concatenation is an
   unsigned 24-bit value, so per IEEE 1800 the whole addition is unsigned and
   ``>>>`` degrades to a logical shift. A negative embedding becomes a large
   positive number, and the result is never negative:
   **h[k] is always in [0, 32767]**, usually pinned at 32767 once ``acc`` is
   large. The "Elman recurrence" therefore behaves as a saturating positive
   counter, not a signed state.
3. **The cue comparison is unsigned too.** ``(psum +- concat) > 32'sd0`` mixes an
   unsigned 32-bit concat with a signed zero, so the test collapses to
   ``!= 0``. Combined with (2) the 64-bit cue would be all-ones and ``dH`` would
   read 0, making ``dH`` unusable on this bitstream. The frozen goldens only pin
   ``d1``, so nothing in A0.1-T depends on this either way — which also means a
   board read of ``dH`` or ``cue`` can prove this reading wrong.
4. ``d1`` differences wrap in 16 bits before ``abs``, then shift right by 5.
5. ``Wh`` is updated from ``gB`` only, against ``hprev`` of B's last token.

``S_SEED`` does not reset ``e_ra``, so a reseed inherits the previous pair's
address. The very first pair after power-on reads an uninitialised register (X in
xsim); ``tests/xsim/tb_a7eam03e.sv`` discards it as a prime step, and so does
:meth:`Eam03eTwin.pair` when ``prime=True``.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from operator import mul
from typing import Sequence

LAW = "eam03e-a0-signsgd-v1"

E3_D = 32          # state width
E3_P = 64          # projection bits
E3_VOC = 256       # byte vocabulary
E3_TMAX = 46       # max sequence length
E3_SH = 8          # Elman shift
E3_MARG = 4096     # DIFF gate on quantised d1
E3_SEED0 = 0xA7E03EA1

E_SIZE = E3_VOC * E3_D   # 8192 INT8
WH_SIZE = E3_D * E3_D    # 1024 INT8


# --------------------------------------------------------------------------- #
# fixed-point helpers (mirror a7eam03e_pkg.sv)
# --------------------------------------------------------------------------- #

def s16(x: int) -> int:
    """Wrap to a 16-bit signed register."""
    return ((x + 0x8000) & 0xFFFF) - 0x8000


def sat16(x: int) -> int:
    if x > 32767:
        return 32767
    if x < -32768:
        return -32768
    return x


def sat8(x: int) -> int:
    if x > 127:
        return 127
    if x < -128:
        return -128
    return x


def sgn8(g: int) -> int:
    if g > 0:
        return 1
    if g < 0:
        return -1
    return 0


def abs16(x: int) -> int:
    """``e3_abs16``: 16-bit wrap, then unsigned magnitude."""
    a = s16(x)
    return (-a) & 0xFFFF if a < 0 else a & 0xFFFF


def h_update(acc_k: int, e_k: int) -> int:
    """``e3_sat16((acc + {{8{e[7]}}, e, 8'd0}) >>> E3_SH)`` with SV signedness.

    The 24-bit concatenation is unsigned, so the add is unsigned and the shift is
    logical. Consequence: the result is never negative. See module docstring (2).
    """
    concat24 = ((e_k & 0xFFFF) << 8) & 0xFFFFFF
    v = (acc_k + concat24) & 0xFFFFFFFF
    x = v >> E3_SH
    if x >= 1 << 31:
        x -= 1 << 32
    return sat16(x)


def xorshift(s: int) -> int:
    x = s & 0xFFFFFFFF
    x ^= (x << 13) & 0xFFFFFFFF
    x &= 0xFFFFFFFF
    x ^= x >> 17
    x ^= (x << 5) & 0xFFFFFFFF
    x &= 0xFFFFFFFF
    return E3_SEED0 if x == 0 else x


def _i8(byte_val: int) -> int:
    return byte_val - 256 if byte_val >= 128 else byte_val


# --------------------------------------------------------------------------- #
# telemetry records
# --------------------------------------------------------------------------- #

@dataclass
class ForwardTrace:
    """One encoder forward pass, per token."""

    text: str
    tokens: list[int] = field(default_factory=list)
    states: list[list[int]] = field(default_factory=list)   # h after each token
    embeds: list[list[int]] = field(default_factory=list)   # e_lat actually used
    h_final: list[int] = field(default_factory=list)
    hprev: list[int] = field(default_factory=list)
    cue: int = 0
    proj_margins: list[int] = field(default_factory=list)   # signed sums per bit
    h_saturated: int = 0    # coords pinned at 32767 (see quirk 2)
    # RTL acc is `logic signed [31:0]` with no saturation, so runaway shows up as
    # silent wrap rather than a rail. Recorded pre-mask to make that visible.
    acc_max_abs: int = 0
    acc_wrapped: int = 0


@dataclass
class PairTrace:
    """One PAIR transaction: forward A, forward B, distance, optional update."""

    same: bool
    learn: bool
    freeze: bool
    updated: bool
    prime: bool
    d1: int
    dH: int
    a: ForwardTrace
    b: ForwardTrace
    gA: list[int] = field(default_factory=list)
    gB: list[int] = field(default_factory=list)
    diff_gate_open: bool = False
    e_writes: int = 0
    wh_writes: int = 0
    e_delta_by_byte: dict[int, list[int]] = field(default_factory=dict)
    wh_delta: list[int] = field(default_factory=list)

    def as_reply(self) -> dict:
        """Same shape the 0xA3 UART reply gives, so the UI can treat both alike."""
        return {
            "kind": 0xA3,
            "dH": self.dH,
            "d1": self.d1,
            "cue": self.b.cue,
            "learn": self.learn,
            "freeze": self.freeze,
            "updated": self.updated,
        }


# --------------------------------------------------------------------------- #
# the twin
# --------------------------------------------------------------------------- #

class Eam03eTwin:
    """Host mirror of ``eam03e_core.sv``. Integer-exact, cycle-agnostic."""

    def __init__(self, seed: int = E3_SEED0) -> None:
        self.law = LAW
        self.seqA: list[int] = []
        self.seqB: list[int] = []
        self.learn = False
        self.freeze = False
        self.pair_count = 0
        self.update_count = 0
        self.reseed(seed)

    # ---------------------------------------------------------------- seeding

    def reseed(self, seed: int = E3_SEED0) -> int:
        """``S_SEED``: 9280 xorshift steps fill E, Wh and the projection rows."""
        seed = seed & 0xFFFFFFFF
        if seed == 0:
            seed = E3_SEED0
        self.seed = seed
        # e_ra has no reset in RTL and S_SEED never writes it, so a reseed
        # inherits the previous pair's address. Only power-on leaves it undefined
        # (X in xsim); 0 keeps the twin deterministic and the pair is a prime.
        if not hasattr(self, "e_ra"):
            self.e_ra = 0
            self.needs_prime = True
        self.E = [0] * E_SIZE
        self.Wh = [0] * WH_SIZE
        self.Prow = [0] * E3_P

        lfsr = seed
        for sa in range(9280):
            cur = lfsr
            lfsr = xorshift(lfsr)
            if sa < 8192:
                self.E[sa] = _i8(cur & 0xFF)
            elif sa < 9216:
                self.Wh[sa - 8192] = _i8((cur >> 8) & 0xFF)
            else:
                # RTL stores the *next* xorshift value into Prow.
                self.Prow[sa - 9216] = lfsr

        self.pair_count = 0
        self.update_count = 0
        return self.seed

    # ------------------------------------------------------------------- I/O

    def buf(self, slot: int, data: bytes | str) -> int:
        """``CMD 0x22``: load slot 0 (A) or 1 (B). Truncates at E3_TMAX like RTL."""
        if isinstance(data, str):
            data = data.encode("utf-8")
        seq = list(data[:E3_TMAX])
        if slot == 0:
            self.seqA = seq
        else:
            self.seqB = seq
        return len(seq)

    def mode(self, learn: bool, freeze: bool) -> None:
        """``CMD 0x20``."""
        self.learn = bool(learn)
        self.freeze = bool(freeze)

    def teacher_off(self) -> None:
        """``CMD 0x13``: learn=0, freeze=1."""
        self.learn = False
        self.freeze = True

    # --------------------------------------------------------------- forward

    def _forward(self, seq: Sequence[int], text: str) -> ForwardTrace:
        tr = ForwardTrace(text=text, tokens=list(seq))
        h = [0] * E3_D
        hprev = [0] * E3_D

        for b in seq:
            base = b * E3_D
            # quirk 1: rotated embedding read
            e_lat = [self.E[self.e_ra]]
            e_lat += [self.E[base + (j - 1)] for j in range(1, E3_D)]
            self.e_ra = base + E3_D - 1

            # map(mul, ...) rather than a genexp: the benchmark runs this 1024
            # times per input byte and the C-level loop is ~3x faster.
            wh = self.Wh
            acc = [sum(map(mul, wh[i:i + E3_D], h))
                   for i in range(0, WH_SIZE, E3_D)]

            for a in acc:
                mag = a if a >= 0 else -a
                if mag > tr.acc_max_abs:
                    tr.acc_max_abs = mag
                if mag >= 1 << 31:
                    tr.acc_wrapped += 1

            hprev = list(h)
            h = [h_update(acc[k], e_lat[k]) for k in range(E3_D)]

            tr.embeds.append(e_lat)
            tr.states.append(list(h))

        tr.h_final = list(h)
        tr.hprev = list(hprev)
        tr.h_saturated = sum(1 for v in h if v == 32767)

        # +-1 projection -> 64-bit cue
        cue = 0
        for pk in range(E3_P):
            row = self.Prow[pk]
            s = 0
            for j in range(E3_D):
                s += h[j] if (row >> j) & 1 else -h[j]
            tr.proj_margins.append(s)
            # quirk 3: unsigned compare -> "!= 0", not "> 0"
            if (s & 0xFFFFFFFF) != 0:
                cue |= 1 << pk
        tr.cue = cue
        return tr

    def encode(self, slot: int = 0) -> ForwardTrace:
        """``CMD 0x24``: forward one slot, no distance, no update."""
        seq = self.seqA if slot == 0 else self.seqB
        return self._forward(seq, self._text(seq))

    @staticmethod
    def _text(seq: Sequence[int]) -> str:
        return bytes(seq).decode("utf-8", errors="replace")

    # ------------------------------------------------------------------ pair

    def pair(self, same: bool, prime: bool = False) -> PairTrace:
        """``CMD 0x23``: forward both slots, measure, then maybe SignSGD."""
        a = self._forward(self.seqA, self._text(self.seqA))
        b = self._forward(self.seqB, self._text(self.seqB))

        hA, hB = a.h_final, b.h_final

        d1 = 0
        for i in range(E3_D):
            ad = abs16(hA[i] - hB[i]) >> 5
            d1 = 0xFFFF if d1 > 0xFFFF - ad else d1 + ad
        dH = (a.cue ^ b.cue).bit_count()

        gate_open = d1 < E3_MARG
        if same:
            gA = [s16(hA[k] - hB[k]) for k in range(E3_D)]
            gB = [s16(hB[k] - hA[k]) for k in range(E3_D)]
        elif gate_open:
            gA = [s16(hB[k] - hA[k]) for k in range(E3_D)]
            gB = [s16(hA[k] - hB[k]) for k in range(E3_D)]
        else:
            gA = [0] * E3_D
            gB = [0] * E3_D

        do_upd = self.learn and not self.freeze
        tr = PairTrace(
            same=bool(same),
            learn=self.learn,
            freeze=self.freeze,
            updated=bool(do_upd),
            prime=bool(prime or self.needs_prime),
            d1=d1,
            dH=dH,
            a=a,
            b=b,
            gA=gA,
            gB=gB,
            diff_gate_open=gate_open,
        )

        if do_upd:
            self._update(tr, b.hprev)
            self.update_count += 1

        self.pair_count += 1
        self.needs_prime = False
        return tr

    def _update(self, tr: PairTrace, hprev: list[int]) -> None:
        """Broadcast SignSGD on E, then last-step SignSGD on Wh."""
        e_before = {}
        for which, (seq, g) in enumerate(((self.seqA, tr.gA), (self.seqB, tr.gB))):
            for b in seq:
                if b not in e_before:
                    e_before[b] = self.E[b * E3_D:(b + 1) * E3_D]
            for b in seq:
                base = b * E3_D
                for i in range(E3_D):
                    self.e_ra = base + i
                    s = sgn8(g[i])
                    if s != 0:
                        self.E[base + i] = sat8(self.E[base + i] - s)
                        tr.e_writes += 1

        for b, before in e_before.items():
            after = self.E[b * E3_D:(b + 1) * E3_D]
            tr.e_delta_by_byte[b] = [after[i] - before[i] for i in range(E3_D)]

        wh_before = list(self.Wh)
        for i in range(E3_D):
            gi = tr.gB[i]
            if sgn8(gi) == 0:
                continue
            row = i * E3_D
            for j in range(E3_D):
                hj = hprev[j]
                if hj == 0:
                    continue
                wdelta = 1 if (gi < 0) == (hj < 0) else -1
                self.Wh[row + j] = sat8(self.Wh[row + j] - wdelta)
                tr.wh_writes += 1
        tr.wh_delta = [self.Wh[k] - wh_before[k] for k in range(WH_SIZE)]

    # ------------------------------------------------------------- summaries

    def weight_stats(self) -> dict:
        e_abs = [abs(v) for v in self.E]
        w_abs = [abs(v) for v in self.Wh]
        return {
            "E_sum_abs": sum(e_abs),
            "E_max_abs": max(e_abs),
            "E_saturated": sum(1 for v in self.E if v in (-128, 127)),
            "Wh_sum_abs": sum(w_abs),
            "Wh_max_abs": max(w_abs),
            "Wh_saturated": sum(1 for v in self.Wh if v in (-128, 127)),
        }

    def eval_telemetry(self, h: Sequence[int]) -> dict:
        """A0.2-L EVAL block for one vector. Telemetry only, never TRAIN input."""
        n = len(h) or 1
        abs_h = [abs(v) for v in h]
        return {
            "n1": sum(abs_h),
            "n2sq": sum(v * v for v in h),
            "max_abs": max(abs_h) if h else 0,
            "mean_abs": sum(abs_h) // n,
            "saturated": sum(1 for v in h if v == 32767),
        }

    def measure(self, text_a: str, text_b: str, same: bool) -> PairTrace:
        """BUF A, BUF B, PAIR — the host ladder's ``measure()`` sequence."""
        self.buf(0, text_a)
        self.buf(1, text_b)
        return self.pair(same)


# --------------------------------------------------------------------------- #
# golden self-check (frozen A0.1-T integers)
# --------------------------------------------------------------------------- #

GOLDEN_A01T = {
    "seed": 0x11111111,
    "strings": ("ALPHA", "BETA.", "OMEGA"),
    "train_steps": 32,
    "init_AB": 3930,
    "init_AC": 5362,
    "train_AB": 1093,
    "train_AC": 2012,
    "reset_AB": 3930,
    "swap_AC": 451,
    "swap_AB": 1574,
}


def golden_check() -> dict:
    """Replay ``tests/xsim/tb_a7eam03e.sv`` on the twin and compare integers."""
    sa, sb, sc = GOLDEN_A01T["strings"]
    steps = GOLDEN_A01T["train_steps"]
    got: dict[str, int] = {}

    t = Eam03eTwin()
    t.reseed(GOLDEN_A01T["seed"])
    t.mode(learn=False, freeze=False)

    t.buf(0, sa)
    t.buf(1, sb)
    t.pair(True, prime=True)          # prime, discarded by the TB
    got["init_AB"] = t.pair(True).d1
    t.buf(1, sc)
    got["init_AC"] = t.pair(False).d1

    t.mode(learn=True, freeze=False)
    for _ in range(steps):
        t.measure(sa, sb, True)
        t.measure(sa, sc, False)

    t.mode(learn=False, freeze=True)
    got["train_AB"] = t.measure(sa, sb, True).d1
    got["train_AC"] = t.measure(sa, sc, False).d1

    t.reseed(GOLDEN_A01T["seed"])
    t.mode(learn=False, freeze=False)
    t.buf(0, sa)
    t.buf(1, sb)
    t.pair(True, prime=True)
    got["reset_AB"] = t.pair(True).d1

    t.mode(learn=True, freeze=False)
    for _ in range(steps):
        t.measure(sa, sc, True)
        t.measure(sa, sb, False)

    t.mode(learn=False, freeze=True)
    got["swap_AC"] = t.measure(sa, sc, True).d1
    got["swap_AB"] = t.measure(sa, sb, False).d1

    keys = ("init_AB", "init_AC", "train_AB", "train_AC",
            "reset_AB", "swap_AC", "swap_AB")
    mismatch = {k: (GOLDEN_A01T[k], got[k]) for k in keys if GOLDEN_A01T[k] != got[k]}
    return {
        "law": LAW,
        "expected": {k: GOLDEN_A01T[k] for k in keys},
        "got": got,
        "mismatch": mismatch,
        "pass": not mismatch,
    }


def dot(ha: Sequence[int], hb: Sequence[int]) -> int:
    return sum(a * b for a, b in zip(ha, hb, strict=True))


def cosine(ha: Sequence[int], hb: Sequence[int]) -> float:
    na = sum(v * v for v in ha)
    nb = sum(v * v for v in hb)
    if na == 0 or nb == 0:
        return 0.0
    return dot(ha, hb) / ((na * nb) ** 0.5)


def triplet_report(seed: int, anchor: str, pos: str, neg: str,
                   steps: int = 32) -> dict:
    """Run the A0/L0 ladder on one seed and report the A0.2-L hypothesis block.

    ``M_L1 = d1(A,N) - d1(A,P)`` and ``M_cos = cos(A,P) - cos(A,N)``.
    Both must be > 0 for the A0.2-L per-seed gate. Twin numbers only.
    """
    t = Eam03eTwin()
    t.reseed(seed)
    t.mode(learn=False, freeze=False)
    t.measure(anchor, pos, True)                 # prime

    pre_p = t.measure(anchor, pos, True)
    pre_n = t.measure(anchor, neg, False)

    t.mode(learn=True, freeze=False)
    for _ in range(steps):
        t.measure(anchor, pos, True)
        t.measure(anchor, neg, False)

    t.mode(learn=False, freeze=True)
    post_p = t.measure(anchor, pos, True)
    post_n = t.measure(anchor, neg, False)

    def block(tp, tn) -> dict:
        cos_p = cosine(tp.a.h_final, tp.b.h_final)
        cos_n = cosine(tn.a.h_final, tn.b.h_final)
        return {
            "d1_pos": tp.d1,
            "d1_neg": tn.d1,
            "M_L1": tn.d1 - tp.d1,
            "cos_pos": round(cos_p, 6),
            "cos_neg": round(cos_n, 6),
            "M_cos": round(cos_p - cos_n, 6),
            "dH_pos": tp.dH,
            "anchor": t.eval_telemetry(tp.a.h_final),
            "pos": t.eval_telemetry(tp.b.h_final),
            "neg": t.eval_telemetry(tn.b.h_final),
        }

    pre, post = block(pre_p, pre_n), block(post_p, post_n)
    return {
        "law": LAW,
        "seed": f"0x{seed:08X}",
        "strings": [anchor, pos, neg],
        "steps": steps,
        "pre": pre,
        "post": post,
        "gates": {
            "d_pos_shrank": post["d1_pos"] < pre["d1_pos"],
            "M_L1_post_positive": post["M_L1"] > 0,
            "M_cos_post_positive": post["M_cos"] > 0,
            "diff_not_collapsed": post["d1_neg"] >= post["d1_pos"],
        },
    }


if __name__ == "__main__":
    import json

    res = golden_check()
    print(json.dumps(res, indent=2))
    print("A7EAM03E_TWIN_GOLDEN_PASS" if res["pass"] else "A7EAM03E_TWIN_GOLDEN_FAIL")
    raise SystemExit(0 if res["pass"] else 1)
