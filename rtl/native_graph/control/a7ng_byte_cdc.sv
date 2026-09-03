// 1-byte req/ack CDC. PROGRAM=NO.
`timescale 1ns / 1ps
module a7ng_byte_cdc (
  input  logic       src_clk, src_rst_n,
  input  logic [7:0] src_data,
  input  logic       src_valid,
  input  logic       dst_clk, dst_rst_n,
  output logic [7:0] dst_data,
  output logic       dst_valid,
  output logic       src_ready,
  input  logic       dst_ready
);
  logic req, ack, pend;
  assign src_ready = ~pend;
  logic [7:0] hold;
  (* ASYNC_REG = "TRUE" *) logic a0, a1, a2;
  (* ASYNC_REG = "TRUE" *) logic r0, r1, r2;
  logic rseen;

  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      req <= 1'b0; pend <= 1'b0; hold <= '0;
      a0 <= 1'b0; a1 <= 1'b0; a2 <= 1'b0;
    end else begin
      a0 <= ack; a1 <= a0; a2 <= a1;
      if (!pend && src_valid) begin
        hold <= src_data; req <= ~req; pend <= 1'b1;
      end else if (pend && (a2 == req))
        pend <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      r0 <= 1'b0; r1 <= 1'b0; r2 <= 1'b0; rseen <= 1'b0;
      ack <= 1'b0; dst_data <= '0; dst_valid <= 1'b0;
    end else begin
      r0 <= req; r1 <= r0; r2 <= r1;
      dst_valid <= 1'b0;
      if (r2 != rseen && dst_ready) begin
        rseen <= r2;
        dst_data <= hold;
        dst_valid <= 1'b1;
        ack <= ~ack;
      end
    end
  end
endmodule
