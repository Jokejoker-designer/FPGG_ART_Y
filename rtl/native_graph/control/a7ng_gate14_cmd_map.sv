// Map legal UART TYPE → glue cmd. FPGA owns MODE. PROGRAM=NO.
`timescale 1ns / 1ps
module a7ng_gate14_cmd_map (
  input  logic        clk, rst_n,
  input  logic        in_v,
  output logic        in_r,
  input  logic [7:0]  typ,
  input  logic [7:0]  tok,
  input  logic signed [3:0] rew,
  input  logic [15:0] echo,
  input  logic [15:0] fpga_txn,
  output logic        out_v,
  input  logic        out_r,
  output logic [3:0]  cmd,
  output logic [7:0]  tok_o,
  output logic signed [3:0] rew_o,
  output logic        snap_v,
  output logic        rew_mismatch
);
  localparam logic [3:0] C_TOK=4'd1, C_FIRE=4'd2, C_REW=4'd3, C_FLUSH=4'd4,
                         C_KILL=4'd5, C_RELOAD=4'd6, C_FREEZE=4'd7,
                         C_TRESET=4'd8, C_TRAIN=4'd9;
  logic busy, fire2;
  logic [3:0] c_hold;
  logic [7:0] t_hold;
  logic signed [3:0] r_hold;

  assign in_r = !busy && !out_v;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_v <= 0; cmd <= 0; tok_o <= 0; rew_o <= 0;
      snap_v <= 0; rew_mismatch <= 0; busy <= 0; fire2 <= 0;
      c_hold <= 0; t_hold <= 0; r_hold <= 0;
    end else begin
      snap_v <= 1'b0; rew_mismatch <= 1'b0;
      if (out_v && out_r) begin
        if (fire2) begin
          cmd <= C_FIRE; tok_o <= 8'd0; rew_o <= 4'sd0;
          fire2 <= 1'b0; busy <= 1'b0;
        end else begin
          out_v <= 1'b0; busy <= 1'b0;
        end
      end else if (!out_v && in_v && in_r) begin
        unique case (typ)
          8'h01, 8'h0A: begin cmd <= C_TRESET; tok_o <= 0; rew_o <= 0; out_v <= 1; busy <= 1; end
          8'h02: begin cmd <= C_TRAIN; tok_o <= 0; rew_o <= 0; out_v <= 1; busy <= 1; end
          8'h03: begin cmd <= C_TOK; tok_o <= tok; rew_o <= 0; out_v <= 1; busy <= 1; end
          8'h04: begin cmd <= C_FIRE; tok_o <= 0; rew_o <= 0; out_v <= 1; busy <= 1; end
          8'h05: begin
            if (echo != fpga_txn) rew_mismatch <= 1'b1;
            else begin cmd <= C_REW; tok_o <= 0; rew_o <= rew; out_v <= 1; busy <= 1; end
          end
          8'h06: begin cmd <= C_FLUSH; tok_o <= 0; rew_o <= 0; out_v <= 1; busy <= 1; end
          8'h07: begin cmd <= C_KILL; tok_o <= 0; rew_o <= 0; out_v <= 1; busy <= 1; end
          8'h08: begin cmd <= C_RELOAD; tok_o <= 0; rew_o <= 0; out_v <= 1; busy <= 1; end
          8'h09: begin cmd <= C_FREEZE; tok_o <= 0; rew_o <= 0; out_v <= 1; busy <= 1; end
          8'h0B, 8'h0D: snap_v <= 1'b1;
          8'h0C: begin
            cmd <= C_TOK; tok_o <= tok; rew_o <= 0; out_v <= 1; busy <= 1; fire2 <= 1;
          end
          default: ;
        endcase
      end
    end
  end
endmodule
