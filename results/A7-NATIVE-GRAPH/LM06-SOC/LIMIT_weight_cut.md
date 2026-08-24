# LIMIT — LM-06 weight cut on SoC (lm06_soc_path)

**Result class:** PASS_NARROW + LIMIT

## Present

- Frozen-law weight modules on SoC response path:
  - `weight_tile803k` (`u_lm06_wtile`) — 32 RAMB36
  - `tile_weight_pingpong` (`u_lm06_wpp`) — 32 RAMB36
- Post-route: BRAM=64/135, WNS=+0.365, TNS=0, PE=16 fabric, MIG present
- New bit SHA `D61BA6D4…` archived under `LM06-SOC/`
- Frozen LM-06 / 01R / 02M / A0.3 SHA **MATCH** (not overwritten)

## Absent / not claimed

- Full LM-06 activation scratch `u_a` (~64 BRAM)
- Full TinyGPT core / DSP=154 path
- Board UART proof that lm_path bit5≠0 after program (RTL sticky only)
- Semantic HS-02 / retrieval answers / BOARD_PASS

## Why not FAIL

UNKNOWN (weight fabric fit + timing + BRAM≤device + non-fake lm_path wiring) **met** on post-route evidence. Remaining gaps are labeled LIMIT, not sold as closed §14 full LM-06 or HS-02.
