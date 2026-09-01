import re, sys
from pathlib import Path
rtl = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
fails = []
block = re.search(r"module\s+a7ng_causal_learn_fast\b.*?\)\s*;", rtl, re.S)
src = block.group(0) if block else rtl
inputs = re.findall(r"input\s+(?:logic\s+)?(?:signed\s+)?(?:\[[^\]]+\]\s+)?(?:a7ng_pkg::\w+\s+)?(\w+)", src)
for f in ("delta_i", "learn_delta_i", "idx_i", "addr_i", "cue_i", "contradict_i"):
    if f in inputs:
        fails.append("forbidden host input " + f)
if "reward_i" not in inputs:
    fails.append("missing reward_i")
print("AUDIT inputs=" + ",".join(inputs))
if fails:
    print("INTERFACE_AUDIT_FAIL " + " | ".join(fails))
    sys.exit(2)
print("INTERFACE_AUDIT_PASS host reward-only (plus query_id teacher question)")
sys.exit(0)
