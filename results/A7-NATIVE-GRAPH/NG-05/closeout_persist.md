# NG-05 persist closeout

**Law:** `a7ng-learn-persist-v0`  
**Marker:** `A7NG05_PERSIST_XSIM_PASS`  
**Gate log:** `GATE_ng05_persist.md`

DDR prior base `0x0300_0000`. Power-loss of BRAM (`bram_kill`) + `reload` restores learned prior. `forget` zeros BRAM+DDR. No host weight write port.

Silicon MIG persist across real power-cycle = later integrate_fit / board debt — XSim models DDR-backed persistence law.
