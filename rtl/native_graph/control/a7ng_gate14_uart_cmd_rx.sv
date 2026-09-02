// Binary Gate14 command decoder + 1-entry queue. core_clk domain bytes in.
// PROGRAM=NO.
`timescale 1ns / 1ps
module a7ng_gate14_uart_cmd_rx (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [7:0]  byte_i,
  input  logic        byte_v_i,
  output logic        cmd_valid_o,
  input  logic        cmd_ready_i,
  output logic [7:0]  cmd_type_o,
  output logic [15:0] cmd_seq_o,
  output logic [7:0]  tok_o,
  output logic signed [3:0] rew_o,
  output logic [15:0] echo_o,
  output logic [7:0]  rj_ver, rj_len, rj_crc, rj_typ, rj_dup, rj_busy
);
  `include "a7ng_gate14_crc.svh"
  typedef enum logic [3:0] {
    H0, H1, VER, TYP, SQ0, SQ1, LN0, LN1, PAY, CR0, CR1
  } st_t;
  st_t st;
  logic [7:0] typ, pay [0:7];
  logic [15:0] seq, crc, gotcrc;
  logic [15:0] len, pi;
  logic [15:0] last_seq;
  logic last_v, qv;
  logic [19:0] gap;
  logic [7:0] qtyp, qtok;
  logic signed [3:0] qrew;
  logic [15:0] qseq, qecho;

  function automatic logic legal(input logic [7:0] t);
    legal = (t >= 8'h01) && (t <= 8'h0D);
  endfunction

  assign cmd_valid_o = qv;
  assign cmd_type_o  = qtyp;
  assign cmd_seq_o   = qseq;
  assign tok_o       = qtok;
  assign rew_o       = qrew;
  assign echo_o      = qecho;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= H0; typ <= 0; seq <= 0; len <= 0; pi <= 0; crc <= 16'hFFFF;
      gotcrc <= 0; last_seq <= 0; last_v <= 0; qv <= 0;
      qtyp <= 0; qtok <= 0; qrew <= 0; qseq <= 0; qecho <= 0;
      rj_ver <= 0; rj_len <= 0; rj_crc <= 0; rj_typ <= 0; rj_dup <= 0; rj_busy <= 0;
      gap <= 0;
      pay[0] <= 0; pay[1] <= 0; pay[2] <= 0; pay[3] <= 0;
      pay[4] <= 0; pay[5] <= 0; pay[6] <= 0; pay[7] <= 0;
    end else begin
      if (qv && cmd_ready_i) qv <= 1'b0;
      if (!byte_v_i && st != H0) begin
        if (gap == 20'hFFFFF) st <= H0;
        else gap <= gap + 20'd1;
      end
      if (byte_v_i) begin
        gap <= 20'd0;
        unique case (st)
          H0: begin
            if (byte_i == 8'hA7) st <= H1;
            else st <= H0;
          end
          H1: begin
            if (byte_i == 8'h14) begin st <= VER; crc <= 16'hFFFF; end
            else if (byte_i == 8'hA7) st <= H1;
            else st <= H0;
          end
          VER: begin
            crc <= crc16_byte(16'hFFFF, byte_i);
            if (byte_i != 8'h01) begin
              if (rj_ver != 8'hFF) rj_ver <= rj_ver + 8'd1;
              st <= H0;
            end else st <= TYP;
          end
          TYP: begin
            crc <= crc16_byte(crc, byte_i); typ <= byte_i; st <= SQ0;
          end
          SQ0: begin crc <= crc16_byte(crc, byte_i); seq[7:0] <= byte_i; st <= SQ1; end
          SQ1: begin crc <= crc16_byte(crc, byte_i); seq[15:8] <= byte_i; st <= LN0; end
          LN0: begin crc <= crc16_byte(crc, byte_i); len[7:0] <= byte_i; st <= LN1; end
          LN1: begin
            crc <= crc16_byte(crc, byte_i);
            len[15:8] <= byte_i;
            if ({byte_i, len[7:0]} > 16'd8) begin
              if (rj_len != 8'hFF) rj_len <= rj_len + 8'd1;
              st <= H0;
            end else if ({byte_i, len[7:0]} == 16'd0) st <= CR0;
            else begin pi <= 16'd0; st <= PAY; end
          end
          PAY: begin
            crc <= crc16_byte(crc, byte_i);
            if (pi < 16'd8) pay[pi[2:0]] <= byte_i;
            if (pi + 16'd1 >= len) st <= CR0;
            else pi <= pi + 16'd1;
          end
          CR0: begin gotcrc[7:0] <= byte_i; st <= CR1; end
          CR1: begin
            st <= H0;
            if ({byte_i, gotcrc[7:0]} != crc) begin
              if (rj_crc != 8'hFF) rj_crc <= rj_crc + 8'd1;
            end else if (!legal(typ)) begin
              if (rj_typ != 8'hFF) rj_typ <= rj_typ + 8'd1;
            end else if (last_v && seq == last_seq) begin
              if (rj_dup != 8'hFF) rj_dup <= rj_dup + 8'd1;
            end else if (qv && !cmd_ready_i) begin
              if (rj_busy != 8'hFF) rj_busy <= rj_busy + 8'd1;
            end else begin
              qv <= 1'b1; qtyp <= typ; qseq <= seq;
              qtok <= pay[0];
              qrew <= pay[0][3:0];
              qecho <= {pay[2], pay[1]};
              last_seq <= seq; last_v <= 1'b1;
            end
          end
          default: st <= H0;
        endcase
      end
    end
  end
endmodule
