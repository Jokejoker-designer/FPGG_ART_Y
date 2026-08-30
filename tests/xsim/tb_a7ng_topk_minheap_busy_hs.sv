// Handshake for serial/min-heap Global Top-8. PROGRAM=NO. XSim only.
// Frozen bitonic merge is 1–2 cycles; min-heap stays busy until ordered commit.
// Old parallel fire (next wave ~2 cycles later) must NOT be reused.
`timescale 1ns / 1ps

module tb_a7ng_topk_minheap_busy_hs;
  import a7ng_pkg::*;

  logic clk, rst_n, clear_i, wave_valid_i;
  logic [4:0] wave_scored_i;
  score_t   wave_score_i [8];
  node_id_t wave_id_i    [8];
  logic       hv, hb;
  score_t     hs [8];
  node_id_t   hi [8];
  logic [31:0] hmc;

  a7ng_topk_wavefront_minheap #(.K(8), .HEAP_CMP_LANES(1)) dut (
    .clk(clk), .rst_n(rst_n), .clear_i(clear_i),
    .wave_valid_i(wave_valid_i), .wave_scored_i(wave_scored_i),
    .wave_score_i(wave_score_i), .wave_id_i(wave_id_i),
    .global_valid_o(hv), .global_score_o(hs), .global_id_o(hi),
    .busy_o(hb), .merge_count_o(hmc)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  integer fails, gv, i, t;

  task automatic fill_wave(input int base_id, input int sc0);
    integer k;
    begin
      wave_scored_i = 5'd8;
      for (k = 0; k < 8; k = k + 1) begin
        wave_score_i[k] = score_t'(sc0 - k);
        wave_id_i[k]    = node_id_t'(base_id + k);
      end
    end
  endtask

  task automatic fire_one();
    begin
      @(negedge clk);
      wave_valid_i = 1'b1;
      @(posedge clk);
      @(negedge clk);
      wave_valid_i = 1'b0;
    end
  endtask

  initial begin
    fails = 0;
    gv = 0;
    rst_n = 1'b0;
    clear_i = 1'b0;
    wave_valid_i = 1'b0;
    wave_scored_i = 5'd0;
    fill_wave(0, 0);
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    clear_i = 1'b1;
    @(posedge clk);
    clear_i = 1'b0;
    @(posedge clk);

    fork
      forever begin
        @(posedge clk);
        if (hv)
          gv = gv + 1;
      end
    join_none

    // --- Serial handshake: fire only when !busy (product producer law) ---
    for (i = 0; i < 4; i = i + 1) begin
      t = 0;
      while (hb && t < 4096) begin
        @(posedge clk);
        t = t + 1;
      end
      if (hb) begin
        $display("FAIL stall-producer still busy before wave %0d", i);
        fails = fails + 1;
      end
      fill_wave(i * 16, 200 - i * 10);
      fire_one();
    end

    t = 0;
    while ((hmc < 32'd4 || gv < 4 || hb) && t < 4096) begin
      @(posedge clk);
      t = t + 1;
    end

    if (hmc !== 32'd4 || gv !== 4 || hb) begin
      $display("FAIL stall-producer merges=%0d gv=%0d busy=%0b wait=%0d", hmc, gv, hb, t);
      fails = fails + 1;
    end else
      $display("PASS stall-producer merges=4 gv=4 busy=0 cycles_after_last_fire=%0d", t);

    // --- Rival: old parallel 1–2 cycle fire. Second wave must be dropped. ---
    clear_i = 1'b1;
    @(posedge clk);
    clear_i = 1'b0;
    gv = 0;
    @(posedge clk);

    fill_wave(0, 100);
    fire_one();
    @(posedge clk); // bitonic-era gap
    fill_wave(16, 90);
    fire_one();

    t = 0;
    while (hb && t < 4096) begin
      @(posedge clk);
      t = t + 1;
    end
    repeat (8) @(posedge clk);

    if (hmc === 32'd2) begin
      $display("FAIL parallel-fire still merged both — cannot treat min-heap as 1-2 cycle");
      fails = fails + 1;
    end else if (hmc === 32'd1) begin
      $display("PASS parallel-fire-drop merges=1 (old bitonic timing FALSIFIED for min-heap)");
    end else begin
      $display("FAIL parallel-fire-drop merges=%0d", hmc);
      fails = fails + 1;
    end

    if (fails == 0)
      $display("TOPK_MINHEAP_BUSY_HS_XSIM_PASS fails=0");
    else
      $display("TOPK_MINHEAP_BUSY_HS_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
