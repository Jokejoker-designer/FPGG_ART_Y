// arty_a7_ng_mig_board_top.sv — Digilent AXI MIG silicon ddr_feed metric_clear sweep (mig_board_r2)
// Law: a7ng-mig-board-r2-v0. Evidence_class: BOARD_MIG (not Native V1 BOARD_PASS, not HS-02).
// CONTROL: MIG-METRIC-00 MIG_XSIM per-run deltas; mig.prj MATCH AXI; frozen LM/01R/02M/A0.3.
// UNIT: sweep cell TOTAL=64 — full 4x4 burst x outstanding grid, metric_clear between cells.
// Does NOT overwrite frozen bits. Does NOT hand-edit mig.prj.
`timescale 1ns / 1ps

module arty_a7_ng_mig_board_top (
  input  logic        CLK100MHZ,
  input  logic [3:0]  sw,
  input  logic [3:0]  btn,
  output logic [3:0]  led,
  input  logic        uart_txd_in,
  output logic        uart_rxd_out,
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

  localparam int N_PE  = 16;
  localparam int TOTAL = 64;
  localparam int N_PRE = 128;
  localparam int N_CELLS = 16;

  logic clk166, clk200, clk_locked, btn0_166;
  logic ui_clk, ui_rst, calib, mig_mmcm;
  logic [23:0] mig_rst_hold;
  logic mig_rst_n;

  clk_arty_ddr u_clk (
    .clk100(CLK100MHZ), .rst(btn[0]), .clk_166(clk166), .clk_200(clk200), .locked(clk_locked)
  );
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

  logic seed_active;
  logic [3:0]  awid, arid_f, arid, bid, rid;
  logic [27:0] awaddr, araddr_f, araddr;
  logic [7:0]  awlen, arlen_f, arlen;
  logic [2:0]  awsize, arsize_f, arsize;
  logic [1:0]  awburst, arburst_f, arburst, bresp, rresp;
  logic awvalid, awready, wlast, wvalid, wready, bvalid, bready;
  logic arvalid_f, arvalid, arready, rlast, rvalid, rready_f, rready;
  logic [127:0] wdata, rdata;
  logic [15:0] wstrb;

  assign arid    = seed_active ? 4'd0 : arid_f;
  assign araddr  = seed_active ? 28'd0 : araddr_f;
  assign arlen   = seed_active ? 8'd0 : arlen_f;
  assign arsize  = seed_active ? 3'd4 : arsize_f;
  assign arburst = seed_active ? 2'b01 : arburst_f;
  assign arvalid = seed_active ? 1'b0 : arvalid_f;
  assign rready  = seed_active ? 1'b0 : rready_f;

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

  typedef enum logic [2:0] {SD_IDLE, SD_AW, SD_W, SD_B, SD_NEXT, SD_DONE} sd_t;
  sd_t sd;
  logic [7:0] seed_i;

  function automatic logic [127:0] pack_node(input logic [31:0] nid);
    logic [127:0] b;
    b = '0;
    b[31:0]    = nid;
    b[47:32]   = 16'd1;
    b[63:48]   = 16'(nid[7:0]);
    b[95:64]   = 32'hDDFE_0000 + nid;
    b[111:96]  = 16'h0100;
    b[119:112] = 8'(nid[7:0]);
    b[127:120] = A7NG_MEM_SCHEMA_VERSION[7:0];
    return b;
  endfunction

  always_ff @(posedge ui_clk) begin
    if (!ui_rst_n) begin
      sd <= SD_IDLE;
      seed_i <= 8'd0;
      seed_active <= 1'b1;
      awvalid <= 1'b0;
      wvalid <= 1'b0;
      wlast <= 1'b0;
      bready <= 1'b1;
      awid <= 4'd0;
      awlen <= 8'd0;
      awsize <= 3'd4;
      awburst <= 2'b01;
      wstrb <= 16'hFFFF;
      awaddr <= '0;
      wdata <= '0;
    end else begin
      unique case (sd)
        SD_IDLE: begin
          seed_active <= 1'b1;
          awaddr <= a7ng_node_byte_addr(NG_DDR_NODE_BASE, {24'd0, seed_i});
          wdata  <= pack_node({24'd0, seed_i});
          awvalid <= 1'b1;
          sd <= SD_AW;
        end
        SD_AW: if (awvalid && awready) begin
          awvalid <= 1'b0;
          wvalid <= 1'b1;
          wlast <= 1'b1;
          sd <= SD_W;
        end
        SD_W: if (wvalid && wready) begin
          wvalid <= 1'b0;
          wlast <= 1'b0;
          sd <= SD_B;
        end
        SD_B: if (bvalid) sd <= SD_NEXT;
        SD_NEXT: begin
          if (seed_i == 8'(N_PRE - 1)) begin
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

  logic feed_en, start;
  logic [4:0] burst;
  logic [3:0] outstanding;
  logic [31:0] base_node, total_recs;
  logic [N_PE-1:0] pe_req;
  logic done, running;
  logic [31:0] empty_st, full_st, pe_st, pe_bs, cyc, cons, drops;
  logic [15:0] occ_a, occ_f;
  logic active_bank;
  logic [31:0] axi_bytes, axi_bursts, axi_beats;
  logic [31:0] data_mm, rresp_err, rlast_err, exp_rec, rcv_rec, cons_rec;
  logic [3:0]  rid_obs;
  logic [31:0] rid_ord_err, r_bp;
  logic [N_PE-1:0] pe_grant;
  logic [31:0] pe_grants;

  assign feed_en = (sd == SD_DONE);

  a7ng_ddr_feed_mig_top #(.BANK_DEPTH(32), .N_PE(N_PE), .MAX_OUT(8), .MAX_BURST(16)) u_feed (
    .clk(ui_clk), .rst_n(ui_rst_n && feed_en),
    .start_i(start), .burst_i(burst), .outstanding_i(outstanding),
    .base_node_i(base_node), .total_recs_i(total_recs), .pe_req_i(pe_req),
    .done_o(done), .running_o(running),
    .empty_stall_o(empty_st), .full_stall_o(full_st),
    .pe_stall_o(pe_st), .pe_busy_o(pe_bs),
    .cycles_o(cyc), .recs_consumed_o(cons), .drop_o(drops),
    .occ_active_o(occ_a), .occ_fill_o(occ_f), .active_bank_o(active_bank),
    .ddr_rd_bytes_o(axi_bytes), .ddr_rd_count_o(axi_beats), .ddr_burst_count_o(axi_bursts),
    .axi_read_bytes_o(axi_bytes), .axi_read_bursts_o(axi_bursts), .axi_read_beats_o(axi_beats),
    .data_mismatch_count_o(data_mm), .rresp_error_count_o(rresp_err),
    .rlast_error_count_o(rlast_err), .expected_records_o(exp_rec),
    .received_records_o(rcv_rec), .consumed_records_o(cons_rec),
    .rid_observed_o(rid_obs), .rid_order_error_o(rid_ord_err),
    .r_backpressure_cycles_o(r_bp), .pe_data_mismatch_count_o(),
    .pe_data_o(), .expect_nid_o(),
    .pe_grant_o(pe_grant), .pe_grant_count_o(pe_grants),
    .m_axi_arid(arid_f), .m_axi_araddr(araddr_f), .m_axi_arlen(arlen_f),
    .m_axi_arsize(arsize_f), .m_axi_arburst(arburst_f),
    .m_axi_arvalid(arvalid_f), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready_f)
  );

  function automatic logic [4:0] burst_lut(input logic [1:0] bi);
    unique case (bi)
      2'd0: return 5'd1;
      2'd1: return 5'd4;
      2'd2: return 5'd8;
      default: return 5'd16;
    endcase
  endfunction

  function automatic logic [3:0] out_lut(input logic [1:0] oi);
    unique case (oi)
      2'd0: return 4'd1;
      2'd1: return 4'd2;
      2'd2: return 4'd4;
      default: return 4'd8;
    endcase
  endfunction

  typedef enum logic [3:0] {
    CS_WAIT_SEED, CS_GAP, CS_START, CS_CLR, CS_WAIT_DONE, CS_LATCH,
    CS_WAIT_UART, CS_NEXT, CS_ALL_DONE
  } cs_t;
  cs_t cs;
  logic [4:0] cell_idx;
  logic [15:0] gap;
  logic sweep_done_ui;

  logic [4:0]  row_burst;
  logic [3:0]  row_out;
  logic [31:0] row_axi_b, row_axi_br, row_axi_bt;
  logic [31:0] row_mm, row_rr, row_rl, row_exp, row_rcv, row_cons;
  logic [3:0]  row_rid;
  logic [31:0] row_bp, row_pe_st, row_pe_bs, row_cyc;
  logic        uart_ack_ui;
  logic        row_tx_pending_ui;

  always_ff @(posedge ui_clk) begin
    if (!ui_rst_n || !feed_en) begin
      cs <= CS_WAIT_SEED;
      start <= 1'b0;
      burst <= 5'd1;
      outstanding <= 4'd1;
      base_node <= 32'd0;
      total_recs <= 32'(TOTAL);
      pe_req <= '0;
      gap <= 16'd0;
      cell_idx <= 5'd0;
      sweep_done_ui <= 1'b0;
      row_tx_pending_ui <= 1'b0;
    end else begin
      start <= 1'b0;
      unique case (cs)
        CS_WAIT_SEED: begin
          gap <= gap + 16'd1;
          if (gap >= 16'd32) begin
            gap <= 16'd0;
            cell_idx <= 5'd0;
            cs <= CS_GAP;
          end
        end
        CS_GAP: begin
          gap <= gap + 16'd1;
          if (gap >= 16'd16) begin
            gap <= 16'd0;
            burst <= burst_lut(cell_idx[3:2]);
            outstanding <= out_lut(cell_idx[1:0]);
            cs <= CS_START;
          end
        end
        CS_START: begin
          pe_req <= {N_PE{1'b1}};
          start <= 1'b1;
          cs <= CS_CLR;
        end
        CS_CLR: if (!done) cs <= CS_WAIT_DONE;
        CS_WAIT_DONE: if (done) cs <= CS_LATCH;
        CS_LATCH: begin
          row_burst   <= burst;
          row_out     <= outstanding;
          row_axi_b   <= axi_bytes;
          row_axi_br  <= axi_bursts;
          row_axi_bt  <= axi_beats;
          row_mm      <= data_mm;
          row_rr      <= rresp_err;
          row_rl      <= rlast_err;
          row_exp     <= exp_rec;
          row_rcv     <= rcv_rec;
          row_cons    <= cons_rec;
          row_rid     <= rid_obs;
          row_bp      <= r_bp;
          row_pe_st   <= pe_st;
          row_pe_bs   <= pe_bs;
          row_cyc     <= cyc;
          pe_req <= '0;
          row_tx_pending_ui <= 1'b1;
          cs <= CS_WAIT_UART;
        end
        CS_WAIT_UART: if (uart_ack_ui) begin
          row_tx_pending_ui <= 1'b0;
          cs <= CS_NEXT;
        end
        CS_NEXT: begin
          if (cell_idx == 5'(N_CELLS - 1)) begin
            sweep_done_ui <= 1'b1;
            cs <= CS_ALL_DONE;
          end else begin
            cell_idx <= cell_idx + 5'd1;
            cs <= CS_GAP;
          end
        end
        CS_ALL_DONE: begin
          pe_req <= '0;
          sweep_done_ui <= 1'b1;
        end
        default: cs <= CS_WAIT_SEED;
      endcase
    end
  end

  logic sweep_done_100, calib_100, seed_done_100;
  logic row_tx_pending_100, uart_ack_100;
  sync_bits #(.WIDTH(4)) u_st_sync (
    .clk(CLK100MHZ), .rst_n(clk_locked),
    .async_in({sweep_done_ui, row_tx_pending_ui, (sd == SD_DONE), calib}),
    .sync_out({sweep_done_100, row_tx_pending_100, seed_done_100, calib_100})
  );
  sync_bits #(.WIDTH(1)) u_ack_sync (
    .clk(ui_clk), .rst_n(ui_rst_n && feed_en),
    .async_in(uart_ack_100),
    .sync_out(uart_ack_ui)
  );

  logic [4:0]  s_burst;
  logic [3:0]  s_out;
  logic [31:0] s_axi_b, s_axi_br, s_axi_bt;
  logic [31:0] s_mm, s_rr, s_rl, s_exp, s_rcv, s_cons;
  logic [3:0]  s_rid;
  logic [31:0] s_bp, s_pe_st, s_pe_bs, s_cyc;
  logic        row_armed, mark_pending, mark_done;
  logic        row_tx_d;
  logic [7:0]  tx_data;
  logic        tx_start, tx_busy;

  localparam int N_ROW_FIELDS = 13;
  localparam int PREFIX_LEN   = 17;

  function automatic logic [7:0] hex4(input logic [3:0] v);
    return (v < 4'd10) ? (8'h30 + {4'd0, v}) : (8'h41 + {4'd0, (v - 4'd10)});
  endfunction

  function automatic logic [7:0] dec1(input logic [3:0] v);
    return 8'h30 + {4'd0, v};
  endfunction

  function automatic logic [7:0] prefix_byte(input logic [4:0] i);
    case (i)
      5'd0:  return "B"; 5'd1: return "O"; 5'd2: return "A"; 5'd3: return "R";
      5'd4:  return "D"; 5'd5: return "_"; 5'd6: return "M"; 5'd7: return "I";
      5'd8:  return "G"; 5'd9: return "_"; 5'd10: return "R"; 5'd11: return "2";
      5'd12: return "_"; 5'd13: return "R"; 5'd14: return "O"; 5'd15: return "W";
      default: return ",";
    endcase
  endfunction

  function automatic logic [31:0] field_val(input logic [3:0] f);
    unique case (f)
      4'd0:  return s_axi_b;
      4'd1:  return s_axi_br;
      4'd2:  return s_axi_bt;
      4'd3:  return s_mm;
      4'd4:  return s_rr;
      4'd5:  return s_rl;
      4'd6:  return s_exp;
      4'd7:  return s_rcv;
      4'd8:  return s_cons;
      4'd9:  return {28'd0, s_rid};
      4'd10: return s_bp;
      4'd11: return s_pe_st;
      4'd12: return s_pe_bs;
      default: return s_cyc;
    endcase
  endfunction

  function automatic logic [7:0] mark_byte(input logic [4:0] i);
    case (i)
      5'd0: return "A"; 5'd1: return "7"; 5'd2: return "N"; 5'd3: return "G";
      5'd4: return "_"; 5'd5: return "M"; 5'd6: return "I"; 5'd7: return "G";
      5'd8: return "_"; 5'd9: return "B"; 5'd10: return "O"; 5'd11: return "A";
      5'd12: return "R"; 5'd13: return "D"; 5'd14: return "_"; 5'd15: return "R";
      5'd16: return "2"; 5'd17: return "_"; 5'd18: return "O"; 5'd19: return "K";
      default: return 8'h0A;
    endcase
  endfunction

  typedef enum logic [3:0] {T_IDLE, T_PREFIX, T_BURST, T_BURST2, T_COMMA1, T_OUT, T_COMMA2,
                            T_HEX, T_COMMA_F, T_NL, T_MARK, T_DONE} t_t;
  t_t ts;
  logic [4:0]  tx_i;
  logic [3:0]  tx_fld;
  logic [3:0]  tx_nib;
  logic [31:0] tx_cur;
  logic [4:0]  mark_i;

  uart_tx #(.CLK_HZ(100_000_000), .BAUD(115200)) u_tx (
    .clk(CLK100MHZ), .rst_n(clk_locked), .start(tx_start), .data(tx_data),
    .tx(uart_rxd_out), .busy(tx_busy)
  );

  always_ff @(posedge CLK100MHZ) begin
    if (!clk_locked) begin
      row_armed <= 1'b0;
      mark_pending <= 1'b0;
      mark_done <= 1'b0;
      uart_ack_100 <= 1'b0;
      row_tx_d <= 1'b0;
      s_burst <= '0; s_out <= '0;
      s_axi_b <= '0; s_axi_br <= '0; s_axi_bt <= '0;
      s_mm <= '0; s_rr <= '0; s_rl <= '0;
      s_exp <= '0; s_rcv <= '0; s_cons <= '0;
      s_rid <= '0; s_bp <= '0;
      s_pe_st <= '0; s_pe_bs <= '0; s_cyc <= '0;
      ts <= T_IDLE;
      tx_start <= 1'b0;
      tx_data <= 8'h00;
      tx_fld <= 4'd0;
      tx_nib <= 4'd7;
      tx_i <= 5'd0;
      tx_cur <= 32'd0;
      mark_i <= 5'd0;
    end else begin
      tx_start <= 1'b0;
      uart_ack_100 <= 1'b0;
      row_tx_d <= row_tx_pending_100;
      if (row_tx_pending_100 && !row_tx_d && !row_armed && !mark_pending && ts == T_IDLE) begin
        s_burst   <= row_burst;
        s_out     <= row_out;
        s_axi_b   <= row_axi_b;
        s_axi_br  <= row_axi_br;
        s_axi_bt  <= row_axi_bt;
        s_mm      <= row_mm;
        s_rr      <= row_rr;
        s_rl      <= row_rl;
        s_exp     <= row_exp;
        s_rcv     <= row_rcv;
        s_cons    <= row_cons;
        s_rid     <= row_rid;
        s_bp      <= row_bp;
        s_pe_st   <= row_pe_st;
        s_pe_bs   <= row_pe_bs;
        s_cyc     <= row_cyc;
        row_armed <= 1'b1;
      end
      if (sweep_done_100 && !mark_pending && !row_armed && !mark_done)
        mark_pending <= 1'b1;

      unique case (ts)
        T_IDLE: begin
          if (row_armed) begin
            tx_i <= 5'd0;
            ts <= T_PREFIX;
          end else if (mark_pending) begin
            mark_i <= 5'd0;
            ts <= T_MARK;
          end
        end
        T_PREFIX: if (!tx_busy && !tx_start) begin
          tx_data <= prefix_byte(tx_i);
          tx_start <= 1'b1;
          if (tx_i == 5'(PREFIX_LEN - 1))
            ts <= T_BURST;
          else
            tx_i <= tx_i + 5'd1;
        end
        T_BURST: if (!tx_busy && !tx_start) begin
          if (s_burst >= 5'd10) begin
            tx_data <= dec1(4'd1);
            tx_start <= 1'b1;
            ts <= T_BURST2;
          end else begin
            tx_data <= dec1(s_burst[3:0]);
            tx_start <= 1'b1;
            ts <= T_COMMA1;
          end
        end
        T_BURST2: if (!tx_busy && !tx_start) begin
          tx_data <= dec1(s_burst[3:0]);
          tx_start <= 1'b1;
          ts <= T_COMMA1;
        end
        T_COMMA1: if (!tx_busy && !tx_start) begin
          tx_data <= ",";
          tx_start <= 1'b1;
          ts <= T_OUT;
        end
        T_OUT: if (!tx_busy && !tx_start) begin
          tx_data <= dec1(s_out[3:0]);
          tx_start <= 1'b1;
          ts <= T_COMMA2;
        end
        T_COMMA2: if (!tx_busy && !tx_start) begin
          tx_data <= ",";
          tx_start <= 1'b1;
          tx_fld <= 4'd0;
          tx_nib <= 4'd7;
          tx_cur <= field_val(4'd0);
          ts <= T_HEX;
        end
        T_HEX: if (!tx_busy && !tx_start) begin
          tx_data <= hex4(tx_cur[4*tx_nib +: 4]);
          tx_start <= 1'b1;
          if (tx_nib == 4'd0) begin
            if (tx_fld == 4'(N_ROW_FIELDS - 1))
              ts <= T_NL;
            else
              ts <= T_COMMA_F;
          end else
            tx_nib <= tx_nib - 4'd1;
        end
        T_COMMA_F: if (!tx_busy && !tx_start) begin
          tx_data <= ",";
          tx_start <= 1'b1;
          tx_fld <= tx_fld + 4'd1;
          tx_nib <= 4'd7;
          tx_cur <= field_val(tx_fld + 4'd1);
          ts <= T_HEX;
        end
        T_NL: if (!tx_busy && !tx_start) begin
          tx_data <= 8'h0A;
          tx_start <= 1'b1;
          row_armed <= 1'b0;
          uart_ack_100 <= 1'b1;
          ts <= T_IDLE;
        end
        T_MARK: if (!tx_busy && !tx_start) begin
          tx_data <= mark_byte(mark_i);
          tx_start <= 1'b1;
          if (mark_i == 5'd21) begin
            mark_pending <= 1'b0;
            mark_done <= 1'b1;
            ts <= T_DONE;
          end else
            mark_i <= mark_i + 5'd1;
        end
        T_DONE: ;
        default: ts <= T_IDLE;
      endcase
    end
  end

  logic [23:0] hb;
  always_ff @(posedge ui_clk) begin
    if (!ui_rst_n) hb <= '0;
    else hb <= hb + 24'd1;
  end
  logic hb_100;
  sync_bits #(.WIDTH(1)) u_hb (
    .clk(CLK100MHZ), .rst_n(clk_locked), .async_in(hb[23]), .sync_out(hb_100)
  );
  assign led = {hb_100, mark_done, seed_done_100, calib_100};

  logic unused_rx; assign unused_rx = uart_txd_in | sw[0] | (|btn);
endmodule
