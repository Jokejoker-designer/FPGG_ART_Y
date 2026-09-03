// a7ng_context_delta.sv — a7ng-learn-ctx-v1 G2 delta (UNIT/OOC only; SoC instantiate ABSENT)
// After legal G1 CONSUME, before WM coalesce. FPGA-owned sat16 delta.
// Host may not write delta / index / winner / address. No DSP multiply.
// Law: prod = signed32(reward) x signed32({1'b0,native_conf}); delta = sat16(prod ASR 8)
`timescale 1ns / 1ps

module a7ng_context_delta #(
  parameter int unsigned TXN_W = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  // G1 consume ready/valid. TB models FPGA G1 output, not host authority.
  input  logic         in_valid,
  output logic         in_ready,
  input  logic signed [3:0] in_reward,
  input  logic [15:0]  in_native_conf,
  input  logic [31:0]  in_subj,
  input  logic [7:0]   in_rel,
  input  logic [31:0]  in_obj,
  input  logic [15:0]  in_q_epoch,
  input  logic [15:0]  in_p_epoch,
  input  logic         in_contradict,
  input  logic [TXN_W-1:0] in_txn,
  output logic         out_valid,
  input  logic         out_ready,
  output logic signed [15:0] delta_o,
  output logic         sat_flag_o,
  output logic signed [3:0] out_reward,
  output logic [15:0]  out_native_conf,
  output logic [31:0]  out_subj,
  output logic [7:0]   out_rel,
  output logic [31:0]  out_obj,
  output logic [15:0]  out_q_epoch,
  output logic [15:0]  out_p_epoch,
  output logic         out_contradict,
  output logic [TXN_W-1:0] out_txn
);
  // 1-deep hold. Accept only on in_valid && in_ready. Hold until out_valid && out_ready.
  assign in_ready = !out_valid || out_ready;

  // Fabric shift-add for reward in {-3..+3}. Do not infer DSP.
  // G0 names signed32 as the mathematical intermediate; legal prod is
  // [-196605,+196605] so 19-bit two's-complement is bit-exact.
  localparam int unsigned PROD_W = 19;

  function automatic logic signed [PROD_W-1:0] ctx_prod(
      input logic signed [3:0] reward,
      input logic [15:0] conf
  );
    logic signed [PROD_W-1:0] c19, x2, x3;
    c19 = $signed({3'b0, conf});
    x2  = {c19[PROD_W-2:0], 1'b0};
    x3  = x2 + c19;
    case (reward)
      4'sd0:   ctx_prod = '0;
      4'sd1:   ctx_prod = c19;
      4'sd2:   ctx_prod = x2;
      4'sd3:   ctx_prod = x3;
      -4'sd1:  ctx_prod = -c19;
      -4'sd2:  ctx_prod = -x2;
      -4'sd3:  ctx_prod = -x3;
      default: ctx_prod = '0;
    endcase
  endfunction

  function automatic logic signed [15:0] sat16(input logic signed [PROD_W-1:0] x);
    if (x > 19'sd32767)
      sat16 = 16'sd32767;
    else if (x < -19'sd32768)
      sat16 = -16'sd32768;
    else
      sat16 = x[15:0];
  endfunction

  wire signed [PROD_W-1:0] prod_w    = ctx_prod(in_reward, in_native_conf);
  wire signed [PROD_W-1:0] shifted_w = prod_w >>> 8;
  wire signed [15:0]       delta_w   = sat16(shifted_w);
  wire                     sat_w     = (shifted_w > 19'sd32767) || (shifted_w < -19'sd32768);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid        <= 1'b0;
      delta_o          <= 16'sd0;
      sat_flag_o       <= 1'b0;
      out_reward       <= 4'sd0;
      out_native_conf  <= 16'd0;
      out_subj         <= 32'd0;
      out_rel          <= 8'd0;
      out_obj          <= 32'd0;
      out_q_epoch      <= 16'd0;
      out_p_epoch      <= 16'd0;
      out_contradict   <= 1'b0;
      out_txn          <= '0;
    end else if (in_valid && in_ready) begin
      out_valid        <= 1'b1;
      delta_o          <= delta_w;
      sat_flag_o       <= sat_w;
      out_reward       <= in_reward;
      out_native_conf  <= in_native_conf;
      out_subj         <= in_subj;
      out_rel          <= in_rel;
      out_obj          <= in_obj;
      out_q_epoch      <= in_q_epoch;
      out_p_epoch      <= in_p_epoch;
      out_contradict   <= in_contradict;
      out_txn          <= in_txn;
    end else if (out_valid && out_ready) begin
      out_valid <= 1'b0;
    end
  end
endmodule
