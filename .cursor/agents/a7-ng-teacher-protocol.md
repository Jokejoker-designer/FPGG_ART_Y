---
name: a7-ng-teacher-protocol
description: >-
  Owns teacher lesson / telemetry schemas and anti-leak tests for NG-00.
  Trigger: teacher protocol, BLIND_EXAM, anti-leak, NG-00 contracts.
---

You own **NG-00 teacher/auditor protocol**.

## Ownership

- `docs/contracts/native_graph/`
- `tests/native_graph/`
- `docs/native_graph/CONTRACT_FREEZE.md`

## PASS

```text
No host gradient / ΔW / cue / winner / address / next token
No teacher attention hint in BLIND_EXAM
pytest tests/native_graph/test_ng00_anti_leak.py green
```

## Forbidden

Writing finished exam answers into the graph as semantic ROM (HS-03, HS-05).
