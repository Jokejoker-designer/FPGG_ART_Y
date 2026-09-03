// UART RX on 100 MHz (same clock as SoC TX). 115200 8N1.
// Stop-bit check, framing/overrun counters. 2-FF RX. PROGRAM=NO.
`timescale 1ns / 1ps
module a7ng_uart_rx100 #(
  parameter int CLK_HZ = 100_000_000,
  parameter int BAUD   = 115200
) (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       rx,
  output logic [7:0] data,
  output logic       valid,
  output logic [7:0] ferr,
  output logic [7:0] oerr
);
  localparam int CLKS_PER_BIT = (CLK_HZ + BAUD/2) / BAUD;
  localparam int HALF = CLKS_PER_BIT / 2;
  localparam int CW = $clog2(CLKS_PER_BIT + 1);
  typedef enum logic [1:0] {IDLE, START, DATA, STOP} st_t;
  st_t st;
  logic [CW-1:0] cnt;
  logic [2:0] idx;
  logic [7:0] sh;
  (* ASYNC_REG = "TRUE" *) logic s0, s1;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin s0 <= 1'b1; s1 <= 1'b1; end
    else begin s0 <= rx; s1 <= s0; end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= IDLE; cnt <= '0; idx <= '0; sh <= '0;
      data <= '0; valid <= 1'b0; ferr <= '0; oerr <= '0;
    end else begin
      valid <= 1'b0;
      unique case (st)
        IDLE: if (!s1) begin st <= START; cnt <= '0; end
        START: begin
          if (cnt == HALF[CW-1:0]) begin
            cnt <= '0;
            if (!s1) begin st <= DATA; idx <= '0; end
            else begin st <= IDLE; if (ferr != 8'hFF) ferr <= ferr + 8'd1; end
          end else cnt <= cnt + 1'b1;
        end
        DATA: begin
          if (cnt == CLKS_PER_BIT[CW-1:0] - 1) begin
            cnt <= '0;
            sh[idx] <= s1;
            if (idx == 3'd7) st <= STOP;
            else idx <= idx + 1'b1;
          end else cnt <= cnt + 1'b1;
        end
        STOP: begin
          if (cnt == CLKS_PER_BIT[CW-1:0] - 1) begin
            cnt <= '0; st <= IDLE;
            if (!s1) begin
              if (ferr != 8'hFF) ferr <= ferr + 8'd1;
            end else if (valid) begin
              if (oerr != 8'hFF) oerr <= oerr + 8'd1;
            end else begin
              data <= sh; valid <= 1'b1;
            end
          end else cnt <= cnt + 1'b1;
        end
        default: st <= IDLE;
      endcase
    end
  end
endmodule
