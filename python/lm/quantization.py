"""Fixed-point contract for BUILD_PROFILE=LM. Not used by LEGACY bits."""
from __future__ import annotations

WEIGHT_BITS = 8
ACT_BITS = 16
ACC_BITS = 32
GRAD_BITS = 16
WEIGHT_MIN = -128
WEIGHT_MAX = 127
ACT_MIN = -(1 << (ACT_BITS - 1))
ACT_MAX = (1 << (ACT_BITS - 1)) - 1
ACC_MIN = -(1 << (ACC_BITS - 1))
ACC_MAX = (1 << (ACC_BITS - 1)) - 1
GRAD_MIN = -(1 << (GRAD_BITS - 1))
GRAD_MAX = (1 << (GRAD_BITS - 1)) - 1
OPTIMIZER = "SGD"


def sat(v: int, lo: int, hi: int) -> int:
    return lo if v < lo else hi if v > hi else int(v)


def q_weight(v: int) -> int:
    return sat(v, WEIGHT_MIN, WEIGHT_MAX)


def q_act(v: int) -> int:
    return sat(v, ACT_MIN, ACT_MAX)


def q_acc(v: int) -> int:
    return sat(v, ACC_MIN, ACC_MAX)


def q_grad(v: int) -> int:
    return sat(v, GRAD_MIN, GRAD_MAX)
