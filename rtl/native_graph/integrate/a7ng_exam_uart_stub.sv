// a7ng_exam_uart_stub.sv — UART host-path stub toward HS-02 blind exam
// Emits status framing only. Does NOT grade answers (host METRIC-EVAL-ONLY later).
// Mode byte: teacher=0 external_LLM=0 learn=0 freeze=1 encoded as 0x91.
// Full blind exam protocol DEFERRED until teacher_off_exam after SoC bit exists.
`timescale 1ns / 1ps

module a7ng_exam_uart_stub #(
  parameter int CLK_HZ = 100_000_000,
  parameter int BAUD   = 115200
) (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       uart_rx,
  output logic       uart_tx,
  input  logic       pe_alive_i,
  input  logic       mig_calib_i,
  input  logic       lm_path_i,
  input  logic [3:0] pe_nibble_i,
  output logic       exam_mode_o,   // freeze=1 path armed
  output logic [7:0] last_cmd_o,
  output logic [7:0] status_byte_o
);
  // HS-02 stub flags (silicon-visible constants; not host-hardwired pytest)
  localparam logic [7:0] STATUS_HS02 = 8'h91; // teacher=0 LLM=0 learn=0 freeze=1
  localparam logic [7:0] CMD_ENTER   = 8'hE0;
  localparam logic [7:0] CMD_STATUS  = 8'h53; // 'S'

  logic [7:0] rx_data;
  logic       rx_valid;
  logic       tx_start;
  logic [7:0] tx_data;
  logic       tx_busy;
  logic       exam_mode;
  logic [7:0] last_cmd;
  logic [2:0] tx_seq;
  logic       pend_status;

  assign exam_mode_o   = exam_mode;
  assign last_cmd_o    = last_cmd;
  assign status_byte_o = STATUS_HS02;

  uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_rx (
    .clk(clk), .rst_n(rst_n), .rx(uart_rx), .data(rx_data), .valid(rx_valid)
  );
  uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_tx (
    .clk(clk), .rst_n(rst_n), .start(tx_start), .data(tx_data), .tx(uart_tx), .busy(tx_busy)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      exam_mode   <= 1'b0;
      last_cmd    <= 8'd0;
      tx_start    <= 1'b0;
      tx_data     <= 8'd0;
      tx_seq      <= 3'd0;
      pend_status <= 1'b0;
    end else begin
      tx_start <= 1'b0;
      if (rx_valid) begin
        last_cmd <= rx_data;
        if (rx_data == CMD_ENTER) exam_mode <= 1'b1;
        if (rx_data == CMD_STATUS) pend_status <= 1'b1;
      end
      if (pend_status && !tx_busy && !tx_start) begin
        unique case (tx_seq)
          3'd0: begin tx_data <= STATUS_HS02; tx_start <= 1'b1; tx_seq <= 3'd1; end
          3'd1: begin
            tx_data <= {mig_calib_i, pe_alive_i, lm_path_i, exam_mode, pe_nibble_i};
            tx_start <= 1'b1; tx_seq <= 3'd2;
          end
          default: begin pend_status <= 1'b0; tx_seq <= 3'd0; end
        endcase
      end
    end
  end
endmodule
