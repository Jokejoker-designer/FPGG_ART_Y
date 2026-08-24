# FROZEN_VERIFY — `lm06_wm_00`

Live recomputation at 2026-08-22, after all candidate runs. Falsifier **F3** = any frozen bitstream,
frozen manifest, `mig.prj` or frozen RTL file byte-modified.

**Result: 16 / 16 MATCH, 0 MISMATCH.**

## 1. Frozen LM-06 sources — byte-identical, both arms

Every file below is an input to **both** the CONTROL and the CANDIDATE compile. The candidate
substitutes working-set memories by **module-name shadowing** in a separate xsim work directory, so
no frozen source is edited, and the arithmetic core is provably the same file in both arms.

| file | SHA256 | mtime (UTC) | verdict |
|------|--------|-------------|---------|
| `rtl/lm/tiny_gpt803k_core.sv` | `B8F485E5A98903A56C23BADEB30CD84451E728F42E64296343086E6D51351880` | 2026-08-18T16:13:37Z | MATCH |
| `rtl/lm/a7lm06_pkg.sv` | `77B01CBDC4654CF192F35CE6CC378DDEC63C35729BE7AB2D2EA22E98B878AED5` | 2026-08-18T13:07:54Z | MATCH |
| `rtl/lm/isqrt32.sv` | `03418C75478B94AE031C4E76B86DC32E2CF6F4D10473AC4CDECE4673C495D48F` | 2026-08-16T07:30:49Z | MATCH |
| `rtl/lm/floordiv_s48.sv` | `C386CD14BDAEE56CCF3D2543E8815C39B13EA364FDEAE12A5DD8A30D634C1182` | 2026-08-16T07:19:33Z | MATCH |
| `rtl/lm/weight_tile803k.sv` | `C7BEB34CC13529BDDD0936E21AA7983F6C1A7C6338BD9268D6AEDACDCC9E777E` | 2026-08-18T17:35:57Z | MATCH |
| `rtl/lm/weight_bram_tdp8.sv` | `80474BCAAEE45DACFB1F86C15FB5AAE328E8DC688F7394786CEAA217F32DD4F5` | 2026-08-17T20:03:12Z | MATCH |
| `rtl/lm/lm06_persist.sv` | `C25822966E3C6C1914D16E5A5E6C92E8CCC453694BC85198A4959F9F3B32B24E` | 2026-08-18T17:35:57Z | MATCH |
| `rtl/lm/weight_bram803k.sv` (CONTROL working set) | `18C65CEFF035455C263FB5983F27ECA19C38706EAF6A68B8C963F51FAA57E72D` | 2026-08-18T13:07:54Z | MATCH |
| `rtl/lm/act_ram128k16.sv` (CONTROL working set) | `1FCD9D4343684378976FD6A29EE02BC2D4F18B4D378B6FC4CFA92674F65D38D9` | 2026-08-18T13:07:54Z | MATCH |
| `rtl/lm/snap_ram4k16.sv` (CONTROL working set) | `A2D02401CF28596F9E429EEC1AB537644C10BAFF3C808C360BE4BED7AB78120A` | 2026-08-18T13:07:54Z | MATCH |

All ten mtimes **predate** this gate's window (2026-08-22T05:28Z onward).

## 2. Frozen bitstreams and recorded evidence

