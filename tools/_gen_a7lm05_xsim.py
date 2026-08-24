import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm05_fixed_ref import TinyGPT399k

out = ROOT / "tests" / "xsim"
m0 = TinyGPT399k(2)
z, p = m0.forward([1])
loss = m0.last_loss([1], 32)
f0 = m0.fold()
m1 = TinyGPT399k(2)
m1.backward_full([1], 32, lr=3, apply=True)
f1 = m1.fold()
(out / "a7lm05_expected.txt").write_text(
    f"{p}\n{loss}\n{f0['xor32']}\n{f0['add32']}\n{f1['xor32']}\n{f1['add32']}\n",
    encoding="utf-8",
)
with (out / "a7lm05_wmem.hex").open("w", encoding="utf-8") as fh:
    for x in TinyGPT399k(2).flat_i8():
        fh.write(f"{x & 255:02x}\n")
print("fwd", p, loss, f0)
print("full", f1)
