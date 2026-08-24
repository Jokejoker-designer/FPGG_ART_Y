# A7-LM-00 through A7-LM-04 full board replay — 2026-08-18

Board: Digilent Arty A7-100T, JTAG `210319BE776EA`, UART COM12.  
Vivado: 2026.1.  
Replay outputs were redirected under this directory; canonical close evidence was not overwritten.

| Milestone | Bit SHA-256 | Replay result | Key evidence |
|---|---|---|---|
| A7-LM-00 | `449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783` | PASS | logits 1000/1000; gradients 128/128; generate 20/20; CE 512→304; AFTER zero writes |
| A7-LM-01 | `96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8` | PASS | 702,545,920 bytes written and read; 5.234375 whole-memory equivalents; recalibration 100/100 |
| A7-LM-02 | `7CEBA854BDE500DDC87C4742315C45562CB5902C6F66377BCE499DA43BD95CC4` | PASS | batch 10,000 exact; hazards 0; compute utilization 1.0; DDR efficiency 0.80646 |
| A7-LM-03 | `C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1` | PASS | CE 128→64; fold exact; writes 806,976; AFTER zero writes |
| A7-LM-04 R3 | `FAC912B3DB543C312565FAA58A457A568E091F156592E4DC82987E92FB8E0318` | FAIL / HOLD | first-try K513 mismatch; held-out median drop 0%; collapse guard FAIL |

## A7-LM-04 R3 hardware findings

- K=257 first issue: PASS.
- K=511 first issue: PASS.
- K=513 first issue: **FAIL**.
  - board fold: xor `4227079101`, add `4211053895`, macs `65664`
  - oracle fold: xor `4186759747`, add `4270895305`, macs `65664`
  - `dma_under=0`, `bank_haz=0`, `axi_berr=0`, `axi_rerr=0`, `swaps=2`, `ntile=3`
- Requant +sat / -sat / non-sat: PASS.
- One-full update and non-head-only distinction: PASS.
- DDR flush/reload 100,352 bytes: PASS.
- AFTER zero writes: PASS.

## A7-LM-04 R3 held-out replay

The frozen R3 recipe and corpus were replayed without retuning:

| Init seed | FPGA CE | Relative change | Result |
|---|---:|---:|---|
| 17 | 2016→2048 | -1.587% | degrade |
| 19 | 2048→1792 | +12.5% | constant-class collapse |
| 23 | 2032→2032 | 0% | no improvement |
| median | | **0%** | FAIL |

The FPGA values for seeds 17 and 23 are not identical to the stored pre-silicon R3 oracle aggregates. This does not change the FAIL verdict, but same-init multi-token forward parity remains an additional unresolved item.

## State after replay

- A7-LM-00/01/02/03 remain BOARD_PASS / FROZEN.
- `ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED` remains ungranted.
- A7-LM-04 remains HOLD.
- The separate A7-LM-05 contract remains OPEN by explicit user waiver; this replay did not run LM-05 and does not grant the LM-04 quality claim.
- The board is left programmed with `arty_a7_lm04r3.bit`.
