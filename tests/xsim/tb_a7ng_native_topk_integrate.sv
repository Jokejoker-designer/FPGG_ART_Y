`timescale 1ns/1ps
import a7ng_pkg::*;
import a7lm06_pkg::*;
//=============================================================================
// HS22-LM06-NATIVE-TOPK-INTEGRATE-01
// TB drives four local-wave Top8 fixtures only. Never drives bind.global_id_i.
//=============================================================================
module tb_a7ng_native_topk_integrate;
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic clear_i, wave_valid;
  logic [4:0] wave_scored;
  score_t   wave_score [8];
  node_id_t wave_id    [8];
  logic grant_lm, do_start, poison;
  node_id_t poison_id [8];
  logic mem_we;
  logic [19:0] mem_addr;
  logic signed [7:0] mem_wdata, mem_rdata;
  logic reducer_busy, global_valid;
  logic [31:0] merge_count, gv_count;
  score_t   global_score [8];
  node_id_t global_id    [8];
  logic bind_busy, bind_done, ctx_we, start_fwd, capture_valid;
  logic [63:0] ctx_pack;
  logic [31:0] ctx_beats, st_beats;
  logic core_busy, core_done;
  logic [9:0] pred;
  logic [7:0] phase;
  logic final_accept;

  a7ng_native_topk_integrate u_int (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .wave_valid_i(wave_valid), .wave_scored_i(wave_scored),
    .wave_score_i(wave_score), .wave_id_i(wave_id),
    .grant_lm_i(grant_lm), .do_start_i(do_start),
    .poison_i(poison), .poison_id_i(poison_id),
    .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
    .reducer_busy_o(reducer_busy), .global_valid_o(global_valid),
    .merge_count_o(merge_count), .gv_count_o(gv_count),
    .global_score_o(global_score), .global_id_o(global_id),
    .bind_busy_o(bind_busy), .bind_done_o(bind_done),
    .ctx_we_o(ctx_we), .ctx_pack_o(ctx_pack), .start_fwd_o(start_fwd),
    .capture_valid_o(capture_valid),
    .ctx_we_beats_o(ctx_beats), .start_fwd_beats_o(st_beats),
    .core_busy_o(core_busy), .core_done_o(core_done), .pred_o(pred),
    .phase_o(phase), .final_accept_o(final_accept)
  );

  logic req_graph, req_lm, grant_graph, owner_g, owner_l, dual_err;
  a7ng_lm_graph_arb u_arb (
    .clk(clk), .rst_n(rst_n),
    .req_graph_i(req_graph), .req_lm_i(req_lm),
    .grant_graph_o(grant_graph), .grant_lm_o(grant_lm),
    .owner_is_graph_o(owner_g), .owner_is_lm_o(owner_l),
    .dual_owner_err_o(dual_err)
  );

  int unsigned mem_we_exam, dual_ticks, gv_events, capture_mismatch, inter_start;
  bit exam;
  always_ff @(posedge clk) begin
    if (rst_n && exam && mem_we) mem_we_exam <= mem_we_exam + 1;
    if (rst_n && dual_err) dual_ticks <= dual_ticks + 1;
    if (rst_n && global_valid) gv_events <= gv_events + 1;
    if (rst_n && start_fwd && (merge_count < 32'd4)) inter_start <= inter_start + 1;
  end

  logic [7:0] wmem [0:802815];
  integer i, w, t;
  localparam logic [63:0] PACK_C = 64'h3b392b291b190b09;
  localparam logic [63:0] PACK_P = 64'h392b291b190b0901;
  logic [9:0] pred_neg, pred_c, pred_p;
  node_id_t exp_c [8];
  node_id_t exp_p [8];
  score_t   exp_cs [8];
  score_t   exp_ps [8];

  task automatic set_wave_ctrl(input int wv);
    integer k;
    node_id_t base;
    wave_scored = 5'd8;
    unique case (wv)
      0: begin
        wave_id[0]=32'd9; wave_id[1]=32'd11;
        wave_id[2]=32'd0; wave_id[3]=32'd2; wave_id[4]=32'd4;
        wave_id[5]=32'd6; wave_id[6]=32'd8; wave_id[7]=32'd10;
      end
      1: begin
        wave_id[0]=32'd25; wave_id[1]=32'd27;
        wave_id[2]=32'd16; wave_id[3]=32'd18; wave_id[4]=32'd20;
        wave_id[5]=32'd22; wave_id[6]=32'd24; wave_id[7]=32'd26;
      end
      2: begin
        wave_id[0]=32'd41; wave_id[1]=32'd43;
        wave_id[2]=32'd32; wave_id[3]=32'd34; wave_id[4]=32'd36;
        wave_id[5]=32'd38; wave_id[6]=32'd40; wave_id[7]=32'd42;
      end
      default: begin
        wave_id[0]=32'd57; wave_id[1]=32'd59;
        wave_id[2]=32'd48; wave_id[3]=32'd50; wave_id[4]=32'd52;
        wave_id[5]=32'd54; wave_id[6]=32'd56; wave_id[7]=32'd58;
      end
    endcase
    wave_score[0]=16'sd165; wave_score[1]=16'sd165;
    for (k = 2; k < 8; k = k + 1) wave_score[k] = 16'sd1;
  endtask

  task automatic apply_perturb_w0;
    set_wave_ctrl(0);
    wave_id[7]    = 32'd1;
    wave_score[7] = 16'sd300;
  endtask

  task automatic fire_wave;
    integer c;
    begin
      wait (!reducer_busy);
      @(posedge clk);
      wave_valid <= 1'b1;
      @(posedge clk);
      wave_valid <= 1'b0;
      for (c = 0; c < 64; c = c + 1) begin
        if (global_valid) begin
          @(posedge clk);
          return;
        end
        @(posedge clk);
      end
      $display("FAIL wave timeout");
      $finish;
    end
  endtask

  task automatic four_waves(input bit perturb);
    integer wv;
    begin
      for (wv = 0; wv < 4; wv = wv + 1) begin
        if (perturb && wv == 0) apply_perturb_w0();
        else set_wave_ctrl(wv);
        fire_wave();
      end
    end
  endtask

  task automatic check_global(input node_id_t exp_i [8], input score_t exp_s [8], input string tag);
    integer k;
    begin
      for (k = 0; k < 8; k = k + 1) begin
        if (global_id[k] !== exp_i[k] || global_score[k] !== exp_s[k]) begin
          $display("FAIL %s slot%0d id=%0d s=%0d exp id=%0d s=%0d",
                   tag, k, global_id[k], global_score[k], exp_i[k], exp_s[k]);
          $finish;
        end
      end
      $display("GLOBAL_OK %s ids=%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d", tag,
               global_id[0],global_id[1],global_id[2],global_id[3],
               global_id[4],global_id[5],global_id[6],global_id[7]);
    end
  endtask

  task automatic poison_after_accept(input logic [63:0] expect_pack);
    integer k;
    begin
      wait (final_accept);
      @(posedge clk);
      @(negedge clk);
      poison <= 1'b1;
      for (k = 0; k < 8; k = k + 1) poison_id[k] = 32'd255;
      $display("R2_POISON_NEGEDGE between_accept_and_S_CTX");
      @(posedge clk);
      #1;
      if (ctx_we !== 1'b1) begin
        $display("FAIL no ctx_we after poison");
        $finish;
      end
      if (ctx_pack !== expect_pack) begin
        capture_mismatch = capture_mismatch + 1;
        $display("FAIL CAPTURE pack=%h exp=%h", ctx_pack, expect_pack);
        $finish;
      end
      $display("CAPTURE_OK pack=%h", ctx_pack);
      @(posedge clk);
      poison <= 1'b0;
    end
  endtask

  initial begin
    clear_i=0; wave_valid=0; wave_scored=0; do_start=0; poison=0;
    mem_we=0; mem_addr=0; mem_wdata=0; req_graph=0; req_lm=0; exam=0;
    for (i=0;i<8;i=i+1) begin wave_score[i]=0; wave_id[i]=0; poison_id[i]=0; end
    exp_c[0]=32'd9; exp_c[1]=32'd11; exp_c[2]=32'd25; exp_c[3]=32'd27;
    exp_c[4]=32'd41; exp_c[5]=32'd43; exp_c[6]=32'd57; exp_c[7]=32'd59;
    exp_p[0]=32'd1; exp_p[1]=32'd9; exp_p[2]=32'd11; exp_p[3]=32'd25;
    exp_p[4]=32'd27; exp_p[5]=32'd41; exp_p[6]=32'd43; exp_p[7]=32'd57;
    for (i=0;i<8;i=i+1) exp_cs[i]=16'sd165;
    exp_ps[0]=16'sd300;
    for (i=1;i<8;i=i+1) exp_ps[i]=16'sd165;

    $display("STRUCTURAL DUT_HIER int=%m.u_int red=u_int.u_red bind=u_int.u_bind core=u_int.u_core");
    $display("STRUCTURAL SOURCE a7ng_topk_wavefront_global=1 a7ng_native_ctx_bind=1 tiny_gpt803k_core=1 uart_module=0");
    $display("STRUCTURAL TB_DOES_NOT_DRIVE_BIND_GLOBAL_ID_I");

    $readmemh("a7lm06_wmem.hex", wmem);
    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    repeat (4) @(posedge clk);
    for (i = 0; i < NPARAM; i = i + 1) begin
      @(posedge clk);
      mem_we <= 1'b1; mem_addr <= i[19:0]; mem_wdata <= wmem[i];
    end
    @(posedge clk); mem_we <= 1'b0;
    exam = 1'b1;
    pred_neg = pred;

    req_graph = 1'b1; req_lm = 1'b0;
    @(posedge clk); wait (grant_graph);
    four_waves(1'b0);
    if (merge_count !== 32'd4) begin $display("FAIL merge_count=%0d", merge_count); $finish; end
    check_global(exp_c, exp_cs, "NEG_GLOBAL");
    req_graph = 1'b0; req_lm = 1'b1; do_start = 1'b0;
    @(posedge clk); wait (grant_lm);
    repeat (64) @(posedge clk);
    if (st_beats !== 32'd0 || pred !== pred_neg) begin
      $display("FAIL NEG start_beats=%0d pred=%0d", st_beats, pred);
      $finish;
    end
    $display("NEG_OK pred=%0d start_beats=0 merges=4", pred);

    @(posedge clk); clear_i <= 1'b1; @(posedge clk); clear_i <= 1'b0;
    req_lm=0; req_graph=1; do_start=0; poison=0;
    @(posedge clk); wait (grant_graph);
    four_waves(1'b0);
    check_global(exp_c, exp_cs, "CTRL");
    req_graph=0; req_lm=1; do_start=1;
    @(posedge clk); wait (grant_lm);
    poison_after_accept(PACK_C);
    fork
      begin wait (bind_done); end
      begin repeat (200_000_000) @(posedge clk); $display("FAIL CTRL timeout"); $finish; end
    join_any
    disable fork;
    pred_c = pred;
    $display("CTRL_DONE pred=%0d pack_ok merges=%0d gv=%0d", pred_c, merge_count, gv_count);

    @(posedge clk); clear_i <= 1'b1; @(posedge clk); clear_i <= 1'b0;
    req_lm=0; req_graph=1; do_start=0; poison=0;
    @(posedge clk); wait (grant_graph);
    four_waves(1'b1);
    check_global(exp_p, exp_ps, "PERT");
    req_graph=0; req_lm=1; do_start=1;
    @(posedge clk); wait (grant_lm);
    poison_after_accept(PACK_P);
    fork
      begin wait (bind_done); end
      begin repeat (200_000_000) @(posedge clk); $display("FAIL PERT timeout"); $finish; end
    join_any
    disable fork;
    pred_p = pred;
    $display("PERT_DONE pred=%0d", pred_p);

    $display("HS22_DYNAMIC waves=4+4+4 merge_final=%0d gv_events=%0d inter_start=%0d ctx_we_beats=%0d start_fwd_beats=%0d pred_C=%0d pred_P=%0d dual_ticks=%0d mem_we_exam=%0d capture_mismatch=%0d",
             merge_count, gv_events, inter_start, ctx_beats, st_beats, pred_c, pred_p,
             dual_ticks, mem_we_exam, capture_mismatch);

    if (inter_start !== 0) begin $display("FAIL intermediate start"); $finish; end
    if (dual_ticks !== 0 || mem_we_exam !== 0 || capture_mismatch !== 0) begin
      $display("FAIL safety"); $finish;
    end
    if (st_beats !== 32'd2) begin $display("FAIL start_fwd_beats=%0d", st_beats); $finish; end
    if (pred_c === pred_p) begin $display("FAIL pred invariant"); $finish; end
    $display("HS22_LM06_NATIVE_TOPK_INTEGRATE_XSIM_PASS pred_C=%0d pred_P=%0d", pred_c, pred_p);
    $finish;
  end
endmodule
