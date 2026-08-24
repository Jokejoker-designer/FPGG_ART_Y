# A7-LM-06 hardware C0 — FAIL_UPLOAD_TILE_STALL

Do not overwrite `ladder.json`.

- Bit SHA `B73C28B157A2799AF5394D5D914E063D09CB2E32AA93692207043AD35FC3432F`
- WNS +0.032 / TNS 0 / WHS +0.020
- Calib + K257/511/513 first-try PASS
- Stall at offset **131072** (first POS byte / first region miss)
- Status: `busy=True wr_n=0 persist=False`

Cause: single 131072 W bank; port B stayed on `caddr=0` (TOK) while port A wrote POS; refill oscillated TOK↔POS.

Fix is C1: miss only on port A; park B on A during host/compute.
