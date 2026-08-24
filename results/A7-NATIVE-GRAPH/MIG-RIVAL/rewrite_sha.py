from pathlib import Path
import hashlib

root = Path(r"d:/Jetking_sem4/SEM_4/arty-a7-online-lm")
out = root / "results/A7-NATIVE-GRAPH/MIG-RIVAL"
files = [
    "rtl/native_graph/memory/a7ng_ddr_feed_axi_bridge.sv",
    "rtl/native_graph/memory/a7ng_ddr_feed_mig_top.sv",
    "rtl/native_graph/memory/a7ng_ddr_feed_pp.sv",
    "rtl/native_graph/memory/a7ng_ddr_feed_top.sv",
    "rtl/native_graph/memory/a7ng_ddr_feed_lat_ddr.sv",
    "rtl/ddr/mig_native_wrap.sv",
    "vivado/ip/mig_7series_0/mig_7series_0/mig.prj",
    "tests/xsim/tb_a7ng_ddr_feed_mig.sv",
    "tests/xsim/run_a7ng_ddr_feed_mig.tcl",
]
lines = []
for rel in files:
    p = root / rel
    h = hashlib.sha256(p.read_bytes()).hexdigest().upper()
    lines.append(f"{h}  {rel}")
(out / "SHA256.txt").write_text("\n".join(lines) + "\n", encoding="ascii")

ctrl = []
pairs = [
    (
        "arty_a7_lm06.bit",
        "67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA",
        root / "build/out/arty_a7_lm06.bit",
    ),
    (
        "arty_a7_eam01r.bit",
        "57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF",
        root / "build/out/arty_a7_eam01r.bit",
    ),
    (
        "arty_a7_eam02m.bit",
        "DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696",
        root / "build/out/arty_a7_eam02m.bit",
    ),
    (
        "arty_a7_eam03e_a03.bit",
        "05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09",
        root / "results/A7-EAM-03E/A03_SIGNED/arty_a7_eam03e_a03.bit",
    ),
]
for _name, exp, p in pairs:
    h = hashlib.sha256(p.read_bytes()).hexdigest().upper()
    m = "MATCH" if h == exp else "MISMATCH"
    ctrl.append(f"{m}  {h}  {p.as_posix()}")
(out / "frozen_sha_control.txt").write_text("\n".join(ctrl) + "\n", encoding="ascii")

mig = root / "vivado/ip/mig_7series_0/mig_7series_0/mig.prj"
mh = hashlib.sha256(mig.read_bytes()).hexdigest().upper()
(out / "mig_prj_sha256.txt").write_text(
    f"{mh}  mig.prj\nPortInterface=AXI\nhand_edit=NO\n", encoding="ascii"
)
print("sha_rows", len(lines))
print("frozen_all_match", all(l.startswith("MATCH") for l in ctrl))
print("mig", mh)
print("primary", lines[1].split()[0])  # mig_top
