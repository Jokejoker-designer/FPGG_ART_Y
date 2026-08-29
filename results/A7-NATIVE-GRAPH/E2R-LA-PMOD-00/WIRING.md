# E2R-LA-PMOD-00 — cắm Logic Analyzer 24 MHz 8 CH vào Pmod **JA**

**Không nối chân PWR** của LA vào board. **GND trước.** Chỉ 3.3 V. Không kẹp DDR.

## Header Pmod JA (nhìn vào board, răng hướng ra)

```
JA1  ja[0]  G13     JA7   ja[4]  D13
JA2  ja[1]  B11     JA8   ja[5]  B18
JA3  ja[2]  A11     JA9   ja[6]  A18
JA4  ja[3]  D12     JA10  ja[7]  K16
JA5  GND            JA11  GND
JA6  3V3 (không nối LA PWR)   JA12  3V3
```

## Dây LA (nhãn trên hộp)

| LA | Pmod JA | Tín hiệu |
|----|---------|----------|
| **GND** | JA5 hoặc JA11 | GND chung |
| CH1 | JA1 | CORE_LIVE (`CORE_START`) |
| CH2 | JA2 | QUERY_ACCEPT (`Q_GO`) |
| CH3 | JA3 | SOA_AR_FIRE |
| CH4 | JA4 | SOA_R_FIRST |
| CH5 | JA7 | BIND_DONE |
| CH6 | JA8 | LM_ACTIVE (`CORE_BUSY`) |
| CH7 | JA9 | W_STALL |
| CH8 | JA10 | SGO |
| CLK / PWR | **không nối** | |

## PulseView

1. Device: **fx2lafw** / Saleae Logic
2. Sample rate: **2 MHz** (sticky DC; không cần 24 MHz)
3. Samples: 10–20 s, arm **trước** khi program bit
4. CH5=0 + CH7=1 + CH8=0 → khớp UART stall (`BIND_DONE` missing, `W_STALL`, `SGO=0`)
