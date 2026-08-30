# GO-H2PACK-SOC-00 — program token

**PROGRAM=NO** until a human names this exact gate.

| Field | Value |
|-------|--------|
| Gate | `GO-H2PACK-SOC-00` |
| Branch | `research/native-ai-v1-grok-orch-00` |
| Worktree | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` |
| Policy | `BIT_FIRST_COM12_SECOND` |
| COM12 | yielded to Cursor; do not open until named token |
| JTAG | `210319BE776EA` only |
| Leftover refuse | `00517465` grant-soa, `885DC99C` grant-miss, pulse/waitbusy/existence, LONGBOOT, two-pass |

Do **not** program:

- grant-soa `00517465…` (silicon pred=733, no PACK hex)
- any older Grok bit
- Cursor bits

After **BIT_OK** of `arty_a7_ng_native_v1_grok_orch_h2pack_00.bit`, wait for a token that names `GO-H2PACK-SOC-00` and the new SHA.

## BIT_OK (2026-08-30 19:40)

```text
SHA256=EC286E9EAAEC1651B7C43687DB2B71FA45A30AABB3525D38F813FA342ED0211C
WNS=+0.510 TNS=0 RAMB36=103
PREBUILD_READY=YES PROGRAM=NO
```

Human token must include: gate `GO-H2PACK-SOC-00` + SHA `EC286E9E…`.
Do not accept a token that names grant-soa `00517465`.
