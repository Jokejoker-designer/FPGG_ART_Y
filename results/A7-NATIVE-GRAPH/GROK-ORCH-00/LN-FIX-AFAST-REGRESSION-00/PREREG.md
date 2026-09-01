# LN-FIX-AFAST-REGRESSION-00 — preregistration (before data)

**PROGRAM=NO.** Core-only SIM_FULL=1 XSim. No graph / MIG / COM12 / JTAG / bit / P&R / full-chip / cofit.  
Do **not** overwrite G5 FAIL or G5 R1 bags. Do **not** hardcode 664 as patched acceptance.

## One unknown

Does LN-FIX core SHA `75706E2C…E8EFB5FB` change frozen Native-V1 A-FAST / phase-1 `pred=664`, and which output matches **independent Python** on the **exact** bind `ctx_n` / `ctx_pack` / token order that produced historical 664?

## Frozen before any A/B XSim

| Item | Value |
|------|--------|
| Historical old core | SHA256 `29D230FC…12290C9E` (CRLF working-tree of 660ccd7) **result 664** |
| Patched core | SHA256 `75706E2C…E8EFB5FB` |
| Bind | `ctx_idx=0` `ctx_n_in=8` `pack[8*i +: 8]=id[i][7:0]` |
| Pack | `64'h3b392b291b190b09` |
| Token order | `[9, 11, 25, 27, 41, 43, 57, 59]` |
| WMEM this gate | `tests/xsim/a7lm06_wmem.hex` SHA `C204E559…3001E0` (G5/LN-MU image) |
| Historical A-FAST WMEM cite | `9A6BBC7A…67D10F` (A-FAST-LM-BOARD-LANE-00 PREREGISTER; **not** this file) |
| Python | `python/ref/a7lm06_fixed_ref.py` SHA `05FACAF4…E8EEA870` law `lm06-signsgd-v1` |
| Sanity | `forward([1])=744` |

Python oracle on this WMEM + this pack is frozen in `ORACLE.json` **before** XSim. Do not edit after.

## A/B

Same TB, same WMEM init, same `load_ctx(8, pack)`, same `start_fwd`.  
Arm OLD = bag `tiny_gpt803k_core_OLD.sv`. Arm NEW = `rtl/lm/tiny_gpt803k_core.sv`.  
Trace `pred` and SMX `logit0`. G1–G5 source SHA must stay unchanged.

## Verdict rules (do not rewrite)

- **PASS** only if **patched core == Python** (pred and logit0).
- If patched pred **≠ 664**: emit **`SEMANTIC_CHANGE_EXACT`**. Keep 664 as **historical old-SHA** evidence. Do **not** force / hardcode 664. Do **not** retarget acceptance to 664.
- If patched pred **= 664** and equals Python: exact A-FAST regression PASS.
- If patched **≠** Python: **FAIL**. Do not patch law/weights to match.

CONTROL ntok=1 pred **744** required on both arms (image lock).

## Not this gate

Full-chip, P&R, bit, COM12, JTAG, board, Teacher-Off, cofit.
