`timescale 1ns / 1ps
// a7ng_ddr_wmem_boot.sv — FPGA-owned AXI master writes 802816 B to DDR_WBASE.
// Sim: $readmemh. Silicon: T2-SPI QSPI flash READ@FLASH_BASE → DDR (no host poke).
import a7lm06_pkg::*;

module a7ng_ddr_wmem_boot #(
  parameter int unsigned N_BYTES   = 802816,
  parameter logic [27:0] BASE      = 28'(DDR_WBASE),
  parameter logic [23:0] FLASH_BASE = 24'h40_0000,
  parameter int unsigned SPI_DIV   = 4
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start_i,
  output logic         busy_o,
  output logic         done_o,
  output logic [31:0]  bytes_written_o,
  // Arty QSPI — single SPI READ (0x03). dq2/dq3 held high (WP#/HOLD#).
  output logic         qspi_cs_n,
  output logic         qspi_sck,
  output logic         qspi_mosi,
  input  logic         qspi_miso,
  output logic         qspi_dq2,
  output logic         qspi_dq3,
  output logic [3:0]   m_axi_awid,
  output logic [27:0]  m_axi_awaddr,
  output logic [7:0]   m_axi_awlen,
  output logic [2:0]   m_axi_awsize,
  output logic [1:0]   m_axi_awburst,
  output logic         m_axi_awvalid,
  input  logic         m_axi_awready,
  output logic [127:0] m_axi_wdata,
  output logic [15:0]  m_axi_wstrb,
  output logic         m_axi_wlast,
  output logic         m_axi_wvalid,
  input  logic         m_axi_wready,
  input  logic [3:0]   m_axi_bid,
  input  logic [1:0]   m_axi_bresp,
  input  logic         m_axi_bvalid,
  output logic         m_axi_bready
);
  localparam int unsigned N_BEATS = N_BYTES / 16;

  assign m_axi_awid    = 4'd1;
  assign m_axi_awlen   = 8'd0;
  assign m_axi_awsize  = 3'd4;
  assign m_axi_awburst = 2'b01;
  assign m_axi_wstrb   = 16'hFFFF;
  assign m_axi_bready  = 1'b1;
  assign qspi_dq2      = 1'b1;
  assign qspi_dq3      = 1'b1;

`ifndef SYNTHESIS
  // -------------------- XSim: $readmemh (not silicon evidence) --------------------
  logic [7:0] img [0:N_BYTES-1];
  initial begin : load_img
    integer i;
    for (i = 0; i < N_BYTES; i++) img[i] = 8'h00;
    $readmemh("a7lm06_wmem.hex", img);
  end

  typedef enum logic [1:0] {S_IDLE, S_ISSUE, S_WAITB, S_DONE} st_t;
  st_t st;
  logic [31:0] beat_i;
  logic [127:0] wbeat;

  always_comb begin
    integer k;
    wbeat = '0;
    for (k = 0; k < 16; k++)
      if ((beat_i * 16 + unsigned'(k)) < N_BYTES)
        wbeat[k*8 +: 8] = img[beat_i * 16 + unsigned'(k)];
  end

  assign qspi_cs_n = 1'b1;
  assign qspi_sck  = 1'b0;
  assign qspi_mosi = 1'b0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE; beat_i <= '0; busy_o <= 1'b0; done_o <= 1'b0;
      bytes_written_o <= '0; m_axi_awvalid <= 1'b0; m_axi_wvalid <= 1'b0;
      m_axi_wlast <= 1'b0; m_axi_awaddr <= BASE; m_axi_wdata <= '0;
    end else unique case (st)
      S_IDLE: begin
        m_axi_awvalid <= 1'b0; m_axi_wvalid <= 1'b0;
        if (start_i && !done_o) begin
          beat_i <= '0; bytes_written_o <= '0; busy_o <= 1'b1; st <= S_ISSUE;
        end
      end
      S_ISSUE: begin
        m_axi_awaddr <= BASE + {beat_i[23:0], 4'b0000};
        m_axi_wdata  <= wbeat;
        m_axi_awvalid <= 1'b1; m_axi_wvalid <= 1'b1; m_axi_wlast <= 1'b1;
        if (m_axi_awvalid && m_axi_awready && m_axi_wvalid && m_axi_wready) begin
          m_axi_awvalid <= 1'b0; m_axi_wvalid <= 1'b0; m_axi_wlast <= 1'b0;
          st <= S_WAITB;
        end
      end
      S_WAITB: if (m_axi_bvalid) begin
        bytes_written_o <= bytes_written_o + 32'd16;
        if (beat_i == (N_BEATS - 1)) begin
          busy_o <= 1'b0; done_o <= 1'b1; st <= S_DONE;
        end else begin
          beat_i <= beat_i + 32'd1; st <= S_ISSUE;
        end
      end
      S_DONE: st <= S_DONE;
      default: st <= S_IDLE;
    endcase
  end

`else
  // -------------------- Silicon T2-SPI: continuous READ stream --------------------
  // One CS assertion: 0x03 + 24-bit addr + N_BYTES data. AXI writes 16 B beats.
  typedef enum logic [2:0] {
    ST_IDLE, ST_CMD, ST_DATA, ST_AXI, ST_WAITB, ST_DONE
  } st_t;
  st_t st;

  logic [31:0] beat_i;
  logic [127:0] beat_buf;
  logic [31:0] out_sr;       // cmd+addr shift-out
  logic [7:0]  in_byte;
  logic [4:0]  byte_fill;    // 0..15 bytes in beat_buf
  logic [5:0]  cmd_bits;     // 32 bits of cmd+addr remaining
  logic [2:0]  bit_ix;       // bit within current data byte
  logic [7:0]  div_cnt;
  logic        sck_hi;       // 0=low/drive, 1=high/sample

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= ST_IDLE; beat_i <= '0; busy_o <= 1'b0; done_o <= 1'b0;
      bytes_written_o <= '0; m_axi_awvalid <= 1'b0; m_axi_wvalid <= 1'b0;
      m_axi_wlast <= 1'b0; m_axi_awaddr <= BASE; m_axi_wdata <= '0;
      beat_buf <= '0; out_sr <= '0; in_byte <= '0; byte_fill <= '0;
      cmd_bits <= '0; bit_ix <= '0; div_cnt <= '0; sck_hi <= 1'b0;
      qspi_cs_n <= 1'b1; qspi_sck <= 1'b0; qspi_mosi <= 1'b0;
    end else begin
      unique case (st)
        ST_IDLE: begin
          qspi_cs_n <= 1'b1; qspi_sck <= 1'b0;
          m_axi_awvalid <= 1'b0; m_axi_wvalid <= 1'b0;
          if (start_i && !done_o) begin
            beat_i <= '0; bytes_written_o <= '0; busy_o <= 1'b1;
            out_sr <= {8'h03, FLASH_BASE};
            cmd_bits <= 6'd32; bit_ix <= '0; byte_fill <= '0;
            beat_buf <= '0; div_cnt <= '0; sck_hi <= 1'b0;
            qspi_cs_n <= 1'b0; st <= ST_CMD;
          end
        end

        ST_CMD: begin
          if (div_cnt != 8'(SPI_DIV - 1)) begin
            div_cnt <= div_cnt + 8'd1;
          end else begin
            div_cnt <= '0;
            if (!sck_hi) begin
              qspi_mosi <= out_sr[31];
              qspi_sck  <= 1'b0;
              sck_hi    <= 1'b1;
            end else begin
              qspi_sck <= 1'b1;
              out_sr   <= {out_sr[30:0], 1'b0};
              sck_hi   <= 1'b0;
              if (cmd_bits == 6'd1) begin
                cmd_bits <= '0; bit_ix <= '0; in_byte <= '0; st <= ST_DATA;
              end else
                cmd_bits <= cmd_bits - 6'd1;
            end
          end
        end

        ST_DATA: begin
          if (div_cnt != 8'(SPI_DIV - 1)) begin
            div_cnt <= div_cnt + 8'd1;
          end else begin
            div_cnt <= '0;
            if (!sck_hi) begin
              qspi_mosi <= 1'b0;
              qspi_sck  <= 1'b0;
              sck_hi    <= 1'b1;
            end else begin
              qspi_sck <= 1'b1;
              in_byte  <= {in_byte[6:0], qspi_miso};
              sck_hi   <= 1'b0;
              if (bit_ix == 3'd7) begin
                bit_ix <= '0;
                // little-endian byte packing into 128-bit beat
                beat_buf[byte_fill*8 +: 8] <= {in_byte[6:0], qspi_miso};
                if (byte_fill == 5'd15) begin
                  byte_fill <= '0;
                  st <= ST_AXI;
                end else
                  byte_fill <= byte_fill + 5'd1;
              end else
                bit_ix <= bit_ix + 3'd1;
            end
          end
        end

        ST_AXI: begin
          qspi_sck <= 1'b0;
          m_axi_awaddr  <= BASE + {beat_i[23:0], 4'b0000};
          m_axi_wdata   <= beat_buf;
          m_axi_awvalid <= 1'b1;
          m_axi_wvalid  <= 1'b1;
          m_axi_wlast   <= 1'b1;
          if (m_axi_awvalid && m_axi_awready && m_axi_wvalid && m_axi_wready) begin
            m_axi_awvalid <= 1'b0;
            m_axi_wvalid  <= 1'b0;
            m_axi_wlast   <= 1'b0;
            st <= ST_WAITB;
          end
        end

        ST_WAITB: begin
          if (m_axi_bvalid) begin
            bytes_written_o <= bytes_written_o + 32'd16;
            if (beat_i == (N_BEATS - 1)) begin
              qspi_cs_n <= 1'b1;
              busy_o <= 1'b0;
              done_o <= 1'b1;
              st <= ST_DONE;
            end else begin
              beat_i <= beat_i + 32'd1;
              // keep CS low — continue sequential READ stream
              bit_ix <= '0; in_byte <= '0; byte_fill <= '0;
              beat_buf <= '0; div_cnt <= '0; sck_hi <= 1'b0;
              st <= ST_DATA;
            end
          end
        end

        ST_DONE: begin
          qspi_cs_n <= 1'b1;
          qspi_sck  <= 1'b0;
          st <= ST_DONE;
        end

        default: st <= ST_IDLE;
      endcase
    end
  end
`endif
endmodule
