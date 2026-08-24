# BRAM loss decomposition — LM06-BRAM-PHYS-AUDIT-00

**DCP:** `build/out/a7lm06_post_route.dcp`  
**SHA256:** `CE6A6AD7FCDD9BC4D602CBD1D4B679FDE56C551A65AC8D0400418F0A5CDA6022`  
**Device:** `xc7a100tcsg324-1` — physical RAMB36 = 36864 bits/tile  

This document separates **parity waste**, **width/tail waste**, and **port/banking-driven tile count**. It does **not** claim saved BRAM.

---

## 1. Tile budget (FACT)

| Owner | Tiles | Share of 132 |
|-------|------:|-------------:|
| `u_a` | 66 | 50.0% |
| `u_w` | 64 | 48.5% |
| `u_snap` | 2 | 1.5% |
| **Total** | **132** | 100% |

All 132 cells are `RAMB36E1`. ECC read/write disabled on all (`EN_ECC_*=0`).

---

## 2. Loss classes observed

### A. FULL_X72_PAYLOAD (17 tiles) — parity already payload

| Where | Count |
|-------|------:|
| `u_w` SDP `*_reg_0` | 16 |
| `u_a` SDP `mem_reg_0` | 1 |

Connectivity (probe): `DIPADIP/DIPBDIP` ← `wr_data[64:71]`, `DOP*` → `q*/rd_data[64:71]`.  
**Loss from unused parity: none** on these tiles. η ≈ 1.0 relative to 36 Kb physical.

### B. WIDTH_BOUND + TAIL_FRAGMENT_32b_IN_X72_SHELL (17 tiles)

| Where | Count |
|-------|------:|
| `u_w` SDP `*_reg_1` | 16 |
| `u_a` SDP `mem_reg_1` | 1 |

Same cells report `READ_WIDTH_A=72`, but:

- `DIADI` carries `wr_data[72:103]` (32 signal bits)
- **all 8 DIP pins tied to `<const1>`**
- outputs use `DOADO[0:31]` → `q*[72:103]` (no DOP signal)

So each logical **104-bit** word = one FULL_X72 tile + one 32-bit fragment living inside an x72-configured shell.

**Parity on these 17 tiles is unused as payload** (`PARITY_UNUSED_NO_TILE_GAIN`).  
Filling DIP with metadata would **not** remove a physical tile: the tile is still required for the 32 data bits unless the 104-bit layout is redesigned.

### C. BIT_SLICED_PORT_BOUND (96 tiles)

| Where | Count | Pattern |
|-------|------:|---------|
| `u_a` TDP | 64 | `mem_reg_{0..3}_{0..15}` — 4×16 |
| `u_w` TDP | 32 | `TILE.u_bank mem_reg_{0..3}_{0..7}` — 4×8 |

Probe on `u_core/u_a/mem_reg_0_0`:

- Shared `ADDRARDADDR[*]` / `ADDRBWRADDR[*]` nets under `u_core/u_a/`
- Shared `clk50`
- Single data bit on `DIADI[0]` (`sat16[0]`); other DIADI tied const
- DIP pins tied const (no payload)

**Limiting dimension = port / dual-port inference**, not raw bit capacity.  
Unused parity exists, but **η_BRAM free-bit % → tile savings is illegal**: one bit-slice still consumes one RAMB36 until the memory is re-inferred wider.

### D. PARITY_USED / x9 aspect (u_snap)

`u_core/u_snap/mem_reg_0`: `READ_WIDTH=9`, `DIPADIP[0]` and `DOPBDOP[0]` carry the 9th bit of `rdata`.  
`mem_reg_1` remains **UNKNOWN** at pin-payload granularity (mostly const DIP; 7–8 DI signals) — not promoted to a tile-gain claim.

---

## 3. Decomposition of “why 132?”

```text
132 = 64 (u_a bit-slice TDP)
    + 32 (u_w bit-slice TDP)
    + 16 (u_w SDP full-x72)
    + 16 (u_w SDP 32b tail-in-x72)
    +  1 (u_a SDP full-x72)
    +  1 (u_a SDP 32b tail-in-x72)
    +  2 (u_snap x9)
```

| Mechanism | Tiles driven | Parity tile-gain possible? |
|-----------|-------------:|----------------------------|
| Dual-port bit-sliced inference | 96 | **No** (port-bound) |
| 104b word as 72+32 split in x72 shells | 34 SDP | **No** via DIP fill alone |
| Snapshot x9 | 2 | **No** whole-tile |

---

## 4. estimated_removable_tiles

**All logical banks: 0.**

Per gate law: only report >0 when a concrete legal remapping shows N→N−k.  
No such remapping was executed (READ_ONLY). Free-bit percentage was **not** multiplied by tile count.

---

## 5. What is *not* the loss driver

- ECC reservation: **absent** (all `EN_ECC_*=0`).
- “All 34 SDP x72 waste parity”: **false** — 17 use parity as payload; 17 waste parity **and** width.
- “TDP width=1 means 1-bit logical memories”: **false** — they are slices of wider logical arrays.
