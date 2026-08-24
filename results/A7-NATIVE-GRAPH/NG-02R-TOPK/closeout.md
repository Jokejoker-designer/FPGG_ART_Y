# NG-02R-TOPK closeout — global Top-8 (SEV-0 reopen)

**Branch:** `NG-02R-TOPK` (does **not** overwrite `results/A7-NATIVE-GRAPH/NG-02/`)  
**Law:** `a7ng-topk-global-v1` (retires pair-winner `a7ng-topk-v0` as global-Top-8 proof)  
**Agent:** `a7-ng-topk-frontier`  
**Board:** Arty A7-100T (silicon not required for this XSim/oracle gate)  
**Evidence class:** XSim + Python oracle = **EVIDENCE** (not BOARD_PASS)

## Defect fixed

Pairwise 8×max was **8 pair winners**, not global Top-8. Counterexample pair0={100,99} dropped 99.

## Implementation

| Item | Choice |
|------|--------|
| Primitive | Full bitonic sorting network 16→8 (see `RESEARCH.md`) |
| K | 8 |
| Tie | lower node_id, then lower lane |
| Valid mask | invalid loses to any valid; pad underfill |
| RTL | `rtl/native_graph/topk/a7ng_topk.sv` |
| Core wiring | `a7ng_ng02_core.sv` passes `valid_mask_i = all-1s` |

## Tests

| Test | Result |
|------|--------|
| Counterexample `{100,99}/{10,9}/…` keeps 100 **and** 99 | PASS |
| Directed ties + signed + partial mask | PASS |
| 100_000 random vectors vs Python oracle (seed `0xA7020201`) | **A7NG02R_TOPK_XSIM_PASS** |
| XSim wall time | ~14 s (Vivado 2026.1) |

Commands:

```text
python tests/xsim/ng02r_topk_oracle.py --n 100000 --out results/A7-NATIVE-GRAPH/NG-02R-TOPK/vectors/topk_100k.txt
cd tests/xsim
xvlog -sv ../../rtl/native_graph/pkg/a7ng_pkg.sv ../../rtl/native_graph/topk/a7ng_topk.sv tb_a7ng_topk.sv
xelab tb_a7ng_topk -s tb_a7ng_topk -timescale 1ns/1ps
xsim tb_a7ng_topk -runall
```

## SHA256

| Artifact | SHA256 |
|----------|--------|
| `rtl/native_graph/topk/a7ng_topk.sv` | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` |
| `rtl/native_graph/topk/a7ng_ng02_core.sv` | `E37DFF112A4D38CA6478E8E02EC0A444F28633A60D5D00D93803041BA137AB9C` |
| `tests/xsim/tb_a7ng_topk.sv` | `E1D11803D919FBAE56A99D5D43F031901BD8F2B841C6EBF7446AA28B5E56C74B` |
| `tests/xsim/ng02r_topk_oracle.py` | `97E2A10B8060F9F270D0A8E58B3785551CB12D00447ECFD8F185481EAB15B2A3` |
| `vectors/topk_100k.txt` | (see `SHA256.txt`) |
| XSim log | `xsim_topk.log` → marker `A7NG02R_TOPK_XSIM_PASS nvec=100000` |

## Not claimed

- No BOARD_PASS  
- No ng02r_flow / wide-dispatch / TermGen  
- No encoder 03E glue  
- Archived NG-02 bit remains historical **pair-winner** silicon — not global Top-8 proof  

## NEXT

P0 `ng02r_flow` (backpressure / conservation) per `STATUS/P0_P1_BACKLOG.md`.
