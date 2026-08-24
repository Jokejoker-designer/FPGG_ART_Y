from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root))
from python.ref.a7lm04_fixed_ref import TinyGPT100k

root = Path(__file__).resolve().parents[1]
m = TinyGPT100k(2)
(root / "tests/xsim/a7lm04_wmem.hex").write_text(
    "\n".join(f"{b & 255:02x}" for b in m.flat_i8()) + "\n", encoding="utf-8"
)
m2 = TinyGPT100k(2)
_z, p = m2.forward([1])
loss = m2.last_loss([1], 32)
f0 = m2.fold()
m2.backward_full([1], 32, lr=3, apply=True)
f1 = m2.fold()
(root / "tests/xsim/a7lm04_expected.txt").write_text(
    f"{p}\n{loss}\n{f0['xor32']}\n{f0['add32']}\n{f1['xor32']}\n{f1['add32']}\n",
    encoding="utf-8",
)
print("pred", p, "loss", loss, "fold0", f0, "fold1", f1)
