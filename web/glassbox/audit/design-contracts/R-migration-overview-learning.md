# Design contract — Tổng quan + Học (migration honesty)

| Field | Decision |
| --- | --- |
| Screen job | Operator sees what this interaction actually measured, and what the 03E lane cannot produce. |
| Primary user and action | Researcher locks one interaction, then reads compare/update facts or the session headline. |
| Content hierarchy | Provenance first; numbers second; empty/awaiting third. Collapse verdict overrides any “stable” story. |
| Navigation | Existing shell tabs. Replay starts the already-wired store action. Awaiting metrics are not buttons. |
| Visual language | Existing tokens, `Kpi`/`Panel`/`Pill`. Source pills stay outlined for SYNTHETIC. |
| Required states | Missing compare, no writes, no answer, awaiting UART/XADC/LM/DDR/EAM. |
| Responsive | Same 1/2/4/7 grids as the imported shell. |
| Evidence used | Contract session fixture; routed WNS/util reports; AWAITING map in `metrics.ts`. UIZZE catalogue unavailable this turn. |
| Forbidden | BOARD stamp, LM-06-as-running, token/s, EAM hit, DDR %, fabricated CE loss, LiteScope, temperature. |
| Acceptance | `tsc --noEmit` clean for these files; every shown number from `measured`/`buildFacts`/`sessionView`. |
