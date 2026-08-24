`timescale 1ns/1ps
// A5 70 write / 71 ctx / 72 cmd. Bank is 4-bit, addr 12-bit.
module lm05_link (
    input  logic clk,
    input  logic rst_n,
    input  logic rx_valid,
    input  logic [7:0] rx_data,
    output logic wr_en,
    output logic [3:0] wr_bank,
    output logic [11:0] wr_addr,
    output logic signed [7:0] wr_data,
    output logic ctx_load,
    output logic [3:0] ctx_n,
    output logic [4:0] ctx_tok [0:7],
    output logic cmd_fwd,
    output logic cmd_dumpz,
    output logic cmd_dumph,
    output logic cmd_dumpa,
    output logic cmd_read,
    output logic cmd_train,
    output logic cmd_dumpg,
    output logic cmd_dumpc,
    output logic cmd_snap,
    output logic cmd_restore,
    output logic cmd_after,
    output logic after_lvl,
    output logic [4:0] trn_tgt,
    output logic [3:0] trn_lr,
    output logic [3:0] rd_bank,
    output logic [11:0] rd_addr
);
    logic collecting;
    logic [3:0] idx;
    logic [7:0] buf_b [0:13];
    logic [7:0] running_xor;
    logic [3:0] wr_left;
    logic [3:0] wr_i;
    logic [11:0] wr_ptr;
    integer i;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            collecting <= 1'b0;
            idx <= 4'd0;
            running_xor <= 8'd0;
            wr_en <= 1'b0;
            wr_bank <= 4'd0;
            wr_addr <= 12'd0;
            wr_data <= 8'sd0;
            ctx_load <= 1'b0;
            ctx_n <= 4'd0;
            cmd_fwd <= 1'b0;
            cmd_dumpz <= 1'b0;
            cmd_dumph <= 1'b0;
            cmd_dumpa <= 1'b0;
            cmd_read <= 1'b0;
            cmd_train <= 1'b0;
            cmd_dumpg <= 1'b0;
            cmd_dumpc <= 1'b0;
            cmd_snap <= 1'b0;
            cmd_restore <= 1'b0;
            cmd_after <= 1'b0;
            after_lvl <= 1'b0;
            trn_tgt <= 5'd0;
            trn_lr <= 4'd8;
            rd_bank <= 4'd0;
            rd_addr <= 12'd0;
            wr_left <= 4'd0;
            wr_i <= 4'd0;
            wr_ptr <= 12'd0;
            for (i = 0; i < 8; i = i + 1)
                ctx_tok[i] <= 5'd0;
            for (i = 0; i < 14; i = i + 1)
                buf_b[i] <= 8'd0;
        end else begin
            wr_en <= 1'b0;
            ctx_load <= 1'b0;
            cmd_fwd <= 1'b0;
            cmd_dumpz <= 1'b0;
            cmd_dumph <= 1'b0;
            cmd_dumpa <= 1'b0;
            cmd_read <= 1'b0;
            cmd_train <= 1'b0;
            cmd_dumpg <= 1'b0;
            cmd_dumpc <= 1'b0;
            cmd_snap <= 1'b0;
            cmd_restore <= 1'b0;
            cmd_after <= 1'b0;
            if (wr_left != 4'd0) begin
                wr_en <= 1'b1;
                wr_addr <= wr_ptr;
                wr_data <= $signed(buf_b[6 + wr_i]);
                wr_ptr <= wr_ptr + 12'd1;
                wr_i <= wr_i + 4'd1;
                wr_left <= wr_left - 4'd1;
            end else if (rx_valid) begin
                if (!collecting) begin
                    if (rx_data == 8'hA5) begin
                        collecting <= 1'b1;
                        idx <= 4'd1;
                        buf_b[0] <= 8'hA5;
                        running_xor <= 8'hA5;
                    end
                end else if (idx < 4'd14) begin
                    buf_b[idx] <= rx_data;
                    running_xor <= running_xor ^ rx_data;
                    idx <= idx + 4'd1;
                end else begin
                    collecting <= 1'b0;
                    idx <= 4'd0;
                    if (rx_data == running_xor) begin
                        if (buf_b[1] == 8'h70) begin
                            wr_bank <= buf_b[2][3:0];
                            wr_ptr <= {buf_b[4][3:0], buf_b[3]};
                            wr_i <= 4'd0;
                            wr_left <= (buf_b[5] == 8'd0 || buf_b[5] > 8'd8) ? 4'd8 : buf_b[5][3:0];
                        end else if (buf_b[1] == 8'h71) begin
                            ctx_n <= buf_b[2][3:0];
                            ctx_tok[0] <= buf_b[3][4:0];
                            ctx_tok[1] <= buf_b[4][4:0];
                            ctx_tok[2] <= buf_b[5][4:0];
                            ctx_tok[3] <= buf_b[6][4:0];
                            ctx_tok[4] <= buf_b[7][4:0];
                            ctx_tok[5] <= buf_b[8][4:0];
                            ctx_tok[6] <= buf_b[9][4:0];
                            ctx_tok[7] <= buf_b[10][4:0];
                            ctx_load <= 1'b1;
                        end else if (buf_b[1] == 8'h72) begin
                            if (buf_b[2] == 8'd1) cmd_fwd <= 1'b1;
                            else if (buf_b[2] == 8'd3) cmd_dumpz <= 1'b1;
                            else if (buf_b[2] == 8'd4) begin
                                cmd_read <= 1'b1;
                                rd_bank <= buf_b[3][3:0];
                                rd_addr <= {buf_b[5][3:0], buf_b[4]};
                            end else if (buf_b[2] == 8'd5) cmd_dumph <= 1'b1;
                            else if (buf_b[2] == 8'd6) cmd_dumpa <= 1'b1;
                            else if (buf_b[2] == 8'd7) begin
                                cmd_train <= 1'b1;
                                trn_tgt <= buf_b[3][4:0];
                                trn_lr <= (buf_b[4][3:0] == 4'd0) ? 4'd8 : buf_b[4][3:0];
                            end else if (buf_b[2] == 8'd8) cmd_dumpg <= 1'b1;
                            else if (buf_b[2] == 8'd9) cmd_dumpc <= 1'b1;
                            else if (buf_b[2] == 8'd10) cmd_snap <= 1'b1;
                            else if (buf_b[2] == 8'd11) cmd_restore <= 1'b1;
                            else if (buf_b[2] == 8'd12) begin
                                cmd_after <= 1'b1;
                                after_lvl <= buf_b[3][0];
                            end
                        end
                    end
                end
            end
        end
    end
endmodule
