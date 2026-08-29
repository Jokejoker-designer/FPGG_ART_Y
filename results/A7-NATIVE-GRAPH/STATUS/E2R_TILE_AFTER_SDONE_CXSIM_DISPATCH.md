# E2R-TILE-AFTER-SDONE-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-TILE-AFTER-SDONE-CXSIM-00/`  
**PROGRAM=NO. No RTL edit. No C-FIX. No LiteScope. No soc_top/MIG.**

REARM [b48f82ae](b48f82ae-0435-47ef-bb5c-4daa971683a4): silicon dest=4→5, ATOM0=`0000059C` sticky sdone=1, hold 300 s, no `CORE_DONE`. Observer closed.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon `D_WAITDONE`→`D_ACK` + `s_done` sticky. UART `TILE_BST=4` is **first-seen** `B_REQ`. `stall=(bst!=B_IDLE)\|\|miss` for the whole refill. |
| UNKNOWN | after `dma_done` at `D_WAITDONE`, does `bst` leave `B_REQ` (chunk handshake)? |
| H_CANDIDATE | `ACK_STUCK` — dest=5 but `bst` stays `B_REQ` |
| H_RIVAL | `CHUNK_ACK` — dest=5 and `bst` reaches `B_WAITACK` or `B_STORE` |
| FALSIFIER | leftover grant bags; `SIM_FULL=1` (stall hardcoded 0); C-FIX; board; treat one-chunk `stall=1` as stuck (nline>1 keeps stall) |
| UNIT | one tile miss, first DMA chunk (not clock-as-query) |
| CONTROL | silicon ATOM dest 4→5; F1p dest=0∧B_REQ (old, no s_done) |
| METRICS | `dbg_dst`, `dbg_bst`, `stall`, `dbg_req`, `ack` after `dma_done` |

## Vehicle

Instantiate `weight_tile803k` `#(.SIM_FULL(0))` only. Force a miss (`addr_a` region ≠ `cur_rg`). Stub DMA: on `dma_go` assert `dma_busy`, deliver 8 `dma_r_valid` beats (read refill, not flush), pulse `dma_done`, drop busy. Do **not** hold busy after done (that was the old MUX falsifier).

Do not require `stall=0` after one chunk. Class from dest+bst only.

## Verdict

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `CHUNK_ACK` | dest=5 and bst ≥ `B_WAITACK` after done | none |
| `ACK_STUCK` | dest=5, bst stays `B_REQ` | none |
| `DEST_STUCK` | dest never leaves `D_WAITDONE` despite done | none |
| `NO_MISS` | never dest=4 | none |

Marker `E2R_TILE_AFTER_SDONE_CXSIM_00_XSIM_PASS` if CHUNK_ACK or ACK_STUCK or DEST_STUCK (classified). Archive TB/tcl/log/CLOSEOUT. `BOARD_PASS` not claimed. Existence not claimed.

Append DISPATCH_LOG both trees. `agent=a7-ng-xsim-verify`, `gate=E2R-TILE-AFTER-SDONE-CXSIM-00`.
