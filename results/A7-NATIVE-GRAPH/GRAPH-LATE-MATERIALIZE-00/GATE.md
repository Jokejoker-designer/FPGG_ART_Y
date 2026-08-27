# GATE graph_late_materialize_00

**Law:** `a7ng-late-mat-v0`  
**ONE UNKNOWN:** Can expensive `NodeRecordV1` (16 B) fetch occur only after global Top-K commit, without TermGen/scorer/Top-K law change?  
**Evidence class target:** XSIM  
**Not BOARD.** Not existence `pred=664`.

## Control

Early materialize (forbidden here): fetch all K slots → `K * 16` bytes even if mask bits are 0.

Late materialize (this core): fetch only `popcount(valid_mask)` survivors.

TB vector: mask `0010_0101` (3 valid / 5 skip) → **48 B**, not 128 B.

## Pass language

| Check | Pass |
|-------|------|
| No AXI AR before `commit_i` | required |
| Invalid slots never generate AR | required |
| `payload_bytes == n_fetch * 16` | required |
| Address = `a7ng_node_byte_addr(NG_DDR_NODE_BASE, id)` | required |
| DSP | 0 (this module is FSM+AXI only) |
| Marker | `A7NG_LATE_MAT_XSIM_PASS` |

## Forbidden

Host-supplied address. Fetching losers. Mixing WM ladder / BRAM cut. Declaring BOARD_PASS.
