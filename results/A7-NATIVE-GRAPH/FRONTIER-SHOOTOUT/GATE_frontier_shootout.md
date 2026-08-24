# GATE — frontier_shootout

**Status:** PASS (engineering)  
**Agent:** a7-ng-topk-frontier  
**Marker:** `A7NG_FRONTIER_SHOOTOUT_XSIM_PASS`  
**Primary artifact:** `results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT/closeout.md`  
**Comparison table:** `results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT/COMPARISON_TABLE.csv`

## Pass criteria (preregistered)

1. Archived A/B/C comparison table under FRONTIER-SHOOTOUT/ — YES  
2. Identical workload (seed `0xF5022201`, 64 query units) — YES  
3. Top-8 law SHA unchanged — YES (`F671FCB1…`)  
4. NG-02R-FLOW bucket SHA unchanged — YES (`CE38FEC3…`)  
5. No BOARD_PASS claim — YES  

## Winner (by numbers)

`B_systolic` (tied with C on M1/M2/M3; wins M7 LUT vs C; A fails M1/M2).

## Evidence class

XSIM + behavioral oracle + OOC synth. Not silicon. Not BOARD_PASS.
