`timescale 1ns / 1ps
// snap_top_ready_slice.sv — bag-local extract from product SoC top.
// TOP_ELAB=slice_not_soc. Do not xvlog live full SoC (MIG).
// GO-READY-GATE-00: three ANDs (go / arready / rvalid) + mux bits needed.
// AW/W/B not gated here (product top AW/W/B unchanged; TB stubs those ports).
module snap_top_ready_slice (
  input  logic boot_active,
  input  logic wdma_owner_ui,
  input  logic dma_go,
  input  logic arready,
  input  logic rvalid,
  input  logic d_arvalid,
  input  logic d_rready,
  input  logic cdc_arvalid,
  input  logic cdc_rready,
  output logic go_gated,
  output logic arready_gated,
  output logic rvalid_gated,
  output logic arvalid,
  output logic rready,
  output logic cdc_arready
);
  // EXTRACT product top mux (unchanged this gate)
  assign arvalid = boot_active ? 1'b0 : (wdma_owner_ui ? d_arvalid : cdc_arvalid);
  assign rready  = boot_active ? 1'b1 : (wdma_owner_ui ? d_rready : cdc_rready);
  assign cdc_arready = !boot_active && !wdma_owner_ui && arready;
  // EXTRACT GO-READY-GATE-00 three ANDs
  assign go_gated      = dma_go && wdma_owner_ui;
  assign arready_gated = arready && wdma_owner_ui;
  assign rvalid_gated  = rvalid && wdma_owner_ui;
endmodule
