---
name: a7-fpga-gate
description: >-
  Operating reference for the Arty A7-100T Native AI V1 program: toolchain paths,
  Vivado/XSim/JTAG command recipes, numeric gate definitions, the frozen
  bitstream SHA registry, evidence classification rules and current milestone
  state. Read this before running any FPGA flow, before archiving a result
  directory, and before writing any status claim. Trigger terms: Arty A7,
  xc7a100t, eam03e, A0.1-T, Phase S, A0.2-L, KIDI, NATIVE-V1, LM-06, 01R, 02M,
  WNS, TNS, golden, bitstream, teacher-off, frozen bit.
---

# Arty A7 Native AI — gate and toolchain reference

Repository: `D:\Jetking_sem4\SEM_4\arty-a7-online-lm`

**MUST READ FIRST (before this skill’s recipes and before `final.md`):**

```text
MUST_READ_UNBLOCK_H5.md
results/A7-EAM-03E/MUST_READ_UNBLOCK_H5.md
```

H5: DIFF gated by `d1 < E3_MARG` empties the metric. S2 Wh-clamp FALSIFIED. Do not tighten clamp. Next = ungated DIFF twin (`eam03e-a03-ungated-diff-v1`), one unknown.

Constitution: `results/A7-EAM-03E/final.md`. Read it in full before any RTL or
tool edit; execute its phases in order.

Authority order: board evidence > `docs/contracts/A7-*.md` > immutable
BOARD_PASS releases > `final.md` > research-branch docs > papers or chat.
An AI cannot declare BOARD_PASS (`AGENTS.md`).

## Toolchain

| Item | Path |
|------|------|
| Vivado 2026.1 | `C:\2026.1\Vivado\bin\vivado.bat` |
| xvlog / xelab / xsim | `C:\2026.1\Vivado\bin\` |
| Vitis 2026.1 | `C:\2026.1\Vitis\bin\vitis.bat` |
| hw_server | `C:\2026.1\Vitis\bin\hw_server.bat` (port 3121) |
| License | `D:\Xilinx\licenses\vivado_basic.lic` |

The license is **node-locked to the Wi-Fi adapter MAC `EC2E98DE7927`**. Disabling
Wi-Fi breaks checkout even with Ethernet up. Valid to 13-aug-2027, includes
Simulation, Synthesis and Implementation.

Set before every batch run:

```powershell
$env:XILINXD_LICENSE_FILE = 'D:\Xilinx\licenses\vivado_basic.lic'
```

MCP servers configured in `.cursor/mcp.json`: `vivado` (30 tools, isolated venv
at `E:\agents\mcp-servers\venvs\vivado-mcp`) and `vitis` (28 tools, global
python). They run different MCP SDK majors on purpose — do not install
`vivado-mcp` into the global environment, it upgrades `mcp` past 2.0 and breaks
`vitis-mcp`.

## Board

Arty A7-100T, `xc7a100tcsg324-1`, JTAG serial `210319BE776EA`, UART COM12 @
115200. Detect before any silicon step; never assume it is attached:

```powershell
[System.IO.Ports.SerialPort]::GetPortNames()   # expect COM12
```

PYNQ-Z2 (`1234-TUL`, `xc7z020`, COM6) is a different lane and must never be
programmed from here. The `vivado` MCP `program_device` tool does not pin a JTAG
serial; program via `vivado/tcl/program_a7eam03e.tcl` or after an explicit
`hw_select_target`.

## Recipes

```powershell
# XSim A0.1-T regression
cmd /c "call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source tests\xsim\run_a7eam03e.tcl"

# full implementation (writes build/out/arty_a7_eam03e.bit)
cmd /c "call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source vivado\tcl\build_a7eam03e.tcl"

# program the board
cmd /c "call C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source vivado\tcl\program_a7eam03e.tcl"

# silicon ladder, STEPS=32
python tools\a7eam03e_a0_silicon.py

