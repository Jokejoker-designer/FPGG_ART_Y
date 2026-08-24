`timescale 1ns/1ps
// Dual-clock persist: BRAM/tile walk on clk_bram (clk50), AXI DMA on clk_dma (ui_clk).
// 802816/128 = 6272 lines. mem_stall holds a line fill across a tile miss.
import a7lm06_pkg::*;
module lm06_persist (
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
    output logic         mem_sel,
    output logic         mem_we,
    output logic [19:0]  mem_addr,
    output logic signed [7:0] mem_wdata,
    input  logic signed [7:0] mem_rdata,
    input  logic         mem_stall,
    output logic         dma_go,
    output logic         dma_wr,
    output logic [27:0]  dma_addr,
    output logic [31:0]  dma_bytes,
    input  logic         dma_busy,
    input  logic         dma_done,
    input  logic         tile_hold,
    input  logic         dma_under,
    input  logic         axi_berr,
    input  logic         axi_rerr,
    output logic         dma_w_valid,
    input  logic         dma_w_ready,
    output logic [127:0] dma_w_data,
    input  logic         dma_r_valid,
    output logic         dma_r_ready,
    input  logic [127:0] dma_r_data,
    output logic [3:0]   dbg_bst,
    output logic [2:0]   dbg_dst,
    output logic [12:0]  dbg_ch,
    output logic         dbg_is_flush,
    output logic         dbg_req
);
    localparam int CHUNK = 128;

    typedef enum logic [3:0] {
        B_IDLE, B_FILL, B_FWAIT, B_FCAP, B_REQ, B_WAITACK,
        B_STORE, B_SWAIT, B_DONE, B_TOUCH
    } bst_t;
    typedef enum logic [2:0] {
        D_IDLE, D_GO, D_FEED, D_DRAIN, D_WAITDONE, D_ACK
    } dst_t;

    bst_t bst;
    dst_t dst;
    logic        is_flush;
    logic [19:0] base;
    logic [9:0]  i;
    logic [3:0]  waitn;
    logic [6:0]  beat;
    logic [12:0] ch;
    // Keep the CDC payload as eight AXI beats instead of one 1024-bit vector.
    // The request/ack handshake still guarantees ownership, while the smaller
    // selectors avoid a 128-byte-wide variable part-select on both clocks.
    (* ram_style = "registers" *) logic [127:0] line_wr [0:7];
    (* ram_style = "registers" *) logic [127:0] line_rd [0:7];
    logic        req, ack;
    logic [1:0]  req_s, ack_s;

    logic        wr_hold;
    logic [27:0] addr_hold;

    assign busy = (bst != B_IDLE) && (bst != B_DONE);
    // B_REQ/WAITACK must not steal the tile address. C1 hang TB: persist
    // reload parked on HEAD, then muxed addr=0 and started a TOK miss that
    // held tile dest forever so persist dest never left B_REQ.
    assign mem_sel = (bst == B_FILL) || (bst == B_FWAIT) || (bst == B_FCAP)
                  || (bst == B_TOUCH) || (bst == B_STORE) || (bst == B_SWAIT);
    assign dma_owner = (dst != D_IDLE);
    assign dbg_bst = bst;
    assign dbg_ch = ch;
    assign dbg_is_flush = is_flush;
    assign dbg_req = req;
    logic [2:0] dst_s0, dst_s1;
    always_ff @(posedge clk_bram) begin
        if (!rst_bram_n) begin
            dst_s0 <= 3'd0;
            dst_s1 <= 3'd0;
        end else begin
            dst_s0 <= dst;
            dst_s1 <= dst_s0;
        end
    end
    assign dbg_dst = dst_s1;
    assign dma_w_data = line_wr[beat[2:0]];
    assign dma_w_valid = (dst == D_FEED);
    assign dma_r_ready = (dst == D_DRAIN);

    always_ff @(posedge clk_bram) begin
        if (!rst_bram_n) begin
            bst <= B_IDLE;
            done <= 1'b0;
            mem_we <= 1'b0;
            mem_addr <= 20'd0;
            mem_wdata <= 8'sd0;
            bytes_done <= 32'd0;
            is_flush <= 1'b0;
            base <= 20'd0;
            i <= 10'd0;
            waitn <= 4'd0;
            ch <= 13'd0;
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
                        base <= 20'd0;
                        ch <= 13'd0;
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
                            if (ch == 13'(NCHUNK - 1))
                                bst <= B_DONE;
                            else begin
                                ch <= ch + 13'd1;
                                base <= base + 20'(CHUNK);
                                i <= 10'd0;
                                bst <= B_FILL;
                            end
                        end else begin
                            i <= 10'd0;
                            waitn <= 4'd0;
                            bst <= B_TOUCH;
                        end
                    end
                end
                B_TOUCH: begin
                    // Present the reload address with we=0 so a region miss
                    // can refill before the first write (same as UART 0x30).
                    mem_addr <= base + {9'd0, i};
                    if (mem_stall)
                        waitn <= 4'd0;
                    else if (waitn < 4'd2)
                        waitn <= waitn + 4'd1;
                    else
                        bst <= B_STORE;
                end
                B_STORE: begin
                    if (!mem_stall) begin
                        mem_we <= 1'b1;
                        mem_addr <= base + {9'd0, i};
                        mem_wdata <= line_rd[i[6:4]][8*i[3:0] +: 8];
                        bst <= B_SWAIT;
                    end else
                        bst <= B_TOUCH;
                end
                B_SWAIT: begin
                    if (mem_stall) begin
                        waitn <= 4'd0;
                        bst <= B_TOUCH;
                    end else if (i == 10'(CHUNK - 1)) begin
                        if (ch == 13'(NCHUNK - 1))
                            bst <= B_DONE;
                        else begin
                            ch <= ch + 13'd1;
                            base <= base + 20'(CHUNK);
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
            wr_hold <= 1'b0;
            addr_hold <= 28'(DDR_WBASE);
            req_s <= 2'd0;
        end else begin
            dma_go <= 1'b0;
            req_s <= {req_s[0], req};
            unique case (dst)
                D_IDLE: begin
                    ack <= 1'b0;
                    // Do not steal the MIG while a tile refill owns it, or
                    // while the previous burst is still busy (go is ignored).
                    if (req_s[1] && !dma_busy && !tile_hold) begin
                        beat <= 7'd0;
                        wr_hold <= is_flush;
                        addr_hold <= 28'(DDR_WBASE) + {9'd0, base};
                        dst <= D_GO;
                    end
                end
                D_GO: begin
                    // Hold go until busy so a 1-cycle pulse cannot miss
                    // ddr_tile_dma / mock IDLE (C1 lost-go).
                    if (tile_hold)
                        dst <= D_IDLE;
                    else begin
                        dma_go <= 1'b1;
                        dma_wr <= wr_hold;
                        dma_addr <= addr_hold;
                        dma_bytes <= 32'(CHUNK);
                        beat <= 7'd0;
                        if (dma_busy)
                            dst <= wr_hold ? D_FEED : D_DRAIN;
                    end
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
