`timescale 1ns/1ps
import a7eam00_pkg::*;
// 32-D INT8 recurrent mixer. Not a full vocab softmax.
module eam_controller (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 go,
    input  logic                 hit,
    input  logic [127:0]         vec,
    input  logic [7:0]           token,
    output logic [255:0]         state_bits,
    output logic signed [15:0]   energy,
    output logic [7:0]           token_hat
);
    logic signed [7:0] st [0:EAM_CTRL_D-1];
    logic signed [15:0] acc;

    always_comb begin
        int i;
        acc = 16'sd0;
        for (i = 0; i < EAM_VEC_B; i++)
            acc = acc + $signed(st[i]);
        energy = acc;
        for (i = 0; i < EAM_CTRL_D; i++)
            state_bits[8*i +: 8] = st[i];
    end

    always_ff @(posedge clk) begin
        int i;
        if (!rst_n) begin
            for (i = 0; i < EAM_CTRL_D; i++)
                st[i] <= 8'sd0;
            token_hat <= 8'd0;
        end else if (go) begin
            token_hat <= hit ? token : st[0];
            for (i = 0; i < EAM_VEC_B; i++)
                st[i] <= eam_sat8($signed({{8{st[i][7]}}, st[i]})
                                + $signed({{8{vec[8*i+7]}}, vec[8*i +: 8]}));
            for (i = EAM_VEC_B; i < EAM_CTRL_D; i++)
                st[i] <= eam_sat8($signed({{8{st[i][7]}}, st[i]})
                                - $signed({{8{st[i][7]}}, st[i] >>> 2}));
        end
    end
endmodule
