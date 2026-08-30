`timescale 1ns / 1ps
// snap_top_grant_quiesce_slice.sv — bag-local extract from product SoC top.
// TOP_ELAB=slice_not_soc. Do not xvlog live full SoC (MIG).
// GO-GRANT-QUIESCE-00: grant quiesce FSM + AR/R outstanding + sync_bits
// + ready-gate three ANDs (go / arready / rvalid) + mux bits.
// CDC / ddr_tile_dma not in this file. AW/W/B not gated (product unchanged).
module snap_top_grant_quiesce_slice (
  input  logic        core_clk,
  input  logic        core_rst_n,
  input  logic        ui_clk,
  input  logic        ui_rst_n,
  input  logic        wdma_owner,
  input  logic        r_path_idle,
  input  logic [2:0]  wdma_dbg_st,
  input  logic        cmd_empty,
  input  logic        wdma_owner_ui,
  input  logic        d_arvalid,
  input  logic        d_rready,
  input  logic        boot_active,
  input  logic        dma_go,
  input  logic        arready,
  input  logic        rvalid,
  input  logic        rlast,
  input  logic        cdc_arvalid,
  input  logic        cdc_rready,
  output logic        wdma_owner_grant,
  output logic        go_gated,
  output logic        arready_gated,
  output logic        rvalid_gated,
  output logic        arvalid,
  output logic        rready,
  output logic        cdc_arready,
  output logic [3:0]  wdma_arr_outst,
  output logic        wdma_dma_idle_ui,
  output logic        wdma_arr_quiet_ui,
  output logic        wdma_cmd_empty_ui,
  output logic        wdma_dma_idle_c,
  output logic        wdma_arr_quiet_c,
  output logic        wdma_cmd_empty_c
);
  // EXTRACT product top mux (unchanged this gate)
  assign arvalid = boot_active ? 1'b0 : (wdma_owner_ui ? d_arvalid : cdc_arvalid);
  assign rready  = boot_active ? 1'b1 : (wdma_owner_ui ? d_rready : cdc_rready);
  assign cdc_arready = !boot_active && !wdma_owner_ui && arready;
  // EXTRACT GO-READY-GATE-00 three ANDs (KEEP)
  assign go_gated      = dma_go && wdma_owner_ui;
  assign arready_gated = arready && wdma_owner_ui;
  assign rvalid_gated  = rvalid && wdma_owner_ui;

  // EXTRACT GO-GRANT-QUIESCE-00 ui facts + grant FSM (product top)
  assign wdma_cmd_empty_ui = cmd_empty;
  assign wdma_dma_idle_ui  = (wdma_dbg_st == 3'd0);

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n)
      wdma_arr_outst <= 4'd0;
    else if (d_arvalid && arready && wdma_owner_ui &&
             !(rvalid && wdma_owner_ui && d_rready && rlast)) begin
      if (wdma_arr_outst != 4'd15)
        wdma_arr_outst <= wdma_arr_outst + 4'd1;
    end else if (rvalid && wdma_owner_ui && d_rready && rlast &&
                 !(d_arvalid && arready && wdma_owner_ui)) begin
      if (wdma_arr_outst != 4'd0)
        wdma_arr_outst <= wdma_arr_outst - 4'd1;
    end
  end
  assign wdma_arr_quiet_ui = (wdma_arr_outst == 4'd0);

  sync_bits #(.WIDTH(3)) u_wdma_rel_sync (
    .clk(core_clk), .rst_n(core_rst_n),
    .async_in({wdma_cmd_empty_ui, wdma_dma_idle_ui, wdma_arr_quiet_ui}),
    .sync_out({wdma_cmd_empty_c, wdma_dma_idle_c, wdma_arr_quiet_c})
  );

  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n)
      wdma_owner_grant <= 1'b0;
    else if (wdma_owner && r_path_idle)
      wdma_owner_grant <= 1'b1;
    else if (!wdma_owner && wdma_cmd_empty_c && wdma_dma_idle_c && wdma_arr_quiet_c)
      wdma_owner_grant <= 1'b0;
    // else: hold grant while cmd/DMA/AR-R drain; or hold 0 if R-path busy
  end
endmodule
