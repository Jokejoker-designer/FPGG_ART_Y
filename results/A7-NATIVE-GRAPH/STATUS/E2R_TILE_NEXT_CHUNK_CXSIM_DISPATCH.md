# E2R-TILE-NEXT-CHUNK-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-TILE-NEXT-CHUNK-CXSIM-00/`  
**PROGRAM=NO. No RTL edit. No C-FIX.**

Prior [CHUNK_ACK](61e7543f-aa5a-4e81-9ded-fe572648630a) / audit [CLEAN](30a49ff5-3cbb-489b-9d90-7722338a3957): first chunk dest 4→5, `bst`→`B_WAITACK`. `nline>1` so stall stays 1 until `B_IDLE`.  
LONG listen [SILENT](cb9f65c5-f4ea-42c4-bd0b-d58f981b6f0d) sealed. This is the **resume** of the 12:37 dispatch (aborted for LONG).

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | First-chunk handshake works on stub. Silicon ATOM1 dest=5 then 300 s silence. `D_ACK` exits only when `!req_s[1]`. |
| UNKNOWN | after first `D_ACK`, does dest return `D_IDLE` and reach `D_WAITDONE` again (chunk 2 `dma_go`)? |
| H_CANDIDATE | `ACK_HOLD` — dest stays 5; no second `dma_go` |
| H_RIVAL | `CHUNK2_GO` — dest returns 0 then 4 again |
| FALSIFIER | stop at first dest=5; hold busy after first done; `SIM_FULL=1`; leftover grant; C-FIX |
| UNIT | one miss, chunk1 then chunk2 (not clock-as-query) |
| CONTROL | CHUNK_ACK dest=5 bst=5; silicon ATOM1 dest=5 |
| METRICS | dest after ACK, second `dma_go`, second dest=4, `bst` |

Copy the CHUNK_ACK TB. **One change:** keep the completable stub for **every** `dma_go` (8 R + done + busy clear). Watch past first dest=5 until dest=0 and dest=4 again, or timeout (document cycle cap). Do not require `stall=0`.

| Class | Meaning |
|-------|---------|
| `CHUNK2_GO` | second dest=4 after first ACK |
| `ACK_HOLD` | dest stays 5; no second go |
| `IDLE_NO_GO` | dest=0 after ACK but never dest=4 again |
| `NO_ACK` | never first dest=5 |

Marker `E2R_TILE_NEXT_CHUNK_CXSIM_00_XSIM_PASS` if classified. Existence not claimed.
