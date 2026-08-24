NG06R_WIDE_ENGINEERING_PASS
date: 2026-08-22
gate: ng06_wide_dispatch
agent: a7-ng-scientific
evidence_class: XSIM
repair: SHA_FREEZE_MATCH (accept live 4C604278; full bag re-run)
bags: BAG_ALWAYS_READY, BAG_SPARSE_READY(seed=0x00A70616), BAG_BURSTY_READY
way16_sparse: util=49.95 ready_duty=49.95 max_jpc=15 starve=0 jobs_acc=799268
way16_bursty: util=50.02 ready_duty=50.02 max_jpc=16 starve=0 jobs_acc=800256
way16_always: util=100.00 max_jpc=16 starve=0
sha_rtl: 4C604278038E016840EBD49C3563EB6068CE4E2B8765DF1A53F8A26707B70052
sha_tb: A20BCA46D6FC497593AD91DCE3B289C9CA5142542FDAF003CEF21AB260F19FB9
log: run_wide_bags_sha_repair.log
not: BOARD_PASS
next: re-audit
