# RESIDUAL — C7_ADDR OBSERVE_ONLY

```text
STATUS          = OPEN
CLOSE           = NO
OWNER_GATE      = U7A / observability cleanup
NOT_IDENTITY    = YES
NOT_CANONICAL   = YES
```

## Fact

`C7_ADDR` is formed from `subj[15:0]`:

```text
rtl/native_graph/learn/a7ng_learned_prior_store.sv
  c7_addr_o <= 32'(NG_DDR_PRIOR_BASE) + {12'h0, upd_subj_i[15:0], 4'h0};

rtl/native_graph/learn/a7ng_persist_gen_fast.sv
  c7_addr_o <= 32'(NG_DDR_PRIOR_BASE) + {12'h0, g2_s[15:0], 4'h0};

rtl/native_graph/learn/a7ng_causal_learn_fast.sv
  c7_addr_o <= 32'(NG_DDR_PRIOR_BASE) + {12'h0, g2_s[15:0], 4'h0};
```

SCHEMA-V2 stores full `subj[31:0]` / `obj[31:0]` on DDR. That does **not** promote `C7_ADDR` to a canonical identity.

## Law

```text
C7_ADDR uses subj[15:0].
C7_ADDR is OBSERVE_ONLY and MUST NOT be treated as canonical identity proof.
Do not silently close this residual.
Track it for U7A / observability cleanup.
```

Do not retarget C7 as a persist-identity substitute. Do not mix this residual into U4-PRE0 or U4-MEM02.
