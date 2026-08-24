`timescale 1ns/1ps
module uart_rx #(
    parameter int CLK_HZ = 8000000,
    parameter int BAUD = 115200
) (
    input  logic clk,
    input  logic rst_n,
    input  logic rx,
    output logic [7:0] data,
    output logic valid
);
    localparam int CLKS_PER_BIT = (CLK_HZ + BAUD/2) / BAUD;
    localparam int HALF = CLKS_PER_BIT / 2;
    localparam int CW = $clog2(CLKS_PER_BIT + 1);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;
    logic [CW-1:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] shift;
    logic rx_sync0, rx_sync1;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rx_sync0 <= 1'b1;
            rx_sync1 <= 1'b1;
        end else begin
            rx_sync0 <= rx;
            rx_sync1 <= rx_sync0;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            clk_count <= '0;
            bit_index <= '0;
            shift <= '0;
            data <= '0;
            valid <= 1'b0;
        end else begin
            valid <= 1'b0;
            case (state)
                IDLE: if (!rx_sync1) begin
                    state <= START;
                    clk_count <= '0;
                end
                START: begin
                    if (clk_count == HALF[CW-1:0]) begin
                        clk_count <= '0;
                        if (!rx_sync1) begin
                            state <= DATA;
                            bit_index <= '0;
                        end else state <= IDLE;
                    end else clk_count <= clk_count + 1'b1;
                end
                DATA: begin
                    if (clk_count == CLKS_PER_BIT[CW-1:0] - 1) begin
                        clk_count <= '0;
                        shift[bit_index] <= rx_sync1;
                        if (bit_index == 3'd7) state <= STOP;
                        else bit_index <= bit_index + 1'b1;
                    end else clk_count <= clk_count + 1'b1;
                end
                STOP: begin
                    if (clk_count == CLKS_PER_BIT[CW-1:0] - 1) begin
                        data <= shift;
                        valid <= 1'b1;
                        state <= IDLE;
                        clk_count <= '0;
                    end else clk_count <= clk_count + 1'b1;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