| artifact | SHA256 | expected by | verdict |
|----------|--------|-------------|---------|
| `build/out/arty_a7_lm06c3.bit` | `222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6` | `docs/contracts/A7-LM-06-CONFIRMATION.md` | MATCH |
| `results/A7-LM-06/hardware_c3/ladder.json` | `37A53A73ED551910F4F28E164749F86967B2B1B376B29027B859DA165E689B61` | `docs/contracts/A7-LM-06-CONFIRMATION.md` | MATCH |
| `build/out/arty_a7_lm05.bit` | `1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51` | `AGENTS.md` | MATCH |
| `build/out/arty_a7_lm04r5.bit` | `A177E0989956DF08C7150E451984C914E1D53B1FCF96A49EBEC68CE8497A55F8` | `ladder.json` frozen block | MATCH |
| `tests/xsim/a7lm06_wmem.hex` | `9A6BBC7AC8AF82725CAFD0B50241EE683C07FB9943C754753025F3569967D10F` | gate-start record | MATCH |
| `tests/xsim/a7lm06_expected.txt` | `0449A78584691718F89C978E236EA96A4BB7A1E1909B3328D5B23A32B0808FB4` | gate-start record | MATCH |
| `tests/xsim/a7lm06_after.hex` | `81865273AD2025DA86A7415267E36CBACD3ADD17D051AFEEE8AEDE05864DE271` | gate-start record | MATCH — **not overwritten** |
| `tests/xsim/tb_a7lm06_core.sv` | `01C539992117B779FB550396286BCBA7F395A8A6599A790B15EDA2321CFFABF2` | gate-start record | MATCH |

`a7lm06_after.hex` deserves a specific note: the pre-existing frozen bench `tb_a7lm06_core.sv`
`$writememh`s to that exact filename. This gate does **not** run that bench, and its own bench writes
only to `raw/wm00_*_after.hex`, so the pre-existing recorded image survives byte-identical.

## 3. Digilent AXI MIG — untouched

| property | value |
|----------|-------|
| `vivado/ip/mig_7series_0/mig_7series_0/mig.prj` SHA256 | `870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D` |
| Value recorded by `a7-vivado-gate` in `ddr_wavefront_00` | `870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D` |
| **MATCH** | **YES** |
| mtime | 2026-08-16T14:38:30Z — predates this gate by 6 days |
| Hand-edited this gate | NO — this gate instantiates no MIG at all |

## 4. Law and contract surfaces not touched

Nothing in this gate reads or writes these paths, and no file under them changed:

```text
LM-06 arithmetic law  lm06-signsgd-v1   shifts / LN STE / sign-SGD / sat8/16/32 / step_sign
LM-06 weights         a7lm06_wmem.hex   same file, same SHA, both arms
LM-06 geometry        V1024 C128 d128 L4 H4 dff256 P802816
01R law / HIT_MAX     rtl/eam, docs/contracts/A7-EAM-01R.md
02M law               docs/contracts/A7-EAM-02M.md
TermGen law           rtl/native_graph/termgen
Top-K law             rtl/native_graph/topk
relation law          rtl/native_graph
encoder               rtl/eam, results/A7-EAM-03E
learning/training law rtl/train
HNSW / NTDE           absent from this gate
frozen manifests      results/A7-LM-06/build_manifest*.json
```

## 5. Additive-only proof for the candidate RTL

Three new files, all under `rtl/native_graph/memory/`, none of which existed before this gate:

```text
rtl/native_graph/memory/a7ng_lm06_wm_wbank.sv
rtl/native_graph/memory/a7ng_lm06_wm_act.sv
rtl/native_graph/memory/a7ng_lm06_wm_snap.sv
```

Plus one new bench and one new runner:

```text
tests/xsim/tb_a7ng_lm06_wm.sv
tests/xsim/run_a7ng_lm06_wm.ps1
```

Zero existing files were modified outside `results/A7-NATIVE-GRAPH/LM06-WM-00/` and the one appended
line in `results/A7-NATIVE-GRAPH/STATUS/DISPATCH_LOG.jsonl`.

`LOOP_STATE.json` was **not** edited by this agent.

### Disclosure — `LOOP_STATE.json` mtime moved inside the gate window

Reported rather than glossed, so the auditor does not have to discover it.

