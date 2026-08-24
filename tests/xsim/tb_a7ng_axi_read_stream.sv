// tb_a7ng_axi_read_stream.sv — fast protocol unit (engineering only, not gate closeout)
`timescale 1ns / 1ps

module tb_a7ng_axi_read_stream;
  localparam int MAX_BEATS = 52;

  logic clk, rst_n;
  logic start;
  logic [4:0] burst;
  logic [3:0] outstanding;
  logic [27:0] base_byte;
  logic [5:0] beat_target;

  logic ar_valid, ar_ready;
  logic [27:0] ar_addr;
  logic [7:0] ar_len;
  logic [3:0] ar_id;
  logic [2:0] ar_size;
  logic r_valid, r_ready, r_last;
  logic [127:0] r_data;
  logic [127:0] beats [MAX_BEATS];
  logic running, done, done_pulse;
  logic [5:0] beats_returned, beats_issued;
  logic [31:0] acc_txns, acc_credit, ret_beats, ret_txns, out_txns, unpack_beats;

  int fail_cnt;

  always #5 clk = ~clk;

  a7ng_axi_read_stream #(
    .MAX_BEATS(MAX_BEATS), .MAX_OUT(8), .MAX_BURST(16)
  ) dut (
    .clk(clk), .rst_n(rst_n),
    .start_i(start),
    .burst_i(burst), .outstanding_i(outstanding),
    .base_byte_i(base_byte), .beat_target_i(beat_target),
    .ar_valid_o(ar_valid), .ar_ready_i(ar_ready),
    .ar_addr_o(ar_addr), .ar_len_o(ar_len), .ar_id_o(ar_id), .ar_size_o(ar_size),
    .r_valid_i(r_valid), .r_ready_o(r_ready),
    .r_data_i(r_data), .r_last_i(r_last),
    .beat_data_o(beats),
    .running_o(running), .done_o(done), .done_pulse_o(done_pulse),
    .beats_returned_o(beats_returned), .beats_issued_o(beats_issued),
    .accepted_txns_o(acc_txns), .accepted_beat_credit_o(acc_credit),
    .returned_beats_o(ret_beats), .returned_transactions_o(ret_txns),
    .outstanding_txns_o(out_txns), .unpack_beats_o(unpack_beats)
  );

  localparam int TXQ_DEPTH = 8;
  logic [3:0]  tx_id   [TXQ_DEPTH];
  logic [27:0] tx_addr [TXQ_DEPTH];
  logic [8:0]  tx_left [TXQ_DEPTH];
  logic [2:0]  tx_wr, tx_rd, tx_cnt;
  logic [3:0]  rid_q;
  logic [8:0]  beat_left;
  logic [27:0] cur_addr;
  int ar_delay, r_delay, ar_hold_cnt, r_hold_cnt;

  function automatic logic [2:0] tx_inc(input logic [2:0] p);
    return (p == TXQ_DEPTH-1) ? 3'd0 : p + 3'd1;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ar_ready <= 1'b0;
      r_valid <= 1'b0;
      rid_q <= '0;
      beat_left <= '0;
      cur_addr <= '0;
      ar_hold_cnt <= 0;
      r_hold_cnt <= 0;
      tx_wr <= 3'd0;
      tx_rd <= 3'd0;
      tx_cnt <= 3'd0;
    end else begin
      if (ar_hold_cnt > 0) begin
        ar_hold_cnt <= ar_hold_cnt - 1;
        ar_ready <= 1'b0;
      end else if (ar_valid && !ar_ready) begin
        ar_ready <= 1'b1;
      end else if (ar_valid && ar_ready) begin
        ar_ready <= 1'b0;
        if (tx_cnt < TXQ_DEPTH) begin
          tx_id[tx_wr]   <= ar_id;
          tx_addr[tx_wr] <= ar_addr;
          tx_left[tx_wr] <= 9'(ar_len) + 9'd1;
          tx_wr <= tx_inc(tx_wr);
          tx_cnt <= tx_cnt + 3'd1;
        end
        ar_hold_cnt <= ar_delay;
      end else
        ar_ready <= 1'b0;

      if (tx_cnt != 0 && beat_left == 0 && !r_valid && r_hold_cnt == 0) begin
        rid_q    <= tx_id[tx_rd];
        cur_addr <= tx_addr[tx_rd];
        beat_left <= tx_left[tx_rd];
      end

      if (r_hold_cnt > 0) begin
        r_hold_cnt <= r_hold_cnt - 1;
        r_valid <= 1'b0;
      end else if (beat_left != 0 && !r_valid) begin
        r_valid <= 1'b1;
        r_data <= {cur_addr, cur_addr, cur_addr, cur_addr};
        r_last <= (beat_left == 9'd1);
        r_hold_cnt <= r_delay;
      end else if (r_valid && r_ready) begin
        if (beat_left == 9'd1) begin
          beat_left <= 9'd0;
          r_valid <= 1'b0;
          tx_rd <= tx_inc(tx_rd);
          tx_cnt <= tx_cnt - 3'd1;
        end else begin
          beat_left <= beat_left - 9'd1;
          cur_addr <= cur_addr + 28'd16;
          r_valid <= 1'b0;
        end
      end
    end
  end

  task automatic drain_idle;
    int d;
    begin
      start = 1'b0;
      d = 0;
      while ((running || ar_valid || r_valid || beat_left != 0 || tx_cnt != 0) && d < 256) begin
        @(posedge clk);
        d = d + 1;
      end
      repeat (8) @(posedge clk);
    end
  endtask

  task automatic wait_transfer(input int timeout, output bit ok);
    int t;
    begin
      ok = 1'b0;
      t = 0;
      while (!running && t < 20) begin
        @(posedge clk);
        t = t + 1;
      end
      if (!running)
        return;
      t = 0;
      while (running && t < timeout) begin
        @(posedge clk);
        t = t + 1;
      end
      ok = done && !running;
      repeat (2) @(posedge clk);
    end
  endtask

  task automatic run_case(
      input string name, input int b, input int o,
      input logic [27:0] base, input int nbeats
  );
    bit finished;
    begin
      drain_idle();
      burst = 5'(b);
      outstanding = 4'(o);
      base_byte = base;
      beat_target = 6'(nbeats);
      ar_delay = $urandom_range(0, 3);
      r_delay  = $urandom_range(0, 3);
      repeat (4) @(posedge clk);
      @(negedge clk);
      start = 1'b1;
      @(posedge clk);
      @(negedge clk);
      start = 1'b0;
      wait_transfer(100000, finished);
      if (!finished) begin
        $display("AXI_STREAM_FAIL %s TIMEOUT running=%0d done=%0d ret=%0d iss=%0d",
                 name, running, done, beats_returned, beats_issued);
        fail_cnt = fail_cnt + 1;
      end else if (beats_returned != nbeats || ret_beats != nbeats ||
                   acc_credit != nbeats || unpack_beats != nbeats) begin
        $display("AXI_STREAM_FAIL %s beats=%0d ret=%0d credit=%0d unpack=%0d expect=%0d",
                 name, beats_returned, ret_beats, acc_credit, unpack_beats, nbeats);
        fail_cnt = fail_cnt + 1;
      end else
        $display("AXI_STREAM_PASS %s burst=%0d out=%0d beats=%0d txns=%0d",
                 name, b, o, nbeats, acc_txns);
      drain_idle();
    end
  endtask

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;
    fail_cnt = 0;
    ar_delay = 0;
    r_delay = 0;
    #20 rst_n = 1'b1;
    repeat (4) @(posedge clk);

    run_case("prior_plane", 1, 1, 28'h0300_0000, 4);
    run_case("prior_burst4", 4, 8, 28'h0300_0000, 4);
    run_case("full_soa_cue", 16, 8, 28'h0110_0000, 32);
    run_case("full_soa_id", 16, 8, 28'h0100_0000, 16);
    run_case("full_soa_52", 16, 8, 28'h0100_0000, 52);

    if (fail_cnt == 0)
      $display("A7NG_AXI_READ_STREAM_UNIT_PASS");
    else
      $display("A7NG_AXI_READ_STREAM_UNIT_FAIL fails=%0d", fail_cnt);
    $finish;
  end
endmodule
