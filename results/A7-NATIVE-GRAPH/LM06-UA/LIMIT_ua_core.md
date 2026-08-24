# LIMIT — LM-06 act u_a on SoC (lm06_ua_core)

**Result class:** PASS_NARROW + LIMIT

## Present

- Frozen-law act scratch `act_ram128k16` as named netlist cell `u_a` (64 RAMB36)
- Weight fabric retained: `u_lm06_wtile` (32) + `u_lm06_wpp` (32)
- Post-route: BRAM=128/135, WNS=+0.257, TNS=0, DSP=0, PE=16 fabric, MIG present
- lm_path sticky requires **both** weight and act readback; act_keep feeds compose
- New bit SHA `D2C6CF4B…` archived under `LM06-UA/`
- CONTROL weight-cut `D61BA6D4…` and frozen LM-06 / 01R / 02M / A0.3 **MATCH** (not overwritten)

## Absent / not claimed

- Full TinyGPT / mac_array / gemv / DSP path
- Board UART proof lm_path bit5≠0 after program
- Semantic HS-02 / retrieval / BOARD_PASS / HS-22 closed

## Why not FAIL

UNKNOWN (instantiate u_a with weight tiles; WNS≥0 TNS=0 BRAM≤device; named u_a in netlist; frozen MATCH) **met** on post-route evidence. Remaining gaps are LIMIT, not sold as §14 full LM-06 or HS-22.
