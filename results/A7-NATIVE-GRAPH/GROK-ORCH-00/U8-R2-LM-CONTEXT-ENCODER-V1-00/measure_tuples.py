import re
from collections import Counter, defaultdict

p = r"D:\Jetking_sem4\SEM_4\arty-a7-online-lm-g14-preboard-00\rtl\native_graph\memory\typeclass_table.svh"
t = open(p, encoding="utf-8", errors="replace").read()


def arr(name):
    m = re.search(
        r"localparam logic \[[^\]]+\] " + name + r" \[0:TC_N-1\] = '\{([^}]+)\}",
        t,
    )
    if not m:
        raise SystemExit("missing " + name)
    out = []
    for x in m.group(1).split(","):
        x = x.strip()
        if not x:
            continue
        x = x.replace("16'd", "").replace("8'd", "")
        out.append(int(x))
    return out


eid, iid, rid, xid, cid = (
    arr("TC_EID"),
    arr("TC_IID"),
    arr("TC_RID"),
    arr("TC_XID"),
    arr("TC_ID"),
)
print("N", len(cid), "id1", cid[0], "idN", cid[-1])
keys = Counter(zip(eid, iid, rid, xid))
dups = [(k, v) for k, v in keys.items() if v > 1]
print("unique_tuples", len(keys), "dups", len(dups), "max_mult", max(keys.values()))
by = defaultdict(list)
for i, c in enumerate(cid):
    by[(eid[i], iid[i], rid[i], xid[i])].append(c)
    if 57 <= c <= 71 or c in (1, 2, 254, 256, 427, 443):
        print("CLASS", c, "e", eid[i], "i", iid[i], "r", rid[i], "x", xid[i])
print("dup_examples")
for k, v in dups[:12]:
    print(k, "n=", v, "ids", by[k][:12])
