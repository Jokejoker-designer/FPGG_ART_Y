// a7ng_episode_bank.sv — MEM-01 beyond stub: BRAM episodes + DDR flush/reload (law: a7ng-mem01-v0)
// Frozen 02M bit untouched. FPGA owns addresses.
`timescale 1ns / 1ps

module a7ng_episode_bank #(
  parameter int unsigned DEPTH = 16,
  parameter int unsigned AW    = 4
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         wr_i,
  input  logic [AW-1:0] wr_id_i,
  input  logic [127:0] wr_data_i,
  input  logic         rd_i,
  input  logic [AW-1:0] rd_id_i,
  output logic [127:0] rd_data_o,
  input  logic         flush_i,
  input  logic         reload_i,
  input  logic         forget_i,
  output logic         busy_o,
  output logic         done_o,
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
  output logic         m_axi_bready,
  output logic [3:0]   m_axi_arid,
  output logic [27:0]  m_axi_araddr,
  output logic [7:0]   m_axi_arlen,
  output logic [2:0]   m_axi_arsize,
  output logic [1:0]   m_axi_arburst,
  output logic         m_axi_arvalid,
  input  logic         m_axi_arready,
  input  logic [3:0]   m_axi_rid,
  input  logic [127:0] m_axi_rdata,
  input  logic [1:0]   m_axi_rresp,
  input  logic         m_axi_rlast,
  input  logic         m_axi_rvalid,
  output logic         m_axi_rready
);
  import a7ng_pkg::*;
  import a7ng_mem_schema_v1_pkg::*;
  logic [127:0] bank [DEPTH];
  integer i;
  typedef enum logic [2:0] {IDLE, FAW, FW, FB, RAR, RR, DONE} st_t;
  st_t st;
  logic [AW-1:0] idx;

  assign m_axi_awid=0; assign m_axi_arid=0;
  assign m_axi_awlen=0; assign m_axi_arlen=0;
  assign m_axi_awsize=3'd4; assign m_axi_arsize=3'd4;
  assign m_axi_awburst=2'b01; assign m_axi_arburst=2'b01;
  assign m_axi_wstrb=16'hFFFF; assign m_axi_bready=1'b1;
  assign busy_o = (st!=IDLE)&&(st!=DONE);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i=0;i<DEPTH;i++) bank[i] <= '0;
      rd_data_o <= '0; done_o <= 0; st <= IDLE; idx <= '0;
      m_axi_awvalid<=0; m_axi_wvalid<=0; m_axi_wlast<=0;
      m_axi_arvalid<=0; m_axi_rready<=0; m_axi_awaddr<=0; m_axi_araddr<=0; m_axi_wdata<=0;
    end else begin
      done_o <= 0;
      if (st==IDLE) begin
        if (forget_i) begin for (i=0;i<DEPTH;i++) bank[i] <= '0; end
        else if (wr_i) bank[wr_id_i] <= wr_data_i;
        else if (rd_i) rd_data_o <= bank[rd_id_i];
        else if (flush_i) begin idx <= '0; st <= FAW; end
        else if (reload_i) begin idx <= '0; st <= RAR; end
      end
      unique case (st)
        IDLE: ;
        FAW: begin
          m_axi_awaddr <= a7ng_episode_byte_addr(NG_DDR_EPISODE_BASE, 32'(idx));
          m_axi_awvalid <= 1;
          if (m_axi_awvalid && m_axi_awready) begin
            m_axi_awvalid <= 0; m_axi_wdata <= bank[idx]; m_axi_wvalid <= 1; m_axi_wlast <= 1; st <= FW;
          end
        end
        FW: if (m_axi_wvalid && m_axi_wready) begin m_axi_wvalid<=0; m_axi_wlast<=0; st<=FB; end
        FB: if (m_axi_bvalid) begin
          if (idx == DEPTH[AW-1:0]-1'b1) st <= DONE;
          else begin idx <= idx + 1'b1; st <= FAW; end
        end
        RAR: begin
          m_axi_araddr <= a7ng_episode_byte_addr(NG_DDR_EPISODE_BASE, 32'(idx));
          m_axi_arvalid <= 1;
          if (m_axi_arvalid && m_axi_arready) begin m_axi_arvalid<=0; m_axi_rready<=1; st<=RR; end
        end
        RR: if (m_axi_rvalid && m_axi_rready) begin
          bank[idx] <= m_axi_rdata; m_axi_rready <= 0;
          if (idx == DEPTH[AW-1:0]-1'b1) st <= DONE;
          else begin idx <= idx + 1'b1; st <= RAR; end
        end
        DONE: begin done_o <= 1; st <= IDLE; end
        default: st <= IDLE;
      endcase
    end
  end
endmodule
