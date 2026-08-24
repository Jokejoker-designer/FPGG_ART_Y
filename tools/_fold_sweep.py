import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from python.ref.a7lm03_fixed_ref import TinyGPT25k, D, V
from python.lm.quantization import q_weight, q_grad

TARGET = (2, 2955722)


def show(tag, m):
    f = m.fold()
    hit = (f["xor32"], f["add32"]) == TARGET
    mark = " HIT" if hit else ""
    print(f"{tag:28} xor={f['xor32']:5} add={f['add32']}{mark}")


def clone_layers(src):
    return [{k: [r[:] for r in ly[k]] for k in ly} for ly in src.layers]


m = TinyGPT25k(2)
m.backward_full([1], 16, lr=3, apply=True)
show("full_lr3", m)

m = TinyGPT25k(2)
m.backward_head([1], 16, lr=3, apply=True)
show("head_only", m)

m = TinyGPT25k(2)
rec = m.backward_full([1], 16, lr=3, apply=False)
for v in range(V):
    for d in range(D):
        g = q_grad((rec["dZ"][v] * int(rec["y"][d])) // rec["s"])
        m.head[v][d] = q_weight(m.head[v][d] - (g >> 3))
show("manual_head", m)

h0 = [row[:] for row in TinyGPT25k(2).head]
m = TinyGPT25k(2)
m.backward_full([1], 16, lr=3, apply=True)
m.head = [row[:] for row in h0]
show("full_restore_head", m)

b = TinyGPT25k(2)
m = TinyGPT25k(2)
m.backward_full([1], 16, lr=3, apply=True)
m.layers = clone_layers(b)
m.head = [r[:] for r in b.head]
show("only_tok_pos", m)

m = TinyGPT25k(2)
m.backward_full([1], 16, lr=3, apply=True)
m.tok = [r[:] for r in b.tok]
m.pos = [r[:] for r in b.pos]
m.head = [r[:] for r in b.head]
show("only_layers", m)

m = TinyGPT25k(2)
m.backward_full([1], 16, lr=3, apply=True)
m.layers = clone_layers(b)
show("head_and_embed", m)

for lr in (0, 1, 2, 4, 5, 8):
    m = TinyGPT25k(2)
    m.backward_full([1], 16, lr=lr, apply=True)
    show(f"full_lr{lr}", m)

print("target", TARGET)
