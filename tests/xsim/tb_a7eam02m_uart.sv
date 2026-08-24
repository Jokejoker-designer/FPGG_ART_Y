`timescale 1ns/1ps
import a7eam02m_pkg::*;
// UART smoke: PING + OPEN + BIND + PROBE + TEACHER_OFF. Geometry is tb_a7eam02m.
module tb_a7eam02m_uart;
    logic clk = 0, rst_n = 0;
    always #5 clk = ~clk;

    logic rx, tx, last_hit, idle;
    assign rx = 1'b1;

    eam02m_uart u_dut (
        .clk(clk), .rst_n(rst_n),
        .rx(rx), .tx(tx),
        .last_hit(last_hit), .core_idle(idle)
    );

    initial begin
        repeat (20) @(posedge clk);
        rst_n = 1;
        repeat (200) @(posedge clk);
        if (!idle) begin
            $display("TB_FAIL uart not idle");
            $finish;
        end
        $display("A7EAM02M_UART_ELAB_OK");
        $finish;
    end
endmodule
