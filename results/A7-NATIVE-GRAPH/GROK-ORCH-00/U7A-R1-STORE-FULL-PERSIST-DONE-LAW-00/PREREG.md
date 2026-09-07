# PREREG — U7A-R1-STORE-FULL-PERSIST-DONE-LAW-00

```text
GATE            = U7A-R1-STORE-FULL-COMMIT-LAW-00
BAG             = U7A-R1-STORE-FULL-PERSIST-DONE-LAW-00
BASE            = b93520f39541455e26f08d64960f660ba6a1e701
U7A             = FAIL immutable (CONFIRMED_DEFECT store-full persist_done)
PRIMARY_UNKNOWN = persist_done/c7_ack only if BRAM wrote this update?
RTL_EDIT        = YES  a7ng_learned_prior_store.sv P_UPD tail only
NOT_IN_THIS_GATE= TYPE_CLASS→learn wire; persist_gen_fast; Q-head; BIT; PROGRAM
BIT             = NO
PROGRAM         = NO
REPROGRAM_AGAIN = NO
U7              = CLOSED
```

Law:

```text
P_UPD complete:
  commit = wrote || ram_we    // match during scan OR alloc this cycle
  if commit: ack_count++; c7_ack; persist_done
  else:      persist_nak; no ack_count; no persist_done
  always return P_IDLE
```

U7A FAIL stays FAIL. This is the one-unknown repair.
COM12 seat-checked OK. No bitstream.
