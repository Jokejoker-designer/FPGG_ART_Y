# Min-heap RTL notes

File: `rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv`  
SHA256: `C197E41948716BEFCD50ABBC558BCEE09CE63BAA1AD61DBC0AF070AEE224DDC0`

Frozen control **not edited**:
- `a7ng_topk.sv` SHA256 `F0A71BFBAE37F16290595A7D18FD54DFEC979ED59F604D1187490426FA8C46FA`
- `a7ng_topk_wavefront_global.sv` SHA256 `D6D6882BD4C5505246C9B24CB95CEF66BE3BC1F0881545AEDCEC302B01C14B7B`

FSM: IDLE → CAND → HEAPIFY (up/down one swap/cycle) → NEXT → SORT (bubble) → COMMIT.
Root = worst retained. COMMIT ranks outputs; **does not** overwrite heap order (that bug caused F1 miss of DEADBEEF).

No soc_top / UART / bind / LM / DDR edits in this gate.
