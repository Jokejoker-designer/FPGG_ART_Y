# CODEX DIRECTIVE — PHASE2-G2-CONTEXT-DELTA-RTL-00

First reply line:

`G1_RESOLVER_V2: accepted for continuation as PASS_NARROW_UNIT_OOC. Next=PHASE2-G2-CONTEXT-DELTA-RTL-00. PROGRAM=NO.`

## Goal and authority

Implement the preregistered FPGA-owned contextual delta arithmetic immediately after the legal G1 `CONSUME` handshake and before any WM coalesce/DDR update. This is one isolated RTL/XSim/OOC gate. Do not fold G3 causal Top-K, persistence, Teacher-Off, or full-chip integration into this task.

Read and obey:

- `D:/Jetking_sem4/SEM_4/arty-a7-online-lm/results/A7-NATIVE-GRAPH/PHASE2-SERIAL-G2-PREREG-00/PREREGISTER.md`
- `D:/Jetking_sem4/SEM_4/arty-a7-online-lm/docs/contracts/native_graph/A7-NATIVE-GRAPH-LEARN-CTX-V1.md`
- `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-grok-orch-00/rtl/native_graph/learn/a7ng_feedback_resolver.sv`
- raw G1 evidence under `results/A7-NATIVE-GRAPH/GROK-ORCH-00/PHASE2-G1-RESOLVER-V2-00/`

Frozen authority hashes to revalidate before work:

- G0 law: `BE892A777F2616F169AFB72D68399FF0150C817A77A20AB249CBAC70512A8E86`
- G1 resolver RTL: `2219DA29C265D2461ED30783EBEA0F0649050B9B6E5F6EAFDB8F1C4E05F3F5F7`
- G2 preregister: `DDEB61064C20A36EC6856EF5EC52C69A4B7F30DA4871C3F536025C6792DA9DF0`

## One unknown

Does an FPGA-only delta engine, driven exclusively by a legal G1 consume record, produce the exact `a7ng-learn-ctx-v1` signed delta for every registered row and remain lossless under downstream backpressure without exposing host-writable delta/index/address authority?

## Required DUT

Create one new isolated module under `rtl/native_graph/learn/`, suggested name `a7ng_context_delta.sv`.

Required transaction input:

- ready/valid input from G1 consume;
- signed reward in legal range `[-3,+3]`;
- FPGA-latched `native_conf` as unsigned 16-bit;
- pass-through contextual identity needed by the later updater: `subj`, `rel`, `obj`, `q_epoch`, `p_epoch`, `contradict`, and `txn`.

Required output:

- ready/valid transaction;
- signed saturated 16-bit `delta`;
- every contextual field and `txn` preserved bit-exact;
- optional `sat_flag`, if implemented, must be derived internally.

Exact law:

```text
prod  = signed32(reward) * signed32({1'b0,native_conf})
delta = sat16(prod >>> 8)
```

The design must hold output valid and every output field stable until `out_valid && out_ready`. Input may be accepted only on `in_valid && in_ready`. At most one transaction may be buffered unless a deeper queue is explicitly preregistered; do not silently drop or overwrite a transaction.

Do not add host-facing `delta_i`, `learn_delta_i`, `idx_i`, winner, way, address, cue, answer, or updated-weight inputs. The TB models FPGA G1 output; it must not present those fields as host authority.

## Frozen directed table

All rows are mandatory:

| reward | native_conf | expected delta |
|---:|---:|---:|
| +3 | 256 | +3 |
| -3 | 256 | -3 |
| +1 | 0 | 0 |
| +1 | 255 | 0 |
| +3 | 65535 | +767 |
| -3 | 65535 | -768 |
| 0 | 256 | 0 |

`+3 * 65535` must produce `+767`, never `+768`.

## Mandatory tests and falsifiers

1. Directed test of every frozen table row after independent reset/idle boundaries.
2. Random differential test of at least 100,000 accepted transactions against an independent signed software/TB oracle.
3. Random input gaps and output backpressure.
4. Assertions/scoreboard:
   - accepted input count equals retired output count at drain;
   - no output without an accepted input;
   - contextual fields and txn pass through exactly;
   - output payload remains stable while stalled;
   - no duplicate, loss, reorder, or stale output after reset;
   - signed negative arithmetic is exact.
5. Static interface audit must fail if a host-authority delta/index/address port exists.
6. Preserve failed attempts and their raw logs before rerun.

## Resource acceptance

Run OOC only after XSim passes and only when no competing Vivado/XSim process exists.

- target part: `xc7a100tcsg324-1`;
- use the current Native V1 core clock contract; state exact period;
- LUT `<= 100`;
- FF `<= 180`;
- LUTRAM/BRAM/DSP `= 0` unless the frozen law objectively requires otherwise; a DSP multiply for reward `[-3,+3]` is a resource FAIL;
- WNS/TNS and WHS/THS clean;
- report control sets.

If a target is missed, preserve the measured result and STOP. Do not weaken arithmetic, context pass-through, backpressure, or the table.

## Hard boundaries

- `PROGRAM=NO`; no COM12/JTAG/board.
- No full-chip/SoC integration and no bitstream.
- Do not modify G1 resolver after its accepted SHA.
- Do not modify frozen G0/G1 contracts, TermGen, scorer, Top-K, LM, MIG IP/generated RTL, or Cursor worktree.
- Do not reuse `a7ng_wm00_learn_upd` as the G2 DUT; its `delta_i` is the negative control.
- Do not claim G3, persistence, Teacher-Off, training convergence, usefulness, Gate 14, or BOARD_PASS.
- One unknown, one implementation gate, then STOP for Codex audit.

## Deliverables

Create `results/A7-NATIVE-GRAPH/GROK-ORCH-00/PHASE2-G2-CONTEXT-DELTA-RTL-00/` containing:

- preregistration copied/referenced before data;
- RTL/testbench source hashes;
- raw xvlog/xelab/xsim logs;
- directed and random scoreboard counts;
- OOC utilization/timing/control-set reports;
- exact commands and Vivado version;
- `RESULTS.md` with explicit `PROGRAM=NO` and non-claims.

Commit only the bounded G2 gate in the Grok branch. Then STOP and wait for Codex audit.
