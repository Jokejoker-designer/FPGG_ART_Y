# FPGA-owned 20 distinct facts (CONTROL corpus identity only)

Corpus SHA `23A4B5039CB80FECC338DF26BAB4E31EC8B314F7DBC178AD3AA572EA06963F8E`  
`n_facts=20` ids f01..f20. Text is **not** a UART payload and **not** a host winner.

Each lesson is a distinct triple. Not 20 repeats of PRE_A / qid=1.

| i | corpus | mapping A (rel=1) | mapping B (rel=2) | node A | node B |
|--:|--------|-------------------|-------------------|--------|--------|
| 0 | f01 | subj=A000 obj=B000 | subj=A000 obj=C000 | 0x20 | 0x40 |
| 1 | f02 | A001 B001 | A001 C001 | 0x21 | 0x41 |
| … | … | … | … | … | … |
| 19 | f20 | A013 B013 | A013 C013 | 0x33 | 0x53 |

Unrelated U[i] i=0..7: subj=D000+i rel=3 obj=E000+i node=0x80+i. Never committed in mapping A.

Query tokens (TB → FPGA, not answers):

```text
PRE_A fact i : 0x10+i    i=0..19
PRE_B fact i : 0x30+i
HOLD_A       : 0x02
UNREL        : 0x03
CONTRA       : 0x04   lookup rel=2 on A subj/obj
HOLD_B       : 0x06
```
