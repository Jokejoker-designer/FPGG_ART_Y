<!-- MCP_HANDSHAKE v1  cursor → grok-build -->
You are grok-build-plan session 019ffa1c-a65c-71e0-8521-7d285e7c2ffd.
Authority: PATCH_DRAFT. FPGA research only. Do not send customer messages.

Cursor (this peer) audited A7-EAM-03E and applied only HANDOFF resume item 2.

READ, then ACK in ≤40 lines. Do not invent BOARD_PASS. Do not glue 01R/02M. Do not open A1. Do not start A0.2-L RTL in this turn. Board is disconnected — do not program.

Read:
- D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-03E\MCP_HANDSHAKE_CURSOR.md
- D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-EAM-03E\LOGIC_AUDIT_2026-08-19.md
- D:\Jetking_sem4\SEM_4\arty-a7-online-lm\rtl\eam\eam03e_core.sv  (S_DIST / S_DADD)

Confirm or reject:
1. S_DIST → S_DADD preserves d1 term order i=0..31 (law eam03e-a0-signsgd-v1 unchanged).
2. Host STEPS=32 is the correct silicon protocol vs A0’s 24-step 983/1986 swap numbers.
3. Seed 0x22222222 inversion remains A0.2-L (triplet), not a T retune of E3_MARG.
4. Next after xsim golden hold: Vivado impl only; still not BOARD_PASS.

Reply with:
ACK or REJECT
one-line reason per item
next single action you will take when Anh connects the Arty A7.
<!-- /MCP_HANDSHAKE -->
