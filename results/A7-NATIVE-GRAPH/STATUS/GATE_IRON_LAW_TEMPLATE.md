# Gate iron-law template (Blueprint V2)

Use for every optimization or transport gate. Copy into PREREGISTER / CLOSEOUT.

---

## Gate metadata

| Field | Value |
|-------|-------|
| Gate ID | |
| Type | implement / repair / bench / law_audit |
| ONE UNKNOWN | |
| Prerequisite gates | |
| Evidence class | XSIM / MIG_XSIM / BOARD / LAW_AUDIT |

## Iron-law declaration

Which term does this gate improve?

| Term | Symbol | Before | After | Measured? |
|------|--------|--------|-------|-----------|
| Query bytes | `B_query` | | | |
| Effective BW | `BW_eff` | | | |
| Compute rate | `R_compute_eff` | | | |
| Control latency | `L_control` | | | |

If **none** → gate is **INVALID** for optimization (doc-only or law audit exception must be stated).

## Anti-claims (check before PASS)

- [ ] Did not claim wall-clock speedup from byte reduction without BENCH gate
- [ ] Did not claim sustained candidates/cycle from emission width alone
- [ ] Did not claim SOA/DDR solved without bytes/query + memory_wait table
- [ ] Did not change frozen law without new `law_id` gate

## Control

| Field | Control value | SOA/test value | Match law? |
|-------|---------------|----------------|------------|
| Candidate set | | | |
| TermGen law_id | | | |
| Scorer law_id | | | |
| Top-K law_id | | | |
| Top-1 oracle | | | |

## PASS criteria

- [ ] ONE UNKNOWN answered with file-backed log
- [ ] DISPATCH_LOG line appended
- [ ] Auditor PASS_NARROW (if implement gate)
- [ ] No HS-01 violation
