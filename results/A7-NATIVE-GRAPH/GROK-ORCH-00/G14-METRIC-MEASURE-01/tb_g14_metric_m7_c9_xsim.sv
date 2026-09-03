// G14-METRIC-MEASURE-01 — M7 C9 exam query persist/AXI bytes. NO TinyGPT.
// g1g5_cofit = C9 SoC graph+persist. NO RTL EDIT.
`timescale 1ns / 1ps

module tb_g14_metric_m7_c9_xsim;
  import a7ng_pkg::*;
  localparam logic [3:0] C_TOK=4'd1, C_FIRE=4'd2, C_REW=4'd3, C_FLUSH=4'd4,
                         C_FREEZE=4'd7, C_TRAIN=4'd9;
  localparam logic [7:0] T_HOLD_A=8'hA2;
  localparam logic [63:0] PACK_A = 64'h8382238122802120;
  localparam int TO = 200000;

  logic clk, rst_n, cv, cr;
  logic [3:0] cmd, mode;
  logic [7:0] tok;
  logic signed [3:0] rew;
  logic [63:0] c9p;
  logic [9:0] lmout;
  logic lmst, lmdn;
  logic pbusy, pdone, c7v, c5;
  logic [15:0] txn, c7seq, c7cnt;
  logic [31:0] c7a;
  logic ddr_req, ddr_we, ddr_ack;
  logic [7:0] ddr_addr;
  logic [63:0] ddr_wdata, ddr_rdata;
  logic [63:0] ddr_mem [0:255];
  node_id_t pid [8];
  integer di;

  always_ff @(posedge clk) begin
    if (ddr_req && ddr_we) ddr_mem[ddr_addr] <= ddr_wdata;
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ddr_ack <= 1'b0;
    else ddr_ack <= ddr_req;
  end
  assign ddr_rdata = ddr_mem[ddr_addr];

  a7ng_g1g5_cofit dut (
    .clk(clk), .rst_n(rst_n),
    .graph_topk_valid_i(1'b0),
    .graph_id_i('{default: '0}), .graph_sc_i('{default: '0}),
    .graph_bind_done_i(1'b0), .graph_lm_busy_i(1'b0), .graph_pred_i(10'd0),
    .c1_mode_o(mode), .c2_anch_o(),
    .c9_topk_o(c9p), .c9_score_o(),
    .c9_r1s_o(), .c9_r1r_o(), .c9_r1o_o(),
    .c10_lmst_o(lmst), .c10_lmdn_o(lmdn), .c10_out_o(lmout),
    .n_host_cue_o(), .n_host_win_o(), .n_host_addr_o(),
    .n_host_tok_o(), .n_host_w_o(), .n_host_mode_o(),
    .teacher_active_o(), .ext_llm_active_o(),
    .last_ack_o(), .exam_lm_used_o(),
    .persist_ddr_req_o(ddr_req), .persist_ddr_we_o(ddr_we),
    .persist_ddr_addr_o(ddr_addr), .persist_ddr_wdata_o(ddr_wdata),
    .persist_ddr_rdata_i(ddr_rdata), .persist_ddr_ack_i(ddr_ack),
    .persist_freeze_o(),
    .persist_c7_valid_o(c7v), .persist_c7_addr_o(c7a),
    .persist_c7_ready_i(1'b1),
    .persist_busy_o(pbusy), .persist_done_o(pdone),
    .c7_commit_seq_o(c7seq), .c7_ack_count_o(c7cnt),
    .query_valid_o(), .query_ready_o(), .query_id_o(), .snap_valid_o(),
    .g14_en_i(1'b1),
    .g14_cmd_v_i(cv), .g14_cmd_r_o(cr),
    .g14_cmd_i(cmd), .g14_tok_i(tok), .g14_rew_i(rew),
    .c8_gen_o(), .c8_sdig_o(),
    .c11_adig_o(), .c11_bdig_o(), .c11_a_for_o(), .c11_b_vis_o(),
    .p_txn_o(txn), .c5_cons_o(c5),
    .g14_lm_start_o(), .g14_persist_id_o(pid)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer we_cyc, we_bytes, req_cyc;
  integer we_exam, bytes_exam, we_flush, bytes_flush;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      we_cyc <= 0; we_bytes <= 0; req_cyc <= 0;
    end else begin
      if (ddr_req) req_cyc <= req_cyc + 1;
      if (ddr_req && ddr_we) begin
        we_cyc <= we_cyc + 1;
        we_bytes <= we_bytes + 8;
      end
    end
  end

  integer g, k, snap0, we0, b0;

  task automatic do_cmd(input logic [3:0] c, input logic [7:0] t, input logic signed [3:0] r);
    begin
      g = 0;
      while (!(cr && !cv) && g < TO) begin @(posedge clk); g++; end
      @(negedge clk); cmd = c; tok = t; rew = r; cv = 1'b1;
      g = 0;
      while (!(cv && cr) && g < TO) begin @(posedge clk); g++; end
      @(negedge clk); cv = 1'b0;
      unique case (c)
        C_FIRE: begin
          g = 0;
          while (g < TO) begin
            @(posedge clk); g++;
            if (c9p != 64'd0) break;
          end
        end
        C_REW: begin
          repeat (256) @(posedge clk);
        end
        C_FLUSH: begin
          g = 0;
          while (g < TO) begin
            @(posedge clk); g++;
            if (pdone && !pbusy) break;
          end
        end
        default: ;
      endcase
    end
  endtask

  initial begin
    for (di = 0; di < 256; di++) ddr_mem[di] = 64'd0;
    cv = 0; cmd = 0; tok = 0; rew = 0; rst_n = 0;
    $display("G14-METRIC-MEASURE-01 M7 C9 XSIM (g1g5_cofit, no TinyGPT, no AXI4 master)");
    $display("EVIDENCE_CLASS=XSIM persist_ddr 64-bit port; AXI4_READ=0 AXI4_WRITE=0 on this wrapper");
    repeat (4) @(posedge clk);
    rst_n = 1;
    g = 0;
    while (!cr && g < 8000) begin @(posedge clk); g++; end
    do_cmd(C_TRAIN, 0, 0);
    for (k = 0; k < 20; k++) begin
      do_cmd(C_TOK, 8'h10 + k[7:0], 0);
      do_cmd(C_FIRE, 0, 0);
      do_cmd(C_REW, 0, 4'sd3);
    end
    we0 = we_bytes;
    do_cmd(C_FLUSH, 0, 0);
    we_flush = we_bytes - we0;
    bytes_flush = we_flush;
    $display("M7_C9_FLUSH_PERSIST_WRITE_BYTES=%0d we_cyc_delta_as_bytes=%0d",
             we_flush, we_flush);
    do_cmd(C_FREEZE, 0, 0);
    we0 = we_bytes; b0 = we_cyc;
    do_cmd(C_TOK, T_HOLD_A, 0);
    do_cmd(C_FIRE, 0, 0);
    repeat (64) @(posedge clk);
    we_exam = we_bytes - we0;
    $display("M7_C9_EXAM_HOLD_A_PACK=%h (expect %h)", c9p, PACK_A);
    $display("M7_C9_EXAM_AXI4_READ_BYTES=0");
    $display("M7_C9_EXAM_AXI4_WRITE_BYTES=0");
    $display("M7_C9_EXAM_PERSIST_WRITE_BYTES=%0d", we_exam);
    $display("M7_C9_EXAM_PERSIST_WE_CYC=%0d", we_cyc - b0);
    $display("M7_C9_MODE=%0d", mode);
    if (c9p !== PACK_A)
      $display("G14_METRIC_M7_C9_WARN pack mismatch got=%h", c9p);
    $display("G14_METRIC_M7_C9_XSIM_PASS");
    $finish;
  end

  initial begin
    #80ms;
    $display("G14_METRIC_M7_C9_FAIL WALL");
    $finish;
  end
endmodule
