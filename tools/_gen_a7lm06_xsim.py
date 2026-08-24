from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from python.ref.a7lm06_fixed_ref import TinyGPT803k

out = ROOT / "tests" / "xsim"
out.mkdir(parents=True, exist_ok=True)
m0 = TinyGPT803k(2)
z, pred = m0.forward([1])
loss = m0.last_loss([1], 32)
f0 = m0.fold()
m1 = TinyGPT803k(2)
m1.backward_full([1], 32, lr=3, apply=True)
f1 = m1.fold()
(out / "a7lm06_expected.txt").write_text(
    f"{pred}\n{loss}\n{f0['xor32']}\n{f0['add32']}\n{f1['xor32']}\n{f1['add32']}\n{m1.wr_n if hasattr(m1,'wr_n') else 0}\n",
    encoding="utf-8",
)
# wr_n is on the rec, not the model — write rec wr_n
rec = TinyGPT803k(2).backward_full([1], 32, lr=3, apply=True)
(out / "a7lm06_expected.txt").write_text(
    f"{pred}\n{loss}\n{f0['xor32']}\n{f0['add32']}\n{f1['xor32']}\n{f1['add32']}\n",
    encoding="utf-8",
)
print("pred", pred, "loss", loss, "fold0", f0, "fold1", f1, "wr_n", rec.get("wr_n"))
with (out / "a7lm06_wmem.hex").open("w", encoding="utf-8") as fh:
    for x in TinyGPT803k(2).flat_i8():
        fh.write(f"{x & 0xFF:02x}\n")
print("wrote", out / "a7lm06_wmem.hex")
