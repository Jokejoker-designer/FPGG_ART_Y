# FRONTIER-SHOOTOUT research note

feedback.md §11 / R5 asked for bucket vs systolic PQ vs two-level under one workload.

At CAP=64 and 48 pushes/query, exact local+global two-level is algebraically best-first
(max of partitioned exact heads = global max), so B and C match on M1/M2. Bucket fails
because bin FIFO is not a total order. OOC LUT separates B (cheaper) from C.

H_RIVAL (single-seed pseudoreplication) addressed with 64 query seeds and 4 bag modes
(uniform / clustered-bins / ties / adversarial). Still one traffic family — not board.

Do not promote A as exact best-first. Do not claim BOARD_PASS from this shootout.
