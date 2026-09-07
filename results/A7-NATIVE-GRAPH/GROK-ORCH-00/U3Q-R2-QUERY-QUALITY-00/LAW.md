# LAW — U3Q-R2 (not a semantic freeze)

Extractor remains FPGA-owned **qfe-v1-crc16-mix-00**.

| Metric | Meaning |
|--------|---------|
| LAW_SELFCHECK | same tokens → same keys. **Not** semantic recall. |
| entity/intent k12 stability | paraphrase bucket coincidence |
| unrelated collision | vs chance 1/4096 |
| perturbation delta | 1-byte edit must move keys |
| retrieval recall@K | **label gold**, independent of keys |

Semantic authority stays **OPEN**. Do not retarget the CRC law to chase paraphrase recall.