# host twin oracle check + long-horizon stability sweep
python -m pytest tests\golden\test_eam03e_twin.py -q
python tools\a7eam03e_stability.py
python tools\a7eam03e_rootcause.py
```

Cheap RTL lint without a full build, useful for a new module:

```powershell
cmd /c "call C:\2026.1\Vivado\bin\xvlog.bat -sv <files>"
cmd /c "call C:\2026.1\Vivado\bin\xelab.bat <top> -s <snapshot>"
```

Clean up `xsim.dir`, `.jou`, `.pb`, `.wdb`, stray `.log` and `vivado_pid*.str`
afterwards.

## Numeric gates

| Gate | Threshold |
|------|-----------|
| WNS | >= 0 ns |
| TNS | = 0 ns |
| DSP | = 0 |
| WHS / THS | report; negative hold is a finding |
| Golden integers | exact, no tolerance |

A0.1-T golden, law `eam03e-a0-signsgd-v1`, seed `0x11111111`, 32 steps, strings
`ALPHA` / `BETA.` / `OMEGA`:

| Phase | d1(AB) | d1(AC) |
|-------|-------:|-------:|
| seed + prime | 3930 | 5362 |
| after 32× BETA=SAME | 1093 | 2012 |
| after RESEED | 3930 | — |
| after 32× OMEGA=SAME | 1574 | 451 |

Marker `A7EAM03EA01T_XSIM_PASS`. Known bad seed `0x22222222`:
SAME 2135→1487, DIFF 1679→229, `M_L1 = -1258`.

**These integers belong to `eam03e-a0-signsgd-v1` and are never edited.** A
changed numerical law needs a new law id, a new contract frozen before coding,
and its own golden bag.

## Frozen bitstream registry — never overwrite

| Bit | SHA256 |
|-----|--------|
| `arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` |
| `arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` |
| `arty_a7_lm05.bit` | `1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51` |
| `arty_a7_lm06c3.bit` | `222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6` |
| A0.1-T `eupd` | `ADD9E46280A697FD40C46911F5E477EF5B3A02EF36FE8054F9642216951C2262` |
| A0.1-T `A01T_CLOSE` | `80F2ED9E0C1A1679F87D5362F2D953258DEF640C6C2079E41B7BFBD7BCD12F41` |
| A0.3 `arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` |

Verify by SHA256, not filename. `build/out/` is a scratch area and gets
overwritten by builds; check a bit is archived elsewhere before rebuilding.
`parse_bit_header` from the `vivado` MCP reads design name, part, build time and
SHA256 offline and is the cheapest guard against programming the wrong bit.

## Evidence discipline

Label every quantitative claim EVIDENCE, ENGINEERING_INFERENCE,
NEEDS_EXPERIMENT or FALSE_OR_OVERCLAIM.

Keep XSim, reference model (host twin) and board evidence in separate sections.
Never merge them and never describe simulation as silicon. The host twin is
admissible only while `golden_check()` reproduces all seven integers exactly.

`FITS != RUNS != TRAINS != CONVERGES != USEFUL`.

A metric that improves because the thing it measures collapsed is a FAIL:
watch `effective_rank`, saturation and `unique_d1_count` next to any AUC or
`M_L1` improvement.

## Result directory layout

`results/<MILESTONE>/<LANE>/` containing, where relevant: `manifest.json`,
`closeout.md`, route timing report, utilisation report, test-ladder JSON, seed
list, dataset SHA, bit SHA, source SHA, host-tool SHA, before/after metrics,
board transcript, failure notes.

Existing lanes: `A01T_CLOSE`, `A02_STABILITY`, `A03_SIGNED`. Planned:
ungated-DIFF law, then `A02_L`, `A1`, and under `results/A7-NATIVE-V1/`:
`KIDI`, `INTEGRATION`, `SCALE_800K`.

## Parameter accounting — never summed

```
P_LM              = 802816
P_encoder         = 9216      (E 256x32 = 8192, Wh 32x32 = 1024)
P_total_trainable = 812032    (only if both stay trainable)
N_episodes        = measured
episode_storage   = measured bytes
index_storage     = measured bytes
```

The fixed binary projection is not trainable. Episodes are learned memory
records, not parameters. "1.6M parameter AI" is a forbidden phrase.

## Current state

| Milestone | State | Artifact |
|-----------|-------|----------|
| A7-EAM-01R / 02M | FROZEN / BOARD_PASS | do not rebuild |
| A7-LM-00…06 | FROZEN / BOARD_PASS | do not rebuild |
| A0.1-T | all 5 gates met: XSim exact, WNS +0.637, TNS 0, DSP 0, silicon exact. BOARD_PASS reserved | `results/A7-EAM-03E/A01T_CLOSE/` |
| A0.3 signed-h | XSim + WNS +0.596 + silicon exact predicted bag. **Not** geometry | `results/A7-EAM-03E/A03_SIGNED/` |
| Phase S (old law) | `STABILITY_FAIL` 11/11. H1 FALSIFIED **on shipped unsigned law**. H2 unsigned-concat CONFIRMED | `A02_STABILITY/` |
| A0.3-S / S2 | S2 Wh-clamp **FALSIFIED** (tighter worse). Do **not** re-run as a fix | MUST_READ |
| A0.2-L / A1 / KIDI / NATIVE-V1 | CLOSED | blocked on H5 gated DIFF, not on 80% constant rail (that was old law) |

S1/S2/S3 in `final.md` §8: **do not apply to shipped `eam03e-a0-signsgd-v1`**. After A0.3, S2 was tried and **failed**. Next is **ungated DIFF**, not more clamp. See `MUST_READ_UNBLOCK_H5.md`.

## Hard stops

Overwriting a frozen bit. Host computing gradient, weight delta, winner, way,
address, cue or answer. Cosine as a TRAIN signal before a separately versioned
L3. GlassBox, ILA or LiteScope before Native V1 freeze. Touching the PYNQ lane.
Jumping to 800k episodes. Two unknowns in one RTL patch. Editing a golden to
make a change pass.
