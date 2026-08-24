# A7-EAM-01R native xsim

**Status:** `A7EAM01R_XSIM_PASS`  
**Snapshot:** `tb_a7eam01r` (xvlog/xelab/xsim 2026.1)  
**Time:** 715395 ns, overflow = 0

| Case | Result |
|------|--------|
| 16 MAP miss + insert | pass, `ovf=0` |
| 16 exact probe, d=0, token match | pass |
| set-byte 1-flip (`key[0] ^= 1`) | HIT d=1 (00G disease) |
| 8-in-one-byte (`^=0xFF`) | HIT d=8 |
| theorem 1-per-byte (`^=0x0101…01`) | HIT d=8 (radius-1) |
| 2-per-byte d=16 | reject |
| unrelated `DEADBEEFCAFEBABE` | reject |

Defaults: `HIT_MAX=8`, `MARGIN_MIN=4`. No full-scan. Index nominates only.

TB keys: `byte[b] = 0xA5 ^ (17*b) ^ (13*i)` so pairwise Hamming ≥ 16 and each bank bucket is unique.
