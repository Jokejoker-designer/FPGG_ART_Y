# RESULTS — U7A-R2-ROOT-B-CLOSURE-00

```text
XSIM = U7A_R2_ROOTB_CLOSURE_PASS  (58910 ns)
RTL_EDIT = NO
U7A = FAIL immutable
U7A-R1 = PASS
```

| Item | Result |
|------|--------|
| persist_gen_fast | DISCONNECTED from graph baseline; LEGACY_RIVAL on teacher_off_soc_xsim only |
| store-full 33rd | done=0 nak=1 seq=32 ack=32 miss; 32-set exact |
| existing key while full | commit once |
| G1 orphan/wrong/dup | ACK_ORPHAN / LATE / n_consume=1 |
| consecutive same key | pri=2 |
| competing update | upd_ready 0 while busy |
| reset before BRAM commit | no leftover |
| SchemaV2 high-id / low16 | hit / miss |
| DDR delayed ACK flush | completes |
| reset between SchemaV2 beats | no false record |
| DDR error | NOT_MODELED |
| TYPE_CLASS→learn | NOT_REACHABLE |
| C7_ADDR | OBSERVE_ONLY `03034ff0` |

persist_done remains phase-polymorphic (P_UPD vs P_FLUSH vs boot). R2 does not collapse them into one semantic ACK.
