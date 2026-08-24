# CLOSEOUT — LM06-SNAPSHOT-LUTRAM-01

**Engineering result:** `PASS_NARROW`  
**Sealed threshold verdict:** `PARETO_WIN` met  
**Adoption description:** `BRAM_ONLY_TRADEOFF` — useful but not free  
**Evidence:** `XSIM + OOC_POST_ROUTE + FULL_POST_ROUTE`  
**Board / bitstream:** none

## Closed unknown

The 4096x16 snapshot can be implemented as distributed RAM while preserving the registered frozen LM-06 workload. Full C3 source substitution post-routes at 130 BRAM, WNS +0.125 ns, TNS 0, WHS +0.011 ns and THS 0.

The candidate frees two BRAM and increases Slice LUTs by 2380 / LUT-as-memory by 1408. Timing still closes but margins decline versus frozen C3. It is accepted as a bounded Project A co-fit lever, not a new BOARD_PASS bit.

## Load-bearing results

- Snapshot unit rerun on current source: 4099 writes, 4102 reads, 3 behavioral collisions, 0 mismatch.
- Full core: `pred=744`, `loss=16`, fold0 `5/94638317`, fold1 `23/94627297`, `wr_n=655616`.
- Frozen workload snapshot activity: 5120 writes, zero same-address collisions.
- Full post-route: 130 RAMB36, 0 RAMB18, snapshot BRAM=0, 37266 Slice LUTs, 3010 LUT-as-memory, 14928 slices, 156 DSP.
- Route: zero failed/unrouted/partial nets and zero overlaps.
- Candidate result directory contains no bitstream; frozen C3 bit SHA remains unchanged.

## Audits and hashes

| Artifact | SHA256 |
|---|---|
| `RESULTS.md` | `B1CC97A70130DC5ABD028C6A3974FFFDD911608466791B4D46D2AC2BE830306E` |
| `AUDIT_PHYSICAL.md` | `A1314F3286CAA40DB1408B585F034A352E59FA16D58054A4ADC78D2594A57139` |
| `AUDIT_FUNCTIONAL.md` | `CFB9FE0E77D62E95A1042FA9659D14F8B22321D788356EB4276EF3261FCB1F81` |
| `AUDIT_REPAIR.md` | `44BD43F6B60E11A4497C4EF18859E59AD98C8EEDF3B604CB80CD9EAF97B37620` |
| full post-route DCP | `FC301A673AACB1A3EBE48498EB82C7EFE491A9A68A32322458590574FB3ACA06` |
| full utilization | `F7D7A2683B0C3C5BC8B4E417AD3E9D167B38EE277EA1BA63878883D31DB86D93` |
| full timing | `D648952675C3CC5F100555186F1DB57CD1110120578EAA9E90CDE59EBCF3D093` |
| full Vivado log | `B86F06986095392B30607629E5213A30F0BD3AFDC322F6C267BD5BD20618C250` |
| current snapshot unit log | `890A8320CA763CA6F2A4FBD1D1660B4056E055ED15FF1C302D4E2E61FDF6981E` |
| full-core log | `6856BF5D740C6D6EBD390D6BB754FBAB4C4788AA43E870066AC778C84ADB6B6E` |

## Boundaries

- Collision-safe only for the measured frozen workload; no generic post-synth same-address collision claim.
- Candidate is a source-substitution experiment under `rtl/native_graph/memory`, not a frozen LM-06 replacement.
- No board, COM12, bitstream, host answer or law change.
- This -2 BRAM result alone does not close Native V1 integration or HS-22.

