import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from python.ref.a7lm03_fixed_ref import TinyGPT25k, board_corpus, train_full_sgd

pairs = board_corpus(32)
for ep, lr in ((16, 8), (24, 8), (16, 5), (24, 5), (32, 6)):
    r = train_full_sgd(TinyGPT25k(2), pairs, epochs=ep, lr=lr)
    print(ep, lr, round(r["drop"], 4), r["loss0"], r["loss1"], r["all_moved"], flush=True)
