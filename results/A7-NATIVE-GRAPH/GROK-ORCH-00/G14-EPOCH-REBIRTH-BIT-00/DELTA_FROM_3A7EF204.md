# DELTA_FROM_3A7EF204 — classify SHA deltas before silicon

```text
READY_TO_PROGRAM = YES
PROGRAM          = NO          (agent does not program)
GATE14_PASS      = NO
BOARD_PASS       = NO
NATIVE_V1_MINI_AI_BOARD_PASS = NO
REBUILD          = NO
RTL_EDIT         = NO
```

This note is **documentation only**. It does not rebuild the bitstream.
It does not retarget the frozen oracle.
It does not authorize `GATE14_PASS`.

Fail bit (silicon, programmed once):

```text
bit   = P2-GATE14-C9-SOC-IO-SAFE-BIT-07
SHA256= 3A7EF204…   (do not reuse)
HOLD_A C9  = 2322838281802120
HOLD_A OUT = 748
boot C8 GEN= FFFFFFFF
```

Unique bit (this bag, frozen):

```text
file  = arty_a7_ng_native_v1_g14_epoch_rebirth_00.bit
SHA256= 1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9
```

---

## Claim (use this wording)

The silicon experiment is **one functional unknown = epoch object**.

It is **not** “only one file differs.”

Vs BIT-07 `SOURCE_SHA.txt`, the important graph / LM / memory blocks are
identical (TinyGPT, CUE, HEAP, wavefront, boot, ABCORE, COFIT, DMA, BIND,
LPG, GLUE, PAX, G1, G2, G3, CDC, REL, TILE). Four **manifest keys** differ
(TOP, STORE, G4, ORACLE). `a7ng_pkg.sv` also differs and **is in the
fileset**, but it was never a `SOURCE_SHA.txt` key.

| Class | Meaning |
|-------|---------|
| `IDENTICAL` | Same SHA as fail-bit manifest. Not the unknown. |
| `FUNCTIONAL_EPOCH` | Persist generation identity law (the intended unknown). |
| `OBSERVABILITY_ONLY` | UART / sticky probe / telemetry. Does not change C9 pack, TinyGPT OUT, or GEN cookie law. |
| `ORACLE_METADATA` | File SHA changed; frozen query/C9/OUT integers did not. |
| `NOT_IN_FILESET` | Source file SHA changed, but the C9 SoC `add_files` list **refuses** that file. Not in `1F0F2ABB`. |

---

## Manifest keys that differ

Hashes are working-tree `Get-FileHash SHA256` / git blob SHA256 of LF
sources (BIT-07 `SOURCE_SHA.txt` used the same method).

### STORE — `FUNCTIONAL_EPOCH`

```text
BIT-07  STORE=25E79722ED29593A8F5D426AD3404B9E655903D1CFA4B074A8B8E3637BE193EE
unique  STORE=BE987C43573686872E4D647C40FC5B1AF2858545AF52B29A16EC625C8DF16190
file    rtl/native_graph/learn/a7ng_learned_prior_store.sv
git     cd8c41c (fail bit) → 1685ab4 (epoch object + wrap REBIRTH)
```

This **is** the intended unknown. Dirty DRAM `FFFFFFFF` is no longer a
legal epoch cookie. `P_INVAL` is REBIRTH (`live_gen=1`, BRAM wipe, DDR
zero), not “zero DDR and keep `live_gen=FFFFFFFF`”.

Intermediate P0 commit `3b6622a` (`header_ok` only, SHA `48B84056…`) is
**not** this bit.

### PKG — `FUNCTIONAL_EPOCH` (not a SOURCE_SHA key; **is** in fileset)

```text
BIT-07 era  a7ng_pkg.sv = 7B62CFBDF6688E8356505942FD36C344871B034A281D25EC62E7B37771A70957
unique      a7ng_pkg.sv = FF0ECAEDCD39A8D7F4D207F87403ADDA1184878EC0B4E4D884993C6A840069B1
file        rtl/native_graph/pkg/a7ng_pkg.sv
git         cd8c41c → 1685ab4
```

Helpers `ng_epoch_legal` / `ng_epoch_pack` / `ng_epoch_gen` /
`ng_epoch_visible` and `NG_EPOCH_STAMP_W=8`. Store calls these. Same
epoch object as STORE, not a second law.

`SOURCE_SHA.txt` never hashed this file. Do not read the four-key
manifest as a complete fileset inventory.

### G4 — `NOT_IN_FILESET`

```text
BIT-07  G4=D1BF034018E1BBB28999EEDB6035278934F1AA898849EBA1E1F633B77DD4DAC9
unique  G4=6F0194A208736A86E9434AACC3DE5B23551FDBB89E7559FB897F12941B689513
file    rtl/native_graph/learn/a7ng_persist_gen_fast.sv
```

Build tcl **hashes** this path then **refuses** it:

```text
REFUSE: persist_gen_fast FAST-ID path in C9 SoC fileset
```

