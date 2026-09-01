# Static interface audit: host-authority delta/index/address ports are a FAIL.
# PROGRAM=NO. Run before xvlog.
import re
import sys
from pathlib import Path

rtl = Path(sys.argv[1])
text = rtl.read_text(encoding="utf-8", errors="replace")
fails = []

if "*" in text:
    fails.append("DUT contains '*' (DSP-risk multiply or other)")

port_block = re.search(r"module\s+a7ng_context_delta\b.*?\)\s*;", text, re.S)
if not port_block:
    fails.append("could not parse module port list")
    ports_src = text
else:
    ports_src = port_block.group(0)

inputs = re.findall(r"input\s+(?:logic\s+)?(?:signed\s+)?(?:\[[^\]]+\]\s+)?(\w+)", ports_src)
outputs = re.findall(r"output\s+(?:logic\s+)?(?:signed\s+)?(?:\[[^\]]+\]\s+)?(\w+)", ports_src)
names = set(inputs) | set(outputs)

forbidden = [
    "delta_i",
    "learn_delta_i",
    "learn_delta",
    "idx_i",
    "winner",
    "way_i",
    "addr_i",
    "address_i",
    "cue_i",
    "answer_i",
    "item_id",
]
for f in forbidden:
    if f in names:
        fails.append("forbidden port " + f)
    # host-authority: an INPUT named like delta/idx/addr
for n in inputs:
    if n in ("delta_i", "learn_delta_i", "idx_i", "addr_i", "address_i", "cue_i"):
        fails.append("forbidden input " + n)

if "delta_o" not in names:
    fails.append("missing FPGA delta_o")
if "in_native_conf" not in names:
    fails.append("missing FPGA native_conf input")

print("AUDIT inputs=" + ",".join(inputs))
print("AUDIT outputs=" + ",".join(outputs))
if fails:
    print("INTERFACE_AUDIT_FAIL " + " | ".join(fails))
    sys.exit(2)
print("INTERFACE_AUDIT_PASS no host delta/index/address port")
sys.exit(0)
