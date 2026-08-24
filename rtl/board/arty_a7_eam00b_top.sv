`timescale 1ns/1ps
// A7-EAM-00B board wrap. 100 MHz EAM + UART 115200. No MIG. No LM bits.
module arty_a7_eam00b_top (
    input  logic       CLK100MHZ,
    input  logic [3:0] sw,
    input  logic [3:0] btn,
    output logic [3:0] led,
    output logic       uart_rxd_out,
    input  logic       uart_txd_in
);
    logic rst_n, btn0_s, last_hit, idle;
    logic [19:0] por;
    logic [23:0] hb;

    sync_bits #(.WIDTH(1)) u_bsync (
        .clk(CLK100MHZ), .rst_n(1'b1), .async_in(btn[0]), .sync_out(btn0_s)
    );

    always_ff @(posedge CLK100MHZ) begin
        if (btn0_s)
            por <= 20'd0;
        else if (!por[19])
            por <= por + 20'd1;
        hb <= hb + 24'd1;
    end
    assign rst_n = por[19] && !btn0_s;

    eam00b_uart u_link (
        .clk(CLK100MHZ), .rst_n(rst_n),
        .rx(uart_txd_in), .tx(uart_rxd_out),
        .last_hit(last_hit), .core_idle(idle)
    );

    assign led[0] = idle;
    assign led[1] = last_hit;
    assign led[2] = ~rst_n;
    assign led[3] = hb[23];
    wire unused = |sw | |btn[3:1];
endmodule
