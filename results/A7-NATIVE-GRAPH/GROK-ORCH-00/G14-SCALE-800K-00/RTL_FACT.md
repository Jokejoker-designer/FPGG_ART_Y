# RTL_FACT — two query paths (no edit)

## Path C9 (Gate14 exam)

| Item | Value | Source |
|------|-------|--------|
| Store DEPTH | 32 | `a7ng_learned_prior_store.sv` |
| Scorer | 1 lane | `a7ng_learned_prior_graph.sv` `u_scorer` |
| Top-K | K=8 | `a7ng_topk_stream_minheap #(.K(8))` |
| AXI4 bytes/exam | 0 | G14-METRIC-MEASURE-01 M7 C9 XSim |
| full_scan 800k | NO — cannot host 800k | DEPTH=32 |

## Path SOA (existence `start_query` / `u_soa`)

| Item | Value | Source |
|------|-------|--------|
| Fetch | all `total_recs_i` | wavefront `target <= total_recs_i` |
| Bytes | 16 × N (AOS) | N=64 MIG: 1024 B |
| Cands into scorer | N (all delivered) | delivered=64 at N=64 |
| full_scan | **YES** | every record fetched |

HS-13: an 800k-episode **SOA** store that fetches all N is a linear scan.
C9 K=8 is bounded but **not** an 800k store.