Active Gate14 path is `g1g5_cofit` → `learned_prior_graph` →
`learned_prior_store`. G4 SHA delta is epoch law copied into a file that
is **not synthesized into `1F0F2ABB`**. It is not a second unknown on
this bit.

### TOP — `OBSERVABILITY_ONLY`

```text
BIT-07  TOP=F395B1BB30E64AB7888B2AC6B72AB4D1229399C93FAD33161D6A18B9C4D4C7AE
unique  TOP=31EEE943F27F0FBBB7082C1951B622EB7A67016803412F0F103B80D22E686D60
file    rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv
git     cd8c41c (exact BIT-07 TOP SHA) → df16ff1 only
```

`git diff cd8c41c HEAD -- …ab_soc_top.sv` is **+153 / −4**, one commit:
`df16ff1 E2R-CORE-START-RST-PROBE-00`. Added UART ASCII messages
`CLK_ALIVE` / `RST_REL` / `START_SEEN` / `RST_CAUSE` (sent_mask 71..74),
sticky observe flops, `boot_count_100`, `crst_fall_100`. JA port stays
removed (same IO-SAFE contract as BIT-07).

Not changed in that diff: TinyGPT, C9 pack, query tokens, persist store
ports, GEN cookie, `start_q` generation. `start_tog` only observes
`start_q`.

Reset / START / owner ranks 1–4 are already closed on unique bit
`7ECCA0E2…`. Do not reopen them from this TOP delta.

**Placement caveat (honest, not a second persist unknown):** extra UART
LUTs/FFs mean `1F0F2ABB` is **not** a placement-identical twin of
`3A7EF204`. That is why the bit SHA differs. The persist/GEN **law**
unknown remains the epoch object. Extra ASCII lines must be ignored by
the host decoder; they are not CFRAME payload. If GEN is legal and C9
still diverges, stop at first divergence — do not blame TOP probes
without new evidence.

### ORACLE — `ORACLE_METADATA`

```text
BIT-07 SOURCE_SHA ORACLE=062932B3853144526B1C9A42C2076966C45EF108C707546C68C9BC89754C912B
unique SOURCE_SHA ORACLE=3CA31319969F22E7280BEFAF58C879003CE60C61BD21BED40945B65C3B09D5B4
```

JSON **values are identical** (HOLD_A C9 `8382238122802120` OUT 653,
UNREL 689, CONTRA 237, HOLD_B 60, same token lists, same query SHAs).

`062932B3` is the CRLF byte image of the same JSON (`len 1645`).
`3CA31319` is LF (`len 1571`). Current bags on disk both hash
`3CA31319` and compare equal byte-for-byte.

Oracle is frozen. Do not retarget.

---

## Manifest keys that do **not** differ

Copied from BIT-07 `SOURCE_SHA.txt` vs this bag:

```text
CDC     5AF2FBDA…  IDENTICAL
REL     56C8AE66…  IDENTICAL
ABCORE  5D493BFC…  IDENTICAL
COFIT   965F97DE…  IDENTICAL
LPG     A3B8B77C…  IDENTICAL
GLUE    8F0CCBF7…  IDENTICAL
PAX     809C3C8E…  IDENTICAL
TINYGPT 75706E2C…  IDENTICAL
BIND    C5F57AD1…  IDENTICAL
TILE    06F62A3A…  IDENTICAL
DMA     20BAE36E…  IDENTICAL
CUE     1721C298…  IDENTICAL  PHYS=4
HEAP    6A651306…  IDENTICAL
WF      2F8888AD…  IDENTICAL
BOOT    C02C8D9E…  IDENTICAL
G1      2219DA29…  IDENTICAL
G2      06143862…  IDENTICAL
G3      2177073D…  IDENTICAL
```

---

## What this experiment can close

If silicon on `1F0F2ABB` shows:

```text
GEN legal  (not FFFFFFFF)
20 architectural commits
HOLD_A C9 = 8382238122802120
OUT A     = 653
UNREL     = 689
CONTRA    = 237
HOLD_B    = 60
```

then P_BOOT / dirty-DRAM epoch root cause is **closed on board**. That is
a large silicon step. It is still **not** `GATE14_PASS`. Gate14 still
requires teacher-off, reset/retrain, persistence identity, LM active-chain,
and the rest of the acceptance checklist.

If GEN is still `FFFFFFFF` / illegal: `EPOCH REBIRTH NOT CLOSED ON SILICON`.
STOP.

---

## Freeze (do not violate for this program)

```text
bit SHA must stay 1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9
no cleanup / refactor
no extra probe
no extra RTL merge
no regenerate bit
slice free = 269 / 15850 (~1.7%)
WNS = +0.373  TNS = 0
```

Further instrumentation can move placement and destroy the comparison.

Do not mix WDMA `cmd_hold` relatch, AXI persist_owner lifetime, digest XOR
omitting subj/rel/obj, or 16-bit DDR key truncation into this freeze.
Those are separate roots.

Human owns JTAG `210319BE776EA`. UART COM12 @ 115200.
Agent `PROGRAM=NO`.
