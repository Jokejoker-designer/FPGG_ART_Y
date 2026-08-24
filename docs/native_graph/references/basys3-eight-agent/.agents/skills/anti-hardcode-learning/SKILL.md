# Anti-hardcode learning skill

When modifying this research project:

- Treat semantic role assignment at reset as a defect.
- Do not create prompt→response lookup tables.
- Do not initialize weights to target mappings.
- Teacher/targets may influence weight updates only in TRAIN.
- Require blind remapping tests across multiple random sessions.
- Require reset-erases-learning and retrain-new-mapping tests.
- Distinguish signal encoding from learned association.
