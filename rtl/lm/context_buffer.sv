`timescale 1ns/1ps
// Last-8 token window. Positions are 0..n-1 of the window.
module context_buffer (
    input  logic clk,
    input  logic rst_n,
    input  logic load,
    input  logic [3:0] load_n,
    input  logic [4:0] load_tok [0:7],
    input  logic append,
    input  logic [4:0] append_tok,
    output logic [3:0] n,
    output logic [4:0] tok [0:7]
);
    integer k;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            n <= 4'd0;
            for (k = 0; k < 8; k = k + 1)
                tok[k] <= 5'd0;
        end else if (load) begin
            n <= (load_n > 4'd8) ? 4'd8 : load_n;
            for (k = 0; k < 8; k = k + 1)
                tok[k] <= load_tok[k];
        end else if (append) begin
            if (n < 4'd8) begin
                tok[n] <= append_tok;
                n <= n + 4'd1;
            end else begin
                for (k = 0; k < 7; k = k + 1)
                    tok[k] <= tok[k + 1];
                tok[7] <= append_tok;
                n <= 4'd8;
            end
        end
    end
endmodule
