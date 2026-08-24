# Resource/timing risk

Full-parallel is an explicit research choice.

The design contains:

- 64 signed weight registers;
- 64 simultaneous train delta lanes;
- 64 inference add/sub contribution lanes;
- 8 parallel reduction trees;
- 8 agent threshold outputs.

Expected risks on XC7A35T:

- combinational adder-tree depth;
- routing congestion;
- fanout on stimulus and teacher buses;
- high toggle activity/power;
- replication added later for traces/LIF state.

Mitigation order that preserves full parallelism:

1. balanced/pipelined reduction trees;
2. register stimulus/teacher at transaction boundary;
3. local floorplanning by destination agent;
4. one pipeline stage between contribution and reduction;
5. one pipeline stage before agent threshold;
6. only then consider narrower proven-safe weight widths.

Do **not** replace the 64-lane architecture with one shared MAC in this branch.
