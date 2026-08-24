"""Locked Basys LM-05 fixed-point reference. Do not edit the law here.

law_id = lm05-signsgd-v1
Source of truth: python/lm/tiny_gpt_ref.py (copied from Basys LM-05 closeout).
"""
from __future__ import annotations

from python.lm.tiny_gpt_ref import (  # noqa: F401
    ATTN_QK_SHIFT,
    BANK_WORDS,
    BLOCK_DEADZONE,
    C,
    D,
    FF,
    LIN_SHIFT,
    TinyGPT,
    V,
    corpus_loss,
    micro_corpus,
    train_full_sgd,
)

LAW_ID = "lm05-signsgd-v1"
PARAM_COUNT = 2 * V * D + C * D + 1 * (4 * D * D + 2 * D * FF)
assert PARAM_COUNT == 3200
