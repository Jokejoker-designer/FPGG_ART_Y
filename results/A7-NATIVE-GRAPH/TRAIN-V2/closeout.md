# TRAIN-V2 closeout — retrain attribution protocol

**Law:** `a7ng-train-v2` (bundle: `a7ng-termgen-v0` + `a7ng-wm00-v0` + `a7ng-reset-learned-v0`)  
**Old control law:** `a7ng-learn-v0` / KIDI20 curriculum  
**Evidence_class:** HARNESS  

| Gate | Result |
|------|--------|
| Same 20/40 facts CONTROL vs V2 | PASS |
| Reset learned only | PASS (generation bump; edges/priors cleared) |
| Freeze old model (no delete/edit) | PASS SHA `9E746E3F…` |
| Run A / RESET / Run B forgets A | PASS |
| V2 ≥ CONTROL top1; V2 ≫ WARM | PASS (1.00 ≥ 0.75; Δ vs warm +0.50) |
| Frozen LM-06/01R/02M/A0.3 | MATCH |
| Host gradient / winner / address | forbidden — not used as answer path |

Teacher-off **silicon** exam still ≠ this harness (HS-02 / §14 remain for later board kit).  
No BOARD_PASS. integrate_fit PASS_NARROW ≠ integrated SoC.
