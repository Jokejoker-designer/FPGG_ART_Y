# A7-LM-04 R5 BOARD PASS — 2026-08-18

**Claim:** `ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED`  
**Scope:** counterfactual target-switch online adaptation on a 100,352-parameter DDR-resident FPGA-updated Transformer. Not 8-way contextual retrieval, conversation, or open-domain language modeling.  
**law_id:** `lm05-signsgd-v1` — unchanged.

## Frozen implementation

| Item | Value |
|---|---|
| board / part | Digilent Arty A7-100T / `xc7a100tcsg324-1` |
| UART | COM12, FTDI `210319BE776EB`, 115200 |
| bit | `build/out/arty_a7_lm04r5.bit` |
| bit SHA-256 | `A177E0989956DF08C7150E451984C914E1D53B1FCF96A49EBEC68CE8497A55F8` |
| timing | WNS +0.157 ns / TNS 0 / WHS +0.030 ns |
| tensor RTL SHA | `2C3A3EF52FB8C7DDC2B2CF4808A62EB0B0BBFB0ECAF46B72BE260F6AA370C996` |
| core RTL SHA | `D5B23E12772A95B36759AB90123B555B11100B50103F49234FAA56DCAF91706C` |

## Repaired root causes

1. The BRAM-to-DDR tile dump now gives synchronous BRAM a complete address-prime cycle before capturing row 0. Silicon proves K257 → K511 → K513 on the first issue for each command, with exact fold and no DMA/bank/AXI errors.
2. Every prefix token now re-enters the layernorm sum/variance/scale states. The multi-token board spot `[20,7]` matches the oracle at pred 140/loss 16 with AFTER enabled and zero writes.

## Conjunctive board result

- upload spots and initial fold exact;
- one full update exact: fold `2/11803320 → 7/11822211`, `wr_n=82048`, different from head-only;
- DDR flush/reload exact for 100,352 bytes;
- AFTER adds zero writes;
- requant positive saturation, negative saturation and non-saturation counts exact;
- all 12 preregistered seed/target runs match the frozen Python oracle at prediction/loss and final fold level;
- median held-out CE drop 100%; worst accuracy 98.4375%; worst Wilson lower bound 91.6659%; target-specific final states are distinct.

## Evidence integrity

| Artifact | SHA-256 |
|---|---|
| preregistration | `28073459CAC369E0FBC73A7B93CA1D79A983E2CDF481B57B76CBB532F0A595A2` |
| one-shot oracle | `CB4DE357C7D5CAD596F07466959AC3AE2F9EF55890462BA830BF7CFAEB4C0DBB` |
| frozen build manifest | `37049F03EFE6396F73047C9E1BE86FF09D7A135313091853F068A5815081C353` |
| board ladder | `8F437583E67023067B9EB2F20627F40C6012264ECD4F2B069BD8E61CAD1A15D1` |
| board manifest | `49B5503625A54BC5170A8053EBD52B36B1360C9F3262DFB8F790551F532A68C5` |

R3/R4 stay on disk as negative evidence. R5 WNS closes LM-04 but is below the separate +0.20 timing threshold, so this release does not authorize LM-05 by timing.
