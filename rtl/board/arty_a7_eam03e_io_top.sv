`timescale 1ns/1ps
// A7-EAM-03E-UI board top. Same core and same law as arty_a7_eam03e_top, plus
// SW/BTN readback over CMD 0x2F so the studio UI can mirror the physical board.
// UI SUPPORT BIT — NOT EVIDENCE. Writes build/out/arty_a7_eam03e_io.bit and never
// touches arty_a7_eam03e.bit or any frozen LM bit.
module arty_a7_eam03e_io_top (
    input  logic       CLK100MHZ,
    input  logic [3:0] sw,
    input  logic [3:0] btn,
    output logic [3:0] led,
    output logic       uart_rxd_out,
    input  logic       uart_txd_in
);
    logic rst_n, btn0_s, last_upd, idle;
    logic [3:0] sw_s, btn_s;
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

    // Two-FF synchronisers only; there is no debounce module in this repo. A
    // mechanical bounce therefore shows up as several sticky edges, which is why
    // the UI treats a button as a one-shot request and not as a counter.
    sync_bits #(.WIDTH(4)) u_sw  (
        .clk(CLK100MHZ), .rst_n(rst_n), .async_in(sw), .sync_out(sw_s)
    );
    sync_bits #(.WIDTH(4)) u_btn (
        .clk(CLK100MHZ), .rst_n(rst_n), .async_in(btn), .sync_out(btn_s)
    );

    eam03e_io_uart u_link (
        .clk(CLK100MHZ), .rst_n(rst_n),
        .rx(uart_txd_in), .tx(uart_rxd_out),
        .sw_s(sw_s), .btn_s(btn_s), .led_in(led),
        .last_upd(last_upd), .core_idle(idle)
    );

    assign led[0] = idle;
    assign led[1] = last_upd;
    assign led[2] = ~rst_n;
    assign led[3] = hb[23];
endmodule
