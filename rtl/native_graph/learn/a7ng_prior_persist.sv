// a7ng_prior_persist.sv — NG-05 DDR-backed prior (law: a7ng-learn-persist-v0)
// BRAM working set + FPGA-owned flush/reload. Host: reward only — no weight write port.
`timescale 1ns / 1ps

module a7ng_prior_persist #(
  parameter int unsigned DEPTH = 64,
  parameter int unsigned AW    = 6
) (
  input  logic               clk,
  input  logic               rst_n,
  input  logic               learn_en_i,
  input  logic               freeze_i,
  input  logic               forget_i,      // wipe BRAM + zero DDR region
  input  logic               bram_kill_i,   // simulate power-loss of BRAM only (DDR keeps)
  input  logic               flush_i,       // BRAM → DDR
  input  logic               reload_i,      // DDR → BRAM (teacher-off persist)
  input  logic               upd_i,
  input  logic [AW-1:0]      idx_i,
  input  logic signed [3:0]  reward_i,
  input  logic               rd_i,
  input  logic [AW-1:0]      rd_idx_i,
  output logic signed [7:0]  prior_o,
  output logic               busy_o,
  output logic               done_o,
  output logic [15:0]        update_count_o,
  // AXI4 (FPGA master)
  output logic [3:0]         m_axi_awid,
  output logic [27:0]        m_axi_awaddr,
  output logic [7:0]         m_axi_awlen,
  output logic [2:0]         m_axi_awsize,
  output logic [1:0]         m_axi_awburst,
  output logic               m_axi_awvalid,
  input  logic               m_axi_awready,
  output logic [127:0]       m_axi_wdata,
  output logic [15:0]        m_axi_wstrb,
  output logic               m_axi_wlast,
  output logic               m_axi_wvalid,
  input  logic               m_axi_wready,
  input  logic [3:0]         m_axi_bid,
  input  logic [1:0]         m_axi_bresp,
  input  logic               m_axi_bvalid,
  output logic               m_axi_bready,
  output logic [3:0]         m_axi_arid,
  output logic [27:0]        m_axi_araddr,
  output logic [7:0]         m_axi_arlen,
  output logic [2:0]         m_axi_arsize,
  output logic [1:0]         m_axi_arburst,
  output logic               m_axi_arvalid,
  input  logic               m_axi_arready,
  input  logic [3:0]         m_axi_rid,
  input  logic [127:0]       m_axi_rdata,
  input  logic [1:0]         m_axi_rresp,
  input  logic               m_axi_rlast,
  input  logic               m_axi_rvalid,
  output logic               m_axi_rready
);
  import a7ng_pkg::*;

  logic signed [7:0] prior [DEPTH];
  integer i;

  function automatic logic signed [7:0] sat8(input logic signed [8:0] x);
    if (x > 9'sd127)  return 8'sd127;
    if (x < -9'sd128) return -8'sd128;
    return x[7:0];
  endfunction

  typedef enum logic [3:0] {
    ST_IDLE, ST_FLUSH_AW, ST_FLUSH_W, ST_FLUSH_B,
    ST_REL_AR, ST_REL_R, ST_FORGET_DDR_AW, ST_FORGET_DDR_W, ST_FORGET_DDR_B, ST_DONE
  } st_t;
  st_t st;
  logic [2:0] beat_i; // 0..3 for 64 bytes
  logic [127:0] beat_pack;
  int unsigned base16;

  assign m_axi_awid    = 4'd0;
  assign m_axi_arid    = 4'd0;
  assign m_axi_awlen   = 8'd0;
  assign m_axi_arlen   = 8'd0;
  assign m_axi_awsize  = 3'd4;
  assign m_axi_arsize  = 3'd4;
  assign m_axi_awburst = 2'b01;
  assign m_axi_arburst = 2'b01;
  assign m_axi_wstrb   = 16'hFFFF;
  assign m_axi_bready  = 1'b1;
  assign busy_o = (st != ST_IDLE) && (st != ST_DONE);

  always_comb begin
    base16 = {29'd0, beat_i} << 4;
    beat_pack = {
      prior[base16+15], prior[base16+14], prior[base16+13], prior[base16+12],
      prior[base16+11], prior[base16+10], prior[base16+9],  prior[base16+8],
      prior[base16+7],  prior[base16+6],  prior[base16+5],  prior[base16+4],
      prior[base16+3],  prior[base16+2],  prior[base16+1],  prior[base16+0]
    };
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < DEPTH; i = i + 1) prior[i] <= 8'sd0;
      prior_o <= 8'sd0;
      update_count_o <= 16'd0;
      done_o <= 1'b0;
      beat_i <= 3'd0;
      st <= ST_IDLE;
      m_axi_awvalid <= 1'b0;
      m_axi_wvalid  <= 1'b0;
      m_axi_wlast   <= 1'b0;
      m_axi_arvalid <= 1'b0;
      m_axi_rready  <= 1'b0;
      m_axi_awaddr  <= '0;
      m_axi_araddr  <= '0;
      m_axi_wdata   <= '0;
    end else begin
      done_o <= 1'b0;

      if (st == ST_IDLE) begin
        if (bram_kill_i) begin
          for (i = 0; i < DEPTH; i = i + 1) prior[i] <= 8'sd0;
        end else if (forget_i) begin
          for (i = 0; i < DEPTH; i = i + 1) prior[i] <= 8'sd0;
          update_count_o <= 16'd0;
          beat_i <= 3'd0;
          st <= ST_FORGET_DDR_AW;
        end else if (flush_i) begin
          beat_i <= 3'd0;
          st <= ST_FLUSH_AW;
        end else if (reload_i) begin
          beat_i <= 3'd0;
          st <= ST_REL_AR;
        end else if (upd_i && learn_en_i && !freeze_i) begin
          prior[idx_i] <= sat8($signed({prior[idx_i][7], prior[idx_i]})
                               + $signed({{5{reward_i[3]}}, reward_i}));
          update_count_o <= update_count_o + 16'd1;
        end
        if (rd_i)
          prior_o <= prior[rd_idx_i];
      end

      unique case (st)
        ST_IDLE: ;

        ST_FLUSH_AW: begin
          m_axi_awaddr  <= NG_DDR_PRIOR_BASE + {23'd0, beat_i, 4'b0000};
          m_axi_awvalid <= 1'b1;
          if (m_axi_awvalid && m_axi_awready) begin
            m_axi_awvalid <= 1'b0;
            m_axi_wdata   <= beat_pack;
            m_axi_wvalid  <= 1'b1;
            m_axi_wlast   <= 1'b1;
            st <= ST_FLUSH_W;
          end
        end

        ST_FLUSH_W: if (m_axi_wvalid && m_axi_wready) begin
          m_axi_wvalid <= 1'b0;
          m_axi_wlast  <= 1'b0;
          st <= ST_FLUSH_B;
        end

        ST_FLUSH_B: if (m_axi_bvalid) begin
          if (beat_i == 3'(NG_PRIOR_BEATS - 1)) begin
            st <= ST_DONE;
          end else begin
            beat_i <= beat_i + 3'd1;
            st <= ST_FLUSH_AW;
          end
        end

        ST_REL_AR: begin
          m_axi_araddr  <= NG_DDR_PRIOR_BASE + {23'd0, beat_i, 4'b0000};
          m_axi_arvalid <= 1'b1;
          if (m_axi_arvalid && m_axi_arready) begin
            m_axi_arvalid <= 1'b0;
            m_axi_rready  <= 1'b1;
            st <= ST_REL_R;
          end
        end

        ST_REL_R: if (m_axi_rvalid && m_axi_rready) begin
          prior[base16+0]  <= m_axi_rdata[7:0];
          prior[base16+1]  <= m_axi_rdata[15:8];
          prior[base16+2]  <= m_axi_rdata[23:16];
          prior[base16+3]  <= m_axi_rdata[31:24];
          prior[base16+4]  <= m_axi_rdata[39:32];
          prior[base16+5]  <= m_axi_rdata[47:40];
          prior[base16+6]  <= m_axi_rdata[55:48];
          prior[base16+7]  <= m_axi_rdata[63:56];
          prior[base16+8]  <= m_axi_rdata[71:64];
          prior[base16+9]  <= m_axi_rdata[79:72];
          prior[base16+10] <= m_axi_rdata[87:80];
          prior[base16+11] <= m_axi_rdata[95:88];
          prior[base16+12] <= m_axi_rdata[103:96];
          prior[base16+13] <= m_axi_rdata[111:104];
          prior[base16+14] <= m_axi_rdata[119:112];
          prior[base16+15] <= m_axi_rdata[127:120];
          m_axi_rready <= 1'b0;
          if (beat_i == 3'(NG_PRIOR_BEATS - 1))
            st <= ST_DONE;
          else begin
            beat_i <= beat_i + 3'd1;
            st <= ST_REL_AR;
          end
        end

        ST_FORGET_DDR_AW: begin
          m_axi_awaddr  <= NG_DDR_PRIOR_BASE + {23'd0, beat_i, 4'b0000};
          m_axi_awvalid <= 1'b1;
          if (m_axi_awvalid && m_axi_awready) begin
            m_axi_awvalid <= 1'b0;
            m_axi_wdata   <= 128'd0;
            m_axi_wvalid  <= 1'b1;
            m_axi_wlast   <= 1'b1;
            st <= ST_FORGET_DDR_W;
          end
        end

        ST_FORGET_DDR_W: if (m_axi_wvalid && m_axi_wready) begin
          m_axi_wvalid <= 1'b0;
          m_axi_wlast  <= 1'b0;
          st <= ST_FORGET_DDR_B;
        end

        ST_FORGET_DDR_B: if (m_axi_bvalid) begin
          if (beat_i == 3'(NG_PRIOR_BEATS - 1))
            st <= ST_DONE;
          else begin
            beat_i <= beat_i + 3'd1;
            st <= ST_FORGET_DDR_AW;
          end
        end

        ST_DONE: begin
          done_o <= 1'b1;
          st <= ST_IDLE;
        end

        default: st <= ST_IDLE;
      endcase
    end
  end
endmodule
