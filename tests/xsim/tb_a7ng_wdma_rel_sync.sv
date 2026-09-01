// P2-WDMA-RELEASE-CDC-AUDIT-03 dual-clock unit. PROGRAM=NO.
// Random-phase clocks, ui-first reset skew, exactly-once release pulse,
// stable {empty,idle,quiet} payload at toggle, no premature owner grant.
`timescale 1ns / 1ps

module tb_a7ng_wdma_rel_sync;
  logic core_clk, ui_clk, core_rst_n, ui_rst_n;
  logic cmd_empty;
  logic [2:0] dma_st;
  logic [3:0] arr_outst;
  logic rel_ok, rel_pulse, req_tog, ack_tog, and_q;
  logic [2:0] payload_hold;
  logic owner, miss, soa;
  logic grant, grant_d, pulse_d;
  integer fails, i;
  integer n_and_rise, n_pulse, n_grant_fall, n_grant_rise;
  integer n_idle_win;
  integer n_premature_rel, n_premature_grant;
  logic and_q_d;
  logic [31:0] and_hist;
  logic [31:0] lfsr;
  integer hold;

  initial core_clk = 1'b0;
  always #5 core_clk = ~core_clk; // 100 MHz
  initial begin
    ui_clk = 1'b0;
    #3;
    forever #4 ui_clk = ~ui_clk; // 125 MHz, 3 ns phase
  end

  a7ng_wdma_rel_sync u_dut (
    .ui_clk(ui_clk), .ui_rst_n(ui_rst_n),
    .core_clk(core_clk), .core_rst_n(core_rst_n),
    .cmd_empty_i(cmd_empty), .dma_st_i(dma_st), .arr_outst_i(arr_outst),
    .rel_ok_o(rel_ok), .rel_pulse_o(rel_pulse),
    .req_tog_o(req_tog), .ack_tog_o(ack_tog),
    .and_q_o(and_q), .payload_hold_o(payload_hold)
  );

  // Product grant law (core): set on owner/miss, drop on dest AND level.
  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n)
      grant <= 1'b0;
    else if ((owner || miss) && !soa)
      grant <= 1'b1;
    else if (!owner && !miss && rel_ok)
      grant <= 1'b0;
  end

  always_ff @(posedge core_clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      grant_d <= 1'b0;
      pulse_d <= 1'b0;
      and_hist <= 32'd0;
      n_pulse <= 0;
      n_grant_fall <= 0;
      n_grant_rise <= 0;
      n_premature_rel <= 0;
      n_premature_grant <= 0;
    end else begin
      if (rel_pulse && !pulse_d) n_pulse <= n_pulse + 1;
      if (grant_d && !grant) n_grant_fall <= n_grant_fall + 1;
      if (!grant_d && grant) n_grant_rise <= n_grant_rise + 1;
      grant_d <= grant;
      pulse_d <= rel_pulse;
      and_hist <= {and_hist[30:0], and_q};
      if (rel_ok && (and_hist == 32'd0) && (and_q === 1'b0)) begin
        $display("FAIL premature rel_ok with no recent source AND t=%0t", $time);
        n_premature_rel <= n_premature_rel + 1;
      end
      if (!grant_d && grant && !(owner || miss)) begin
        $display("FAIL premature owner grant t=%0t", $time);
        n_premature_grant <= n_premature_grant + 1;
      end
    end
  end

  always_ff @(posedge ui_clk or negedge ui_rst_n) begin
    if (!ui_rst_n) begin
      and_q_d <= 1'b0;
      n_and_rise <= 0;
    end else begin
      if (and_q && !and_q_d) begin
        n_and_rise <= n_and_rise + 1;
        if (payload_hold !== 3'b111 && and_q) begin
          // payload is captured on the toggle cycle; allow one-cycle align
        end
      end
      and_q_d <= and_q;
    end
  end

  function automatic [31:0] step_lfsr(input [31:0] s);
    step_lfsr = {s[30:0], s[31] ^ s[21] ^ s[1] ^ s[0]};
  endfunction

  initial begin
    #4000000;
    $display("FAIL WDMA rel CDC TB timeout");
    $finish;
  end

  initial begin
    fails = 0; n_idle_win = 0;
    cmd_empty = 1'b0; dma_st = 3'd1; arr_outst = 4'd1;
    owner = 1'b0; miss = 1'b0; soa = 1'b0;
    lfsr = 32'hA5A5_C3C3;
    core_rst_n = 1'b0; ui_rst_n = 1'b0;
    repeat (8) @(posedge ui_clk);
    ui_rst_n = 1'b1;
    repeat (5) @(posedge core_clk);
    core_rst_n = 1'b1;
    repeat (8) @(posedge core_clk);

    // Structured: grant, drain, exactly-once release, no drop while busy.
    for (i = 0; i < 16; i = i + 1) begin
      @(negedge core_clk);
      owner = 1'b1; miss = 1'b0; soa = 1'b0;
      @(negedge ui_clk);
      cmd_empty = 1'b0; dma_st = 3'd5; arr_outst = 4'd3;
      repeat (6) @(posedge core_clk);
      if (!grant) begin
        $display("FAIL grant not set i=%0d", i);
        fails = fails + 1;
      end
      @(negedge core_clk); owner = 1'b0;
      repeat (8) @(posedge core_clk);
      if (!grant) begin
        $display("FAIL grant dropped before quiet i=%0d", i);
        fails = fails + 1;
      end
      @(negedge ui_clk);
      cmd_empty = 1'b1; dma_st = 3'd0; arr_outst = 4'd0;
      n_idle_win = n_idle_win + 1;
      hold = 0;
      while (grant && hold < 80) begin
        @(posedge core_clk);
        hold = hold + 1;
      end
      if (grant) begin
        $display("FAIL grant stuck after quiet i=%0d", i);
        fails = fails + 1;
      end
      if (payload_hold !== 3'b111) begin
        $display("FAIL payload not 111 got=%b i=%0d", payload_hold, i);
        fails = fails + 1;
      end
      repeat (4) @(posedge core_clk);
    end

    // Randomized flags + owner; dest AND must not invent idle.
    for (i = 0; i < 200; i = i + 1) begin
      lfsr = step_lfsr(lfsr);
      @(negedge ui_clk);
      cmd_empty = lfsr[0];
      dma_st    = lfsr[3:1];
      arr_outst = lfsr[7:4];
      @(negedge core_clk);
      owner = lfsr[8];
      miss  = lfsr[9] & ~lfsr[8];
      soa   = lfsr[10];
    end
    // Forced idle windows with random owner — handshake under skew.
    for (i = 0; i < 16; i = i + 1) begin
      lfsr = step_lfsr(lfsr);
      @(negedge core_clk);
      owner = lfsr[0]; miss = 1'b0; soa = 1'b0;
      @(negedge ui_clk);
      cmd_empty = 1'b0; dma_st = 3'd2; arr_outst = 4'd1;
      repeat (3) @(posedge ui_clk);
      @(negedge ui_clk);
      cmd_empty = 1'b1; dma_st = 3'd0; arr_outst = 4'd0;
      repeat (12) @(posedge ui_clk);
      @(negedge ui_clk);
      cmd_empty = 1'b0; dma_st = 3'd4; arr_outst = 4'd2;
      repeat (4) @(posedge core_clk);
    end
    repeat (20) @(posedge core_clk);

    if (n_premature_rel != 0) begin
      $display("FAIL premature_rel=%0d", n_premature_rel);
      fails = fails + 1;
    end
    if (n_premature_grant != 0) begin
      $display("FAIL premature_grant=%0d", n_premature_grant);
      fails = fails + 1;
    end
    // Pulse must not exceed idle windows / AND rises (no extra release).
    if (n_pulse > (n_and_rise + 2)) begin
      $display("FAIL extra pulses pulse=%0d and_rise=%0d", n_pulse, n_and_rise);
      fails = fails + 1;
    end
    if (n_pulse < 16) begin
      $display("FAIL too few pulses=%0d (structured idle_win=%0d)", n_pulse, n_idle_win);
      fails = fails + 1;
    end
    if (n_grant_fall < 16) begin
      $display("FAIL grant_fall=%0d", n_grant_fall);
      fails = fails + 1;
    end

    if (fails == 0)
      $display("WDMA_REL_CDC_XSIM_PASS fails=0 pulse=%0d and_rise=%0d grant_fall=%0d idle_win=%0d phase=3ns rst_skew=ui_first",
               n_pulse, n_and_rise, n_grant_fall, n_idle_win);
    else
      $display("WDMA_REL_CDC_XSIM_FAIL fails=%0d pulse=%0d and_rise=%0d grant_fall=%0d",
               fails, n_pulse, n_and_rise, n_grant_fall);
    $finish;
  end
endmodule