| property | value |
|----------|-------|
| mtime observed at closeout | 2026-08-22T06:16:15Z — **inside** this gate's window (05:28Z onward) |
| `updated` field | `2026-08-22T05:20:00+00:00` — **unchanged**, still predates the gate |
| `next` | `lm06_wm_00` — unchanged |
| `queue[lm06_wm_00].status` | `OPEN` — unchanged |
| `queue[lm06_wm_ladder].status` | `BLOCKED` — unchanged |
| `queue[bram_owner_00].status` | `BLOCKED` — unchanged |
| `queue[full_integration].status` | `BLOCKED` — unchanged |
| queue length | 52 — unchanged |
| SHA256 at closeout | `A4494B6AF9BC0749498C74D14F83256FEB59967E03E313255122D992A2250067` (34,301 B) |

This agent issued no write to that path; every tool call touching it was a read. The content is
semantically identical to the state read at gate start, so the mtime move is a filesystem touch (IDE
indexer or the parent process), not a state change. The SHA above is recorded so the parent can
confirm nothing was flipped before it flips the gate itself. **No status was changed by this gate.**

### Second observation, during the human-correction pass (2026-08-22 ~06:55Z)

While re-hashing the edited files, `LOOP_STATE.json` was found **changed again** — by the parent, not
by this agent:

| property | value |
|----------|-------|
| mtime | 2026-08-22T06:34:45Z |
| size / SHA256 | 35,076 B / `963C79C282A05A27FC85CEEB0FC31292F295FDD43659116C05132C255EBF0FBD` (was 34,301 B / `A4494B6A…`) |
| `updated` | `2026-08-22T05:20:00+00:00` — still unchanged |
| `next` | `lm06_wm_00` — unchanged |
| `lm06_wm_00` / `lm06_wm_ladder` / `bram_owner_00` / `full_integration` | `OPEN` / `BLOCKED` / `BLOCKED` / `BLOCKED` — all unchanged |
| queue length | 52 — unchanged |

Recorded because the manifest SHA for this path now differs from the one in the closeout table above,
and an auditor comparing the two must not read that as tampering by this agent. **No write to
`LOOP_STATE.json` was issued by this agent at any point, before or after the correction.** The parent
also created `results/A7-NATIVE-GRAPH/STATUS/VERDICT_lm06_wm_00_BINDING.md` and appended its own
`BINDING_VERDICT` line to `DISPATCH_LOG.jsonl`; neither was written or altered by this agent.

## 6. No board activity

| check | value |
|-------|-------|
| synthesis run | NO |
| implementation run | NO |
| bitstream written | NO — newest `.bit` mtime is 2026-08-18T19:16:55Z (`arty_a7_lm06c3.bit`), predating this gate |
| COM12 programmed | NO |
| `program_hw_devices` invoked | NO |
| `r2_rdb` latched | NO |
| board claim made | NO |
| `NATIVE_V1_MINI_AI_BOARD_PASS` declared | NO — AI does not declare it |

Evidence class of this gate is therefore **simulation-class**. `XSIM != BOARD`,
`FITS != RUNS`, `POST_ROUTE != FUNCTIONAL_INTEGRATION`.

### Toolchain hygiene

All eight xsim work directories created by this gate (`tests/xsim/wm00_*`) were removed at closeout;
their logs are archived unedited in `raw/` and hashed in `SHA256.txt`. No `xsim` / `xelab` / `xvlog`
process from this gate is still alive.

Pre-existing residue that is **not** from this gate, disclosed so it is not attributed here: the
`tests/xsim/{xsim,xelab,xvlog}.{log,pb,jou}` and `*.backup.*` files (newest mtime 04:47:37Z, all
predating the 05:28Z gate start), the repo-root `xelab/xvlog` artifacts (newest 04:49:17Z), and the
long-lived Vivado GUI process PID 25604 started 01:22:51Z. That process only refreshes its
`vivado_pid25604.str` heartbeat; it recorded zero `program_hw_devices` events. The same items were
already recorded as MINOR-2 by `a7-vivado-gate` on `ddr_wavefront_00`.
