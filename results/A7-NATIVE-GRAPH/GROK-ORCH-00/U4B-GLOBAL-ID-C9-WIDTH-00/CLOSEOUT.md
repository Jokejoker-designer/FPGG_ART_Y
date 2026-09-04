# CLOSEOUT — U4B-GLOBAL-ID-C9-WIDTH-00

Live ID path is 20-bit: `c9_id20_o` / `ctx_pack20_o` via `a7ng_id20_pack`.
Sentinel **799999 = 0xC34FF** does not alias to 0xFF. Legacy 64-bit C9/LM
pack is diagnostic only. XSim pack + glue/bind chain PASS. U2R impl used
HEAD glue (one unknown); U4B restored after route.

Next fullchip fileset must include `rtl/native_graph/integrate/a7ng_id20_pack.sv`.
