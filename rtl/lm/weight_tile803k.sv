`timescale 1ns/1ps
import a7lm06_pkg::*;
// One 131072 INT8 region resident. POS/TOK/LAYER/HEAD share the bank.
// SIM_FULL=1: 1M sim BRAM, stall=0.
module weight_tile803k #(
    parameter bit SIM_FULL = 1'b1
) (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               clk_dma,
    input  logic               rst_dma_n,
    input  logic               we_a,
    input  logic [19:0]        addr_a,
    input  logic signed [7:0]  wdata_a,
    output logic signed [7:0]  rdata_a,
    input  logic [19:0]        addr_b,
    output logic signed [7:0]  rdata_b,
    output logic               stall,
    output logic [2:0]         cached_rg,
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
    input  logic [127:0]       dma_r_data,
    output logic [3:0]         dbg_bst,
    output logic [2:0]         dbg_dst,
    output logic [2:0]         dbg_cur_rg,
    output logic               dbg_miss,
    output logic               dbg_dirty,
    output logic               dbg_req,
    output logic               dbg_req_s1
);
    function automatic [2:0] rg_of(input logic [19:0] a);
        if (a < 20'(OFF_POS)) return 3'd0;
        if (a < 20'(OFF_L0))  return 3'd1;
        if (a < 20'(OFF_HEAD)) return 3'd2 + 3'((a - 20'(OFF_L0)) / 20'(LAYER_W));
        return 3'd6;
    endfunction
    function automatic [16:0] loc_of(input logic [19:0] a);
        if (a < 20'(OFF_POS)) return a[16:0];
        if (a < 20'(OFF_L0))  return 17'(a - 20'(OFF_POS));
        if (a < 20'(OFF_HEAD)) return 17'((a - 20'(OFF_L0)) % 20'(LAYER_W));
        return 17'(a - 20'(OFF_HEAD));
    endfunction
    function automatic [19:0] rg_base(input logic [2:0] rg);
        case (rg)
            3'd0: return 20'(OFF_TOK);
            3'd1: return 20'(OFF_POS);
            3'd2: return 20'(OFF_L0);
            3'd3: return 20'(OFF_L0) + 20'(LAYER_W);
            3'd4: return 20'(OFF_L0) + 20'(2 * LAYER_W);
            3'd5: return 20'(OFF_L0) + 20'(3 * LAYER_W);
            default: return 20'(OFF_HEAD);
        endcase
    endfunction
    function automatic [10:0] rg_nline(input logic [2:0] rg);
        return (rg == 3'd1) ? 11'd128 : 11'd1024;
    endfunction

    generate
        if (SIM_FULL) begin : FULL
            weight_bram803k u_full (
                .clk(clk), .we_a(we_a), .addr_a(addr_a), .wdata_a(wdata_a),
                .rdata_a(rdata_a), .addr_b(addr_b), .rdata_b(rdata_b)
            );
            assign stall = 1'b0;
            assign cached_rg = 3'd0;
            assign dirty = 1'b0;
            assign dma_owner = 1'b0;
            assign dma_go = 1'b0;
            assign dma_wr = 1'b0;
            assign dma_addr = 28'(DDR_WBASE);
            assign dma_bytes = 32'd128;
            assign dbg_bst = 4'd0;
            assign dbg_dst = 3'd0;
            assign dbg_cur_rg = 3'd0;
            assign dbg_miss = 1'b0;
            assign dbg_dirty = 1'b0;
            assign dbg_req = 1'b0;
            assign dbg_req_s1 = 1'b0;
            assign dma_w_valid = 1'b0;
            assign dma_w_data = 128'd0;
            assign dma_r_ready = 1'b0;
        end else begin : TILE
            localparam int CHUNK = 128;
            logic [2:0]  hold_rg, cur_rg;
            logic        need_a, need_b, miss, dirty_r;
            logic [9:0]  i;
            logic [10:0] ch;
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
            logic        bank_we;
            logic [16:0] bank_aa, bank_ab, tile_idx;
            logic signed [7:0] bank_wd, bank_ra, bank_rb;
            logic        refill;
            logic [10:0] nline_h;

            assign need_a = (rg_of(addr_a) != cur_rg);
            // Port A owns the resident region. Port B is a helper; a
            // TOK/POS or layer straddle must not start a second miss
            // (C0 board: upload hung at 131072, busy held by oscillation).
            assign need_b = 1'b0;
            assign miss   = need_a;
            assign stall  = (bst != B_IDLE) || miss;
            assign cached_rg = cur_rg;
            assign dirty = dirty_r;
            assign dma_owner = (dst != D_IDLE);
            assign dbg_bst = bst;
            assign dbg_cur_rg = cur_rg;
            assign dbg_miss = miss;
            assign dbg_dirty = dirty_r;
            assign dbg_req = req;
            assign dbg_req_s1 = req_s[1];
            logic [2:0] dst_s0, dst_s1;
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    dst_s0 <= 3'd0;
                    dst_s1 <= 3'd0;
                end else begin
                    dst_s0 <= dst;
                    dst_s1 <= dst_s0;
                end
            end
            assign dbg_dst = dst_s1;
            assign dma_w_data = line_wr[128*beat +: 128];
            assign dma_w_valid = (dst == D_FEED);
            assign dma_r_ready = (dst == D_DRAIN);
            assign refill = (bst == B_FILL) || (bst == B_FWAIT) || (bst == B_FCAP)
                         || (bst == B_STORE) || (bst == B_SWAIT);
            assign tile_idx = 17'(ch) * 17'(CHUNK) + 17'(i);
            assign nline_h = rg_nline(is_flush ? cur_rg : hold_rg);
            assign bank_we = (bst == B_STORE)
                          || (we_a && (bst == B_IDLE) && !need_a);
            assign bank_wd = (bst == B_STORE) ? line_rd[8*i +: 8] : wdata_a;
            assign bank_aa = refill ? tile_idx : loc_of(addr_a);
            assign bank_ab = loc_of(addr_b);

            weight_bram_tdp8 #(.DEPTH(131072)) u_bank (
                .clk(clk), .we_a(bank_we), .addr_a(bank_aa), .wdata_a(bank_wd),
                .rdata_a(bank_ra), .addr_b(bank_ab), .rdata_b(bank_rb)
            );
            assign rdata_a = bank_ra;
            assign rdata_b = bank_rb;

            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    bst <= B_IDLE;
                    cur_rg <= 3'd0;
                    hold_rg <= 3'd0;
                    dirty_r <= 1'b0;
                    is_flush <= 1'b0;
                    i <= 10'd0;
                    ch <= 11'd0;
                    waitn <= 4'd0;
                    req <= 1'b0;
                    ack_s <= 2'd0;
                end else begin
                    ack_s <= {ack_s[0], ack};
                    if (we_a && (bst == B_IDLE) && !need_a)
                        dirty_r <= 1'b1;
                    unique case (bst)
                        B_IDLE: begin
                            req <= 1'b0;
                            if (miss) begin
                                hold_rg <= need_a ? rg_of(addr_a) : rg_of(addr_b);
                                ch <= 11'd0;
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
                            line_wr[8*i +: 8] <= bank_ra;
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
                                    if (ch == nline_h - 11'd1) begin
                                        dirty_r <= 1'b0;
                                        is_flush <= 1'b0;
                                        ch <= 11'd0;
                                        i <= 10'd0;
                                        bst <= B_REQ;
                                    end else begin
                                        ch <= ch + 11'd1;
                                        i <= 10'd0;
                                        bst <= B_FILL;
                                    end
                                end else begin
                                    i <= 10'd0;
                                    bst <= B_STORE;
                                end
                            end
                        end
                        B_STORE: bst <= B_SWAIT;
                        B_SWAIT: begin
                            if (i == 10'(CHUNK - 1))
                                bst <= B_NEXT;
                            else begin
                                i <= i + 10'd1;
                                bst <= B_STORE;
                            end
                        end
                        B_NEXT: begin
                            if (ch == nline_h - 11'd1) begin
                                cur_rg <= hold_rg;
                                dirty_r <= 1'b0;
                                bst <= B_IDLE;
                            end else begin
                                ch <= ch + 11'd1;
                                i <= 10'd0;
                                bst <= B_REQ;
                            end
                        end
                        default: bst <= B_IDLE;
                    endcase
                end
            end

            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    dst <= D_IDLE;
                    dma_go <= 1'b0;
                    dma_wr <= 1'b0;
                    dma_addr <= 28'(DDR_WBASE);
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
                            // Raw dma_busy (not AND-owned): dest is IDLE so
                            // owner=0; a gated busy would always look free
                            // and pulse go into a still-busy MIG.
                            if (req_s[1] && !dma_busy) begin
                                beat <= 7'd0;
                                dst <= D_GO;
                            end
                        end
                        D_GO: begin
                            dma_go <= 1'b1;
                            dma_wr <= is_flush;
                            dma_addr <= 28'(DDR_WBASE) + 28'(rg_base(is_flush ? cur_rg : hold_rg))
                                + {10'd0, ch, 7'd0};
                            dma_bytes <= 32'(CHUNK);
                            beat <= 7'd0;
                            if (dma_busy)
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
