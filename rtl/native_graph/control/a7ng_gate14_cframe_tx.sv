// Serialize one CFRAME. Byte-at-a-time CRC. PROGRAM=NO.
`timescale 1ns / 1ps
module a7ng_gate14_cframe_tx (
  input  logic        clk, rst_n,
  input  logic        start,
  input  logic [7:0]  ckpt,
  input  logic [15:0] seq,
  input  logic [7:0]  pay [0:47],
  input  logic [15:0] len,
  output logic [7:0]  byte_o,
  output logic        byte_v,
  input  logic        byte_r,
  output logic        busy
);
  `include "a7ng_gate14_crc.svh"
  logic [15:0] crc, i;
  logic [3:0] ph;
  // ph: 0 SOF0 1 SOF1 2 VER 3 CKPT 4 SQ0 5 SQ1 6 LN0 7 LN1 8 PAY 9 CR0 10 CR1
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ph <= 0; i <= 0; crc <= 16'hFFFF; byte_o <= 0; byte_v <= 0; busy <= 0;
    end else begin
      if (!busy) begin
        byte_v <= 1'b0;
        if (start) begin
          busy <= 1'b1; ph <= 0; i <= 0; crc <= 16'hFFFF;
          byte_o <= 8'hC1; byte_v <= 1'b1;
        end
      end else if (byte_v && byte_r) begin
        unique case (ph)
          0: begin byte_o <= 8'h11; ph <= 1; end
          1: begin byte_o <= 8'h01; crc <= crc16_byte(16'hFFFF, 8'h01); ph <= 2; end
          2: begin byte_o <= ckpt; crc <= crc16_byte(crc, ckpt); ph <= 3; end
          3: begin byte_o <= seq[7:0]; crc <= crc16_byte(crc, seq[7:0]); ph <= 4; end
          4: begin byte_o <= seq[15:8]; crc <= crc16_byte(crc, seq[15:8]); ph <= 5; end
          5: begin byte_o <= len[7:0]; crc <= crc16_byte(crc, len[7:0]); ph <= 6; end
          6: begin byte_o <= len[15:8]; crc <= crc16_byte(crc, len[15:8]);
                   ph <= (len == 0) ? 4'd9 : 4'd8; i <= 0; end
          8: begin
            byte_o <= pay[i[5:0]];
            crc <= crc16_byte(crc, pay[i[5:0]]);
            if (i + 16'd1 >= len) ph <= 9;
            else i <= i + 16'd1;
          end
          9: begin byte_o <= crc[7:0]; ph <= 10; end
          10: begin byte_o <= crc[15:8]; ph <= 11; end
          11: begin byte_v <= 1'b0; busy <= 1'b0; ph <= 0; end
          default: begin busy <= 0; byte_v <= 0; end
        endcase
      end
    end
  end
endmodule
