# P2-CAUSAL-LEARN-FAST-00 — preregistration (copied before data)

**PROGRAM=NO.** Fast/no-MIG XSim of PLAN G3 sequence. Not board. Not G4/G5.

Source: `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\PHASE2-SERIAL-G3-PREREG-00\PREREGISTER.md`  
SHA256 `CAAEB8217F922400937404E02EAFC4E9DB3950E0CCC7DE42630FC80444867088`

G0 `BE892A777F2616F169AFB72D68399FF0150C817A77A20AB249CBAC70512A8E86`  
G1 resolver (do not modify) `2219DA29C265D2461ED30783EBEA0F0649050B9B6E5F6EAFDB8F1C4E05F3F5F7`  
G2 DUT (do not modify) `0614386298F31DC6A5EB456959290F9C6ADDC899FBF91F8CD49BB5A3D2BBA800`

## One unknown

Does C3 → G1 CONSUME → G2 delta → modeled C7 ACK → C9 on a fast no-MIG FPGA Top-K vehicle move B vs A in the four preregistered directions (positive up, negative down, unrelated unchanged, contradiction down on K*) with host reward-only?

UNIT = held-out query. RESET learned state between arms. Host Top-K / TRAIN-V2 score_fn / pred=664 = FAIL.
