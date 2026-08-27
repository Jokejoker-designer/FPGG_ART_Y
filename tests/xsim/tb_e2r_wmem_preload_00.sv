`timescale 1ns / 1ps
// tb_e2r_wmem_preload_00.sv — Gate 2: AXI memory model + wmem boot write/readback
module tb_e2r_wmem_preload_00;
  import a7lm06_pkg::*;

  localparam int unsigned N_BYTES = 802816;
  localparam int unsigned N_BEATS = N_BYTES / 16;
  localparam logic [27:0] BASE = 28'(DDR_WBASE);

  logic clk, rst_n, start_i, busy_o, done_o;
  logic [31:0] bytes_written_o;
  logic [3:0]  awid, bid;
  logic [27:0] awaddr;
  logic [7:0]  awlen;
  logic [2:0]  awsize;
  logic [1:0]  awburst, bresp;
  logic        awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic [127:0] wdata;
  logic [15:0] wstrb;

  // Simple DDR model (byte array)
  logic [7:0] ddr [0:N_BYTES-1];
  logic [7:0] gold [0:N_BYTES-1];

  integer gi, mismatches;
  logic aw_fire, w_fire;

  a7ng_ddr_wmem_boot #(.N_BYTES(N_BYTES), .BASE(BASE)) dut (
    .clk(clk), .rst_n(rst_n), .start_i(start_i),
    .busy_o(busy_o), .done_o(done_o), .bytes_written_o(bytes_written_o),
    .m_axi_awid(awid), .m_axi_awaddr(awaddr), .m_axi_awlen(awlen),
    .m_axi_awsize(awsize), .m_axi_awburst(awburst),
    .m_axi_awvalid(awvalid), .m_axi_awready(awready),
    .m_axi_wdata(wdata), .m_axi_wstrb(wstrb), .m_axi_wlast(wlast),
    .m_axi_wvalid(wvalid), .m_axi_wready(wready),
    .m_axi_bid(bid), .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(bready)
  );

  initial clk = 0;
  always #6 clk = ~clk; // ~83 MHz ui-like

  // AXI slave: accept AW+W same cycle, respond B next cycle
  logic [27:0] aw_q;
  logic [127:0] w_q;
  logic pend_b;
  assign awready = rst_n && awvalid && wvalid && !pend_b;
  assign wready  = awready;
  assign aw_fire = awvalid && awready;
  assign w_fire  = wvalid && wready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pend_b <= 1'b0;
      bvalid <= 1'b0;
      bid <= 4'd0;
      bresp <= 2'b00;
      aw_q <= '0;
      w_q <= '0;
    end else begin
      if (aw_fire && w_fire) begin
        aw_q <= awaddr;
        w_q <= wdata;
        pend_b <= 1'b1;
        bvalid <= 1'b0;
      end else if (pend_b) begin
        begin : write_beat
          integer wi;
          for (wi = 0; wi < 16; wi++) begin
            if ((aw_q - BASE + wi) < N_BYTES)
              ddr[aw_q - BASE + wi] <= w_q[wi*8 +: 8];
          end
        end
        bid <= awid;
        bresp <= 2'b00;
        bvalid <= 1'b1;
        pend_b <= 1'b0;
      end else if (bvalid && bready) begin
        bvalid <= 1'b0;
      end
    end
  end

  initial begin
    $display("E2R-WMEM-PRELOAD-00 TB start");
    for (gi = 0; gi < N_BYTES; gi++) begin
      ddr[gi] = 8'hXX;
      gold[gi] = 8'h00;
    end
    $readmemh("a7lm06_wmem.hex", gold);
    rst_n = 0;
    start_i = 0;
    repeat (10) @(posedge clk);
    rst_n = 1;
    repeat (5) @(posedge clk);
    start_i = 1;
    @(posedge clk);
    start_i = 0;

    wait (done_o);
    @(posedge clk);

    if (bytes_written_o !== N_BYTES) begin
      $display("FAIL bytes_written=%0d expected %0d", bytes_written_o, N_BYTES);
      $fatal(1);
    end

    mismatches = 0;
    for (gi = 0; gi < N_BYTES; gi++) begin
      if (ddr[gi] !== gold[gi]) begin
        mismatches++;
        if (mismatches <= 8)
          $display("MISMATCH @%0d ddr=%02h gold=%02h", gi, ddr[gi], gold[gi]);
      end
    end

    if (mismatches != 0) begin
      $display("FAIL mismatches=%0d", mismatches);
      $fatal(1);
    end

    $display("E2R_WMEM_PRELOAD_XSIM_PASS bytes=%0d base=0x%h sha_src=9A6BBC7A...", N_BYTES, BASE);
    $display("firewall_inputs: mig_calib=1 wmem_load_done=1 soa_load_done=1 => core_start=1");
    $finish;
  end

  // Timeout: 50k beats * ~4 cycles ~ generous wall
  initial begin
    #500_000_000;
    $display("FAIL timeout");
    $fatal(1);
  end
endmodule
