# rtl/native_graph

A7-NATIVE-GRAPH RTL root for Digilent **Arty A7-100T**.

## Layout (planned)

```text
rtl/native_graph/
  pkg/          shared widths / score term enums
  scorer/       NG-01 16-lane PE (a7-ng-rtl-scorer)
  topk/         NG-02 comparator tree
  frontier/     NG-02 bucket FIFOs
  memory/       NG-03 DDR shard + BRAM hotset
  top/          board tops (later)
```

## Authority

`docs/NATIVE_AI_ARTY_A7_BLUEPRINT/`  
`docs/native_graph/CONTRACT_FREEZE.md`

Do not place encoder / LM-06 / 01R / 02M sources here. Do not overwrite frozen bits.
