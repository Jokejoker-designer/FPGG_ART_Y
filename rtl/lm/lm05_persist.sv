`timescale 1ns/1ps
// Dual-clock persist: BRAM/tile walk on clk_bram (clk50), AXI DMA on clk_dma (ui_clk).
// 399360/128 = 3120 lines. mem_stall holds a line fill across a tile miss.
import a7lm05_pkg::*;
module lm05_persist (
    input  logic         clk_bram,
    input  logic         rst_bram_n,
    input  logic         clk_dma,
    input  logic         rst_dma_n,
    input  logic         go_flush,
    input  logic         go_reload,
    output logic         busy,
    output logic         done,
    output logic [31:0]  bytes_done,
    output logic         last_under,
    output logic         last_berr,
    output logic         last_rerr,
    output logic         dma_owner,
    output logic         mem_we,
    output logic [18:0]  mem_addr,
    output logic signed [7:0] mem_wdata,
    input  logic signed [7:0] mem_rdata,
    input  logic         mem_stall,
    output logic         dma_go,
    output logic         dma_wr,
    output logic [27:0]  dma_addr,
    output logic [31:0]  dma_bytes,
    input  logic         dma_busy,
    input  logic         dma_done,
    input  logic         dma_under,
    input  logic         axi_berr,
    input  logic         axi_rerr,
    output logic         dma_w_valid,
    input  logic         dma_w_ready,
    output logic [127:0] dma_w_data,
    input  logic         dma_r_valid,
    output logic         dma_r_ready,
    input  logic [127:0] dma_r_data
);
    localparam int CHUNK = 128;

    typedef enum logic [3:0] {
        B_IDLE, B_FILL, B_FWAIT, B_FCAP, B_REQ, B_WAITACK,
        B_STORE, B_SWAIT, B_DONE
    } bst_t;
    typedef enum logic [2:0] {
        D_IDLE, D_GO, D_FEED, D_DRAIN, D_WAITDONE, D_ACK
    } dst_t;

    bst_t bst;
    dst_t dst;
    logic        is_flush;
    logic [18:0] base;
    logic [9:0]  i;
    logic [3:0]  waitn;
    logic [6:0]  beat;
    logic [11:0] ch;
    // Keep the CDC payload as eight AXI beats instead of one 1024-bit vector.
    // The request/ack handshake still guarantees ownership, while the smaller
    // selectors avoid a 128-byte-wide variable part-select on both clocks.
    (* ram_style = "registers" *) logic [127:0] line_wr [0:7];
    (* ram_style = "registers" *) logic [127:0] line_rd [0:7];
    logic        req, ack;
    logic [1:0]  req_s, ack_s;

    assign busy = (bst != B_IDLE) && (bst != B_DONE);
    assign dma_owner = (dst != D_IDLE);
    assign dma_w_data = line_wr[beat[2:0]];
    assign dma_w_valid = (dst == D_FEED);
    assign dma_r_ready = (dst == D_DRAIN);

    always_ff @(posedge clk_bram) begin
        if (!rst_bram_n) begin
            bst <= B_IDLE;
            done <= 1'b0;
            mem_we <= 1'b0;
            mem_addr <= 19'd0;
            mem_wdata <= 8'sd0;
            bytes_done <= 32'd0;
            is_flush <= 1'b0;
            base <= 19'd0;
            i <= 10'd0;
            waitn <= 4'd0;
            ch <= 12'd0;
            req <= 1'b0;
            ack_s <= 2'd0;
        end else begin
            done <= 1'b0;
            mem_we <= 1'b0;
            ack_s <= {ack_s[0], ack};
            unique case (bst)
                B_IDLE: begin
                    req <= 1'b0;
                    if (go_flush || go_reload) begin
                        is_flush <= go_flush;
                        base <= 19'd0;
                        ch <= 12'd0;
                        i <= 10'd0;
                        waitn <= 4'd0;
                        bytes_done <= 32'd0;
                        bst <= go_flush ? B_FILL : B_REQ;
                    end
                end
                B_FILL: begin
                    mem_addr <= base + {9'd0, i};
                    waitn <= 4'd0;
                    bst <= B_FWAIT;
                end
                B_FWAIT: begin
                    if (mem_stall)
                        waitn <= 4'd0;
                    else if (waitn < 4'd2)
                        waitn <= waitn + 4'd1;
                    else
                        bst <= B_FCAP;
                end
                B_FCAP: begin
                    line_wr[i[6:4]][8*i[3:0] +: 8] <= mem_rdata;
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
                        bytes_done <= bytes_done + 32'(CHUNK);
                        if (is_flush) begin
                            if (ch == 12'(NCHUNK - 1))
                                bst <= B_DONE;
                            else begin
                                ch <= ch + 12'd1;
                                base <= base + 19'(CHUNK);
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
                    if (!mem_stall) begin
                        mem_we <= 1'b1;
                        mem_addr <= base + {9'd0, i};
                        mem_wdata <= line_rd[i[6:4]][8*i[3:0] +: 8];
                        bst <= B_SWAIT;
                    end
                end
                B_SWAIT: begin
                    if (mem_stall) begin
                        // hold we off; retry STORE
                        bst <= B_STORE;
                    end else if (i == 10'(CHUNK - 1)) begin
                        if (ch == 12'(NCHUNK - 1))
                            bst <= B_DONE;
                        else begin
                            ch <= ch + 12'd1;
                            base <= base + 19'(CHUNK);
                            i <= 10'd0;
                            bst <= B_REQ;
                        end
                    end else begin
                        i <= i + 10'd1;
                        bst <= B_STORE;
                    end
                end
                B_DONE: begin
                    done <= 1'b1;
                    req <= 1'b0;
                    bst <= B_IDLE;
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
            dma_addr <= 28'(DDR_WBASE);
            dma_bytes <= 32'(CHUNK);
            beat <= 7'd0;
            ack <= 1'b0;
            last_under <= 1'b0;
            last_berr <= 1'b0;
            last_rerr <= 1'b0;
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
                    dma_addr <= 28'(DDR_WBASE) + {9'd0, base};
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
                    if (dma_under) last_under <= 1'b1;
                    if (axi_berr) last_berr <= 1'b1;
                end
                D_DRAIN: begin
                    if (dma_r_valid) begin
                        line_rd[beat[2:0]] <= dma_r_data;
                        if (beat == 7'd7)
                            dst <= D_WAITDONE;
                        else
                            beat <= beat + 7'd1;
                    end
                    if (axi_rerr) last_rerr <= 1'b1;
                end
                D_WAITDONE: begin
                    if (dma_done || !dma_busy) begin
                        if (dma_under) last_under <= 1'b1;
                        if (axi_berr) last_berr <= 1'b1;
                        if (axi_rerr) last_rerr <= 1'b1;
                        dst <= D_ACK;
                    end
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
endmodule
