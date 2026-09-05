# Native AI CLI V0.2.1

PowerShell-first development console for the V3.1 Native AI project.

Tracks **U6-TYPECLASS XSim PASS** and **U7A REAUDIT_COMPLETE**.
Does **not** claim silicon TYPE_CLASS retrieval, board PASS, Gate14, LM, Q-head, or U7.

## Install

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

Creates a local `.venv` and a Desktop shortcut `NativeAI CLI`.

## Run

```powershell
.\native-ai.ps1
```

Default backend is `demo`: it replays **frozen U6 gold** (CLASS_ID streams, scores, Top-K). It is UX/dev trace only.

```powershell
.\native-ai.ps1 --backend demo --trace full
.\native-ai.ps1 --backend xsim --trace full
.\native-ai.ps1 --backend uart --trace full
```

`xsim` does not launch Vivado in V0.2. `uart` is locked.

## Commands

`/help`, `/status`, `/trace`, `/mode`, `/backend`, `/metrics`, `/reset`, `/export`, `/clear`, `/exit`

## Frozen law shown by /status

- `MASTER_RETRIEVAL_OBJECT = TYPE_CLASS`
- `QUERY_LAW = qse-v1-lexicon-hdc-00`
- `RETRIEVAL_LAW = masked conjunctive`
- Top-K identity = **CLASS_ID**, not raw NID
- U5Q raw FAIL immutable
- T2 PASS, U6 TYPECLASS XSim PASS
- U7A reaudit complete: XSim done⇔CLASS_ID Top-K; SoC Root-B still partial
- U7/U8 CLOSED
- BIT=NO PROGRAM=NO

## Current safety boundary

- no new BIT
- no PROGRAM
- UART final chat locked
- demo scores come from U6 gold (`+8` per bound field), not invented ranking
