`timescale 1ns/1ps
import a7eam00_pkg::*;
// 32-bit AXI4-Lite, 8-bit address. Single outstanding.
module eam_axil (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [7:0]   s_axil_awaddr,
    input  logic         s_axil_awvalid,
    output logic         s_axil_awready,
    input  logic [31:0]  s_axil_wdata,
    input  logic [3:0]   s_axil_wstrb,
    input  logic         s_axil_wvalid,
    output logic         s_axil_wready,
    output logic [1:0]   s_axil_bresp,
    output logic         s_axil_bvalid,
    input  logic         s_axil_bready,
    input  logic [7:0]   s_axil_araddr,
    input  logic         s_axil_arvalid,
    output logic         s_axil_arready,
    output logic [31:0]  s_axil_rdata,
    output logic [1:0]   s_axil_rresp,
    output logic         s_axil_rvalid,
    input  logic         s_axil_rready,

    input  logic         core_idle,
    input  logic         last_hit,
    input  logic [6:0]   last_dist,
    input  logic [3:0]   last_way,
    input  logic [31:0]  hit_cnt,
    input  logic [31:0]  miss_cnt,
    input  logic [31:0]  qry_cnt,
    input  logic [7:0]   last_cycles,
    input  logic [7:0]   epoch,
    input  logic         dbg_ack,
    input  logic [255:0] dbg_rdata,

    output logic         soft_rst,
    output logic         clr_stat,
    output logic         axi_start,
    output logic [63:0]  axi_key,
    output logic [127:0] axi_ctx,
    output logic [7:0]   axi_tok,
    output logic [7:0]   hit_max,
    output logic [3:0]   ema_shift,
    output logic         auto_update,
    output logic         dbg_fetch,
    output logic         dbg_commit,
    output logic [EAM_AW-1:0] dbg_index,
    output logic [255:0] dbg_wdata
);
    logic [31:0] key_lo, key_hi, ctx0, ctx1, ctx2, ctx3;
    logic [7:0]  ctx_tok;
    logic [31:0] cfg;
    logic [11:0] dbg_idx;
    logic [2:0]  dbg_wsel;
    logic [255:0] dbg_lat;
    logic        wr_fire, rd_fire;
    logic [7:0]  wr_addr, rd_addr;
    logic [31:0] wr_data;
    logic [3:0]  wr_strb;

    assign axi_key = {key_hi, key_lo};
    assign axi_ctx = {ctx3, ctx2, ctx1, ctx0};
    assign axi_tok = ctx_tok;
    assign hit_max = cfg[7:0];
    assign ema_shift = cfg[11:8];
    assign auto_update = cfg[16];
    assign dbg_index = dbg_idx[EAM_AW-1:0];
    assign dbg_wdata = dbg_lat;

    assign s_axil_awready = wr_fire;
    assign s_axil_wready  = wr_fire;
    assign s_axil_arready = rd_fire;
    assign s_axil_bresp   = 2'b00;
    assign s_axil_rresp   = 2'b00;

    assign wr_fire = s_axil_awvalid && s_axil_wvalid && !s_axil_bvalid;
    assign rd_fire = s_axil_arvalid && !s_axil_rvalid;
    assign wr_addr = s_axil_awaddr;
    assign wr_data = s_axil_wdata;
    assign wr_strb = s_axil_wstrb;
    assign rd_addr = s_axil_araddr;

    function automatic logic [31:0] wmerge(input logic [31:0] oldv, input logic [31:0] n, input logic [3:0] s);
        logic [31:0] r;
        r = oldv;
        if (s[0]) r[7:0]   = n[7:0];
        if (s[1]) r[15:8]  = n[15:8];
        if (s[2]) r[23:16] = n[23:16];
        if (s[3]) r[31:24] = n[31:24];
        return r;
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s_axil_bvalid <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata  <= 32'd0;
            soft_rst <= 1'b0;
            clr_stat <= 1'b0;
            axi_start <= 1'b0;
            dbg_fetch <= 1'b0;
            dbg_commit <= 1'b0;
            key_lo <= 32'd0;
            key_hi <= 32'd0;
            ctx0 <= 32'd0;
            ctx1 <= 32'd0;
            ctx2 <= 32'd0;
            ctx3 <= 32'd0;
            ctx_tok <= 8'd0;
            cfg <= 32'h0001_0200; // AUTO=1, EMA=2, HIT_MAX=0
            dbg_idx <= 12'd0;
            dbg_wsel <= 3'd0;
            dbg_lat <= '0;
        end else begin
            soft_rst <= 1'b0;
            clr_stat <= 1'b0;
            axi_start <= 1'b0;
            dbg_fetch <= 1'b0;
            dbg_commit <= 1'b0;
            if (dbg_ack)
                dbg_lat <= dbg_rdata;

            if (s_axil_bvalid && s_axil_bready)
                s_axil_bvalid <= 1'b0;
            if (s_axil_rvalid && s_axil_rready)
                s_axil_rvalid <= 1'b0;

            if (wr_fire) begin
                s_axil_bvalid <= 1'b1;
                unique case (wr_addr[7:2])
                    6'h00: begin
                        if (wr_data[0] && wr_strb[0]) soft_rst <= 1'b1;
                        if (wr_data[1] && wr_strb[0]) clr_stat <= 1'b1;
                        if (wr_data[2] && wr_strb[0] && core_idle) dbg_fetch <= 1'b1;
                        if (wr_data[3] && wr_strb[0] && core_idle) dbg_commit <= 1'b1;
                    end
                    6'h05: cfg <= wmerge(cfg, wr_data, wr_strb);
                    6'h06: key_lo <= wmerge(key_lo, wr_data, wr_strb);
                    6'h07: key_hi <= wmerge(key_hi, wr_data, wr_strb);
                    6'h08: if (wr_data[0]) axi_start <= core_idle;
                    6'h09: ctx0 <= wmerge(ctx0, wr_data, wr_strb);
                    6'h0A: ctx1 <= wmerge(ctx1, wr_data, wr_strb);
                    6'h0B: ctx2 <= wmerge(ctx2, wr_data, wr_strb);
                    6'h0C: ctx3 <= wmerge(ctx3, wr_data, wr_strb);
                    6'h0D: ctx_tok <= wr_data[7:0];
                    6'h0E: dbg_idx <= wr_data[11:0];
                    6'h0F: dbg_wsel <= wr_data[2:0];
                    6'h11: dbg_lat[32*dbg_wsel +: 32] <= wr_data;
                    default: ;
                endcase
            end

            if (rd_fire) begin
                s_axil_rvalid <= 1'b1;
                unique case (rd_addr[7:2])
                    6'h01: s_axil_rdata <= {last_hit, 7'd0, 4'd0, last_way,
                                            1'b0, last_dist, 6'd0, !core_idle, core_idle};
                    6'h02: s_axil_rdata <= hit_cnt;
                    6'h03: s_axil_rdata <= miss_cnt;
                    6'h04: s_axil_rdata <= qry_cnt;
                    6'h05: s_axil_rdata <= cfg;
                    6'h06: s_axil_rdata <= key_lo;
                    6'h07: s_axil_rdata <= key_hi;
                    6'h09: s_axil_rdata <= ctx0;
                    6'h0A: s_axil_rdata <= ctx1;
                    6'h0B: s_axil_rdata <= ctx2;
                    6'h0C: s_axil_rdata <= ctx3;
                    6'h0D: s_axil_rdata <= {24'd0, ctx_tok};
                    6'h0E: s_axil_rdata <= {20'd0, dbg_idx};
                    6'h0F: s_axil_rdata <= {29'd0, dbg_wsel};
                    6'h10: s_axil_rdata <= dbg_lat[32*dbg_wsel +: 32];
                    6'h12: s_axil_rdata <= {16'd0, last_cycles, epoch};
                    default: s_axil_rdata <= 32'd0;
                endcase
            end
        end
    end
endmodule
