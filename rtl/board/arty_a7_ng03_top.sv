// arty_a7_ng03_top.sv — NG-03 MIG + hotset shard smoke (self-seed + query)
// Does NOT overwrite frozen LM/EAM bits. Law: a7ng-hotset-v0
`timescale 1ns / 1ps

module arty_a7_ng03_top (
  input  logic        CLK100MHZ,
  input  logic [3:0]  sw,
  input  logic [3:0]  btn,
  output logic [3:0]  led,
  output logic [13:0] ddr3_addr,
  output logic [2:0]  ddr3_ba,
  output logic        ddr3_cas_n,
  output logic [0:0]  ddr3_ck_n,
  output logic [0:0]  ddr3_ck_p,
  output logic [0:0]  ddr3_cke,
  output logic [0:0]  ddr3_cs_n,
  output logic        ddr3_ras_n,
  output logic        ddr3_reset_n,
  output logic        ddr3_we_n,
  inout  logic [15:0] ddr3_dq,
  inout  logic [1:0]  ddr3_dqs_n,
  inout  logic [1:0]  ddr3_dqs_p,
  output logic [1:0]  ddr3_dm,
  output logic [0:0]  ddr3_odt
);
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;

  logic clk166, clk200, clk_locked, btn0_166;
  logic ui_clk, ui_rst, calib, mig_mmcm;
  logic [23:0] mig_rst_hold;
  logic mig_rst_n;

  clk_arty_ddr u_clk (
    .clk100(CLK100MHZ), .rst(btn[0]), .clk_166(clk166), .clk_200(clk200), .locked(clk_locked)
  );
  // Sample btn only in the 166 MHz domain that consumes it (async in → sync)
  sync_bits #(.WIDTH(1)) u_b0_166 (
    .clk(clk166), .rst_n(clk_locked), .async_in(btn[0]), .sync_out(btn0_166)
  );

  always_ff @(posedge clk166 or negedge clk_locked) begin
    if (!clk_locked) begin
      mig_rst_hold <= 24'hFF_FFFF;
      mig_rst_n <= 1'b0;
    end else if (btn0_166) begin
      mig_rst_hold <= 24'hFF_FFFF;
      mig_rst_n <= 1'b0;
    end else if (mig_rst_hold != 24'd0) begin
      mig_rst_hold <= mig_rst_hold - 24'd1;
      mig_rst_n <= 1'b0;
    end else
      mig_rst_n <= 1'b1;
  end

  logic [3:0] awid, arid, bid, rid;
  logic [27:0] awaddr, araddr;
  logic [7:0] awlen, arlen;
  logic [2:0] awsize, arsize;
  logic [1:0] awburst, arburst, bresp, rresp;
  logic awvalid, awready, wlast, wvalid, wready, bvalid, bready;
  logic arvalid, arready, rlast, rvalid, rready;
  logic [127:0] wdata, rdata;
  logic [15:0] wstrb;

  // Mux: seed writer vs shard fetch reader
  logic seed_active;
  logic [3:0]  s_arid; logic [27:0] s_araddr; logic [7:0] s_arlen;
  logic [2:0]  s_arsize; logic [1:0] s_arburst; logic s_arvalid, s_rready;
  logic [3:0]  w_awid; logic [27:0] w_awaddr; logic [7:0] w_awlen;
  logic [2:0]  w_awsize; logic [1:0] w_awburst; logic w_awvalid, w_wvalid, w_wlast, w_bready;
  logic [127:0] w_wdata; logic [15:0] w_wstrb;

  assign arid    = seed_active ? 4'd0 : s_arid;
  assign araddr  = seed_active ? 28'd0 : s_araddr;
  assign arlen   = seed_active ? 8'd0 : s_arlen;
  assign arsize  = seed_active ? 3'd4 : s_arsize;
  assign arburst = seed_active ? 2'b01 : s_arburst;
  assign arvalid = seed_active ? 1'b0 : s_arvalid;
  assign rready  = seed_active ? 1'b0 : s_rready;

  assign awid    = seed_active ? w_awid : 4'd0;
  assign awaddr  = seed_active ? w_awaddr : 28'd0;
  assign awlen   = seed_active ? w_awlen : 8'd0;
  assign awsize  = seed_active ? w_awsize : 3'd4;
  assign awburst = seed_active ? w_awburst : 2'b01;
  assign awvalid = seed_active ? w_awvalid : 1'b0;
  assign wdata   = seed_active ? w_wdata : 128'd0;
  assign wstrb   = seed_active ? w_wstrb : 16'h0;
  assign wlast   = seed_active ? w_wlast : 1'b0;
  assign wvalid  = seed_active ? w_wvalid : 1'b0;
  assign bready  = seed_active ? w_bready : 1'b1;

  mig_native_wrap u_mig (
    .sys_clk_i(clk166), .clk_ref_i(clk200), .sys_rst_n(mig_rst_n),
    .ui_clk(ui_clk), .ui_rst(ui_rst), .init_calib_complete(calib), .mmcm_locked(mig_mmcm),
    .ddr3_addr(ddr3_addr), .ddr3_ba(ddr3_ba), .ddr3_cas_n(ddr3_cas_n),
    .ddr3_ck_n(ddr3_ck_n), .ddr3_ck_p(ddr3_ck_p), .ddr3_cke(ddr3_cke),
    .ddr3_cs_n(ddr3_cs_n), .ddr3_ras_n(ddr3_ras_n), .ddr3_reset_n(ddr3_reset_n),
    .ddr3_we_n(ddr3_we_n), .ddr3_dq(ddr3_dq), .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p), .ddr3_dm(ddr3_dm), .ddr3_odt(ddr3_odt),
    .s_axi_awid(awid), .s_axi_awaddr(awaddr), .s_axi_awlen(awlen),
    .s_axi_awsize(awsize), .s_axi_awburst(awburst),
    .s_axi_awvalid(awvalid), .s_axi_awready(awready),
    .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wlast(wlast),
    .s_axi_wvalid(wvalid), .s_axi_wready(wready),
    .s_axi_bid(bid), .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
    .s_axi_arid(arid), .s_axi_araddr(araddr), .s_axi_arlen(arlen),
    .s_axi_arsize(arsize), .s_axi_arburst(arburst),
    .s_axi_arvalid(arvalid), .s_axi_arready(arready),
    .s_axi_rid(rid), .s_axi_rdata(rdata), .s_axi_rresp(rresp),
    .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
  );

  logic ui_rst_n;
  assign ui_rst_n = ~ui_rst & calib;

  // Seed first 16 node records (FPGA-owned pattern)
  typedef enum logic [2:0] {SD_IDLE, SD_AW, SD_W, SD_B, SD_NEXT, SD_DONE} sd_t;
  sd_t sd;
  logic [7:0] seed_i;
  localparam logic [7:0] SEED_N = 8'd16;

  always_ff @(posedge ui_clk) begin
    if (!ui_rst_n) begin
      sd <= SD_IDLE;
      seed_i <= 8'd0;
      seed_active <= 1'b1;
      w_awvalid <= 1'b0;
      w_wvalid <= 1'b0;
      w_wlast <= 1'b0;
      w_bready <= 1'b1;
      w_awid <= 4'd0;
      w_awlen <= 8'd0;
      w_awsize <= 3'd4;
      w_awburst <= 2'b01;
      w_wstrb <= 16'hFFFF;
      w_awaddr <= '0;
      w_wdata <= '0;
    end else begin
      unique case (sd)
        SD_IDLE: begin
          seed_active <= 1'b1;
          w_awaddr <= a7ng_node_byte_addr(NG_DDR_NODE_BASE, {24'd0, seed_i});
          w_wdata  <= {64'h0, 32'hA700_0000 + {24'd0, seed_i}, {24'd0, seed_i}};
          w_awvalid <= 1'b1;
          sd <= SD_AW;
        end
        SD_AW: if (w_awvalid && awready) begin
          w_awvalid <= 1'b0;
          w_wvalid <= 1'b1;
          w_wlast <= 1'b1;
          sd <= SD_W;
        end
        SD_W: if (w_wvalid && wready) begin
          w_wvalid <= 1'b0;
          w_wlast <= 1'b0;
          sd <= SD_B;
        end
        SD_B: if (bvalid) begin
          sd <= SD_NEXT;
        end
        SD_NEXT: begin
          if (seed_i == SEED_N - 8'd1) begin
            seed_active <= 1'b0;
            sd <= SD_DONE;
          end else begin
            seed_i <= seed_i + 8'd1;
            sd <= SD_IDLE;
          end
        end
        SD_DONE: seed_active <= 1'b0;
        default: sd <= SD_IDLE;
      endcase
    end
  end

  logic query, busy, done, hit;
  logic [31:0] nid, hits, misses, cands, bytes, bursts;
  logic [63:0] dout;
  logic [3:0] q_idx;
  typedef enum logic [1:0] {Q_WAIT, Q_ISSUE, Q_WAIT_DONE, Q_NEXT} q_t;
  q_t qs;
  logic smoke_pass;

  a7ng_shard_fetch u_fetch (
    .clk(ui_clk), .rst_n(ui_rst_n && (sd == SD_DONE)),
    .query_i(query), .node_id_i(nid),
    .busy_o(busy), .done_o(done), .hit_o(hit), .data_o(dout),
    .hits_o(hits), .misses_o(misses),
    .candidates_o(cands), .ddr_read_bytes_o(bytes), .ddr_bursts_o(bursts),
    .m_axi_arid(s_arid), .m_axi_araddr(s_araddr), .m_axi_arlen(s_arlen),
    .m_axi_arsize(s_arsize), .m_axi_arburst(s_arburst),
    .m_axi_arvalid(s_arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(s_rready)
  );

  // Query plan: 7 (miss), 7 (hit), 9 (miss) — expect bytes=32, cands=3
  always_ff @(posedge ui_clk) begin
    if (!ui_rst_n || sd != SD_DONE) begin
      qs <= Q_WAIT;
      query <= 1'b0;
      q_idx <= 4'd0;
      nid <= 32'd0;
      smoke_pass <= 1'b0;
    end else begin
      query <= 1'b0;
      unique case (qs)
        Q_WAIT: qs <= Q_ISSUE;
        Q_ISSUE: begin
          unique case (q_idx)
            4'd0: nid <= 32'd7;
            4'd1: nid <= 32'd7;
            default: nid <= 32'd9;
          endcase
          query <= 1'b1;
          qs <= Q_WAIT_DONE;
        end
        Q_WAIT_DONE: if (done) qs <= Q_NEXT;
        Q_NEXT: begin
          if (q_idx == 4'd2) begin
            smoke_pass <= (bytes == 32'd32) && (cands == 32'd3) && (hits >= 32'd1);
            qs <= Q_WAIT; // hold result
            q_idx <= 4'd3;
          end else if (q_idx < 4'd3) begin
            q_idx <= q_idx + 4'd1;
            qs <= Q_ISSUE;
          end
        end
        default: qs <= Q_WAIT;
      endcase
    end
  end

  // LED: [0]=calib [1]=seed_done [2]=smoke_pass [3]=busy/heartbeat
  logic [23:0] hb;
  always_ff @(posedge ui_clk) begin
    if (!ui_rst_n) hb <= '0;
    else hb <= hb + 24'd1;
  end

  logic calib_s, seed_s, pass_s, busy_s;
  sync_bits #(.WIDTH(4)) u_led (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({busy | hb[23], smoke_pass, (sd == SD_DONE), calib}),
    .sync_out({busy_s, pass_s, seed_s, calib_s})
  );
  assign led = {busy_s, pass_s, seed_s, calib_s};
endmodule
