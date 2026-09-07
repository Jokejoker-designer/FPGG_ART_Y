# RTL vs frozen golden — U3Q-R3

```text
LAW              = qse-v1-lexicon-hdc-00  (unchanged)
PREREG           = _PREREG.md
FROZEN_VECTORS   = FROZEN_VECTORS.json  n=98
XSIM             = U3Q_R3_RTL_GOLDEN_PASS
MATCH            = 98 / 98
MISMATCH         = 0
FIRST_DIVERGENCE = none
COVERAGE         = 1.0
HOST_*           = 0 on every vector
THRESHOLD/LAW    = not retargeted
```

Sections: entity 42, intent 18, same-ent-diff-intent 3, unrelated 8,
perturbation 5, adversarial 20, sentinel 2.

Transcript: `xsim_golden.log`. Per-vector CSV: `golden_compare.csv`.
OOC: DSP=0, utilization-only, no timing claim, Tcl exit=0.
