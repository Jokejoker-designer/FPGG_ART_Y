from pathlib import Path

root = Path(r"d:/Jetking_sem4/SEM_4/arty-a7-online-lm")
mig = root / "vivado/ip/mig_7series_0/mig_7series_0"
outdir = root / "results/A7-NATIVE-GRAPH/MIG-RIVAL"
outdir.mkdir(parents=True, exist_ok=True)
lines = ["# mig_h_rival Digilent AXI MIG - do not hand-edit mig.prj"]
for f in [
    "rtl/native_graph/pkg/a7ng_pkg.sv",
    "rtl/native_graph/memory/a7ng_mem_schema_v1.sv",
    "rtl/native_graph/memory/a7ng_ddr_feed_pp.sv",
    "rtl/native_graph/memory/a7ng_ddr_feed_axi_bridge.sv",
    "rtl/native_graph/memory/a7ng_ddr_feed_mig_top.sv",
    "rtl/ddr/mig_native_wrap.sv",
    "tests/xsim/tb_a7ng_ddr_feed_mig.sv",
]:
    lines.append(f'sv work "{(root / f).as_posix()}"')
rtl = mig / "user_design/rtl"
for f in sorted(rtl.rglob("*.v")):
    if f.name in ("mig_7series_0_mig.v", "mig_7series_0_mig_sim.v"):
        continue
    lines.append(f'verilog work "{f.as_posix()}"')
lines.append(f'verilog work "{(rtl / "mig_7series_0_mig_sim.v").as_posix()}"')
lines.append(f'verilog work "{(mig / "example_design/sim/wiredly.v").as_posix()}"')
lines.append(
    f'sv work "{(mig / "example_design/sim/ddr3_model.sv").as_posix()}" -d x2Gb -d sg15E -d x16'
)
lines.append('verilog work "C:/2026.1/Vivado/data/verilog/src/glbl.v"')
prj = outdir / "mig_feed_xsim.prj"
prj.write_text("\n".join(lines) + "\n", encoding="ascii")
print(f"WROTE {prj} lines={len(lines)}")
