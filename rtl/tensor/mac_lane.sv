`timescale 1ns/1ps
// One INT16 x INT8 -> INT48 accumulate. Maps to DSP48E1.
module mac_lane (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               clr,
    input  logic               en,
    input  logic signed [15:0] a,
    input  logic signed [7:0]  b,
    output logic signed [47:0] acc
);
    logic signed [24:0] a_ext;
    logic signed [17:0] b_ext;
    assign a_ext = {{9{a[15]}}, a};
    assign b_ext = {{10{b[7]}}, b};

    (* use_dsp = "yes" *) logic signed [47:0] acc_r;
    always_ff @(posedge clk) begin
        if (!rst_n || clr) acc_r <= 48'sd0;
        else if (en) acc_r <= acc_r + a_ext * b_ext;
    end
    assign acc = acc_r;
endmodule
