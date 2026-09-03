// Dump C0–C11 via a7ng_gate14_cframe_tx. FPGA-owned payloads. PROGRAM=NO.
`timescale 1ns / 1ps
module a7ng_gate14_cframe_sched (
  input  logic        clk, rst_n,
  input  logic        start_all,
  input  logic        tx_busy,
  output logic        start_tx,
  output logic [7:0]  ckpt,
  output logic [15:0] seq,
  output logic [15:0] len,
  output logic [7:0]  pay [0:47],
  input  logic [63:0] c0_id,
  input  logic [3:0]  c1_mode,
  input  logic [63:0] c2_anch,
  input  logic [63:0] c3_ids,
  input  logic [127:0] c3_sc,
  input  logic [63:0] c4_ev,
  input  logic [31:0] c5_cons,
  input  logic [31:0] c5_rej,
  input  logic [7:0]  c5_ack,
  input  logic [15:0] c6_rsv,
  input  logic        c6_sat,
  input  logic [31:0] c7_addr,
  input  logic [7:0]  c7_ack,
  input  logic [7:0]  c7_err,
  input  logic [31:0] c8_gen,
  input  logic [63:0] c8_sdig,
  input  logic [63:0] c9_ids,
  input  logic [127:0] c9_sc,
  input  logic [63:0] c9_pack,
  input  logic        c9_poison,
  input  logic [31:0] c9_r1s,
  input  logic [7:0]  c9_r1r,
  input  logic [31:0] c9_r1o,
  input  logic        c10_lmst,
  input  logic        c10_lmdn,
  input  logic [9:0]  c10_out,
  input  logic [15:0] c10_x,
  input  logic [63:0] c11_adig,
  input  logic [63:0] c11_bdig,
  input  logic        c11_afor,
  input  logic        c11_bvis
);
  logic run, want, saw_busy;
  logic [3:0] ck;
  logic [15:0] sq;
  integer i;

  assign ckpt = {4'd0, ck};
  assign seq  = sq;

  always_comb begin
    for (i = 0; i < 48; i = i + 1) pay[i] = 8'd0;
    len = 16'd0;
    unique case (ck)
      4'd0: begin
        len = 16'd8;
        pay[0] = c0_id[7:0];  pay[1] = c0_id[15:8];
        pay[2] = c0_id[23:16]; pay[3] = c0_id[31:24];
        pay[4] = c0_id[39:32]; pay[5] = c0_id[47:40];
        pay[6] = c0_id[55:48]; pay[7] = c0_id[63:56];
      end
      4'd1: begin len = 16'd1; pay[0] = {4'd0, c1_mode}; end
      4'd2: begin
        len = 16'd8;
        pay[0] = c2_anch[7:0];  pay[1] = c2_anch[15:8];
        pay[2] = c2_anch[23:16]; pay[3] = c2_anch[31:24];
        pay[4] = c2_anch[39:32]; pay[5] = c2_anch[47:40];
        pay[6] = c2_anch[55:48]; pay[7] = c2_anch[63:56];
      end
      4'd3: begin
        len = 16'd24;
        pay[0] = c3_ids[7:0];   pay[1] = c3_ids[15:8];
        pay[2] = c3_ids[23:16]; pay[3] = c3_ids[31:24];
        pay[4] = c3_ids[39:32]; pay[5] = c3_ids[47:40];
        pay[6] = c3_ids[55:48]; pay[7] = c3_ids[63:56];
        pay[8]  = c3_sc[7:0];    pay[9]  = c3_sc[15:8];
        pay[10] = c3_sc[23:16];  pay[11] = c3_sc[31:24];
        pay[12] = c3_sc[39:32];  pay[13] = c3_sc[47:40];
        pay[14] = c3_sc[55:48];  pay[15] = c3_sc[63:56];
        pay[16] = c3_sc[71:64];  pay[17] = c3_sc[79:72];
        pay[18] = c3_sc[87:80];  pay[19] = c3_sc[95:88];
        pay[20] = c3_sc[103:96]; pay[21] = c3_sc[111:104];
        pay[22] = c3_sc[119:112]; pay[23] = c3_sc[127:120];
      end
      4'd4: begin
        len = 16'd8;
        pay[0] = c4_ev[7:0];  pay[1] = c4_ev[15:8];
        pay[2] = c4_ev[23:16]; pay[3] = c4_ev[31:24];
        pay[4] = c4_ev[39:32]; pay[5] = c4_ev[47:40];
        pay[6] = c4_ev[55:48]; pay[7] = c4_ev[63:56];
      end
      4'd5: begin
        len = 16'd9;
        pay[0] = c5_cons[7:0];  pay[1] = c5_cons[15:8];
        pay[2] = c5_cons[23:16]; pay[3] = c5_cons[31:24];
        pay[4] = c5_rej[7:0];   pay[5] = c5_rej[15:8];
        pay[6] = c5_rej[23:16];  pay[7] = c5_rej[31:24];
        pay[8] = c5_ack;
      end
      4'd6: begin len = 16'd3; pay[0] = c6_rsv[7:0]; pay[1] = c6_rsv[15:8]; pay[2] = {7'd0, c6_sat}; end
      4'd7: begin
        len = 16'd6;
        pay[0] = c7_addr[7:0]; pay[1] = c7_addr[15:8];
        pay[2] = c7_addr[23:16]; pay[3] = c7_addr[31:24];
        pay[4] = c7_ack; pay[5] = c7_err;
      end
      4'd8: begin
        len = 16'd12;
        pay[0] = c8_gen[7:0]; pay[1] = c8_gen[15:8];
        pay[2] = c8_gen[23:16]; pay[3] = c8_gen[31:24];
        pay[4] = c8_sdig[7:0];  pay[5] = c8_sdig[15:8];
        pay[6] = c8_sdig[23:16]; pay[7] = c8_sdig[31:24];
        pay[8] = c8_sdig[39:32]; pay[9] = c8_sdig[47:40];
        pay[10] = c8_sdig[55:48]; pay[11] = c8_sdig[63:56];
      end
      4'd9: begin
        len = 16'd42;
        pay[0] = c9_ids[7:0];   pay[1] = c9_ids[15:8];
        pay[2] = c9_ids[23:16]; pay[3] = c9_ids[31:24];
        pay[4] = c9_ids[39:32]; pay[5] = c9_ids[47:40];
        pay[6] = c9_ids[55:48]; pay[7] = c9_ids[63:56];
        pay[8]  = c9_sc[7:0];    pay[9]  = c9_sc[15:8];
        pay[10] = c9_sc[23:16];  pay[11] = c9_sc[31:24];
        pay[12] = c9_sc[39:32];  pay[13] = c9_sc[47:40];
        pay[14] = c9_sc[55:48];  pay[15] = c9_sc[63:56];
        pay[16] = c9_sc[71:64];  pay[17] = c9_sc[79:72];
        pay[18] = c9_sc[87:80];  pay[19] = c9_sc[95:88];
        pay[20] = c9_sc[103:96]; pay[21] = c9_sc[111:104];
        pay[22] = c9_sc[119:112]; pay[23] = c9_sc[127:120];
        pay[24] = c9_pack[7:0];  pay[25] = c9_pack[15:8];
        pay[26] = c9_pack[23:16]; pay[27] = c9_pack[31:24];
        pay[28] = c9_pack[39:32]; pay[29] = c9_pack[47:40];
        pay[30] = c9_pack[55:48]; pay[31] = c9_pack[63:56];
        pay[32] = {7'd0, c9_poison};
        pay[33] = c9_r1s[7:0]; pay[34] = c9_r1s[15:8];
        pay[35] = c9_r1s[23:16]; pay[36] = c9_r1s[31:24];
        pay[37] = c9_r1r;
        pay[38] = c9_r1o[7:0]; pay[39] = c9_r1o[15:8];
        pay[40] = c9_r1o[23:16]; pay[41] = c9_r1o[31:24];
      end
      4'd10: begin
        len = 16'd6;
        pay[0] = {7'd0, c10_lmst};
        pay[1] = {7'd0, c10_lmdn};
        pay[2] = c10_out[7:0];
        pay[3] = {6'd0, c10_out[9:8]};
        pay[4] = c10_x[7:0];
        pay[5] = c10_x[15:8];
      end
      default: begin
        len = 16'd18;
        pay[0] = c11_adig[7:0];  pay[1] = c11_adig[15:8];
        pay[2] = c11_adig[23:16]; pay[3] = c11_adig[31:24];
        pay[4] = c11_adig[39:32]; pay[5] = c11_adig[47:40];
        pay[6] = c11_adig[55:48]; pay[7] = c11_adig[63:56];
        pay[8]  = c11_bdig[7:0];  pay[9]  = c11_bdig[15:8];
        pay[10] = c11_bdig[23:16]; pay[11] = c11_bdig[31:24];
        pay[12] = c11_bdig[39:32]; pay[13] = c11_bdig[47:40];
        pay[14] = c11_bdig[55:48]; pay[15] = c11_bdig[63:56];
        pay[16] = {7'd0, c11_afor};
        pay[17] = {7'd0, c11_bvis};
      end
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      run <= 0; want <= 0; saw_busy <= 0; ck <= 0; sq <= 0; start_tx <= 0;
    end else begin
      start_tx <= 1'b0;
      if (!run && start_all) begin
        run <= 1'b1; ck <= 4'd0; want <= 1'b1; saw_busy <= 1'b0;
      end else if (run) begin
        if (tx_busy) saw_busy <= 1'b1;
        if (want && !tx_busy) begin
          start_tx <= 1'b1; want <= 1'b0; saw_busy <= 1'b0;
          sq <= sq + 16'd1;
        end else if (!want && !start_tx && saw_busy && !tx_busy) begin
          if (ck == 4'd11) run <= 1'b0;
          else begin ck <= ck + 4'd1; want <= 1'b1; saw_busy <= 1'b0; end
        end
      end
    end
  end
endmodule
