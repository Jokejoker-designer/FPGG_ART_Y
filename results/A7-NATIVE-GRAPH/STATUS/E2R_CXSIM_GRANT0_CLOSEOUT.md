# E2R C-XSIM-GRANT0 CLOSEOUT — dest≠4 with grant=0

**Agent:** [a7-ng-xsim-verify](893c5b09-f28b-4c1d-a5e5-3b4b2fde6248)  
**Archive:** `E2R-RPATH-IDLE-CXSIM-GRANT0-00/`  
**XSIM:** FAIL · `VERDICT_CLASS=FAIL_NO_DESTWAIT_GRANT0` · `C_FIX=NONE`

TB held B1 grant=0 on the mux vehicle. DUT dest reached `D_DRAIN=3`, never `D_WAITDONE=4`. WDMA stuck `W_WAITOWN` `own_ui=0`.  
H_CANDIDATE (dest=4 ∧ grant=0) **falsified** here. Silicon UART `TILE_DST=4∧GRANT=0` **not reproduced**.

Log SHA `E2B2BA9A4AA78F0B594638C1DE179B99E10D76DBBEBC9F0D3B443E3F2DA064D2`.  
XSim ≠ board. No C-FIX. No BOARD_PASS.
