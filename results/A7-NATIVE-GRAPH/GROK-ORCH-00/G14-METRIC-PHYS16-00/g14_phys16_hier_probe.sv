// Bind probe into a7ng_cue_soa_mig_top. NO RTL EDIT.
`timescale 1ps / 100fs

module g14_phys16_hier_probe #(parameter int PHYS = 16) (
  input logic        clk,
  input logic        rst_n,
  input logic        running,
  input logic        done,
  input logic [PHYS-1:0] tg_valid_in,
  input logic [31:0] empty_st,
  input logic [31:0] axi_bytes,
  input logic [31:0] rbp,
  input logic [31:0] delivered
);
  integer elig, act, fire;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      elig <= 0; act <= 0; fire <= 0;
    end else if (running) begin
      elig <= elig + 1;
      if (|tg_valid_in) fire <= fire + 1;
      act <= act + $countones(tg_valid_in);
    end
  end

  always @(posedge done) begin
    if (rst_n) begin
      $display("PHYS16_MIG_HIER empty_stall=%0d r_backpressure=%0d axi_read_bytes=%0d delivered=%0d",
               empty_st, rbp, axi_bytes, delivered);
      $display("PHYS16_MIG_LANE_ACT_SUM=%0d ELIG=%0d FIRE=%0d PHYS=%0d", act, elig, fire, PHYS);
      if (elig > 0)
        $display("PHYS16_MIG_LANE_UTIL=%0.6f STALL_FRAC=%0.6f",
                 real'(act) / (real'(PHYS) * real'(elig)),
                 real'(empty_st) / real'(elig));
    end
  end
endmodule

bind a7ng_cue_soa_mig_top g14_phys16_hier_probe #(.PHYS(16)) u_g14_phys16 (
  .clk(clk),
  .rst_n(rst_n),
  .running(running_o),
  .done(done_o),
  .tg_valid_in(tg_valid_in),
  .empty_st(buffer_empty_stall_o),
  .axi_bytes(axi_read_bytes_o),
  .rbp(r_backpressure_cycles_o),
  .delivered(cand_delivered_o)
);
