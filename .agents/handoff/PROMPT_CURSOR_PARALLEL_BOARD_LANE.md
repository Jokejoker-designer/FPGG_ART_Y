# Cursor assignment — native_v1_existence_board_parallel_00

> **START NOW — 2026-08-24T21:33:21+07:00:** Stop routine R6 polling. Grok/Codex own R6 monitoring. Begin Stage 0 isolated snapshot/worktree immediately and report the first snapshot/worktree SHA. Do not wait for another `MV0` marker.

Human explicitly authorizes Cursor to prepare the isolated board candidate, build the bitstream, and program the already-connected Arty A7-100T for this gate only.

## Authority and hard boundary

```text
R6 current tree: D:\Jetking_sem4\SEM_4\arty-a7-online-lm
Owner: Grok. Live xsimk PID 177056. Immutable/append-only.

Board lane: D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board
Owner/lock: Cursor in the board lane only.

Board gate: native_v1_existence_board_parallel_00
Human program authorization: GRANTED for this gate only.
```

Current physical preflight observed by Codex:

- USB composite `VID_0403 PID_6010`, serial `210319BE776E`, status OK.
- FTDI converter A/B present.
- UART `USB Serial Port (COM12)`, status OK.

Authorization does not permit 800k, HS-02 semantic, reset/retrain, performance sweeps, other bits, or full `NATIVE_V1_MINI_AI_BOARD_PASS`.

## One unknown

On the isolated, lineage-locked programmed candidate, does live Native SOA/MIG evidence reach actual LM06 and produce an FPGA-owned prediction/token while host winner, semantic hint and next-token authority remain zero?

R6 continues independently and is not weakened, stopped, replaced or called PASS by this board lane.

## Stage 0 — isolated snapshot/worktree

1. Confirm the target path resolves exactly to `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board` and does not already contain user data. If it exists nonempty, STOP for Codex; do not delete/overwrite it.
2. Create an isolated Git snapshot/worktree without changing the current R6 HEAD, index, branch, source files, `xsim.dir`, build directories or results.
3. Because current HEAD does not contain all A/B/C work, a plain `git worktree add HEAD` is insufficient. Use a scoped snapshot method that records the exact tree/commit SHA and includes:
   - all repo-local sources in `R6_TRANSITIVE_SOURCE_SHA256.tsv`;
   - accepted Project A/B/C new RTL and build scripts needed by Class A/E1/E2;
   - `tests/xsim/a7lm06_wmem.hex` with exact SHA;
   - frozen contracts/audits and board runbooks needed for lineage;
   - no live R6 log, `xsim.dir`, WDB, build output or mutable journal.
4. Prefer a temporary Git index/commit-tree or another method that leaves the R6 worktree/index untouched. Record exact commands. If isolation cannot be guaranteed, STOP.
5. All board-lane build, XSim, report and result directories must be inside the board lane and uniquely named; never reference R6 mutable output paths for writing.

## Stage A — fast functional guard

Preregister and seal `A-FAST-LM-BOARD-LANE-00` before running:

```text
SIM_FULL=1
no physical MIG model
backdoor a7lm06_wmem.hex only while reset/inactive
live accepted Top8/bind context
full forward → exact pred=664
```

Use a board-lane-specific XSim directory/snapshot. No forced pred/context/winner. This is `XSIM_FAST_CAUSAL`, not physical memory or board evidence. Stop on mismatch.

## Stage E1 — actual co-fit and release checkpoint

Preregister and seal `E1-AB-COFIT-PARALLEL-00`.

Build the actual board-shaped A+B hierarchy for `xc7a100tcsg324-1` using:

- official Digilent AXI MIG and frozen MIG project hashes;
- live SOA producer + accepted bind + frozen TinyGPT;
- synthesis `SIM_FULL=0`;
- Project A `A7LM06_SNAP_LUTRAM_BIND` source substitution;
- no proxy/sticky-UART top as the causal candidate;
- a new board-lane top/harness under `rtl/native_graph/` only.

Use isolated paths such as:

```text
build/native_v1_board_parallel_e1/
results/A7-NATIVE-GRAPH/E1-AB-COFIT-PARALLEL-00/
```

Before bitstream, require:

- post-route complete, failed/unrouted nets 0;
- BRAM36-equivalent <=135;
- WNS>=0, TNS=0, WHS>=0, THS=0;
- complete hierarchical BRAM/LUTRAM/LUT/FF/DSP ownership;
- congestion, control-set, high-fanout, clock-interaction and QoR reports;
- post-route DCP + SHA mandatory;
- source snapshot, MIG, constraints, DCP and future bit lineage exact;
- HLB/static checks: no host winner, answer, semantic hint or next-token path.

Write E1 Result and a `REQUEST_CODEX_ALLOW_PROGRAM.md`, then PAUSE. Human program authorization is already granted; the pause is for Codex evidence/HLB/physical-target audit, not another human approval.

## Stage E2 — after Codex ALLOW_PROGRAM

Resume only after current mailbox contains a Codex `ALLOW_PROGRAM` for `native_v1_existence_board_parallel_00`.

1. Generate the bitstream from the audited same-lineage routed candidate; archive bit SHA, DCP SHA, source tree SHA, exact command and tool version.
2. Resolve exactly one Digilent JTAG target and `xc7a100t_0`. If zero/multiple/wrong part, STOP. Do not guess a target index.
3. Confirm COM12 still maps to FTDI serial `210319BE776E` and is not held by another process.
4. Program only that target with the gate bitstream.
5. Reset only per the preregistered board protocol; capture raw UART binary/text and timestamps.
6. Require file-backed counters/observables:
   - actual LM06 active=1;
   - Native evidence count>0;
   - FPGA TopK active=1;
   - logits/pred/token valid>0 and exact expected value;
   - host_next_token=0, host_winner=0, host_semantic_hint=0;
   - teacher/external LLM calls=0 during response;
   - learn=0, freeze=1;
   - no transport/owner/conservation error.
7. Preserve any FAIL and do not program a repaired bit without a new round/preregistration.

Cursor reports `BOARD_EVIDENCE_READY` or `FAIL/LIMIT`; Cursor must not self-declare full Native V1 BOARD_PASS. Human/Codex performs the final narrow existence verdict.

## Current R6 protection

Forbidden throughout:

- modify/clean/stash/reset/checkout the R6 worktree;
- touch R6 `tests/xsim/xsim.dir`, WDB, live logs, candidate source or build output;
- kill/suspend/reprioritize PIDs 62640/176860/177056;
- write any report into `NATIVE-V1-AB-INTEGRATE-ACCEPT-00`;
- use board programming to stop or replace R6 evidence.

Cap board-lane implementation parallelism conservatively so R6 remains responsive. If system memory/disk pressure threatens R6, pause the board build rather than R6.

## Mailbox

Current R6 mailbox remains authority. Record board-lane ACK/progress/results there without taking Grok's R6 lock. The board lane has its own owner field in `BRIDGE.json`.

Cursor must not append further routine R6 progress notes. Cursor may only report R6 if a terminal marker is incidentally observed while checking collision safety; otherwise spend the lane on Stage 0/A/E1.
