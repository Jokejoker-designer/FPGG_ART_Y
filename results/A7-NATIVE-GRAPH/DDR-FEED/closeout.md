# Closeout — ddr_feed (A7-BRAM-WM-01)

```text
GATE: ddr_feed
AGENT: a7-ng-memory-arch
RESULT: PASS
EVIDENCE_CLASS: XSIM
MARKER: A7NG_DDR_FEED_XSIM_PASS
LAW: a7ng-ddr-feed-wm01-v0
```

## UNKNOWN closed

Ping-pong DDR→WM feed with swept burst×outstanding **does** reduce PE stall vs single-issue baseline under synthetic LATENCY=24 (H_CANDIDATE supported). H_RIVAL (MIG artifact) remains **OPEN**.

## Key metrics

- baseline stall_frac (1,1)=0.961544 → best (4,8)=0.475410
- recs/cycle 0.038456 → 0.524590
- DROP=0 / 32 cells; ddr_rd_bytes=4096 (=256×16) each cell
- CONTROL: WM-00 / schema / LM-06/01R/02M/A0.3 **MATCH**

## Explicit non-claims

- Not 100 MHz SoC / ARCH_PASS (WM-00 WNS=−290.499 OPEN)
- Not MIG silicon bandwidth
- Not BOARD_PASS
- No LM-06 integrate; no PE>16; no TermGen/TRAIN-V2/HNSW

## Artifacts

- `GATE_ddr_feed.md`
- `xsim_ddr_feed.log`
- `sweep_table.txt`
- `SHA256.txt` / `frozen_sha_control.txt`
- `A7NG_DDR_FEED_XSIM_PASS.md`
