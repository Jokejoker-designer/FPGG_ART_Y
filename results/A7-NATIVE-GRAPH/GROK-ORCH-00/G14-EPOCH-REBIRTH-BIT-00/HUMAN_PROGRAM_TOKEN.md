# HUMAN PROGRAM TOKEN — G14-EPOCH-REBIRTH-BIT-00

```text
READY_TO_PROGRAM = YES
PROGRAM          = NO          (agent / MCP / hw_server MUST NOT program)
GATE14_PASS      = NO
REBUILD          = NO
RTL_EDIT         = NO
```

Human programs **this exact bit once**. Do not cleanup, probe, merge RTL,
or regenerate before the run. Slice headroom is 269/15850 (~1.7%).

---

## Frozen bit

```text
file  = results/A7-NATIVE-GRAPH/GROK-ORCH-00/G14-EPOCH-REBIRTH-BIT-00/arty_a7_ng_native_v1_g14_epoch_rebirth_00.bit
SHA256= 1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9
```

Refuse if SHA is `3A7EF204…` / `7ECCA0E2…` / `A0B338E0…` or anything else.

Board: Arty A7-100T `xc7a100tcsg324-1`  
JTAG: Digilent `210319BE776EA`  
UART: COM12 @ 115200  

Causal claim: **one functional unknown = epoch object** (STORE+PKG).
See `DELTA_FROM_3A7EF204.md` and `SILICON_READOUT.md`.

Not “only one file differs.” Not “same placement + one RTL file.”
Exactly: frozen graph/LM/data path + epoch law + observability-only TOP
+ new physical implementation. Grade E0→E5. Stop at first divergence.

---

## Frozen oracle (do not retarget)

```text
HOLD_A C9=8382238122802120 OUT=653
UNREL  OUT=689
CONTRA OUT=237
HOLD_B OUT=60
```

---

## One-program protocol (do not improvise)

1. Confirm `.bit` SHA256 is exactly `1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9`.
2. Arm COM12 @ 115200 **before** JTAG.
3. Record capture-start timestamp.
4. Program JTAG `210319BE776EA` **once**.
5. Record JTAG DONE timestamp.
6. Do **not** reprogram even if UART looks strange.
7. Analyse only bytes after DONE.
8. Capture at least BOOT → GEN → commit_seq/state evidence → CORE_DONE → C9 → OUT.
9. Keep the raw capture. SHA256 it.
10. Stop at first divergence. Do not keep running “to see the last pred.”

---

## Decision tree

```text
BOOT
 │
 ▼
GEN legal?
 │
 ├── NO / FFFFFFFF
 │      → EPOCH REBIRTH NOT CLOSED ON SILICON
 │      → STOP
 │
 └── YES
        │
        ▼
20 intended architectural commits?
        │
        ├── NO
        │      → STATE-COMMIT DIVERGENCE
        │      → STOP
        │
        └── YES
               │
               ▼
HOLD_A C9 = 8382238122802120 ?
               │
               ├── NO
               │      → QUERY/STATE PIPELINE STILL DIVERGES
               │      → STOP at first available checkpoint
               │
               └── YES
                      │
                      ▼
OUT = 653 ?
                      │
                      ├── NO → LM/BIND downstream opened
                      │
                      └── YES
                             ↓
                    run UNREL → CONTRA → HOLD_B
```

Expect vs fail bit `3A7EF204`: boot C8 GEN ≠ `FFFFFFFF`.

After DONE, if UART looks strange: do **not** reprogram, reset-retry,
change spacing, add delay, regenerate, or retarget the decoder onto this
capture. Keep raw bytes. Name first divergence first.
See `SILICON_READOUT.md` (E0–E5).

Full E0–E5 match closes P_BOOT/epoch **on board**. It still does **not**
make `GATE14_PASS`.

Agent must not call `program_device` / `hw_server` program.
