`timescale 1ns/1ps
import a7lm05_pkg::*;
// Working W for 399360 params: resident emb + one layer + head.
// Uncached layers live in DDR at DDR_WBASE. Miss = writeback dirty + refill.
// SIM_FULL=1: 524288-deep sim BRAM. Silicon: three UG901 TDP banks.
// Tile refill is dual-clock: banks on clk (clk50), AXI DMA on clk_dma (ui_clk).
module weight_tile399k #(
    parameter bit SIM_FULL = 1'b1
) (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               clk_dma,
    input  logic               rst_dma_n,
    input  logic               we_a,
    input  logic [18:0]        addr_a,
    input  logic signed [7:0]  wdata_a,
    output logic signed [7:0]  rdata_a,
    input  logic [18:0]        addr_b,
    output logic signed [7:0]  rdata_b,
    output logic               stall,
    output logic [1:0]         cached_ly,
    output logic               dirty,
    output logic               dma_owner,
    output logic               dma_go,
    output logic               dma_wr,
    output logic [27:0]        dma_addr,
    output logic [31:0]        dma_bytes,
    input  logic               dma_busy,
    input  logic               dma_done,
    output logic               dma_w_valid,
    input  logic               dma_w_ready,
    output logic [127:0]       dma_w_data,
    input  logic               dma_r_valid,
    output logic               dma_r_ready,
    input  logic [127:0]       dma_r_data
);
    function automatic logic is_emb(input logic [18:0] a);
        return (a < 19'(OFF_L0));
    endfunction
    function automatic logic is_head(input logic [18:0] a);
        return (a >= 19'(OFF_HEAD));
    endfunction
    function automatic logic is_layer(input logic [18:0] a);
        return (a >= 19'(OFF_L0)) && (a < 19'(OFF_HEAD));
    endfunction
    function automatic [1:0] ly_of(input logic [18:0] a);
        return 2'((a - 19'(OFF_L0)) / 19'(LAYER_W));
    endfunction
    function automatic [16:0] lay_off(input logic [18:0] a);
        return 17'((a - 19'(OFF_L0)) % 19'(LAYER_W));
    endfunction

    generate
        if (SIM_FULL) begin : FULL
            weight_bram399k u_full (
                .clk(clk), .we_a(we_a), .addr_a(addr_a), .wdata_a(wdata_a),
                .rdata_a(rdata_a), .addr_b(addr_b), .rdata_b(rdata_b)
            );
            assign stall = 1'b0;
            assign cached_ly = 2'd0;
            assign dirty = 1'b0;
            assign dma_owner = 1'b0;
            assign dma_go = 1'b0;
            assign dma_wr = 1'b0;
            assign dma_addr = 28'(DDR_WBASE);
            assign dma_bytes = 32'd128;
            assign dma_w_valid = 1'b0;
            assign dma_w_data = 128'd0;
            assign dma_r_ready = 1'b0;
        end else begin : TILE
            localparam int CHUNK = 128;
            localparam int NLINE = LAYER_W / CHUNK;

            logic [1:0]  hold_ly, cur_ly;
            logic        need_a, need_b, miss, dirty_r;
            logic [9:0]  i;
            logic [9:0]  ch;
            logic [3:0]  waitn;
            logic        is_flush;
            (* ram_style = "registers" *) logic [1023:0] line_wr;
            (* ram_style = "registers" *) logic [1023:0] line_rd;
            logic        req, ack;
            logic [1:0]  req_s, ack_s;

            typedef enum logic [3:0] {
                B_IDLE, B_FILL, B_FWAIT, B_FCAP, B_REQ, B_WAITACK,
                B_STORE, B_SWAIT, B_NEXT
            } bst_t;
            typedef enum logic [2:0] {
                D_IDLE, D_GO, D_FEED, D_DRAIN, D_WAITDONE, D_ACK
            } dst_t;
            bst_t bst;
            dst_t dst;
            logic [6:0] beat;

            logic signed [7:0] emb_ra, emb_rb, lay_ra, lay_rb, hed_ra, hed_rb;
            logic        emb_we, lay_we, hed_we;
            logic [15:0] emb_aa, emb_ab;
            logic [16:0] lay_aa, lay_ab;
            logic [15:0] hed_aa, hed_ab;
            logic signed [7:0] emb_wd, lay_wd, hed_wd;
            logic [1:0]  rsel_a, rsel_b;
            logic        refill;
            logic [16:0] tile_idx;

            assign need_a = is_layer(addr_a) && (ly_of(addr_a) != cur_ly);
            assign need_b = is_layer(addr_b) && (ly_of(addr_b) != cur_ly);
            // One refill at a time. Dual-layer probes must not be presented
            // while the core is frozen on stall (see tiny_gpt399k_core fold).
            assign miss   = need_a || need_b;
            assign stall  = (bst != B_IDLE) || miss;
            assign cached_ly = cur_ly;
            assign dirty = dirty_r;
            assign dma_owner = (dst != D_IDLE);
            assign dma_w_data = line_wr[128*beat +: 128];
            assign dma_w_valid = (dst == D_FEED);
            assign dma_r_ready = (dst == D_DRAIN);

            assign refill = (bst == B_FILL) || (bst == B_FWAIT) || (bst == B_FCAP)
                         || (bst == B_STORE) || (bst == B_SWAIT);
            assign tile_idx = 17'(ch) * 17'(CHUNK) + 17'(i);

            assign emb_we = we_a && (bst == B_IDLE) && !need_a && is_emb(addr_a);
            assign hed_we = we_a && (bst == B_IDLE) && !need_a && is_head(addr_a);
            assign lay_we = (bst == B_STORE)
                         || (we_a && (bst == B_IDLE) && !need_a
                             && is_layer(addr_a) && (ly_of(addr_a) == cur_ly));
            assign emb_wd = wdata_a;
            assign hed_wd = wdata_a;
            assign lay_wd = (bst == B_STORE) ? line_rd[8*i +: 8] : wdata_a;
            assign emb_aa = addr_a[15:0];
            assign emb_ab = addr_b[15:0];
            assign hed_aa = 16'(addr_a - 19'(OFF_HEAD));
            assign hed_ab = 16'(addr_b - 19'(OFF_HEAD));
            assign lay_aa = refill ? tile_idx : lay_off(addr_a);
            assign lay_ab = is_layer(addr_b) ? lay_off(addr_b) : 17'd0;

            weight_bram_tdp8 #(.DEPTH(65536)) u_emb (
                .clk(clk), .we_a(emb_we), .addr_a(emb_aa), .wdata_a(emb_wd),
                .rdata_a(emb_ra), .addr_b(emb_ab), .rdata_b(emb_rb)
            );
            weight_bram_tdp8 #(.DEPTH(73728)) u_lay (
                .clk(clk), .we_a(lay_we), .addr_a(lay_aa), .wdata_a(lay_wd),
                .rdata_a(lay_ra), .addr_b(lay_ab), .rdata_b(lay_rb)
            );
            weight_bram_tdp8 #(.DEPTH(65536)) u_hed (
                .clk(clk), .we_a(hed_we), .addr_a(hed_aa), .wdata_a(hed_wd),
                .rdata_a(hed_ra), .addr_b(hed_ab), .rdata_b(hed_rb)
            );

            always_ff @(posedge clk) begin
                if (is_emb(addr_a))       rsel_a <= 2'd0;
                else if (is_head(addr_a)) rsel_a <= 2'd2;
                else                      rsel_a <= 2'd1;
                if (is_emb(addr_b))       rsel_b <= 2'd0;
                else if (is_head(addr_b)) rsel_b <= 2'd2;
                else                      rsel_b <= 2'd1;
            end
            assign rdata_a = (rsel_a == 2'd0) ? emb_ra : ((rsel_a == 2'd2) ? hed_ra : lay_ra);
            assign rdata_b = (rsel_b == 2'd0) ? emb_rb : ((rsel_b == 2'd2) ? hed_rb : lay_rb);

            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    bst <= B_IDLE;
                    cur_ly <= 2'd0;
                    hold_ly <= 2'd0;
                    dirty_r <= 1'b0;
                    is_flush <= 1'b0;
                    i <= 10'd0;
                    ch <= 10'd0;
                    waitn <= 4'd0;
                    req <= 1'b0;
                    ack_s <= 2'd0;
                end else begin
                    ack_s <= {ack_s[0], ack};
                    if (we_a && (bst == B_IDLE) && is_layer(addr_a) && (ly_of(addr_a) == cur_ly))
                        dirty_r <= 1'b1;
                    unique case (bst)
                        B_IDLE: begin
                            req <= 1'b0;
                            if (miss) begin
                                hold_ly <= need_a ? ly_of(addr_a) : ly_of(addr_b);
                                ch <= 10'd0;
                                i <= 10'd0;
                                if (dirty_r) begin
                                    is_flush <= 1'b1;
                                    bst <= B_FILL;
                                end else begin
                                    is_flush <= 1'b0;
                                    bst <= B_REQ;
                                end
                            end
                        end
                        B_FILL: begin
                            waitn <= 4'd0;
                            bst <= B_FWAIT;
                        end
                        B_FWAIT: begin
                            if (waitn < 4'd2)
                                waitn <= waitn + 4'd1;
                            else
                                bst <= B_FCAP;
                        end
                        B_FCAP: begin
                            line_wr[8*i +: 8] <= lay_ra;
                            if (i == 10'(CHUNK - 1)) begin
                                i <= 10'd0;
                                bst <= B_REQ;
                            end else begin
                                i <= i + 10'd1;
                                bst <= B_FILL;
                            end
                        end
                        B_REQ: begin
                            req <= 1'b1;
                            if (ack_s[1])
                                bst <= B_WAITACK;
                        end
                        B_WAITACK: begin
                            req <= 1'b0;
                            if (!ack_s[1]) begin
                                if (is_flush) begin
                                    if (ch == 10'(NLINE - 1)) begin
                                        dirty_r <= 1'b0;
                                        is_flush <= 1'b0;
                                        ch <= 10'd0;
                                        i <= 10'd0;
                                        bst <= B_REQ;
                                    end else begin
                                        ch <= ch + 10'd1;
                                        i <= 10'd0;
                                        bst <= B_FILL;
                                    end
                                end else begin
                                    i <= 10'd0;
                                    bst <= B_STORE;
                                end
                            end
                        end
                        B_STORE: begin
                            bst <= B_SWAIT;
                        end
                        B_SWAIT: begin
                            if (i == 10'(CHUNK - 1))
                                bst <= B_NEXT;
                            else begin
                                i <= i + 10'd1;
                                bst <= B_STORE;
                            end
                        end
                        B_NEXT: begin
                            if (ch == 10'(NLINE - 1)) begin
                                cur_ly <= hold_ly;
                                dirty_r <= 1'b0;
                                bst <= B_IDLE;
                            end else begin
                                ch <= ch + 10'd1;
                                i <= 10'd0;
                                bst <= B_REQ;
                            end
                        end
                        default: bst <= B_IDLE;
                    endcase
                end
            end

            always_ff @(posedge clk_dma) begin
                if (!rst_dma_n) begin
                    dst <= D_IDLE;
                    dma_go <= 1'b0;
                    dma_wr <= 1'b0;
                    dma_addr <= 28'(DDR_WBASE) + 28'(OFF_L0);
                    dma_bytes <= 32'(CHUNK);
                    beat <= 7'd0;
                    ack <= 1'b0;
                    req_s <= 2'd0;
                end else begin
                    dma_go <= 1'b0;
                    req_s <= {req_s[0], req};
                    unique case (dst)
                        D_IDLE: begin
                            ack <= 1'b0;
                            if (req_s[1]) begin
                                beat <= 7'd0;
                                dst <= D_GO;
                            end
                        end
                        D_GO: begin
                            dma_go <= 1'b1;
                            dma_wr <= is_flush;
                            dma_addr <= 28'(DDR_WBASE) + 28'(OFF_L0)
                                + (28'(is_flush ? cur_ly : hold_ly) * 28'(LAYER_W))
                                + {18'd0, ch, 7'd0};
                            dma_bytes <= 32'(CHUNK);
                            beat <= 7'd0;
                            dst <= is_flush ? D_FEED : D_DRAIN;
                        end
                        D_FEED: begin
                            if (dma_w_ready) begin
                                if (beat == 7'd7)
                                    dst <= D_WAITDONE;
                                else
                                    beat <= beat + 7'd1;
                            end
                        end
                        D_DRAIN: begin
                            if (dma_r_valid) begin
                                line_rd[128*beat +: 128] <= dma_r_data;
                                if (beat == 7'd7)
                                    dst <= D_WAITDONE;
                                else
                                    beat <= beat + 7'd1;
                            end
                        end
                        D_WAITDONE: begin
                            if (dma_done || !dma_busy)
                                dst <= D_ACK;
                        end
                        D_ACK: begin
                            ack <= 1'b1;
                            if (!req_s[1]) begin
                                ack <= 1'b0;
                                dst <= D_IDLE;
                            end
                        end
                        default: dst <= D_IDLE;
                    endcase
                end
            end
        end
    endgenerate
endmodule
