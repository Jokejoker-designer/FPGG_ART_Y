# Full-parallel RTL skill

This branch intentionally studies spatial parallelism.

Requirements:

- 8 destination agents operate concurrently.
- 8 source lanes feed each destination concurrently.
- 64 plasticity decisions exist logically in the same TRAIN transaction.
- Do not serialize the 8x8 matrix without creating a separate comparison architecture.
- Pipeline is allowed; resource sharing across synapses is not the default.
- Preserve bit-exact behavior through any pipeline retiming.
- Report post-synthesis LUT/FF/DSP/BRAM, WNS/TNS, congestion and power.
