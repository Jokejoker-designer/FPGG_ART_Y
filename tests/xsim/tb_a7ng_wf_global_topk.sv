// tb_a7ng_wf_global_topk.sv — wf_global_topk_00 cross-wave global Top-8
// UNKNOWN: Does G_(t+1)=TopK(G_t ∪ TopK(W_t)) preserve NG-02R law across waves?
// FALSIFIER: rank-9 in W2 beats W1 8th but per-wave-only path keeps wrong survivor.
// UNIT: one query = full multi-wave candidate set (not one clock cycle).
// Evidence_class: XSIM — not BOARD.
`timescale 1ns / 1ps

module tb_a7ng_wf_global_topk;
  import a7ng_pkg::*;

  logic clk, rst_n;
  logic clear_i, wave_valid_i;
  logic [4:0] wave_scored_i;
  score_t   wave_score_i [8];
  node_id_t wave_id_i    [8];
  logic       global_valid_o;
  score_t     global_score_o [8];
  node_id_t   global_id_o    [8];
  logic [31:0] merge_count_o;

  a7ng_topk_wavefront_global #(.K(8)) dut (
    .clk(clk), .rst_n(rst_n),
    .clear_i(clear_i),
    .wave_valid_i(wave_valid_i),
    .wave_scored_i(wave_scored_i),
    .wave_score_i(wave_score_i),
    .wave_id_i(wave_id_i),
    .global_valid_o(global_valid_o),
    .global_score_o(global_score_o),
    .global_id_o(global_id_o),
    .busy_o(),
    .merge_count_o(merge_count_o)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer fails, i, k;
  score_t   ws [8];
  node_id_t wi [8];
  score_t   gs [8];
  node_id_t gi [8];
  score_t   exp_g [8];
  node_id_t exp_gid [8];
  score_t   exp_pw [8];
  node_id_t exp_pid [8];

  score_t   lat_gs [8];
  node_id_t lat_gi [8];
  logic     lat_ok;

  task automatic drive_wave(
    input logic [4:0] n_scored,
    input score_t scores [8],
    input node_id_t ids [8]
  );
    integer w, c;
    begin
      lat_ok = 1'b0;
      wave_scored_i = n_scored;
      for (w = 0; w < 8; w = w + 1) begin
        wave_score_i[w] = scores[w];
        wave_id_i[w]    = ids[w];
      end
      @(posedge clk);
      wave_valid_i = 1'b1;
      @(posedge clk);
      wave_valid_i = 1'b0;
      for (c = 0; c < 32; c = c + 1) begin
        if (global_valid_o) begin
          for (w = 0; w < 8; w = w + 1) begin
            lat_gs[w] = global_score_o[w];
            lat_gi[w] = global_id_o[w];
          end
          lat_ok = 1'b1;
          break;
        end
        @(posedge clk);
      end
      if (!lat_ok) begin
        $display("FAIL drive_wave timeout n_scored=%0d", n_scored);
        fails = fails + 1;
      end
    end
  endtask

  task automatic check_global(
    input score_t exp_s [8],
    input node_id_t exp_i [8],
    input string tag
  );
    integer c;
    begin
      for (c = 0; c < 8; c = c + 1) begin
        if (lat_gs[c] !== exp_s[c] || lat_gi[c] !== exp_i[c]) begin
          $display("FAIL %s slot%0d got s=%0d id=%0h exp s=%0d id=%0h",
                   tag, c, lat_gs[c], lat_gi[c], exp_s[c], exp_i[c]);
          fails = fails + 1;
        end
      end
    end
  endtask

  task automatic check_perwave_fail(
    input score_t pw_s [8],
    input node_id_t pw_i [8],
    input string tag
  );
    integer c, diff;
    begin
      diff = 0;
      for (c = 0; c < 8; c = c + 1)
        if (lat_gs[c] !== pw_s[c] || lat_gi[c] !== pw_i[c])
          diff = diff + 1;
      if (diff == 0) begin
        $display("FAIL %s per-wave-only matches global (reducer not needed)", tag);
        fails = fails + 1;
      end else begin
        $display("PASS %s per-wave-only differs from global (%0d slots)", tag, diff);
      end
    end
  endtask

  initial begin
    fails = 0;
    rst_n = 0;
    clear_i = 0;
    wave_valid_i = 0;
    wave_scored_i = 0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // ------------------------------------------------------------------
    // Counterexample: non-sequential node_id; W2 rank-9 beats W1 8th (130).
    // W1: 16 scored → local top-8 = 200,190,...,130 (ids 0xA000..0xA007)
    // W2: 0xDEADBEEF score 135 beats 130; fillers < 50
    // Global must include 0xDEADBEEF; per-wave-only (W2) must NOT.
    // ------------------------------------------------------------------
  clear_i = 1;
  @(posedge clk);
  clear_i = 0;
  @(posedge clk);

    // Build W1 wave top-8 from 16 candidates (scores 200,190,...,50 step -10 for 16)
    for (i = 0; i < 8; i = i + 1) begin
      ws[i] = score_t'(200 - 10*i);
      wi[i] = node_id_t'(32'hA000 + i);
    end
    drive_wave(5'd16, ws, wi);

    // W2 wave top-8: superstar + fillers
    ws[0] = score_t'(135);
    wi[0] = node_id_t'(32'hDEAD_BEEF);
    for (i = 1; i < 8; i = i + 1) begin
      ws[i] = score_t'(50 - i);
      wi[i] = node_id_t'(32'hB000 + i);
    end
    drive_wave(5'd16, ws, wi);

    exp_g[0] = 200; exp_gid[0] = 32'hA000;
    exp_g[1] = 190; exp_gid[1] = 32'hA001;
    exp_g[2] = 180; exp_gid[2] = 32'hA002;
    exp_g[3] = 170; exp_gid[3] = 32'hA003;
    exp_g[4] = 160; exp_gid[4] = 32'hA004;
    exp_g[5] = 150; exp_gid[5] = 32'hA005;
    exp_g[6] = 140; exp_gid[6] = 32'hA006;
    exp_g[7] = 135; exp_gid[7] = 32'hDEAD_BEEF;

    check_global(exp_g, exp_gid, "counterexample_global");

    exp_pw[0] = 135; exp_pid[0] = 32'hDEAD_BEEF;
    for (i = 1; i < 8; i = i + 1) begin
      exp_pw[i] = 50 - i;
      exp_pid[i] = 32'hB000 + i;
    end
    check_perwave_fail(exp_pw, exp_pid, "counterexample_perwave_only");

    if (merge_count_o !== 32'd2) begin
      $display("FAIL merge_count got %0d exp 2", merge_count_o);
      fails = fails + 1;
    end

    // ------------------------------------------------------------------
    // Three-wave accumulation: G must retain W1 best across W2 low + W3 bump
    // ------------------------------------------------------------------
    clear_i = 1;
    @(posedge clk);
    clear_i = 0;
    @(posedge clk);

    ws[0] = 300; wi[0] = 32'hC001;
    for (i = 1; i < 8; i = i + 1) begin
      ws[i] = 100 - i;
      wi[i] = 32'hC100 + i;
    end
    drive_wave(5'd16, ws, wi);

    ws[0] = 50; wi[0] = 32'hD001;
    for (i = 1; i < 8; i = i + 1) begin
      ws[i] = 40 - i;
      wi[i] = 32'hD100 + i;
    end
    drive_wave(5'd16, ws, wi);

    ws[0] = 250; wi[0] = 32'hE001;
    for (i = 1; i < 8; i = i + 1) begin
      ws[i] = 30 - i;
      wi[i] = 32'hE100 + i;
    end
    drive_wave(5'd16, ws, wi);

    if (lat_gi[0] !== 32'hC001 || lat_gs[0] !== 300) begin
      $display("FAIL three_wave top1 got s=%0d id=%0h", lat_gs[0], lat_gi[0]);
      fails = fails + 1;
    end
    if (lat_gi[1] !== 32'hE001 || lat_gs[1] !== 250) begin
      $display("FAIL three_wave rank2 got s=%0d id=%0h", lat_gs[1], lat_gi[1]);
      fails = fails + 1;
    end

    // ------------------------------------------------------------------
    // Verdict
    // ------------------------------------------------------------------
    if (fails == 0) begin
      $display("A7NG_WF_GLOBAL_TOPK_XSIM_PASS fails=0 merge_count=%0d", merge_count_o);
    end else begin
      $display("A7NG_WF_GLOBAL_TOPK_XSIM_FAIL fails=%0d", fails);
    end
    #100 $finish;
  end
endmodule
