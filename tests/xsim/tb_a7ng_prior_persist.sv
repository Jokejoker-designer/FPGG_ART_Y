// tb_a7ng_prior_persist.sv — NG-05 DDR persist / kill-BRAM / reload / forget / retrain
`timescale 1ns / 1ps

module tb_a7ng_prior_persist;
  import a7ng_pkg::*;

  logic clk, rst_n, learn_en, freeze, forget, bram_kill, flush, reload, upd, rd;
  logic busy, done;
  logic [5:0] idx, rd_idx;
  logic signed [3:0] reward;
  logic signed [7:0] prior;
  logic [15:0] ucnt;

  logic [3:0] awid, arid, bid, rid;
  logic [27:0] awaddr, araddr;
  logic [7:0] awlen, arlen;
  logic [2:0] awsize, arsize;
  logic [1:0] awburst, arburst, bresp, rresp;
  logic awvalid, awready, wlast, wvalid, wready, bvalid, bready;
  logic arvalid, arready, rlast, rvalid, rready;
  logic [127:0] wdata, rdata;
  logic [15:0] wstrb;

  a7ng_prior_persist dut (
    .clk(clk), .rst_n(rst_n),
    .learn_en_i(learn_en), .freeze_i(freeze), .forget_i(forget),
    .bram_kill_i(bram_kill), .flush_i(flush), .reload_i(reload),
    .upd_i(upd), .idx_i(idx), .reward_i(reward),
    .rd_i(rd), .rd_idx_i(rd_idx),
    .prior_o(prior), .busy_o(busy), .done_o(done), .update_count_o(ucnt),
    .m_axi_awid(awid), .m_axi_awaddr(awaddr), .m_axi_awlen(awlen),
    .m_axi_awsize(awsize), .m_axi_awburst(awburst),
    .m_axi_awvalid(awvalid), .m_axi_awready(awready),
    .m_axi_wdata(wdata), .m_axi_wstrb(wstrb), .m_axi_wlast(wlast),
    .m_axi_wvalid(wvalid), .m_axi_wready(wready),
    .m_axi_bid(bid), .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(bready),
    .m_axi_arid(arid), .m_axi_araddr(araddr), .m_axi_arlen(arlen),
    .m_axi_arsize(arsize), .m_axi_arburst(arburst),
    .m_axi_arvalid(arvalid), .m_axi_arready(arready),
    .m_axi_rid(rid), .m_axi_rdata(rdata), .m_axi_rresp(rresp),
    .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready)
  );

  a7ng_axi_mem_model #(.DEPTH_WORDS(4096)) mem (
    .clk(clk), .rst_n(rst_n),
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

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic poke_upd(input [5:0] i, input signed [3:0] r);
    begin
      @(negedge clk); idx = i; reward = r; upd = 1;
      @(posedge clk); #1; upd = 0;
    end
  endtask

  task automatic poke_rd(input [5:0] i);
    begin
      @(negedge clk); rd_idx = i; rd = 1;
      @(posedge clk); #1; rd = 0;
    end
  endtask

  task automatic do_pulse(ref logic sig);
    begin
      @(negedge clk); sig = 1;
      @(posedge clk); #1; sig = 0;
      wait (done);
      @(posedge clk);
    end
  endtask

  integer fails;
  initial begin
    fails = 0;
    rst_n = 0; learn_en = 1; freeze = 0;
    forget = 0; bram_kill = 0; flush = 0; reload = 0;
    upd = 0; rd = 0; idx = 0; rd_idx = 0; reward = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Train idx3 = +3 twice → 6
    poke_upd(6'd3, 4'sd3);
    poke_upd(6'd3, 4'sd3);
    poke_rd(6'd3);
    if (prior !== 8'sd6) begin $display("FAIL train prior=%0d", prior); fails = fails + 1; end

    // Flush to DDR
    do_pulse(flush);

    // Kill BRAM (power-loss hotset) — prior gone in BRAM
    @(negedge clk); bram_kill = 1;
    @(posedge clk); #1; bram_kill = 0;
    poke_rd(6'd3);
    if (prior !== 8'sd0) begin $display("FAIL bram_kill prior=%0d", prior); fails = fails + 1; end

    // Reload from DDR — teacher-off persist
    do_pulse(reload);
    poke_rd(6'd3);
    if (prior !== 8'sd6) begin $display("FAIL persist reload prior=%0d", prior); fails = fails + 1; end

    // Full forget removes BRAM+DDR behavior
    do_pulse(forget);
    poke_rd(6'd3);
    if (prior !== 8'sd0) begin $display("FAIL forget prior=%0d", prior); fails = fails + 1; end
    do_pulse(reload);
    poke_rd(6'd3);
    if (prior !== 8'sd0) begin $display("FAIL forget DDR prior=%0d", prior); fails = fails + 1; end

    // Retrain different mapping
    poke_upd(6'd3, -4'sd3);
    poke_rd(6'd3);
    if (prior !== -8'sd3) begin $display("FAIL retrain prior=%0d", prior); fails = fails + 1; end

    // Host cannot inject weights: no prior_wr port — freeze+learn_en prove reward-only path
    @(negedge clk); freeze = 1;
    poke_upd(6'd3, 4'sd3);
    poke_rd(6'd3);
    if (prior !== -8'sd3) begin $display("FAIL freeze inject prior=%0d", prior); fails = fails + 1; end

    if (fails == 0) $display("A7NG05_PERSIST_XSIM_PASS");
    else $display("A7NG05_PERSIST_XSIM_FAIL fails=%0d", fails);
    $finish;
  end
endmodule
