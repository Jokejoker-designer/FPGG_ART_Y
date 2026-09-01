# P2-CAUSAL-LEARN-FAST-00 — RESULTS

G3 preregister SHA-256: `CAAEB8217F922400937404E02EAFC4E9DB3950E0CCC7DE42630FC80444867088`  
DUT SHA-256: `21AD48A5F900435F02741E96D9A9FE1A90355430CB77393A5CA6EC90467F99A5`  
G1 resolver (unmodified): `2219DA29C265D2461ED30783EBEA0F0649050B9B6E5F6EAFDB8F1C4E05F3F5F7`  
G2 delta (unmodified): `0614386298F31DC6A5EB456959290F9C6ADDC899FBF91F8CD49BB5A3D2BBA800`  
TB SHA-256: `167F5C6D3052F3702A75ABBC3146F21F78536143440E5D8223057777FF408767`

Vivado 2026.1 (SW Build 6511674). Part `xc7a100tcsg324-1`. Clock contract **12.5 MHz / 80.000 ns**.  
`PROGRAM=NO`. No COM12/JTAG/bit/full-chip. SoC instantiate ABSENT. Do not program `A0219207…`.

## Unknown

Does C3 → G1 CONSUME → G2 delta → modeled C7 ACK → C9 on a fast no-MIG FPGA Top-K vehicle move B vs A in the four preregistered directions, host reward-only?

UNIT = held-out query. RESET between arms.

## XSim (Vivado 2026.1)

Attempt-1: xelab FAIL (dual procedural driver on loop index `pi`). Log kept: `unit_xelab_attempt1_FAIL.log`.

Attempt-2: `CAUSAL_LEARN_FAST_XSIM_PASS fails=0 UNIT=held-out-query`

| Arm | Treatment | Held-out | A_hold K* | B_hold K* | C7 | Verdict |
|-----|-----------|----------|-----------|-----------|----|---------|
| positive | reward=+3, contradict=0 | Q_HOLD | rank 3 score 39 | rank 2 score 42 | ACK delta=+3 | **move_up PASS** |
| negative | reward=−3, contradict=0 | Q_HOLD | rank 3 score 39 | rank 3 score 36 | ACK delta=−3 | **move_down PASS** |
| unrelated | reward=+2 on K* | Q_UNREL | no K* | bit-exact same 8 ids+scores | ACK delta=+2 | **unchanged PASS** |
| contradiction | FPGA contradict=1, reward=−3 | Q_HOLD | rank 3 score 39 | rank 3 score 33 | ACK delta=−3 | **move_down PASS** |

C3/C9 = DUT `topk_id_o` / `topk_score_o` (FPGA scorer_lane + FPGA Top-8 order: higher score, then lower id). No host `score_fn`. Host ingress = `query_id` (teacher question) + `reward`/`txn_echo` only. `INTERFACE_AUDIT_PASS`.

C7 is a modeled FPGA DDR ACK (LUTRAM apply, `c7_addr_o` FPGA-owned). Not real MIG.

## OOC (after XSim; no competing Vivado)

```text
LUT=3869 (logic 3869, LUTRAM=0)
FF=548
BRAM=0 DSP=0
control_sets=24
WNS=-2.277 TNS=-88.148 (42 failing endpoints)
WHS=+0.146 THS=0
clk period=80.000 ns
```

Hierarchy: top sort/ROM 3683 LUT, G1 66, G2 76, scorer_lane 46.

**OOC timing is not met.** Bulk is the combinational 8-cell sort. This is a measured physical finding on the isolated fast top. It does **not** lower the four-arm table (HS-17). DSP=0. No G2/G1 source edit.

## Not claimed

```text
G4 persist / generation / reload
G5 Teacher-Off / LM-06 / C10
Gate 14 PASS
BOARD_PASS / NATIVE_V1_*_BOARD_PASS
PROGRAM / full-chip / SoC instantiate
live TOPK= hex on A0219207
pred=664 as G3 evidence
OOC WNS clean / resource closure of Native V1
TRAINS / CONVERGES / USEFUL
```

XSim ≠ board. Causal visibility on the fast vehicle ≠ Teacher-Off.

STOP for Codex audit.
