# Attempt-1 FAIL (hang) — preserved

**PROGRAM=NO.** First XSim hung in `pulse_persist while(pbusy)` (~388s). Process killed.

Cause (post-mortem, not a pass): `slot_i` was `logic [3:0]`; P_FLUSH/P_RELOAD/P_INVAL wait for `slot_i == 16`, which a 4-bit counter never reaches (wraps 15→0). Handshake `else if (ddr_ack_i)` without `ddr_req_o` could also double-advance if ack was registered.

Raw logs (PowerShell UTF-16 redirect):

- `unit_xvlog_attempt1_hang.log`
- `unit_xelab_attempt1_hang.log`
- `unit_xsim_attempt1_hang.log`

Do not delete. Not evidence of seven-cell PASS.
