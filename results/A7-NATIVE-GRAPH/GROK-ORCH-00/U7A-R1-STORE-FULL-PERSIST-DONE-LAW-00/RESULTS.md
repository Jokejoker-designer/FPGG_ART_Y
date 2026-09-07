# RESULTS — U7A-R1-STORE-FULL-COMMIT-LAW-00

```text
XSIM = U7A_R1_STORE_FULL_COMMIT_LAW_PASS  (51675 ns)
```

Bag path remains `U7A-R1-STORE-FULL-PERSIST-DONE-LAW-00` (same gate).

| Case | persist_done | persist_nak | seq | ack | lookup |
|------|--------------|-------------|-----|-----|--------|
| fill 32 distinct | 1 each | 0 | 32 | 32 | all hit, pri snap |
| 33rd distinct (full) | **0** | **1** | 32 | 32 | miss; 32-set bit-exact |
| existing key while full | **1** | 0 | 33 | 33 | pri+1; neighbor unchanged |
| G1 duplicate reward | n/a | n/a | — | — | n_consume=1, ACK_DUP |
| SchemaV2 high-id | 1 | 0 | — | — | high hit; low16 alias miss |
| reset after identity beat | — | — | — | — | lk_hit=0 |

`persist_nak_o` is **fail completion** (return to P_IDLE) so waiters do not deadlock. It is **not** store success.

U7A FAIL immutable. TYPE_CLASS→learn NOT_REACHABLE. persist_gen_fast unpatched.
BIT=NO. PROGRAM=NO. C7_ADDR OBSERVE_ONLY. Minheap timing OPEN.
