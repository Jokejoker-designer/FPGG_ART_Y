# GATE LOCAL-MINHEAP-STREAM-TOP8-00

```text
GATE=LOCAL-MINHEAP-STREAM-TOP8-00
LABEL=MINHEAP
PHYS=4
PROGRAM=NO
PROMPT_SHA256=DC57B133681BA2DA35FEECBEA5B04317DF9406B47B1DDCCE1198090D7BBD3B51
```

Keep 4 physical Fold6 lanes + global `a7ng_topk_wavefront_minheap`.
Replace local combinational `a7ng_topk` (~7800 LUT) with exact streaming Min-heap.
Do not store all 16 scores then fire bitonic.
Do not promote TWO-LANE. Do not start 1-lane.
Do not program board (`program_authorized=false`).
