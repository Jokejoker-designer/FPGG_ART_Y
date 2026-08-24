# FROZEN / LAW-FREEZE VERIFICATION — ddr_wavefront_00

Hashes from `SHA256.txt` (regenerate with `sha256.ps1`).

## NEW this gate (only these two RTL files were created)

| File | SHA256 |
|------|--------|
| `rtl/native_graph/memory/a7ng_cue_wave_stage.sv` | `5D3D0EAEDC902B4ED36FD97155C9F8BA367992EB794B5CFA4179845C14495A10` |
| `rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv` | `E6DDD67AC14DF8101D0E6BDABA37063E9E3591FC7DB3B65C6C04FD903694B2E4` |

## UNCHANGED — byte-identical to the `MIG-METRIC-00` archive

| File | SHA256 now | MIG-METRIC-00/SHA256.txt | Verdict |
|------|------------|--------------------------|---------|
| `a7ng_ddr_feed_pp.sv` | `1FB685BDC712B1F854F639B8715C207F9D86A838F56E72A95658854C1D274637` | `1FB685BD…4637` | **MATCH** |
| `a7ng_ddr_feed_axi_bridge.sv` | `D07A9742BD61E6D1DAC34F7017B6B817697A2C98CD4A825EFA54F77275F48454` | `D07A9742…8454` | **MATCH** |
| `mig.prj` | `870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D` | `870FA6EE…190D` | **MATCH**, `PortInterface=AXI`, hand_edit=NO |

The two existing feed/bridge modules and the official Digilent `mig.prj` were **not edited**. The
wavefront is a pure addition on top of them.

## Black-box law modules instantiated, not modified

| File | SHA256 | Law |
|------|--------|-----|
| `a7ng_scorer_array.sv` | `57F3F8B19FAD37F7FE9F71ADAB4912EC56D8F3BD4D3260B74808FC281C6F73C7` | `a7ng-scorer-v0` |
| `a7ng_termgen_array.sv` | `5A8697036424592C2817FEB29AB23C7788391DC54ADBADD5B7F10A07B2DD93F7` | `a7ng-termgen-v0` |
| `a7ng_topk.sv` | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` | `a7ng-topk-global-v1` |
| `a7ng_pkg.sv` | `267E5CF1F489E2926645D7914E28727264E18A1CE037CC175CAC7E8FA045959B` | shared types / TermGen HDC |
| `a7ng_mem_schema_v1.sv` | `F0FE426EB7B6968392458F7377BB86D579F768FFE66ABE2A4D8E8FD8D57DEB85` | NodeRecordV1 strides |
| `a7ng_axi_mem_model.sv` | `40DF08BB58E7EB6E1CC0F0A87B4D67564E8EA602CACE166C67EED7D088D8007C` | preflight model, unmodified |

## Not touched at all

01R law · HIT_MAX · relation law · LM-06 · 02M · training/learning law · encoder · HNSW · NTDE ·
frozen bitstreams · `mig.prj` · COM12 (no program) · `r2_rdb` (no latch).
